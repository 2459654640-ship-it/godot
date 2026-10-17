extends Control
const ComicUI=preload("res://scripts/ui_comic.gd")
const Dialogue=preload("res://scripts/ui_dialogue.gd")
const Journal=preload("res://scripts/journal.gd")
const MapView=preload("res://scripts/minimap.gd")
var world
var font=preload("res://assets/fonts/MetroSans.otf")
var serif=preload("res://assets/fonts/MetroSerif.otf")
var mono=preload("res://assets/fonts/MetroMono.ttf")
var objective: Label
var location_label: Label
var prompt: Label
var target_label: Label
var toast_label: Label
var toast_time=0.0
var modal: PanelContainer
var modal_box: VBoxContainer
var scrim: ColorRect
var map_small
var map_large
var inventory_count: Label
var quick_items:HBoxContainer
var quick_signature=""
var route_label: Label
var status_label: Label
var amber=Color("d7b477")
var text_color=Color("d5d0bd")
var muted=Color("8b9a92")
var dialogue_id=""
var dialog_title: Label
var is_departure=false
var comic_active=false
var typing:Array=[]
var last_choice=""

func _process(delta:float):
	advance_typing(delta)

func advance_typing(delta:float):
	for entry in typing:
		if not is_instance_valid(entry.label):continue
		entry.elapsed+=delta
		entry.label.visible_characters=mini(entry.total,floori(entry.elapsed*entry.rate))
	typing=typing.filter(func(entry):return is_instance_valid(entry.label) and entry.label.visible_characters<entry.total)

func finish_typing():
	for entry in typing:
		if is_instance_valid(entry.label):entry.label.visible_characters=-1
	typing.clear()

func _input(event):
	if modal_visible() and not typing.is_empty() and event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_SPACE,KEY_ENTER,KEY_KP_ENTER]:
		finish_typing()
		get_viewport().set_input_as_handled()

func setup(w):
	world=w
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	var theme=Theme.new()
	theme.default_font=font
	theme.default_font_size=20
	self.theme=theme
	# Top masthead and separated location plaque.
	var mast=panel(Vector2(32,28),Vector2(246,86))
	var b=margin_box(mast,18,10)
	b.add_theme_constant_override("separation",4)
	var line=HBoxContainer.new()
	b.add_child(line)
	var brand=label("МЕТРО",14,muted)
	brand.add_theme_font_override("font",mono)
	line.add_child(brand)
	line.add_spacer(false)
	line.add_child(label({"life":"D–6","labor":"D–6","waterworks":"水厂","commune":"公社","sech":"谢契","coal":"D–6","starcity":"星城"}.get(world.floor_id,""),17,amber))
	var title=label("地铁 1982",27,text_color)
	title.add_theme_font_override("font",serif)
	b.add_child(title)
	var top=panel(Vector2(298,28),Vector2(516,56))
	var topbox=margin_box(top,17,11)
	location_label=label("生活层 / 伊万的卧室",19,text_color)
	topbox.add_child(location_label)
	var tag=panel(Vector2(1240,28),Vector2(328,56))
	var tb=margin_box(tag,17,11)
	status_label=label("16 XI 1982   /   07:42",17,muted)
	status_label.add_theme_font_override("font",mono)
	tb.add_child(status_label)
	# Current goal is short; the detailed quest network belongs in the journal.
	var goal=panel(Vector2(32,134),Vector2(246,144))
	var gb=margin_box(goal,18,15)
	gb.add_child(label("当前目标  /  OBJECTIVE",14,amber))
	objective=label("",18,text_color)
	objective.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	gb.add_child(objective)
	var journal_btn=button("J   查看手记与路线",func():show_journal(),true,true)
	journal_btn.add_theme_font_size_override("font_size",16)
	gb.add_child(journal_btn)
	var key_panel=panel(Vector2(32,769),Vector2(250,93))
	var kb=margin_box(key_panel,16,12)
	kb.add_child(label("W A S D    移动       E   互动",16,text_color))
	kb.add_child(label("Tab  总览   /   滚轮  缩放",15,muted))
	# Minimap has geometry, not a screenshot of the reference.
	var mp=panel(Vector2(1302,106),Vector2(266,214))
	var mb=margin_box(mp,6,5)
	var mt=label(("D–6  /  " if world.floor_id in ["life","labor"] else "")+world.floor_name(),14,muted)
	mt.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	mb.add_child(mt)
	map_small=MapView.new()
	map_small.custom_minimum_size=Vector2(252,168)
	map_small.world=world
	mb.add_child(map_small)
	# Bottom command bar with a warmer identity block and a small route indicator.
	var bar=panel(Vector2(32,890),Vector2(1536,78))
	var row=HBoxContainer.new()
	row.add_theme_constant_override("separation",26)
	var mar=MarginContainer.new()
	mar.add_theme_constant_override("margin_left",22)
	mar.add_theme_constant_override("margin_right",22)
	mar.add_theme_constant_override("margin_top",14)
	bar.add_child(mar)
	mar.add_child(row)
	var identity=VBoxContainer.new()
	identity.custom_minimum_size.x=160
	row.add_child(identity)
	identity.add_child(label("ИВАН / 伊万",21,amber))
	identity.add_child(label("D-6 武装小队 · 23 岁",13,muted))
	var rule=VSeparator.new()
	row.add_child(rule)
	inventory_count=label("",18,text_color)
	row.add_child(inventory_count)
	quick_items=HBoxContainer.new()
	quick_items.add_theme_constant_override("separation",4)
	row.add_child(quick_items)
	row.add_child(button("I  背包",func():show_inventory(),true,true))
	row.add_child(button("J  手记",func():show_journal(),true,true))
	row.add_child(button("M  地图",func():show_map(),true,true))
	row.add_spacer(false)
	route_label=label("尚未选择离站方式",15,muted)
	row.add_child(route_label)
	row.add_child(button("Esc  菜单",func():show_pause(),true,true))
	prompt=label("",22,amber)
	add_child(prompt)
	prompt.position=Vector2(470,817)
	prompt.size=Vector2(660,45)
	prompt.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	prompt.add_theme_constant_override("outline_size",8)
	prompt.add_theme_color_override("font_outline_color",Color("0a1415"))
	target_label=label("",19,amber)
	add_child(target_label)
	target_label.add_theme_constant_override("outline_size",6)
	target_label.add_theme_color_override("font_outline_color",Color("0b1516"))
	toast_label=label("",18,amber)
	add_child(toast_label)
	toast_label.position=Vector2(420,110)
	toast_label.size=Vector2(760,55)
	toast_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	toast_label.add_theme_constant_override("outline_size",8)
	toast_label.add_theme_color_override("font_outline_color",Color("0b1516"))
	scrim=ColorRect.new()
	add_child(scrim)
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scrim.color=Color(0.02,0.05,0.055,0.58)
	scrim.visible=false
	scrim.mouse_filter=Control.MOUSE_FILTER_STOP
	modal=PanelContainer.new()
	add_child(modal)
	modal.add_theme_stylebox_override("panel",style(Color("101c1e"),Color("766747"),1,0))
	modal.visible=false
	refresh_status()

func style(bg: Color,border: Color,width: int=1,rad: int=0) -> StyleBoxFlat:
	var s=StyleBoxFlat.new()
	s.bg_color=bg
	s.border_color=border
	s.set_border_width_all(width)
	s.set_corner_radius_all(rad)
	s.shadow_color=Color(0,0,0,0.28)
	s.shadow_size=5
	return s
func panel(pos:Vector2,sz:Vector2) -> PanelContainer:
	var p=PanelContainer.new()
	add_child(p)
	p.position=pos
	p.size=sz
	p.add_theme_stylebox_override("panel",style(Color(0.035,0.045,0.043,0.94),Color("655e49")))
	p.mouse_filter=Control.MOUSE_FILTER_PASS
	return p
func margin_box(parent:Control,h:int=24,v:int=20) -> VBoxContainer:
	var m=MarginContainer.new()
	m.add_theme_constant_override("margin_left",h)
	m.add_theme_constant_override("margin_right",h)
	m.add_theme_constant_override("margin_top",v)
	m.add_theme_constant_override("margin_bottom",v)
	parent.add_child(m)
	var b=VBoxContainer.new()
	b.add_theme_constant_override("separation",10)
	m.add_child(b)
	return b
func label(text:String,sz:int=20,c:Color=Color("d5d0bd")) -> Label:
	var l=Label.new()
	l.text=text
	l.add_theme_font_size_override("font_size",sz)
	l.add_theme_color_override("font_color",c)
	l.mouse_filter=Control.MOUSE_FILTER_IGNORE
	return l
func button(text:String,cb:Callable,enabled:bool=true,compact:bool=false) -> Button:
	var b=Button.new()
	b.text=text
	b.alignment=HORIZONTAL_ALIGNMENT_LEFT
	b.add_theme_font_size_override("font_size",18 if compact else 20)
	var normal=style(Color("18292a"),Color("43534b"))
	normal.content_margin_left=12
	normal.content_margin_right=12
	normal.content_margin_top=6 if compact else 12
	normal.content_margin_bottom=6 if compact else 12
	b.add_theme_stylebox_override("normal",normal)
	var hover=normal.duplicate()
	hover.bg_color=Color("30413a")
	hover.border_color=amber
	b.add_theme_stylebox_override("hover",hover)
	b.add_theme_stylebox_override("focus",hover)
	b.add_theme_stylebox_override("pressed",hover)
	var disabled=normal.duplicate()
	disabled.bg_color=Color("111d1f")
	disabled.border_color=Color("283938")
	b.add_theme_stylebox_override("disabled",disabled)
	b.add_theme_color_override("font_color",text_color)
	b.add_theme_color_override("font_hover_color",Color("f3d39a"))
	b.add_theme_color_override("font_disabled_color",Color("68766f"))
	b.disabled=not enabled
	b.pressed.connect(func():world.get_node("/root/Session").sound("ui");cb.call())
	return b
func rule():
	var h=HSeparator.new()
	h.add_theme_color_override("color",Color("45534a"))
	modal_box.add_child(h)
func body(text:String,sz:int=21,c:Color=Color("c8cebd")):
	var l=label(text,sz,c)
	l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_constant_override("line_spacing",7)
	modal_box.add_child(l)

func prose(text:String,sz:int=21,parent:Control=null):
	var rich=RichTextLabel.new()
	rich.bbcode_enabled=true
	rich.visible_characters_behavior=TextServer.VC_CHARS_AFTER_SHAPING
	rich.fit_content=true
	rich.scroll_active=false
	rich.add_theme_font_size_override("normal_font_size",sz)
	rich.add_theme_color_override("default_color",Color("a7b0a5"))
	rich.add_theme_constant_override("normal_line_spacing",8)
	var expression=RegEx.new()
	expression.compile("「[^」]*」")
	var cursor=0
	var markup=""
	for quote in expression.search_all(text):
		markup+=text.substr(cursor,quote.get_start()-cursor).replace("[","[lb]")
		markup+="[color=#d6bd90]"+quote.get_string().replace("[","[lb]")+"[/color]"
		cursor=quote.get_end()
	markup+=text.substr(cursor).replace("[","[lb]")
	rich.text=markup
	(parent if parent else modal_box).add_child(rich)
	if dialogue_id!="":
		var total=rich.get_total_character_count()
		rich.visible_characters=0
		typing.append({"label":rich,"total":total,"elapsed":0.0,"rate":maxf(180.0,float(total)/1.2)})
		rich.mouse_filter=Control.MOUSE_FILTER_STOP
		rich.gui_input.connect(func(event):
			if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:finish_typing();rich.accept_event())
	return rich

func character_prose(id:String,text:String):
	var portrait_path="res://assets/portraits/"+id+".png"
	if not ResourceLoader.exists(portrait_path):
		prose(text)
		return
	var row=HBoxContainer.new()
	row.add_theme_constant_override("separation",18)
	modal_box.add_child(row)
	var portrait=TextureRect.new()
	portrait.texture=load(portrait_path)
	portrait.custom_minimum_size=Vector2(132,158)
	portrait.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(portrait)
	var words=prose(text,20,row)
	words.size_flags_horizontal=Control.SIZE_EXPAND_FILL

func start_modal(title:String,subtitle:String,wide:bool=false):
	typing.clear()
	if wide:dialogue_id=""
	for child in modal.get_children():
		modal.remove_child(child)
		child.queue_free()
	modal.set_anchors_preset(Control.PRESET_TOP_LEFT)
	modal.add_theme_stylebox_override("panel",style(Color("101c1e"),Color("766747"),1,0))
	scrim.color=Color(0.02,0.05,0.055,0.58)
	modal.position=Vector2(388,150) if wide else Vector2(864,145)
	modal.size=Vector2(824,710) if wide else Vector2(704,715)
	var outer=MarginContainer.new()
	for side in ["left","right","top","bottom"]:outer.add_theme_constant_override("margin_"+side,26)
	modal.add_child(outer)
	var main=VBoxContainer.new()
	main.add_theme_constant_override("separation",12)
	outer.add_child(main)
	main.add_child(label(subtitle,15,amber))
	var head=HBoxContainer.new()
	main.add_child(head)
	dialog_title=label(title,31,text_color)
	dialog_title.add_theme_font_override("font",serif)
	head.add_child(dialog_title)
	head.add_spacer(false)
	head.add_child(button("×",func():close(),true,true))
	var scroller=ScrollContainer.new()
	scroller.size_flags_vertical=Control.SIZE_EXPAND_FILL
	scroller.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	main.add_child(scroller)
	modal_box=VBoxContainer.new()
	modal_box.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	modal_box.add_theme_constant_override("separation",13)
	scroller.add_child(modal_box)
	main.add_child(label("空格 / 点击正文  显示全文    ·    ESC  返回",14,muted))
	modal.visible=true
	scrim.visible=true
	is_departure=false
	target_label.visible=false

func show_dialogue(id:String):
	var v=world.story.view(id)
	var first=world.story.Conversation.visit(world.story,id,v.body)
	Dialogue.render(self,id,first)

func show_reply(id:String,text:String):
	var first=world.story.Conversation.reply(world.story,id,last_choice,text)
	last_choice=""
	Dialogue.render(self,id,first)

func close():
	if comic_active:show_comic_pause();return
	if world.story.ending and world.story.flags.has("chapter_endpoint"):show_chapter_end();return
	finish_typing()
	dialogue_id=""
	last_choice=""
	modal.visible=false
	scrim.visible=false
	is_departure=false
	world.player.blocked=false
	map_large=null

func modal_visible() -> bool:return modal.visible
func set_prompt(id:String):
	if id=="":
		prompt.text=""
		target_label.text=""
		return
	var t=world.targets[id]
	prompt.text="[ E ]   "+("交谈 · " if t.kind=="talk" else "调查 · ")+t.label
	target_label.text=("◇  " if t.kind=="talk" else "⌕  ")+t.label
	target_label.visible=not modal_visible()
	var p:Vector2=world.camera.unproject_position(t.pos+Vector3(0,2.2,0))
	target_label.position=p-Vector2(target_label.get_minimum_size().x/2,20)
func refresh_status():
	if not objective:return
	objective.text=world.story.objective()
	inventory_count.text="%d 制式弹 · %d 土制弹" % [world.story.economy.military,world.story.economy.handmade]
	route_label.text=world.story.ROUTES.get(world.story.route,"尚未选择离站方式")
	var signature=",".join(world.story.items)
	if quick_items and signature!=quick_signature:
		for child in quick_items.get_children():
			quick_items.remove_child(child)
			child.queue_free()
		for id in world.story.items.slice(0,3):
			var icon=TextureRect.new()
			icon.texture=load(item_icon(id))
			icon.custom_minimum_size=Vector2(44,44)
			icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.tooltip_text=world.story.ITEMS[id][0]
			quick_items.add_child(icon)
		quick_signature=signature
func tick(delta:float):
	location_label.text=("D–6 " if world.floor_id in ["life","labor"] else "")+world.floor_name()+"  /  "+world.room_name
	status_label.text=str(world.story.flags.get("story_day",16))+" XI 1982  /  "+str(world.story.flags.get("story_time","07:42"))+" · "+("旅程" if comic_active or world.story.ending else (("换班" if world.phase>=8 else "早班") if world.floor_id in ["life","labor"] else "探索"))
	map_small.queue_redraw()
	if is_instance_valid(map_large):map_large.queue_redraw()
	if toast_time>0:
		toast_time-=delta
		toast_label.modulate.a=minf(toast_time,1.0)
	else:toast_label.text=""
func toast(text:String,duration:float=4.0):
	toast_label.text=text
	toast_label.modulate.a=1
	toast_time=duration

func show_inventory():
	start_modal("随身物品","INVENTORY   /   道具通过对话与场景互动使用",true)
	var ammo=HBoxContainer.new();ammo.add_theme_constant_override("separation",18);modal_box.add_child(ammo)
	for kind in ["military","handmade"]:
		ammo.add_child(icon_rect("res://assets/visual/item_"+kind+".png",52))
		ammo.add_child(label(world.story.Economy.AMMO[kind].name+" × "+str(world.story.economy[kind]),19,amber))
	if world.story.items.is_empty() and world.story.economy.goods.is_empty():body("物品袋里暂时没有其它东西。",17,muted)
	for id in world.story.items:
		var item=world.story.ITEMS[id]
		var row=HBoxContainer.new()
		row.add_theme_constant_override("separation",18)
		modal_box.add_child(row)
		var icon=TextureRect.new()
		icon.texture=load(item_icon(id))
		icon.custom_minimum_size=Vector2(92,92)
		icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		row.add_child(icon)
		var description=VBoxContainer.new()
		description.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		row.add_child(description)
		description.add_child(label(item[0]+"   /   "+item[2],22,amber))
		var detail=label(item[1],18,text_color)
		detail.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		description.add_child(detail)
		rule()
	var s=world.story
	rule();body("体力 %d · 饱食 %d · 辐射 %d"%[s.economy.health,s.economy.food,s.economy.radiation],18,amber)
	for id in s.economy.goods:
		var good:Dictionary=s.Economy.GOODS[id]
		var row=HBoxContainer.new();modal_box.add_child(row)
		row.add_child(icon_rect("res://assets/visual/item_"+id+".png",64))
		row.add_child(label(good.name+" × "+str(s.economy.goods[id]),20,text_color))
		row.add_spacer(false)
		if good.effect!="":row.add_child(button("使用",func():toast(s.Economy.consume(s,id));show_inventory(),true,true))

func show_journal(tab:String="tasks",shown_floor:String=""):
	start_modal("伊万的日志","任务 · 百科 · 地图",true)
	var tabs=HBoxContainer.new();modal_box.add_child(tabs)
	for pair in [["tasks","任务"],["lore","百科"],["map","地图"]]:
		tabs.add_child(button(pair[1],func():show_journal(pair[0]),true,true))
	rule()
	if tab=="tasks":
		body(world.story.objective(),23,amber)
		for task in Journal.tasks(world.story):
			body(("◆ " if task.done else "◇ ")+task.name,21,amber if task.done else text_color)
			body(task.background,17,muted)
			if not task.done:body(task.step,18,text_color)
		if not world.story.intel.is_empty():
			rule();body("已经听说的事",21,amber)
			for entry in world.story.intel:body(entry,17)
		if not world.story.flags.get("comic_records",[]).is_empty():
			rule();body("旅程记录",22,amber)
			for record in world.story.flags.comic_records:
				body(record.title,20,amber);body(record.body,17)
				if record.choice!="":body("伊万："+record.choice,17,muted)
	elif tab=="lore":
		for entry in Journal.encyclopedia(world.story):
			body(entry[0],22,amber);body(entry[1],18);rule()
	else:
		var requested=world.floor_id if shown_floor=="" else shown_floor
		var floors=GridContainer.new();floors.columns=3;floors.add_theme_constant_override("h_separation",10);modal_box.add_child(floors)
		for pair in [["life","生活层"],["labor","作业层"]]+world.story.Campaign.NAMES.keys().filter(func(id):return world.story.f("visited_"+id) or world.floor_id==id).map(func(id):return [id,world.story.Campaign.NAMES[id]]):floors.add_child(button(pair[1],func():show_journal("map",pair[0]),true,true))
		body("当前位置："+world.floor_name()+" · 旅程中的设施通过图文路线相连",18,amber)
		map_large=MapView.new();map_large.custom_minimum_size=Vector2(720,320)
		map_large.world=world;map_large.expanded=true;map_large.display_floor=requested;modal_box.add_child(map_large)
		var legend=GridContainer.new();legend.columns=3;legend.add_theme_constant_override("h_separation",18);modal_box.add_child(legend)
		for zone in world.facility_zones(requested):
			if zone.code in ["00","09","10","L0"]:continue
			legend.add_child(label(zone.code+"  "+("伊万 / 老爹" if requested=="life" and zone.code=="01" else zone.name),15,text_color))
		body("金色：通路与门口 · 蓝色：附近的人。地图只显示本层可探索的区域；门后还有其它生活或作业区。",16,muted)

func show_map():show_journal("map")

func item_icon(id:String)->String:
	return "res://assets/visual/item_"+world.story.Campaign.ITEM_ART.get(id,id)+".png"

func icon_rect(path:String,size:float=68)->TextureRect:
	var icon=TextureRect.new();icon.texture=load(path)
	icon.custom_minimum_size=Vector2(size,size);icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	return icon

func show_shop(message:String=""):
	start_modal("第七供应点 · 柳德米拉","只收制式弹 · 生活物资，不售武器",true)
	var s=world.story
	body("制式弹 %d  /  土制弹 %d（不能抵账）"%[s.economy.military,s.economy.handmade],22,amber)
	if message!="":body(message,18,Color("a4bca0"))
	for id in s.Economy.GOODS:
		var good:Dictionary=s.Economy.GOODS[id]
		var row=HBoxContainer.new();row.add_theme_constant_override("separation",14);modal_box.add_child(row)
		row.add_child(icon_rect("res://assets/visual/item_"+id+".png"))
		var b=VBoxContainer.new();b.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(b)
		b.add_child(label(good.name+"  ·  "+str(good.price)+" 发",21,amber))
		var detail=label(good.detail,16,muted);detail.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;b.add_child(detail)
		b.add_child(label("余货 %d · 已有 %d"%[s.economy.stock.get(id,0),s.economy.goods.get(id,0)],15,muted))
		row.add_child(button("购买",func():shop_buy(id),s.economy.military>=good.price and s.economy.stock.get(id,0)>0,true))
	if s.has("vodka"):
		rule();body("战前伏特加 · 收购 18 发制式弹",21,amber)
		modal_box.add_child(button("出售这瓶伏特加…",func():confirm_sale()))
	modal_box.add_child(button("返回交谈",func():show_dialogue("supply")))

func confirm_sale():
	start_modal("卖掉这瓶酒？","交易确认",true)
	body("柳德米拉愿意出 18 发制式弹。卖出后，这瓶酒就不能再拿去交换或交给别人。",21)
	modal_box.add_child(button("确认出售 · 18 发",func():shop_sell()))
	modal_box.add_child(button("先留着",func():show_shop()))

func show_pause():
	start_modal("暂停 / 现场记录","D–6   /   现场记录",true)
	modal_box.add_child(button("继续探索",func():close()))
	modal_box.add_child(button("保存手记  [F5]",func():world.save_game()))
	modal_box.add_child(button("读取手记  [F9]",func():world.load_game()))
	modal_box.add_child(button("重新开始（保留已有存档）",func():show_restart_confirm()))
	audio_controls()
	rule()
	body("WASD / 方向键：8 方向移动\nE：交谈 / 调查\nI：背包　J：手记　M：地图\nTab：总览　滚轮：缩放\nEsc：关闭界面 / 菜单",20)
	body("靠近人物或物件时会出现互动提示。图文旅程可在暂停页保存，也能打开背包使用物资。",16,muted)
func show_restart_confirm():
	start_modal("重新开始？","当前未保存的进度将丢失",true)
	modal_box.add_child(button("确认重新开始",func():world.restart()))
	modal_box.add_child(button("返回",func():show_pause()))

func show_departure(confirmed:bool):
	var s=world.story
	if confirmed:
		show_chapter_end()
		return
	start_modal("离开 D-6？","出发确认 / "+s.ROUTES.get(world.pending_route,""),true)
	is_departure=true
	body("离开后将进入图文旅程。确认前可以返回上下两层，办完还没办的事。",21)
	if not s.has("mask") or not s.has("filter"):body("你没有完整防护，单独离站会暴露在辐射尘与污浊空气中。仍要出发吗？",20,Color("d09c7a"))
	modal_box.add_child(button("确认出发",func():
		var snapshot=s.serialize().duplicate(true);snapshot.erase("checkpoint")
		snapshot.floor=world.floor_id;snapshot.position=[world.player.position.x,.04,world.player.position.z]
		s.departure_checkpoint=snapshot
		s.route=world.pending_route;s.ending=false
		show_comic("official" if s.route=="official" else "solo")))
	modal_box.add_child(button("再准备一下",func():close()))

func show_comic(sequence:String=""):
	ComicUI.render(self,sequence)
	tick(0)

func comic_choose(index:int=-1):
	finish_typing()
	world.get_node("/root/Session").sound("page")
	var s=world.story
	var old_panel=s.Comic.panel(s)
	if s.flags.comic.sequence=="intro":s.Conversation.append(s,"semyon",old_panel.body,"semyon")
	s.Comic.choose(s,index)
	if s.flags.comic.active:show_comic()
	else:
		comic_active=false
		if s.flags.has("next_facility"):
			world.travel_campaign(s.flags.next_facility)
		elif s.f("intro_done") and not s.ending:close();refresh_status();toast("第一件事：到第七供应点领取今日维生素 D",7)
		else:show_chapter_end()

func show_comic_pause():
	start_modal("旅程暂停","已读的面板和选择会随存档保存",true)
	modal_box.add_child(button("继续剧情",func():show_comic()))
	modal_box.add_child(button("查看背包 / 使用物资",func():show_inventory()))
	modal_box.add_child(button("保存当前进度",func():world.save_game()))
	modal_box.add_child(button("读取存档",func():world.load_game()))
	modal_box.add_child(button("重新开始",func():show_restart_confirm()))
	audio_controls()

func show_chapter_end():
	comic_active=false
	var s=world.story
	var ending_id:String=s.flags.get("campaign_ending","")
	if ending_id!="":
		var outcome:Dictionary=s.Campaign.data().endings[ending_id]
		start_modal(outcome.title,"МЕТРО 1982   /   旅程终章",true)
		make_cinematic()
		var row=HBoxContainer.new();row.add_theme_constant_override("separation",38);modal_box.add_child(row)
		var art=TextureRect.new()
		art.texture=load("res://assets/cinematics/"+{"home":"wake","tea":"wake","anna":"sergey","commune":"descent","sech":"sergey","starcity":"trolley","bridge":"wake","signal":"trolley","ocean":"surface"}.get(ending_id,"wake")+".png")
		art.custom_minimum_size=Vector2(680,360);art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;row.add_child(art)
		var text_box=VBoxContainer.new();text_box.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(text_box)
		var epilogue:String=outcome.body
		if s.f("father_angry") and ending_id in ["starcity","bridge"]:epilogue+="\n你没有收回那句恨。以后怎么相处，要等以后再说。"
		prose(epilogue,25,text_box)
		rule()
		body("你的选择",19,amber)
		for pair in [["water_secured","给 D-6 找到了两箱净水滤芯"],["greenhouse_fixed","修好了公社温室的回水"],["anna_reunited","核实了安娜哥哥的身份与探视安排"],["radio_fixed","恢复了谢契的短波电台"],["books_saved","替谢尔盖救下受潮的书"],["father_semyon","问清了父亲与老爹当年的往事"],["cautious_signal","没有把所有人的坐标交给陌生呼叫"]]:
			if s.f(pair[0]):body("· "+pair[1],20,muted)
		modal_box.add_child(button("保存这段旅程",func():world.save_game()))
		modal_box.add_child(button("查看手记与已读旅程",func():show_journal()))
		if not s.departure_checkpoint.is_empty():modal_box.add_child(button("回到离站前，尝试另一条路",func():world.return_checkpoint()))
		modal_box.add_child(button("重新开始",func():show_restart_confirm()))
		return
	var plant=s.flags.get("chapter_endpoint","")=="waterworks_exterior"
	start_modal("水厂外围" if plant else "火光边的陌生人","下一章 / 继续旅程",true)
	make_cinematic()
	is_departure=true
	body("队伍在水厂气闸前停下。接下来的设施里，可以自由探索、交谈和检查设备。" if plant else "谢尔盖还在等你的回答。可以跟他走，也可以问清公社的路。",25)
	modal_box.add_child(button("进入水处理厂" if plant else "与谢尔盖继续交谈",func():world.travel_campaign("waterworks") if plant else show_comic("companions")))
	modal_box.add_child(button("保存进度",func():world.save_game()))
	if not s.departure_checkpoint.is_empty():modal_box.add_child(button("回到离站前",func():world.return_checkpoint()))

func make_cinematic():
	modal.position=Vector2.ZERO
	modal.size=get_viewport_rect().size
	modal.add_theme_stylebox_override("panel",style(Color("0b1314"),Color("0b1314"),0))
	scrim.color=Color("0b1314")
	var outer=modal.get_child(0)
	for side in ["left","right"]:outer.add_theme_constant_override("margin_"+side,48)
	for side in ["top","bottom"]:outer.add_theme_constant_override("margin_"+side,32)
	var main=outer.get_child(0)
	var head=main.get_child(1)
	var close_button=head.get_child(head.get_child_count()-1)
	close_button.text="暂停" if comic_active else "手记"
	if not comic_active:
		for connection in close_button.pressed.get_connections():close_button.pressed.disconnect(connection.callable)
		close_button.pressed.connect(func():show_journal())

func audio_controls():
	rule();body("声音",20,amber)
	var session=world.get_node("/root/Session")
	for pair in [["Master","总音量"],["Music","背景旋律"],["Effects","脚步与交互音效"]]:
		var row=HBoxContainer.new();modal_box.add_child(row)
		var name_label=label(pair[1],17,muted);name_label.custom_minimum_size.x=190;row.add_child(name_label)
		var slider=HSlider.new();slider.min_value=0;slider.max_value=1;slider.step=.05;slider.value=session.volume(pair[0]);slider.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(slider)
		var readout=label(str(roundi(slider.value*100))+"%",16,amber);readout.custom_minimum_size.x=55;row.add_child(readout)
		var bus_name:String=pair[0]
		slider.value_changed.connect(func(value):session.set_volume(bus_name,value);readout.text=str(roundi(value*100))+"%")

func dialogue_actor()->String:return {"armory":"armorer","main_gate":"main_guard"}.get(dialogue_id,dialogue_id)

func shop_buy(id:String):
	var s=world.story
	var before=s.economy.ledger.size()
	var result=s.Economy.buy(s,id)
	if s.economy.ledger.size()>before:s.Conversation.reply(s,"supply","「买一份"+s.Economy.GOODS[id].name+"。」",result)
	show_shop(result)

func shop_sell():
	var s=world.story
	var before=s.economy.ledger.size()
	var result=s.Economy.sell_vodka(s)
	if s.economy.ledger.size()>before:s.Conversation.reply(s,"supply","「这瓶酒，按你说的价收吧。」",result)
	show_shop(result)
