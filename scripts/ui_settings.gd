extends VBoxContainer
## Shared by the title screen, pause menu and cinematic pause menu.
const Video=preload("res://scripts/video_settings.gd")
var session
var staged:Dictionary={}
var status:Label
var confirm:Button
var cancel:Button
var picks:Dictionary={}
var sizes:Array=[]
func setup(s):
	session=s;staged=session.video.duplicate();add_theme_constant_override("separation",12)
	var skin=Theme.new()
	for kind in ["Button","OptionButton","TabContainer"]:
		skin.set_color("font_color",kind,Color("e3d9bd"));skin.set_color("font_hover_color",kind,Color("f4e7c8"));skin.set_color("font_disabled_color",kind,Color("68766a"))
		for state in (["normal","hover","pressed","focus","disabled"] if kind!="TabContainer" else ["panel","tab_selected","tab_unselected","tab_hovered"]):
			var ink=StyleBoxFlat.new();ink.bg_color=Color("2e3d32") if state in ["hover","pressed","tab_selected"] else Color("142321");ink.border_color=Color("b39b66") if state in ["focus","tab_selected","hover"] else Color("53614f");ink.set_border_width_all(1);ink.set_corner_radius_all(3);ink.content_margin_left=12;ink.content_margin_right=12;ink.content_margin_top=8;ink.content_margin_bottom=8;skin.set_stylebox(state,kind,ink)
	theme=skin
	var tabs=TabContainer.new();tabs.custom_minimum_size.y=365;add_child(tabs)
	var graphics=VBoxContainer.new();graphics.name="画面";graphics.add_theme_constant_override("separation",12);tabs.add_child(graphics)
	select(graphics,"显示模式",["窗口","最大化窗口","无边框全屏"],staged.mode,func(i):staged.mode=i)
	sizes=Video.RESOLUTIONS.duplicate();var size=Vector2i(staged.width,staged.height)
	if size not in sizes:sizes.append(size)
	select(graphics,"窗口分辨率",sizes.map(func(p):return "%d × %d"%[p.x,p.y]),sizes.find(size),func(i):staged.width=sizes[i].x;staged.height=sizes[i].y)
	select(graphics,"画面填充",["保持比例 · 两侧或上下留黑边","填满窗口 · 可能拉伸画面"],1 if staged.fill else 0,func(i):staged.fill=i==1)
	select(graphics,"画质",["流畅 · 70% 渲染 / 关闭动态阴影","均衡 · 85% 渲染 / 主光源阴影","精细 · 原生渲染 / 完整阴影"],staged.quality,func(i):staged.quality=i)
	select(graphics,"垂直同步",["关闭","开启"],1 if staged.vsync else 0,func(i):staged.vsync=i==1)
	var caps=[30,60,120,144,0]
	select(graphics,"帧率上限",["30 FPS","60 FPS","120 FPS","144 FPS","不限"],caps.find(staged.fps),func(i):staged.fps=caps[i])
	words(graphics,"全屏使用显示器当前分辨率；窗口分辨率决定退出全屏后的尺寸。画质影响场景清晰度、抗锯齿和阴影，界面文字保持清晰。",16)
	var audio=VBoxContainer.new();audio.name="声音";audio.add_theme_constant_override("separation",20);tabs.add_child(audio)
	for pair in [["Master","总音量"],["Music","剧情与背景音乐"],["Radio","收音机音乐"],["Effects","交互与战斗音效"],["Footsteps","脚步声"]]:
		var row=HBoxContainer.new();audio.add_child(row);var caption=words(row,pair[1]);caption.custom_minimum_size.x=190
		var slider=HSlider.new();slider.name="Audio_"+pair[0];slider.min_value=0;slider.max_value=1;slider.step=.05;slider.value=session.volume(pair[0]);slider.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(slider)
		var readout=words(row,str(roundi(slider.value*100))+"%",17);readout.custom_minimum_size.x=58;var bus:String=pair[0]
		slider.value_changed.connect(func(value):session.set_volume(bus,value);readout.text=str(roundi(value*100))+"%")
	words(audio,"声音即时保存。剧情配乐与收音机使用独立音量。",16)
	status=words(self,"");status.custom_minimum_size.y=28
	var buttons=HBoxContainer.new();buttons.add_theme_constant_override("separation",12);add_child(buttons)
	button(buttons,"应用画面设置",func():session.preview_video(staged))
	confirm=button(buttons,"保留更改",func():session.confirm_video());cancel=button(buttons,"恢复原设置",func():session.revert_video())
	session.video_changed.connect(refresh);refresh()
func refresh():
	if not is_instance_valid(session):return
	confirm.disabled=not session.video_preview;cancel.disabled=not session.video_preview
	status.text="请确认画面可用；%d 秒后自动恢复原设置。"%ceili(session.video_seconds) if session.video_preview else "画面设置已保存。"
	if not session.video_preview:staged=session.video.duplicate()
	if not session.video_preview:
		var indices={"显示模式":staged.mode,"窗口分辨率":sizes.find(Vector2i(staged.width,staged.height)),"画面填充":1 if staged.fill else 0,"画质":staged.quality,"垂直同步":1 if staged.vsync else 0,"帧率上限":[30,60,120,144,0].find(staged.fps)}
		for key in picks:picks[key].select(maxi(0,int(indices[key])))
func _process(_delta):
	if is_instance_valid(session) and session.video_preview:status.text="请确认画面可用；%d 秒后自动恢复原设置。"%ceili(session.video_seconds)
func words(parent:Node,text:String,size:int=19)->Label:
	var l=Label.new();l.text=text;l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;l.add_theme_font_size_override("font_size",size);l.add_theme_color_override("font_color",Color("d7d0b6"));l.size_flags_horizontal=Control.SIZE_EXPAND_FILL;parent.add_child(l);return l
func select(parent:Node,title:String,choices:Array,index:int,action:Callable):
	var row=HBoxContainer.new();parent.add_child(row);var caption=words(row,title);caption.custom_minimum_size.x=175
	var pick=OptionButton.new();pick.custom_minimum_size.y=36;pick.size_flags_horizontal=Control.SIZE_EXPAND_FILL;pick.clip_text=true;row.add_child(pick)
	pick.name="Setting_"+title;picks[title]=pick
	for text in choices:pick.add_item(str(text))
	pick.select(maxi(0,index));pick.item_selected.connect(action)
func button(parent:Node,title:String,action:Callable)->Button:
	var b=Button.new();b.text=title;b.custom_minimum_size=Vector2(150,44);parent.add_child(b);b.pressed.connect(action);return b
