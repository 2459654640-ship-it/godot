extends RefCounted
## Local storage: contents stay at the settlement, serialized with the economy.
const LOCKERS={"life":Vector3(-14.2,0,-2),"commune":Vector3(3.1,0,22.5),"sech":Vector3(-15,0,12)}
const NAMES={"life":"伊万的储物柜","commune":"公社客人物资柜","sech":"住户车厢寄存柜"}
static func setup(w):
	if LOCKERS.has(w.floor_id):w.target("personal_storage",LOCKERS[w.floor_id]+Vector3(0,0,.8),NAMES[w.floor_id])
static func accessible(w)->bool:
	if not LOCKERS.has(w.floor_id) or (is_instance_valid(w.combat) and w.combat.active):return false
	return Vector2(w.player.position.x,w.player.position.z).distance_to(Vector2(LOCKERS[w.floor_id].x,LOCKERS[w.floor_id].z))<2.5
static func move(s,place:String,id:String,count:int,deposit:bool)->bool:
	var bag=preload("res://scripts/backpack.gd")
	if not LOCKERS.has(place) or s.context.get("floor","")!=place or count<=0:return false
	if id not in bag.ORDINARY_ITEMS and id not in ["military","handmade"] and not s.Economy.GOODS.has(id):return false
	var all:Dictionary=s.economy.stashes;var stored:Dictionary=all.get(place,{})
	if deposit:
		if bag.count(s,id)<count:return false
		bag.change(s,id,-count);stored[id]=int(stored.get(id,0))+count
	else:
		if int(stored.get(id,0))<count:return false
		if id not in ["military","handmade"] and not bag.can_add(s,id,count):return false
		stored[id]-=count;bag.change(s,id,count)
		if stored[id]==0:stored.erase(id)
	all[place]=stored;s.changed.emit();return true
static func render(h,deposit:bool=true):
	var w=h.world
	if not accessible(w):h.toast("走到物资柜旁，再存放或领取物品。");return
	var s=w.story;var place:String=w.floor_id
	h.start_modal(NAMES[place],"物品留在这里，返回这处聚落时可以取回。",true)
	var tabs=HBoxContainer.new();h.modal_box.add_child(tabs)
	tabs.add_child(h.button("存入背包物资",func():render(h,true),true,true))
	tabs.add_child(h.button("领取寄存物资",func():render(h,false),true,true))
	h.body("武器、防护装备、子弹与普通物资都可寄存。不同聚落的寄存柜独立；任务文件随身保护。",17,h.muted)
	if s.flags.get("raid_last_result","")=="lost":
		h.body("上次行动损失："+"、".join(s.flags.get("raid_losses",[])),17,h.amber)
		if (not s.has("revolver") and not s.has("grey_carbine")) or not s.has("mask") or not s.has("filter"):
			h.modal_box.add_child(h.button("借用基础外勤装备 · 撤回后偿还 8 发制式弹",func():
				if not s.has("revolver") and not s.has("grey_carbine"):s.give("revolver");s.equip_weapon("revolver")
				if not s.has("mask"):s.give("mask")
				if not s.has("filter"):s.give("filter")
				s.economy.handmade=maxi(8,int(s.economy.handmade));s.flags.raid_loan=maxi(8,int(s.flags.get("raid_loan",0)));w.autosave();render(h,deposit)))
	var source:Dictionary=s.economy.goods.duplicate() if deposit else s.economy.stashes.get(place,{})
	var bag=preload("res://scripts/backpack.gd")
	if deposit:
		for id in bag.ORDINARY_ITEMS:
			if s.has(id):source[id]=1
		for id in ["military","handmade"]:
			if s.economy[id]>0:source[id]=s.economy[id]
	var found=false
	for id in source:
		if int(source.get(id,0))<=0:continue
		found=true;var item:String=id;var count:int=source[id]
		var row=HBoxContainer.new();row.add_theme_constant_override("separation",16);h.modal_box.add_child(row)
		row.add_child(h.icon_rect(h.item_icon(id),46))
		var label=h.label(bag.name_of(s,id)+" × %d"%count,20,h.text_color);label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(label)
		for amount in ([1,count] if count>1 else [1]):
			var quantity:int=amount
			row.add_child(h.button(("存入" if deposit else "领取")+("全部" if count>1 and amount==count else "一份"),func():
				if accessible(w) and move(s,place,item,quantity,deposit):w.autosave()
				else:h.toast("背包容量不足，或已经携带这件装备。")
				render(h,deposit),true,true))
	if not found:h.body("没有可以存放的物资。" if deposit else "柜子里暂时没有物资。",20,h.muted)
