extends RefCounted
## A dedicated transfer screen leaves room for the actual bag grid and the
## selected find, without the journal's persistent navigation.
const Bag=preload("res://scripts/backpack.gd")
const INK=Color("e9e5d8")
const DIM=Color("9faeaa")
const GOLD=Color("dec68f")

static func surface(h,bg:Color,rule:Color,width:int=1)->StyleBoxFlat:
	var skin:StyleBoxFlat=h.style(bg,rule,width,5)
	skin.shadow_size=0
	return skin

static func show(h,target:String,selected:String=""):
	var w=h.world
	var raid=load("res://scripts/raid_loot.gd")
	if not raid.can_reach(w,target) or not raid.safe(w):
		h.toast("需要在安全位置靠近容器。")
		return
	var record:Dictionary=raid.record(w,target)
	if record.is_empty() or not record.searched:return
	var ui=load("res://scripts/ui_workbench.gd")
	var s=w.story
	h.start_modal(record.title,"",true,"screen:field_transfer")
	for child in h.modal.get_children(true):
		h.modal.remove_child(child)
		child.queue_free()
	h.modal.position=Vector2(74,70)
	h.modal.size=Vector2(1452,850)
	h.modal.add_theme_stylebox_override("panel",surface(h,Color(.078,.111,.110,.96),Color("596762")))
	h.scrim.color=Color(.047,.062,.065,.56)
	h.set_meta("fixed_screen","field_transfer")
	var main=h.margin_box(h.modal,32,26)
	main.add_theme_constant_override("separation",18)
	var heading=ui.row(main,20)
	var nameplate=ui.column(heading)
	nameplate.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	nameplate.add_theme_constant_override("separation",3)
	ui.words(h,nameplate,w.floor_name()+"  /  "+w.room_name,16,DIM)
	h.dialog_title=ui.words(h,nameplate,record.title,36,INK)
	h.dialog_title.add_theme_font_override("font",h.serif)
	ui.action(h,heading,"Esc  结束搜索",func():h.close())
	ui.line(main)
	var panes=ui.row(main,30)
	panes.size_flags_vertical=Control.SIZE_EXPAND_FILL
	var found=ui.column(panes,572)
	found.add_theme_constant_override("separation",10)
	var divider=VSeparator.new()
	panes.add_child(divider)
	var bag=ui.column(panes)
	bag.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	bag.add_theme_constant_override("separation",9)
	h.modal_box=main

	var ids:Array=record.loot.keys()
	var page_key=target+"_field_page"
	var index=clampi(int(h.get_meta(page_key,0)),0,maxi(0,ceili(ids.size()/5.0)-1))
	var entries:Array=ids.slice(index*5,index*5+5)
	var choice_key=target+"_field_selection"
	var incoming:String=h.get_meta(choice_key,"")
	if incoming not in entries:incoming="" if entries.is_empty() else entries[0]
	h.set_meta(choice_key,incoming)
	var found_header=ui.row(found)
	ui.words(h,found_header,"容器内的物资",24,INK)
	var count=ui.words(h,found_header,"%d 件"%total(record.loot),17,DIM)
	count.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	if entries.is_empty():ui.words(h,found,"容器已搜空。",20,DIM)
	for id in entries:
		var item:String=id
		var button=loot_button(h,found,Bag.name_of(s,item),int(record.loot[item]),item,item==incoming,func():
			h.set_meta(choice_key,item)
			show(h,target,selected))
		button.name="FieldLootEntry_"+item
	if ids.size()>5:ui.page(h,found,page_key,ids.size(),5,func():show(h,target,selected))
	ui.gap(found)
	var pack=Bag.pack(s,{},true)
	var placement=preview(s,pack,incoming)
	if incoming!="":about_find(h,ui,found,raid,record,target,incoming,selected,placement)
	bag_contents(h,ui,bag,raid,target,selected,pack,placement)
	ui.line(main)
	h.modal_hint=ui.words(h,main,"拖动整理格位  ·  选中背包物品可旋转或放回  ·  Esc 返回",14,DIM)

static func total(loot:Dictionary)->int:
	var result=0
	for amount in loot.values():result+=int(amount)
	return result

static func loot_button(h,parent,title:String,quantity:int,id:String,active:bool,callback:Callable)->Button:
	var b:Button=h.button(title+"   ×%d"%quantity,callback,true,true)
	b.custom_minimum_size=Vector2(0,53)
	b.icon=load(h.item_icon(id))
	b.expand_icon=true
	b.add_theme_constant_override("icon_max_width",38)
	b.add_theme_constant_override("h_separation",16)
	b.add_theme_font_size_override("font_size",19)
	b.add_theme_color_override("font_color",INK)
	var normal=surface(h,Color("373a2e") if active else Color("222d2b"),Color("a58d61") if active else Color("3d4b49"))
	normal.content_margin_left=15
	normal.content_margin_right=16
	b.add_theme_stylebox_override("normal",normal)
	var hover=normal.duplicate()
	hover.bg_color=Color("3c4a43")
	hover.border_color=Color("b9ad88")
	b.add_theme_stylebox_override("hover",hover)
	b.add_theme_stylebox_override("focus",hover)
	parent.add_child(b)
	return b

static func about_find(h,ui,parent,raid,record:Dictionary,target:String,id:String,selected:String,placement:Dictionary):
	var s=h.world.story
	ui.line(parent)
	ui.words(h,parent,Bag.name_of(s,id),25,GOLD)
	var note="土制弹用于战斗，制式弹也可用于交易。"
	if s.Economy.GOODS.has(id):note=s.Economy.GOODS[id].detail
	elif s.ITEMS.has(id):note=s.ITEMS[id][1]
	ui.words(h,parent,note,17,INK)
	ui.words(h,parent,ui.dimensions(s,id),15,DIM)
	var controls=ui.row(parent,10)
	var take=ui.action(h,controls,"收取一件  →",func():
		if not raid.take(h.world,target,id):h.toast("背包没有适合这件物品的连续空格。")
		show(h,target,selected),not placement.get("blocked",false),true)
	take.name="TakeFieldItem"
	if not take.disabled:
		var ink:StyleBoxFlat=take.get_theme_stylebox("normal").duplicate()
		ink.bg_color=Color("d8bd89")
		ink.border_color=Color("e6cb95")
		take.add_theme_stylebox_override("normal",ink)
		take.add_theme_color_override("font_color",Color("292b23"))
	if int(record.loot[id])>1:ui.action(h,controls,"收取这叠",func():raid.take_all(h.world,target,id),not placement.get("blocked",false))
	ui.action(h,controls,"收取能放下的全部",func():raid.take_all(h.world,target))

static func bag_contents(h,ui,parent,raid,target:String,selected:String,pack:Dictionary,placement:Dictionary):
	var s=h.world.story
	var summary=ui.row(parent)
	ui.words(h,summary,"随身背包",24,INK)
	var used=ui.words(h,summary,"%d / 48 格"%pack.used,18,DIM)
	used.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	var center=CenterContainer.new()
	parent.add_child(center)
	var grid=load("res://scripts/inventory_grid.gd").new()
	grid.cell=64
	grid.field_preview=placement
	grid.field_style=true
	center.add_child(grid)
	grid.setup(h,selected,"all",func(id):show(h,target,id))
	var note:String=placement.get("note","")
	if note!="":ui.words(h,parent,note,16,GOLD if not placement.get("blocked",false) else Color("e2ad96"))
	var selection=pack.pieces.filter(func(p):return p.key==h.get_meta("bag_selected_key","") and p.id==selected)
	if not selection.is_empty():
		var piece:Dictionary=selection[0]
		ui.words(h,parent,Bag.name_of(s,piece.id)+"   "+ui.dimensions(s,piece.id),16,INK)
		var controls=ui.row(parent,10)
		ui.action(h,controls,"旋转",func():
			if Bag.move_piece(s,piece.key,piece.at,true):h.world.autosave()
			else:h.toast("旋转后放不下，请先腾出相邻格。")
			show(h,target,piece.id),piece.size.x!=piece.size.y)
		ui.action(h,controls,"放回容器 ×1",func():
			if not raid.store(h.world,target,piece.id):h.toast("这件物品无法留在容器里。")
			show(h,target,piece.id))
	if not pack.overflow.is_empty():ui.words(h,parent,"还有 %d 组物资在栏外。"%pack.overflow.size(),15,DIM)

static func preview(s,pack:Dictionary,id:String)->Dictionary:
	if id=="":return {}
	if id in ["military","handmade"]:return {"note":"收取后直接装入弹药储备。"}
	if not Bag.can_add(s,id):return {"blocked":true,"note":"当前没有合适的空格，或身上已有这件装备。"}
	if s.Economy.GOODS.has(id):
		var current={}
		for piece in pack.pieces:current[piece.key]=piece.count
		for piece in Bag.pack(s,{id:1}).pieces:
			if piece.id!=id or int(piece.count)<=int(current.get(piece.key,0)):continue
			if current.has(piece.key):return {"key":piece.key,"note":"收取后叠入标记的格位。"}
			return {"id":id,"at":piece.at,"size":piece.size,"note":"金色框标记收取后的格位。"}
	elif id in ["mask","filter"]:return {"note":"收取后放入外勤装备栏。"}
	elif not Bag.protected_item(id):
		var occupied={}
		for piece in pack.pieces:Bag.occupy(occupied,piece.at,piece.size)
		var fit=Bag.fit_piece(Bag.size_of(id),occupied)
		if not fit.is_empty():return {"id":id,"at":fit[0],"size":fit[1],"note":"金色框标记收取后的格位。"}
	return {"note":"收取后随身携带。"}
