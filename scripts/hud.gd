extends Control
const Publications=preload("res://scripts/publications.gd")
var observed_publications:Array=[]
var collection_scroll=0
var terminal_game
var modal_hint:Label
const UiSurface=preload("res://scripts/ui_surface.gd")
const ComicUI=preload("res://scripts/ui_comic.gd")
const Dialogue=preload("res://scripts/ui_dialogue.gd")
const Journal=preload("res://scripts/journal.gd")
const MapView=preload("res://scripts/minimap.gd")
var world
var font:Font
var serif:Font
var mono:Font
var objective: Label
var objective_title:Label
var objective_kind:Label
var speech_buttons:Array=[]
var receipt_box:VBoxContainer
var receipt_timers:Array=[]
var observed_inventory:Dictionary={}
var observed_tasks:Dictionary={}
var observing=false
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
var health_bar:ProgressBar
var food_bar:ProgressBar
var vitals_label:Label
var leads_button:Button
var last_guidance=""
var shop_tab="buy"
var radio_open=false
var saves_return_menu=false

func _process(delta:float):
	advance_typing(delta)

func advance_typing(delta:float):
	while not typing.is_empty() and not is_instance_valid(typing[0].label):typing.pop_front()
	if not typing.is_empty():
		var entry:Dictionary=typing[0]
		if entry.has("root") and is_instance_valid(entry.root) and not entry.root.visible:
			entry.root.visible=true
			var ancestor=entry.root.get_parent()
			while ancestor and not ancestor is ScrollContainer:ancestor=ancestor.get_parent()
			if ancestor:scroll_dialogue_to(ancestor,entry.root)
		entry.elapsed+=delta
		entry.label.visible_characters=mini(entry.total,floori(entry.elapsed*entry.rate))
		if entry.label.visible_characters>=entry.total:typing.pop_front()
	for b in speech_buttons:
		if is_instance_valid(b):b.disabled=not typing.is_empty()
	if is_instance_valid(receipt_box):receipt_box.visible=not modal_visible()
	if not modal_visible():
		for entry in receipt_timers:entry.time-=delta
	for entry in receipt_timers:
		if entry.time<=0 and is_instance_valid(entry.node):entry.node.queue_free()
	receipt_timers=receipt_timers.filter(func(entry):return entry.time>0)

func finish_typing():
	var current:Control=null
	if not typing.is_empty():current=typing[0].get("root",typing[0].label)
	for entry in typing:
		if is_instance_valid(entry.label):entry.label.visible_characters=-1
		if entry.has("root") and is_instance_valid(entry.root):entry.root.visible=true
	typing.clear()
	for b in speech_buttons:
		if is_instance_valid(b):b.disabled=false
	if is_instance_valid(current):
		var ancestor=current.get_parent()
		while ancestor and not ancestor is ScrollContainer:ancestor=ancestor.get_parent()
		if ancestor:scroll_dialogue_to(ancestor,current)

func scroll_dialogue_to(scroll:ScrollContainer,control:Control):
	# Container geometry settles after the text/portrait rows become visible.
	# Align the new exchange rather than leaving the old greeting on screen.
	if not is_inside_tree():return
	var tree=get_tree()
	await tree.process_frame
	if not is_inside_tree():return
	await tree.process_frame
	if is_instance_valid(scroll) and is_instance_valid(control) and control.is_visible_in_tree() and scroll.get_child_count()>0:
		var content:Control=scroll.get_child(0)
		scroll.scroll_vertical=roundi(control.global_position.y-content.global_position.y)

func _input(event):
	if modal_visible() and not typing.is_empty() and event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_SPACE,KEY_ENTER,KEY_KP_ENTER]:
		finish_typing()
		get_viewport().set_input_as_handled()

func setup(w):
	world=w
	font=load("res://assets/fonts/MetroSans.otf");serif=load("res://assets/fonts/MetroSerif.otf");mono=load("res://assets/fonts/MetroMono.ttf")
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
	line.add_child(label({"life":"D–6","labor":"D–6","waterworks":"水厂","commune":"公社","sech":"谢契","coal":"D–6","starcity":"星城外围","surface":"地表","railfront":"联络线"}.get(world.floor_id,""),17,amber))
	var title=label("地铁 1982",27,text_color)
	title.add_theme_font_override("font",serif)
	b.add_child(title)
	var top=panel(Vector2(298,28),Vector2(516,56))
	var topbox=margin_box(top,17,11)
	location_label=label("D-6生活层 / 伊万的卧室",19,text_color)
	topbox.add_child(location_label)
	var tag=panel(Vector2(1240,28),Vector2(328,56))
	var tb=margin_box(tag,17,11)
	status_label=label("16 XI 1982   /   07:42",17,muted)
	status_label.add_theme_font_override("font",mono)
	tb.add_child(status_label)
	# Current goal is short; the detailed quest network belongs in the journal.
	var goal=panel(Vector2(32,134),Vector2(264,220))
	var gb=margin_box(goal,18,15)
	objective_kind=label("正在跟进",13,muted);gb.add_child(objective_kind)
	objective_title=label("",23,amber);objective_title.add_theme_font_override("font",serif);objective_title.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;gb.add_child(objective_title)
	objective=label("",17,Color("bac7c0"))
	objective.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	gb.add_child(objective)
	gb.add_child(label("线索与待办收在手记里",14,muted))
	var key_panel=panel(Vector2(32,769),Vector2(250,93))
	var kb=margin_box(key_panel,16,12)
	kb.add_child(label("W A S D    移动       E   互动",16,text_color))
	kb.add_child(label("Tab  总览   /   滚轮  切换目标或缩放",15,muted))
	# Minimap has geometry, not a screenshot of the reference.
	var mp=panel(Vector2(1302,106),Vector2(266,214))
	var mb=margin_box(mp,6,5)
	var mt=label(world.floor_name(),14,muted)
	mt.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	mb.add_child(mt)
	map_small=MapView.new()
	map_small.custom_minimum_size=Vector2(252,168)
	map_small.world=world
	mb.add_child(map_small)
	# Bottom command bar with a warmer identity block and a small route indicator.
	var bar=panel(Vector2(32,890),Vector2(1536,86))
	var row=HBoxContainer.new();row.add_theme_constant_override("separation",20)
	var mar=MarginContainer.new()
	for side in ["left","right"]:mar.add_theme_constant_override("margin_"+side,22)
	for side in ["top","bottom"]:mar.add_theme_constant_override("margin_"+side,12)
	bar.add_child(mar);mar.add_child(row)
	var identity=VBoxContainer.new();identity.custom_minimum_size.x=145;row.add_child(identity)
	identity.add_child(label("ИВАН / 伊万",21,amber))
	identity.add_child(label("随身记录 · 1982",13,muted))
	var vitals=VBoxContainer.new();vitals.custom_minimum_size.x=240;vitals.add_theme_constant_override("separation",5);row.add_child(vitals)
	vitals_label=label("",14,text_color);vitals.add_child(vitals_label)
	health_bar=vital_bar(vitals,Color("9aa98d"));health_bar.tooltip_text="生命 · 伤药用于恢复伤势"
	food_bar=vital_bar(vitals,Color("c3a36a"));food_bar.tooltip_text="饱食 · 活动中缓慢消耗；饥饿不会直接扣生命"
	inventory_count=label("",16,text_color);row.add_child(inventory_count)
	quick_items=HBoxContainer.new();quick_items.visible=false;row.add_child(quick_items)
	row.add_spacer(false)
	row.add_child(button("I  背包",func():show_inventory(),true,true))
	row.add_child(button("J  手记",func():show_journal(),true,true))
	leads_button=button("留意的事",func():show_journal("leads"),true,true);row.add_child(leads_button)
	route_label=label("",13,muted);route_label.visible=false;row.add_child(route_label)
	row.add_child(button("Esc  暂停",func():show_pause(),true,true))
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
	UiSurface.attach(modal)
	refresh_status()

func vital_bar(parent:Control,color:Color)->ProgressBar:
	var bar=ProgressBar.new();bar.show_percentage=false;bar.custom_minimum_size=Vector2(240,7);bar.mouse_filter=Control.MOUSE_FILTER_PASS
	bar.add_theme_stylebox_override("background",style(Color("1a2423"),Color("38433c")))
	bar.add_theme_stylebox_override("fill",style(color,color,0))
	parent.add_child(bar)
	return bar

func style(bg: Color,border: Color,width: int=1,rad: int=0) -> StyleBoxFlat:
	var s=StyleBoxFlat.new()
	s.bg_color=bg
	s.border_color=border
	s.set_border_width_all(width)
	s.set_corner_radius_all(rad if rad>0 else 3)
	s.shadow_color=Color(0,0,0,0.28)
	s.shadow_size=8
	s.shadow_offset=Vector2(0,3)
	return s
func panel(pos:Vector2,sz:Vector2) -> PanelContainer:
	var p=PanelContainer.new()
	add_child(p)
	p.position=pos
	p.size=sz
	p.add_theme_stylebox_override("panel",style(Color(0.035,0.045,0.043,0.94),Color("655e49")))
	p.mouse_filter=Control.MOUSE_FILTER_PASS
	UiSurface.attach(p)
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
	UiSurface.attach(b,"button")
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
	rich.text=highlight_items(markup)
	(parent if parent else modal_box).add_child(rich)
	if dialogue_id!="":
		var total=rich.get_total_character_count()
		rich.visible_characters=0
		typing.append({"label":rich,"total":total,"elapsed":0.0,"rate":48.0})
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
	radio_open=false
	typing.clear();speech_buttons.clear()
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
	modal_hint=label("空格 / 点击正文  显示全文    ·    ESC  返回",14,muted)
	main.add_child(modal_hint)
	modal.visible=true
	scrim.visible=true
	is_departure=false
	target_label.visible=false

func show_dialogue(id:String):
	world.story.FirstMeetings.begin(world.story,id)
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
	radio_open=false
	last_choice=""
	modal.visible=false
	scrim.visible=false
	is_departure=false
	world.player.blocked=false
	map_large=null
	if is_instance_valid(terminal_game):
		terminal_game.save_record()
		terminal_game.set_process_input(false)
		terminal_game.set_process(false)
		world.autosave()
		terminal_game=null

func modal_visible() -> bool:return modal.visible
func set_prompt(id:String):
	if id=="":
		prompt.text=""
		target_label.text=""
		return
	var t=world.targets[id]
	var actor=world.target_actor(id)
	var live_position:Vector3=actor.global_position if actor else t.pos
	prompt.text="[ E ]   "+("交谈 · " if t.kind=="talk" else ("拾取 · " if t.kind=="collect" else "调查 · "))+t.label
	if world.interaction_candidates.size()>1:
		prompt.text+="   [ 滚轮切换 %d/%d ]"%[world.interaction_candidates.find(id)+1,world.interaction_candidates.size()]
	target_label.text=("◇  " if t.kind=="talk" else "⌕  ")+t.label
	target_label.visible=not modal_visible()
	var p:Vector2=world.camera.unproject_position(live_position+Vector3(0,2.2,0))
	target_label.position=p-Vector2(target_label.get_minimum_size().x/2,20)
func refresh_status():
	if not objective:return
	var focus=Journal.active(world.story)
	objective_title.text=focus.name if not focus.is_empty() else "留意身边的人"
	objective_kind.text=(focus.kind+" / 正在跟进") if not focus.is_empty() else "自由探索"
	objective.text=focus.step if not focus.is_empty() else "看看手记旁的线索，或找周围的人聊聊。"
	observe_progress()
	if health_bar:
		health_bar.value=world.story.economy.health;food_bar.value=world.story.economy.food
		vitals_label.text="生命 %d   /   饱食 %d"%[world.story.economy.health,world.story.economy.food]
		leads_button.text="留意的事 · "+str(Journal.leads(world.story).size())
	inventory_count.text="%d 制式弹 · %d 土制弹" % [world.story.economy.military,world.story.economy.handmade]
	if world.story.equipped_weapon()!="":inventory_count.text+="\n1  "+("收枪" if world.story.weapon_drawn() else "拔枪")+" · "+world.story.ITEMS[world.story.equipped_weapon()][0]
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
	prompt.visible=not modal_visible()
	if not modal_visible() and world.nearest!="" and not world.waiting_shift:set_prompt(world.nearest)
	location_label.text=world.floor_name()+"  /  "+world.room_name
	status_label.text=str(world.story.flags.get("story_day",16))+" XI 1982  /  "+str(world.story.flags.get("story_time","07:42"))+" · "+("旅程" if comic_active or world.story.ending else (("换班" if world.phase>=8 else "早班") if world.floor_id in ["life","labor"] else "探索"))
	var guidance=JSON.stringify([Journal.active(world.story),world.story.economy.health,world.story.economy.food,Journal.leads(world.story).size()])
	if guidance!=last_guidance:last_guidance=guidance;refresh_status()
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
	preload("res://scripts/ui_inventory.gd").render(self)

func show_journal(tab:String="tasks",shown_floor:String=""):
	start_modal("伊万的手记","随身卷宗   /   任务、地图与见闻",true)
	modal.position=Vector2(230,84);modal.size=Vector2(1140,832)
	var tabs=HFlowContainer.new();tabs.add_theme_constant_override("h_separation",8);tabs.add_theme_constant_override("v_separation",6);modal_box.add_child(tabs)
	for pair in [["tasks","01  事要办"],["map","02  地图"],["lore","03  百科"],["leads","04  留意的事"],["history","05  已读记录"],["closed","06  完成与失败"],["collection","07  收集品"]]:
		var b=button(pair[1],func():show_journal(pair[0]),true,true)
		if tab==pair[0]:b.add_theme_color_override("font_color",amber)
		tabs.add_child(b)
	rule()
	var s=world.story
	if tab=="tasks":
		var current=Journal.active(s)
		body("正在跟进",16,amber)
		if current.is_empty():body("还没决定下一件事。留意身边的人，或翻翻旁边的线索。",21)
		else:quest_card(current,true)
		rule();body("其它进行中的任务 · 可切换追踪",16,amber)
		var count=0
		for task in Journal.tasks(s):
			if task.done or task.failed or task.id==current.get("id",""):continue
			quest_card(task,false);count+=1
		if count==0:body("没有其它待办。",18,muted)
	elif tab=="closed":
		var count=0
		for task in Journal.tasks(s):
			if task.done or task.failed:quest_card(task,false);count+=1
		if count==0:body("办妥的事会留在这里。",20,muted)
	elif tab=="leads":
		body("路过时想到的事",25,amber)
		body("这些还不是答应过的差事。找个人问问，也许会有新的路。",17,muted)
		for lead in Journal.leads(s):body("· "+lead,21)
		if Journal.leads(s).is_empty():body("暂时没有新的念头。按自己的步子走。",20)
		if s.has("photo") and not s.f("quest_photo") and not s.f("father"):
			modal_box.add_child(button("把问照片的事记进待办",func():s.flags.quest_photo=true;show_journal()))
	elif tab=="history":
		body("已经听说的事",23,amber)
		for entry in s.intel:body(entry,18)
		for record in s.flags.get("comic_records",[]):
			rule();body(record.title,21,amber);prose(record.body,19)
			if record.choice!="":body("伊万："+record.choice,18,muted)
	elif tab=="lore":
		for entry in Journal.encyclopedia(s):body(entry[0],24,amber);body(entry[1],19);rule()
	elif tab=="collection":
		show_collection()
	elif tab=="map":
		var requested=world.floor_id if shown_floor=="" else shown_floor
		var floors=GridContainer.new();floors.columns=3;floors.add_theme_constant_override("h_separation",10);modal_box.add_child(floors)
		for pair in [["life","D-6生活层"],["labor","D-6作业层"]]+world.story.Campaign.NAMES.keys().filter(func(id):return world.story.f("visited_"+id) or world.floor_id==id).map(func(id):return [id,world.story.Campaign.NAMES[id]]):floors.add_child(button(pair[1],func():show_journal("map",pair[0]),true,true))
		var focus=Journal.active(s)
		if not focus.is_empty() and focus.place==requested:body("手记里圈过的一带："+focus.area,19,amber)
		body("当前位置："+world.floor_name()+" · 旅程中的设施通过图文路线相连",18,amber)
		map_large=MapView.new();map_large.custom_minimum_size=Vector2(720,320)
		map_large.world=world;map_large.expanded=true;map_large.display_floor=requested;modal_box.add_child(map_large)
		var legend=GridContainer.new();legend.columns=3;legend.add_theme_constant_override("h_separation",18);modal_box.add_child(legend)
		for zone in world.facility_zones(requested):
			if zone.code in ["00","L0"] or (requested=="life" and zone.code in ["09","10"]):continue
			legend.add_child(label(zone.code+"  "+("伊万 / 老爹" if requested=="life" and zone.code=="01" else zone.name),15,text_color))
		body("金色：通路与门口 · 蓝色：附近的人。地图只显示本层可探索的区域；门后还有其它生活或作业区。",16,muted)

func quest_card(task:Dictionary,tracked:bool):
	var card=PanelContainer.new();card.add_theme_stylebox_override("panel",style(Color("26322e") if tracked else Color("172321"),Color("a38a5d") if tracked else Color("445148"),1,4));modal_box.add_child(card);UiSurface.attach(card)
	var box=margin_box(card,22,18)
	var place={"life":"D-6 生活层","labor":"D-6 作业层"}.get(task.place,world.story.Campaign.NAMES.get(task.place,""))
	box.add_child(label(task.kind+" / "+task.status+" / "+place+" · "+task.area,14,muted))
	var title=label(task.name,25,amber);title.add_theme_font_override("font",serif);box.add_child(title)
	if task.failed:box.add_child(label(task.step,17,Color("d4947d")))
	if not task.done and not task.failed:
		box.add_child(label("当前目标",15,amber))
		var step=label(task.step,21,Color("e4ddc4"));step.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;box.add_child(step)
		var local=task.place==world.floor_id or (task.place in ["life","labor"] and world.floor_id in ["life","labor"])
		if not local:box.add_child(label("下一步所在设施："+place,16,muted))
		if not tracked:box.add_child(button("接下来跟进这件事",func():Journal.track(world.story,task.id);show_journal(),true,true))
		else:box.add_child(button("在地图上看看这一带",func():show_journal("map",task.place),true,true))
	box.add_child(button("查看任务详情",func():show_task_detail(task.id),true,true))

func show_task_detail(id:String):
	var found=Journal.tasks(world.story).filter(func(t):return t.id==id)
	if found.is_empty():show_journal();return
	var task:Dictionary=found[0]
	start_modal(task.name,task.kind+" / "+task.status,true)
	modal_hint.text="目标随任务进度更新 · Esc 返回"
	var place={"life":"D-6生活层","labor":"D-6作业层"}.get(task.place,world.story.Campaign.NAMES.get(task.place,"设施"))
	body("当前目标" if not task.done and not task.failed else "任务结果",18,amber)
	prose(task.step,25)
	if not task.done and not task.failed:
		body("前往："+place+" · "+task.area,18,amber)
		modal_box.add_child(button("在地图上查看",func():show_journal("map",task.place)))
		modal_box.add_child(button("追踪这个任务",func():Journal.track(world.story,id);show_task_detail(id)))
	rule();body("任务背景",18,amber);prose(task.background,20)
	body("目标随实际进度更新；未经历的后续剧情不会提前显示。",16,muted)
	modal_box.add_child(button("返回任务列表",func():show_journal()))

func inventory_snapshot()->Dictionary:
	var out={}
	for id in world.story.items:out[id]=1
	for id in world.story.economy.goods:out[id]=int(world.story.economy.goods[id])
	out["military"]=int(world.story.economy.military);out["handmade"]=int(world.story.economy.handmade)
	return out
func observe_progress():
	var now=inventory_snapshot();var quests={}
	for t in Journal.tasks(world.story):quests[t.id]=t.status
	var books:Array=world.story.flags.get("publications",{}).keys()
	if not observing:observed_inventory=now;observed_tasks=quests;observed_publications=books;observing=true;return
	for id in books:
		if id not in observed_publications:receipt("获得刊物 · "+Publications.entry(id).title)
	observed_publications=books
	var events={}
	for t in Journal.tasks(world.story):
		var event=""
		if not observed_tasks.has(t.id):event="接取"+t.kind
		elif observed_tasks[t.id]!=t.status:event="任务失败" if t.failed else ("任务完成" if t.done else "任务更新")
		if event!="":
			if not events.has(event):events[event]=[]
			events[event].append(t.name)
	for event in events:receipt(event+" · "+"、".join(events[event]))
	var gained=[]
	for id in now:
		var amount=int(now[id])-int(observed_inventory.get(id,0))
		if amount<=0:continue
		var title=world.story.ITEMS[id][0] if world.story.ITEMS.has(id) else (world.story.Economy.GOODS[id].name if world.story.Economy.GOODS.has(id) else ("制式子弹" if id=="military" else "土制子弹"))
		gained.append(title+" ×"+str(amount))
	if not gained.is_empty():receipt("获得物品 · "+"、".join(gained))
	observed_inventory=now;observed_tasks=quests

func show_collection():
	var s=world.story
	modal_hint.text="鼠标停留查看线索   ·   已收录的刊物可以打开阅读   ·   ESC  返回"
	body("随身书架   %02d / %02d"%[Publications.count(s),Publications.data().entries.size()],25,amber)
	body("找到的书刊可以随时翻阅。未收录的只留剪影；鼠标停在书影上，看看你想起了哪里。",17,muted)
	for series in Publications.data().series:
		rule()
		var entries:Array=Publications.data().entries.filter(func(book):return book.series==series.id)
		body(series.name+"   "+str(Publications.count(s,series.id))+" / "+str(entries.size()),22,amber)
		body(series.description,16,muted)
		var grid=GridContainer.new();grid.columns=3;grid.add_theme_constant_override("h_separation",14);grid.add_theme_constant_override("v_separation",12);modal_box.add_child(grid)
		for book in entries:
			var found=Publications.owned(s,book.id)
			var panel=PanelContainer.new();panel.custom_minimum_size=Vector2(338,230)
			panel.size_flags_horizontal=Control.SIZE_EXPAND_FILL
			panel.add_theme_stylebox_override("panel",style(Color("21302a") if found else Color("14201e"),Color("8e7a54") if found else Color("3d4c44"),1,3))
			panel.tooltip_text=(book.author+" · "+book.date) if found else book.hint
			grid.add_child(panel)
			var box=margin_box(panel,16,13)
			var row=HBoxContainer.new();row.add_theme_constant_override("separation",16);box.add_child(row)
			var icon=TextureRect.new();icon.texture=Publications.icon(book);icon.custom_minimum_size=Vector2(91,125);icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;icon.mouse_filter=Control.MOUSE_FILTER_PASS
			var shader=ShaderMaterial.new();shader.shader=load("res://assets/visual/publication_icon.gdshader");shader.set_shader_parameter("unknown",not found);icon.material=shader;row.add_child(icon)
			if not found:
				var question=Label.new();question.text="?";question.add_theme_font_size_override("font_size",43);question.add_theme_color_override("font_color",Color("a8af95"));question.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;question.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;question.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);question.mouse_filter=Control.MOUSE_FILTER_IGNORE;icon.add_child(question)
			var words=VBoxContainer.new();words.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(words)
			var title=label(book.title if found else "未收录",19,text_color if found else muted);title.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;title.custom_minimum_size.x=170;words.add_child(title)
			words.add_child(label("第 %02d 册"%int(book.issue),14,muted))
			if found:
				var state=world.story.flags.publications[book.id]
				words.add_child(label("已翻阅" if state.read else "尚未翻阅",14,amber))
				box.add_child(button("翻开阅读",func():collection_scroll=modal_box.get_parent().scroll_vertical;show_publication(book.id),true,true))
			else:box.add_child(label("鼠标停留 · 回想线索",14,muted))
	if collection_scroll>0:modal_box.get_parent().set_deferred("scroll_vertical",collection_scroll)

func show_publication(id:String):
	var book=Publications.read(world.story,id)
	if book.is_empty():return
	world.autosave()
	start_modal("翻开一册旧书","随身卷宗   /   刊物阅读",true)
	modal.position=Vector2(265,84);modal.size=Vector2(1070,832)
	modal_hint.text="滚轮翻页   ·   合上书返回收藏   ·   ESC  返回探索"
	var header=HBoxContainer.new();header.add_theme_constant_override("separation",28);modal_box.add_child(header)
	var icon=TextureRect.new();icon.texture=Publications.icon(book);icon.custom_minimum_size=Vector2(110,148);icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;header.add_child(icon)
	var info=VBoxContainer.new();info.size_flags_horizontal=Control.SIZE_EXPAND_FILL;header.add_child(info)
	var title=label(book.title,28,amber);title.add_theme_font_override("font",serif);title.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;info.add_child(title)
	info.add_child(label(book.author,18,text_color));info.add_child(label(book.date,16,muted))
	rule()
	var paper=PanelContainer.new();paper.add_theme_stylebox_override("panel",style(Color("c8bea0"),Color("8e8264"),1,2));modal_box.add_child(paper)
	var inset=margin_box(paper,30,25)
	var text=RichTextLabel.new();text.bbcode_enabled=false;text.text=book.body;text.fit_content=true;text.scroll_active=false;text.add_theme_color_override("default_color",Color("293329"));text.add_theme_font_override("normal_font",serif);text.add_theme_font_size_override("normal_font_size",23);text.add_theme_constant_override("line_separation",10);inset.add_child(text)
	modal_box.add_child(button("合上书 · 返回刊物收藏",func():show_journal("collection"),true,true))

func show_blocks():
	start_modal("下工之后 · 方块","公社公共终端   /   消遣与练习",true)
	modal.position=Vector2(300,90);modal.size=Vector2(1000,820)
	modal_hint.text="方向键操作   ·   空格落下   ·   P 暂停   ·   ESC  退出终端"
	body("这台旧训练终端被机修组修好了。下工的居民轮流在这里消磨一会儿时间。",18,muted)
	terminal_game=preload("res://scripts/blocks_game.gd").new()
	terminal_game.best=int(world.story.flags.get("blocks_best",0))
	terminal_game.record_changed.connect(func(value):world.story.flags.blocks_best=value)
	terminal_game.leave_requested.connect(func():close())
	modal_box.add_child(terminal_game)
	modal_box.add_child(button("关掉屏幕 · 回到食堂",func():close(),true,true))
func receipt(text:String):
	if not is_instance_valid(receipt_box):
		receipt_box=VBoxContainer.new();receipt_box.position=Vector2(360,105);receipt_box.custom_minimum_size.x=650;receipt_box.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(receipt_box)
	move_child(receipt_box,get_child_count()-1)
	var card=PanelContainer.new();card.mouse_filter=Control.MOUSE_FILTER_IGNORE;card.add_theme_stylebox_override("panel",style(Color("182a25"),amber,1,5));receipt_box.add_child(card)
	var content=margin_box(card,16,10);var words=RichTextLabel.new();words.bbcode_enabled=true;words.fit_content=true;words.scroll_active=false;words.custom_minimum_size.x=620;words.text=highlight_items(text);content.add_child(words)
	receipt_timers.append({"node":card,"time":7.0})
func highlight_items(text:String)->String:
	var names=[]
	for id in world.story.ITEMS:names.append(world.story.ITEMS[id][0])
	for id in world.story.Economy.GOODS:names.append(world.story.Economy.GOODS[id].name)
	for book in Publications.data().entries:names.append(book.title)
	names.append_array(["扳手","保险芯","制式子弹","土制子弹","滤毒罐","匕首","香烟","照片","伏特加","面具","滤芯","干布"])
	names.sort_custom(func(a,b):return a.length()>b.length())
	var patterns=[]
	for name in names:patterns.append(name)
	var regex=RegEx.new();regex.compile("|".join(patterns))
	var cursor=0;var result=""
	for found in regex.search_all(text):result+=text.substr(cursor,found.get_start()-cursor)+"[color=#e2c47e]"+found.get_string()+"[/color]";cursor=found.get_end()
	return result+text.substr(cursor)

func show_map():show_journal("map")

func item_icon(id:String)->String:
	if id=="portable_radio":return "res://assets/visual/item_portable_radio.svg"
	return "res://assets/visual/item_"+world.story.Campaign.ITEM_ART.get(id,id)+".png"

func icon_rect(path:String,size:float=68)->TextureRect:
	var icon=TextureRect.new();icon.texture=load(path)
	icon.custom_minimum_size=Vector2(size,size);icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	return icon

var shop_actor="supply"
func show_shop(message:String="",tab:String=""):
	if tab!="":shop_tab=tab
	start_modal("第七供应点 · 柳德米拉" if shop_actor=="supply" else "聚落军需与资源收购","生活物资交易 · 任务物品与纪念物不出售",true)
	var s=world.story
	var tabs=HBoxContainer.new();modal_box.add_child(tabs)
	tabs.add_child(button("购买",func():show_shop("","buy"),true,true));tabs.add_child(button("出售",func():show_shop("","sell"),true,true))
	body(("购买物资" if shop_tab=="buy" else "出售背包物资")+"  /  制式弹 %d · 土制弹 %d"%[s.economy.military,s.economy.handmade],22,amber)
	if message!="":body(message,18,Color("a4bca0"))
	var list=s.Economy.GOODS.keys().filter(func(id):return s.Economy.GOODS[id].get("purchase",true)) if shop_tab=="buy" else s.items.duplicate()
	if shop_tab=="sell":
		for id in s.economy.goods:
			if int(s.economy.goods[id])>0:list.append(id)
		if list.is_empty():body("背包里没有可展示的物品。",18,muted)
	for id in list:
		var good:Dictionary=s.Economy.GOODS.get(id,{})
		var row=HBoxContainer.new();row.add_theme_constant_override("separation",14);modal_box.add_child(row)
		row.add_child(icon_rect(item_icon(id),64))
		var b=VBoxContainer.new();b.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(b)
		var title:String=good.get("name",s.ITEMS.get(id,[id])[0])
		if shop_tab=="buy":
			b.add_child(label(title+" · %d 发"%good.price,21,amber))
			var detail=label(good.detail,16,muted);detail.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;b.add_child(detail)
			b.add_child(label("余货 %d · 已有 %d"%[s.economy.stock.get(id,0),s.economy.goods.get(id,0)],15,muted))
			row.add_child(button("购买",func():shop_buy(id),s.economy.military>=good.price and s.economy.stock.get(id,0)>0,true))
		else:
			var price:int=s.Economy.sale_price(s,id)
			b.add_child(label(title+" × "+str(s.economy.goods.get(id,1)),21,amber))
			b.add_child(label("收购价 %d 发 / 件"%price if price>0 else "任务所需 / 个人物品 · 不收购",16,muted))
			row.add_child(button("出售一件" if price>0 else "不能出售",func():confirm_sale(id),price>0,true))
	modal_box.add_child(button("返回交谈",func():show_dialogue(shop_actor)))
func confirm_sale(id:String="vodka"):
	var s=world.story;var price:int=s.Economy.sale_price(s,id)
	start_modal("出售这件物品？","交易确认",true)
	body("商人愿意出 %d 发制式子弹。确认后从背包移除一件。"%price,21)
	modal_box.add_child(button("确认出售 · %d 发"%price,func():shop_sell(id),price>0))
	modal_box.add_child(button("先留着",func():show_shop("","sell")))

func show_pause():
	start_modal("暂停 / 现场记录","D–6   /   现场记录",true)
	modal_box.add_child(button("继续探索",func():close()))
	modal_box.add_child(button("保存游戏…  [F5]",func():show_saves(true)))
	modal_box.add_child(button("读取存档…  [F9]",func():show_saves(false)))
	modal_box.add_child(button("重新开始（保留已有存档）",func():show_restart_confirm()))
	modal_box.add_child(button("返回主界面…",func():show_menu_confirm()))
	if is_instance_valid(world.combat) and world.combat.active:modal_box.add_child(button("重试本场战斗（恢复战前资源）",func():world.combat.retry()))
	modal_box.add_child(button("设置 · 画面与声音",show_settings))
	audio_controls()
	rule()
	body("WASD / 方向键：8 方向移动\nE：与当前选中的目标交互\nI：背包　J：手记　M：地图\nTab：总览　滚轮：附近有多个目标时切换，否则缩放\nEsc：关闭界面 / 菜单",20)
	body("靠近人物或物件时会出现互动提示。图文旅程可在暂停页保存，也能打开背包使用物资。",16,muted)
func show_restart_confirm():
	start_modal("重新开始？","当前未保存的进度将丢失",true)
	modal_box.add_child(button("确认重新开始",func():world.restart()))
	modal_box.add_child(button("返回",func():show_pause()))

func show_menu_confirm():
	start_modal("收起这段旅程？","先保存手记，下次就能从主界面继续",true)
	modal_box.add_child(button("保存并返回主界面",func():show_saves(true,true)))
	modal_box.add_child(button("直接返回（放弃未保存进度）",func():world.return_menu()))
	modal_box.add_child(button("继续旅程",func():show_comic_pause() if comic_active else show_pause()))

func show_departure(confirmed:bool):
	var s=world.story
	if confirmed:
		show_chapter_end()
		return
	start_modal("离开 D-6？","出发确认 / "+s.ROUTES.get(world.pending_route,""),true)
	is_departure=true
	body("离开后将进入图文旅程。确认前可以返回上下两层，办完还没办的事。",21)
	if not s.has("mask") or not s.has("filter"):body("防护尚未齐全。请去下层领取，或向供应点购买面具与配套滤毒罐。",20,Color("d09c7a"))
	modal_box.add_child(button("确认出发",func():
		if not s.has("mask") or not s.has("filter"):toast("先取得面具与滤毒罐；可去下层领取或向供应点购买。",6);return
		var snapshot=s.serialize().duplicate(true);snapshot.erase("checkpoint")
		snapshot.floor=world.floor_id;snapshot.position=[world.player.position.x,.04,world.player.position.z]
		s.departure_checkpoint=snapshot
		s.flags.departure_committed=true
		s.Progression.fail(s,["life","labor"],"已离开 D-6，本次旅程无法返回完成这项委托。")
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
		world.sync_event_music("")
		if s.flags.has("resume_dialogue"):
			var id:String=s.flags.resume_dialogue;s.flags.erase("resume_dialogue");show_dialogue(id)
		elif s.flags.has("next_facility"):
			world.travel_campaign(s.flags.next_facility)
		elif s.f("intro_done") and not s.ending:close();refresh_status();toast("第一件事：到第七供应点领取今日维生素 D",7)
		else:show_chapter_end()

func show_comic_pause():
	start_modal("旅程暂停","已读的面板和选择会随存档保存",true)
	modal_box.add_child(button("继续剧情",func():show_comic()))
	modal_box.add_child(button("查看背包 / 使用物资",func():show_inventory()))
	modal_box.add_child(button("保存当前进度",func():show_saves(true)))
	modal_box.add_child(button("读取存档",func():show_saves(false)))
	modal_box.add_child(button("设置 · 画面与声音",show_settings))
	modal_box.add_child(button("重新开始",func():show_restart_confirm()))
	modal_box.add_child(button("返回主界面…",func():show_menu_confirm()))
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
		art.texture=load("res://assets/cinematics/"+{"home":"wake","tea":"wake","anna":"commune","commune":"commune","sech":"sergey","starcity":"starcity","bridge":"wake","signal":"starcity","ocean":"starcity"}.get(ending_id,"wake")+".png")
		art.custom_minimum_size=Vector2(680,360);art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;row.add_child(art)
		var text_box=VBoxContainer.new();text_box.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(text_box)
		var epilogue:String=outcome.body
		if s.f("father_angry") and ending_id in ["starcity","bridge"]:epilogue+="\n你没有收回那句恨。以后怎么相处，要等以后再说。"
		prose(epilogue,25,text_box)
		rule()
		body("你的选择",19,amber)
		for pair in [["water_secured","给 D-6 找到了两箱净水滤芯"],["greenhouse_fixed","修好了公社温室的回水"],["anna_reunited","核实了安娜哥哥的身份与探视安排"],["radio_fixed","恢复了谢契的短波电台"],["books_saved","替谢尔盖救下受潮的书"],["father_semyon","问清了父亲与老爹当年的往事"],["cautious_signal","没有把所有人的坐标交给陌生呼叫"]]:
			if s.f(pair[0]):body("· "+pair[1],20,muted)
		modal_box.add_child(button("保存这段旅程",func():show_saves(true)))
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
	modal_box.add_child(button("保存进度",func():show_saves(true)))
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
	for pair in [["Master","总音量"],["Music","背景旋律"],["Radio","收音机音乐"],["Effects","交互音效"],["Footsteps","脚步声"]]:
		var row=HBoxContainer.new();modal_box.add_child(row)
		var name_label=label(pair[1],17,muted);name_label.custom_minimum_size.x=190;row.add_child(name_label)
		var slider=HSlider.new();slider.min_value=0;slider.max_value=1;slider.step=.05;slider.value=session.volume(pair[0]);slider.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(slider)
		var readout=label(str(roundi(slider.value*100))+"%",16,amber);readout.custom_minimum_size.x=55;row.add_child(readout)
		var bus_name:String=pair[0]
		slider.value_changed.connect(func(value):session.set_volume(bus_name,value);readout.text=str(roundi(value*100))+"%")

func show_settings():
	start_modal("设置","画面 / 声音",true)
	modal_hint.text="应用后确认保留更改 · Esc 返回"
	modal.position=Vector2(230,70);modal.size=Vector2(1140,860)
	var controls=preload("res://scripts/ui_settings.gd").new();modal_box.add_child(controls);controls.setup(world.get_node("/root/Session"))
	modal_box.add_child(button("返回",func():show_comic_pause() if comic_active else show_pause()))

func dialogue_actor()->String:return {"armory":"armorer","main_gate":"main_guard","d6_return_desk":"commander","front_veteran":"plant_veteran"}.get(dialogue_id,dialogue_id)

func shop_buy(id:String):
	var s=world.story
	var before=s.economy.ledger.size()
	var result=s.Economy.buy(s,id)
	if s.economy.ledger.size()>before:s.Conversation.reply(s,shop_actor,"「买一份"+s.Economy.GOODS[id].name+"。」",result)
	show_shop(result)

func shop_sell(id:String="vodka"):
	var s=world.story
	var before=s.economy.ledger.size()
	var result=s.Economy.sell(s,id)
	if s.economy.ledger.size()>before:s.Conversation.reply(s,shop_actor,"「这件东西，按你说的价收吧。」",result)
	show_shop(result)

func show_saves(saving:bool,return_to_menu:bool=false,group:String="manual"):
	saves_return_menu=return_to_menu
	start_modal("保存游戏" if saving else "读取存档","6 个手动档位 · 自动存档单独保留 · 不同档位互不覆盖",true)
	modal_hint.text="滚轮浏览档位    ·    Esc 返回"
	var store=world.SaveStore
	if not saving:
		var tabs=HBoxContainer.new();modal_box.add_child(tabs)
		tabs.add_child(button("手动存档",func():show_saves(false,false,"manual"),true,true))
		tabs.add_child(button("自动与旧版存档",func():show_saves(false,false,"auto"),true,true))
	var paths:Array=store.manual_paths() if saving or group=="manual" else store.automatic_paths()+[store.QUICK]
	for path in paths:
		var data=store.read(path)
		var card=PanelContainer.new();card.add_theme_stylebox_override("panel",style(Color("192824"),Color("5e614a"),1,6));modal_box.add_child(card)
		var content=margin_box(card,14,12);var row=HBoxContainer.new();content.add_child(row)
		var words=VBoxContainer.new();words.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(words)
		words.add_child(label(store.title(path),22,amber))
		var details=label(store.description(path),16,muted if data.is_empty() else text_color);details.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;words.add_child(details)
		var slot:String=path;var metadata:Dictionary=data
		row.add_child(button("保存到此档位" if saving else "读取",func():confirm_slot(slot,saving,metadata),saving or not data.is_empty(),true))
	modal_box.add_child(button("返回",func():show_comic_pause() if comic_active else show_pause()))
func saved_slot(path:String):
	if not world.save_game(path):return
	if saves_return_menu:world.return_menu()
	else:show_saves(true)
func confirm_slot(path:String,saving:bool,data:Dictionary):
	if saving and data.is_empty() and not FileAccess.file_exists(path):saved_slot(path);return
	start_modal("覆盖这个存档？" if saving else "读取这个存档？","覆盖只影响所选档位；读取会放弃当前未保存的进度。",true)
	body(world.SaveStore.title(path),24,amber)
	body(world.SaveStore.description(path),19,text_color)
	modal_box.add_child(button("确认覆盖" if saving else "确认读取",func():
		if saving:saved_slot(path)
		else:world.load_game(path)))
	modal_box.add_child(button("返回列表",func():show_saves(saving,saves_return_menu)))

func show_combat_defeat():
	start_modal("你倒在了"+({"surface":"地表废墟里","railfront":"联络线战区"}.get(world.floor_id,"水厂里")),"本场战斗前已保留检查点 · 重试恢复当时的资源",true)
	body("面罩内的呼吸声渐渐远去。"+("远处传来老兵叫你的名字。" if is_instance_valid(world.combat.veteran) else "寒风还在废墟之间回响。"),23)
	modal_box.add_child(button("从交火前重试",func():world.combat.retry()))
	modal_box.add_child(button("读取其它手记",func():show_saves(false)))
