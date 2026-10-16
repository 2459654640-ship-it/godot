extends Control
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
	line.add_child(label("D–6",17,amber))
	var title=label("地铁 1982",27,text_color)
	title.add_theme_font_override("font",serif)
	b.add_child(title)
	var top=panel(Vector2(298,28),Vector2(516,56))
	var topbox=margin_box(top,17,11)
	location_label=label("居住层 / 伊万的卧室",19,text_color)
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
	var mt=label("D–6  /  居住层",14,muted)
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
	toast("离站前，先看看床下木箱，与老爹说句话。",7)

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
	b.pressed.connect(cb)
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

func prose(text:String,sz:int=21):
	var rich=RichTextLabel.new()
	rich.bbcode_enabled=true
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
	modal_box.add_child(rich)

func start_modal(title:String,subtitle:String,wide:bool=false):
	for child in modal.get_children():
		modal.remove_child(child)
		child.queue_free()
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
	main.add_child(label("ESC  返回     /     对话期间移动暂停",14,muted))
	modal.visible=true
	scrim.visible=true
	is_departure=false
	target_label.visible=false

func show_dialogue(id:String):
	dialogue_id=id
	var v=world.story.view(id)
	start_modal(v.name,v.role+"   /   D–6 居住层")
	prose(v.body)
	rule()
	if v.options.is_empty():body("这里暂时没有可执行的操作。",17,muted)
	for option in v.options:
		var o:Dictionary=option
		var b=button(o.text,func():world.perform(o.key,id),o.enabled)
		b.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		modal_box.add_child(b)
		if not o.enabled:body("  └ "+o.reason,15,muted)
	modal_box.add_child(button("结束交谈" if v.role!="调查" else "收起调查",func():close(),true,true))

func show_reply(id:String,text:String):
	var v=world.story.view(id)
	start_modal(v.name,"交互结果   /   状态已更新")
	prose(text,22)
	rule()
	modal_box.add_child(button("继续交谈 / 调查",func():show_dialogue(id)))
	modal_box.add_child(button("返回探索",func():close()))

func close():
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
	inventory_count.text="%02d 件随身物品" % world.story.items.size()
	route_label.text=world.story.ROUTES.get(world.story.route,"尚未选择离站方式")
	var signature=",".join(world.story.items)
	if quick_items and signature!=quick_signature:
		for child in quick_items.get_children():
			quick_items.remove_child(child)
			child.queue_free()
		for id in world.story.items.slice(0,3):
			var icon=TextureRect.new()
			icon.texture=load("res://assets/visual/item_"+id+".png")
			icon.custom_minimum_size=Vector2(44,44)
			icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.tooltip_text=world.story.ITEMS[id][0]
			quick_items.add_child(icon)
		quick_signature=signature
func tick(delta:float):
	location_label.text="D–6 居住层  /  "+world.room_name
	status_label.text="16 XI 1982   /   "+("换班 · 黄灯" if world.phase>=8 else "07:42 · 早班")
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
	if world.story.items.is_empty():body("背包里还没有物品。卧室床下的木箱值得看看。")
	for id in world.story.items:
		var item=world.story.ITEMS[id]
		var row=HBoxContainer.new()
		row.add_theme_constant_override("separation",18)
		modal_box.add_child(row)
		var icon=TextureRect.new()
		icon.texture=load("res://assets/visual/item_"+id+".png")
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

func show_journal():
	start_modal("离站前的手记","JOURNAL   /   原版剧情基线 · D–6 局部扩展",true)
	body(world.story.objective(),24,amber)
	rule()
	body("净水危机",21,amber)
	body("储水只够两周。是否随队寻找净水滤芯，或走另一条路，由你在离站前决定。登记征召不会立即结束探索。",18)
	body("可尝试的离站办法",21,amber)
	for pair in [
	 ["征召小队",world.story.f("kit"),"科瓦廖夫登记 → 供应点领取防护 → 集合气闸"],
	 ["维修许可",world.story.has("permit"),"向妮娜借工具 → 洗漱区取保险芯 → 修监测箱 → 妮娜签字 → 伊戈尔"],
	 ["战前旧物",world.story.f("cache"),"卧室木箱 → 匕首撬暗格 → 伏特加与伊戈尔交涉"],
	 ["换班侧门",world.story.f("shift"),"用香烟交换情报，或帮厨房止漏换热汤送给米哈伊尔 → 侧门等黄灯"],
	 ["检修管线",world.story.has("knife") or world.story.has("wrench"),"带工具调查盖板 → 绕过岗哨；硬撬会折损匕首，不补发装备"]]:
		body(("◆ " if pair[1] else "◇ ")+pair[0],20,amber if pair[1] else text_color)
		body(pair[2],16,muted)
	rule()
	body("已获得的情报",21,amber)
	if world.story.intel.is_empty():body("尚无记录。调查征召令、收音机和走廊记号。",18,muted)
	for info in world.story.intel:body("— "+info,18)
	body("范围边界：水厂、父亲去向、东方-7与后续阵营关系均未在此原型定稿。",16,muted)

func show_map():
	start_modal("D–6 居住层","LEVEL PLAN   /   金色：出入口 · 蓝色：居民",true)
	map_large=MapView.new()
	map_large.custom_minimum_size=Vector2(720,460)
	map_large.world=world
	map_large.expanded=true
	modal_box.add_child(map_large)
	body("这是一张平面导览图。房间由主通道连接；东段正门与侧门均有实体门闩。",18)
	body("Tab 切换斜俯视总览，滚轮调整镜头距离。地图不用于传送。",16,muted)

func show_pause():
	start_modal("暂停 / 现场记录","D–6   /   视觉与关卡原型",true)
	modal_box.add_child(button("继续探索",func():close()))
	modal_box.add_child(button("保存手记  [F5]",func():world.save_game()))
	modal_box.add_child(button("读取手记  [F9]",func():world.load_game()))
	modal_box.add_child(button("重新开始（保留已有存档）",func():show_restart_confirm()))
	modal_box.add_child(button("声音："+("关" if AudioServer.is_bus_mute(0) else "开"),func():AudioServer.set_bus_mute(0,not AudioServer.is_bus_mute(0));show_pause()))
	rule()
	body("WASD / 方向键：8 方向移动\nE：交谈 / 调查\nI：背包　J：手记　M：地图\nTab：总览　滚轮：缩放\nEsc：关闭界面 / 菜单",20)
	body("角色与器物为统一尺度的原创低模原型资产，不代表最终美术。固定镜头使用切墙视图，保留完整墙体碰撞。",16,muted)
func show_restart_confirm():
	start_modal("重新开始？","当前未保存的进度将丢失",true)
	modal_box.add_child(button("确认重新开始",func():world.restart()))
	modal_box.add_child(button("返回",func():show_pause()))

func show_departure(confirmed:bool):
	var s=world.story
	var departure_route=world.pending_route if not confirmed else s.route
	start_modal("门的另一边" if confirmed else "确认离开 D–6？","DEPARTURE   /   "+s.ROUTES.get(departure_route,"尚未选择"),true)
	is_departure=true
	body("你选择了："+s.ROUTES.get(departure_route,""),26,amber)
	if not confirmed:
		body("确认后展示本次离站记录，原型到此为止。你仍可返回继续探索，或更换离站路线。",20)
		if not s.has("mask") or not s.has("filter"):body("防护不全：没有完整的面具与滤毒罐。这条路不会自动补给；是否仍然离开？",20,Color("d29270"))
		modal_box.add_child(button("确认离站 · 查看本次记录",func():s.route=world.pending_route;s.ending=true;s.changed.emit();show_departure(true)))
		modal_box.add_child(button("还没准备好，返回探索",func():close()))
	else:
		body("居住层的灯光在你身后合拢。前面是未写完的路。",22)
		body("携带物品：%d 件　／　情报：%d 条" % [s.items.size(),s.intel.size()],20)
		body("防护装备："+("齐备" if s.has("mask") and s.has("filter") else "不齐备 · 风险已确认"),20)
		if s.f("father") or s.has("frequency"):body("带走的疑问：父亲的去向与东方-7。没有证实，也没有遗忘。",20)
		if s.route=="bribe":body("代价：战前伏特加已交出；通行没有写入登记簿。",18,amber)
		if s.route=="shift":body("代价：用物资或劳动换到时间窗；没有额外装备。",18,amber)
		if s.route=="hatch":body("代价：绕行旧管线；工具是否保留取决于拆卸方式。",18,amber)
		rule()
		body("D–6 视觉与关卡原型结束。水厂、地表、东方-7和父亲线将在后续逐块扩展。",18,muted)
		modal_box.add_child(button("返回 D–6，继续比较其他办法",func():s.ending=false;s.changed.emit();close()))
		modal_box.add_child(button("保存这次离站记录",func():world.save_game()))
		modal_box.add_child(button("重新开始",func():show_restart_confirm()))
