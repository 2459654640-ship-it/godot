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
	if not LOCKERS.has(place) or s.context.get("floor","")!=place or not s.Economy.GOODS.has(id) or id=="portable_radio" or count<=0:return false
	var all:Dictionary=s.economy.stashes
	var stored:Dictionary=all.get(place,{})
	var source:Dictionary=s.economy.goods if deposit else stored
	var dest:Dictionary=stored if deposit else s.economy.goods
	if int(source.get(id,0))<count:return false
	source[id]=int(source[id])-count
	if source[id]==0:source.erase(id)
	dest[id]=int(dest.get(id,0))+count
	all[place]=stored;s.changed.emit();return true
static func render(h,deposit:bool=true):
	var w=h.world
	if not accessible(w):h.toast("走到物资柜旁，再存放或领取物品。");return
	var s=w.story;var place:String=w.floor_id
	h.start_modal(NAMES[place],"物品留在这里，返回这处聚落时可以取回。",true)
	var tabs=HBoxContainer.new();h.modal_box.add_child(tabs)
	tabs.add_child(h.button("存入背包物资",func():render(h,true),true,true))
	tabs.add_child(h.button("领取寄存物资",func():render(h,false),true,true))
	h.body("任务文件、武器和随身收音机随身保管。不同聚落的寄存柜独立。",17,h.muted)
	var source:Dictionary=s.economy.goods if deposit else s.economy.stashes.get(place,{})
	var found=false
	for id in s.Economy.GOODS:
		if id=="portable_radio" or int(source.get(id,0))<=0:continue
		found=true;var item:String=id;var count:int=source[id]
		var row=HBoxContainer.new();row.add_theme_constant_override("separation",16);h.modal_box.add_child(row)
		row.add_child(h.icon_rect(h.item_icon(id),46))
		var label=h.label(s.Economy.GOODS[id].name+" × %d"%count,20,h.text_color);label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(label)
		for amount in ([1,count] if count>1 else [1]):
			var quantity:int=amount
			row.add_child(h.button(("存入" if deposit else "领取")+("全部" if count>1 and amount==count else "一份"),func():
				if accessible(w) and move(s,place,item,quantity,deposit):w.autosave()
				render(h,deposit),true,true))
	if not found:h.body("没有可以存放的物资。" if deposit else "柜子里暂时没有物资。",20,h.muted)
