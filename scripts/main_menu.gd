extends Control
const Surface=preload("res://scripts/ui_surface.gd")
const SaveStore=preload("res://scripts/save_store.gd")
const SAVE="user://d6_save.json"
var save_path=SAVE
const SCENES=["life","labor","waterworks","commune","sech","coal","starcity"]
var dialog:PanelContainer
var status:Label
var continue_button:Button
var save_data:Dictionary={}
var serif:Font
var sans:Font
func _ready():
	serif=load("res://assets/fonts/MetroSerif.otf");sans=load("res://assets/fonts/MetroSans.otf")
	var theme=Theme.new();theme.default_font=sans;theme.default_font_size=21;self.theme=theme
	var art=TextureRect.new();art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	art.texture=load("res://assets/cinematics/menu_station.png" if ResourceLoader.exists("res://assets/cinematics/menu_station.png") else "res://assets/cinematics/wake.png")
	art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED;add_child(art)
	var shade=Gradient.new();shade.set_color(0,Color(.02,.04,.04,.97));shade.set_color(1,Color(.02,.04,.04,.05))
	var gradient=GradientTexture2D.new();gradient.gradient=shade;gradient.fill_from=Vector2.ZERO;gradient.fill_to=Vector2.RIGHT
	var veil=TextureRect.new();veil.texture=gradient;veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);veil.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(veil)
	var box=VBoxContainer.new();box.position=Vector2(100,150);box.size=Vector2(500,700);box.add_theme_constant_override("separation",18);add_child(box)
	words(box,"МОСКВА  /  1982",19,Color("bda371"))
	var title=words(box,"地铁1982",64,Color("eee1c3"));title.add_theme_font_override("font",serif)
	words(box,"灯光之外，还有人在等你。",23,Color("b3bdaf"))
	var space=Control.new();space.custom_minimum_size.y=65;box.add_child(space)
	read_save()
	continue_button=choice(box,"继续游戏",continue_game);continue_button.disabled=save_data.is_empty()
	status=words(box,save_summary(),16,Color("9da99e"));status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	choice(box,"新的旅程",new_game)
	choice(box,"设置",show_settings)
	choice(box,"读取手记",show_saves)
	choice(box,"操作与制作信息",show_about)
	choice(box,"退出游戏",func():get_tree().quit())
	var footer=words(self,"一九八二年十一月  ·  莫斯科地下",16,Color("a3ac9e"));footer.position=Vector2(100,930)
	var music=AudioStreamPlayer.new();music.stream=preload("res://assets/audio/shelter_theme.wav");music.bus="Music";music.volume_db=-12;add_child(music)
	if DisplayServer.get_name()!="headless":music.play()
func words(parent:Node,text:String,size:int,color:Color)->Label:
	var label=Label.new();label.text=text;label.add_theme_font_size_override("font_size",size);label.add_theme_color_override("font_color",color);parent.add_child(label);return label
func skin()->StyleBoxFlat:
	var style=StyleBoxFlat.new();style.bg_color=Color("152322");style.border_color=Color("76694e");style.set_border_width_all(1);style.set_corner_radius_all(3);style.content_margin_left=22;style.content_margin_right=22;style.content_margin_top=12;style.content_margin_bottom=12;return style
func choice(parent:Node,text:String,action:Callable)->Button:
	var button=Button.new();button.text=text;button.custom_minimum_size.y=57;button.alignment=HORIZONTAL_ALIGNMENT_LEFT;button.add_theme_stylebox_override("normal",skin());button.add_theme_color_override("font_color",Color("e2d6b8"));parent.add_child(button);Surface.attach(button,"button")
	var hover=skin();hover.bg_color=Color("27392f");hover.border_color=Color("c3a66d");button.add_theme_stylebox_override("hover",hover)
	var pressed=skin();pressed.bg_color=Color("101c19");button.add_theme_stylebox_override("pressed",pressed)
	button.add_theme_color_override("font_disabled_color",Color("657269"))
	button.pressed.connect(func():get_node("/root/Session").sound("ui");action.call());return button
func read_save():
	save_data=SaveStore.read(save_path)
	if save_path==SAVE:
		var recent=SaveStore.newest()
		if not recent.is_empty():save_data=recent.data;save_path=recent.path
func save_summary()->String:return SaveStore.summary(save_data)
func show_saves():
	var box=open_dialog("读取手记")
	for i in SaveStore.paths().size():
		var path:String=SaveStore.paths()[i];var data=SaveStore.read(path)
		var title=["快速手记","手动一","手动二","手动三","自动一","自动二","自动三"][i]
		var b=choice(box,title+"  /  "+SaveStore.summary(data),func():save_path=path;continue_game())
		b.add_theme_font_size_override("font_size",16);b.disabled=data.is_empty()
	choice(box,"返回",close_dialog)
func continue_game():
	save_data=SaveStore.read(save_path)
	if save_data.is_empty():status.text="这份手记暂时无法读取。";continue_button.disabled=true;return
	var position=save_data.get("position",[-10.5,.04,-3.4])
	get_node("/root/Session").enter(save_data,save_data.get("floor","life"),Vector3(position[0],maxf(position[1],.04),position[2]))
func new_game():
	if save_data.is_empty():start_new();return
	var box=open_dialog("开始新的旅程")
	words(box,"手动与快速手记会保留。新旅程只会轮换三个自动记录；可先把旧旅程存入手动位。",21,Color("d6d5c0"))
	choice(box,"从战争序章开始",start_new);choice(box,"返回",close_dialog)
func start_new():
	get_node("/root/Session").clear();get_tree().change_scene_to_file("res://scenes/d6.tscn")
func open_dialog(title:String)->VBoxContainer:
	close_dialog();dialog=PanelContainer.new();dialog.position=Vector2(570,180);dialog.size=Vector2(780,620);dialog.add_theme_stylebox_override("panel",skin());add_child(dialog);Surface.attach(dialog)
	var box=VBoxContainer.new();box.add_theme_constant_override("separation",20);dialog.add_child(box);words(box,title,34,Color("d9c394"));return box
func close_dialog():
	if is_instance_valid(dialog):remove_child(dialog);dialog.queue_free()
func show_settings():
	var box=open_dialog("设置")
	for pair in [["Master","总音量"],["Music","背景旋律"],["Effects","交互音效"],["Footsteps","脚步声"]]:
		var row=HBoxContainer.new();box.add_child(row);var caption=words(row,pair[1],21,Color("d6d5c0"));caption.custom_minimum_size.x=160
		var slider=HSlider.new();slider.min_value=0;slider.max_value=1;slider.step=.05;slider.value=get_node("/root/Session").volume(pair[0]);slider.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(slider)
		var value=words(row,str(roundi(slider.value*100))+"%",18,Color("c3aa75"));value.custom_minimum_size.x=65;var bus:String=pair[0]
		slider.value_changed.connect(func(v):get_node("/root/Session").set_volume(bus,v);value.text=str(roundi(v*100))+"%")
	choice(box,"返回主界面",close_dialog)
func show_about():
	var box=open_dialog("旅程之前")
	for line in ["WASD / 方向键移动，E 调查或交谈。","交火时鼠标瞄准、左键射击，R 装填土制弹。","老兵倒地后靠近并按住 E 两秒救援。","J 打开手记，M 翻到地图，I 打开背包。","空格补全文字，Esc 暂停，F5 保存，F9 读取。","请留意人物说的话、墙上的标牌与现场留下的纸条。","中文字体：Noto。脚步素材：Kenney（CC0）。"]:words(box,line,20,Color("c2c9b9"))
	choice(box,"返回主界面",close_dialog)
func _unhandled_input(event:InputEvent):
	if event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:close_dialog()
