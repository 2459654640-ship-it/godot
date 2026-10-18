extends RefCounted
## A persistent transcript above a separate, pinned reply list.
static func portrait(h,id:String)->String:
	var art={"armory":"queue","main_gate":"commander","d6_return_desk":"commander","coal_gate_entry":"queue"}.get(id,id)
	if id=="ivan" and h.world.player.art_id!="":art=h.world.player.art_id
	if h.world.npcs.has(id) and h.world.npcs[id].art_id!="":art=h.world.npcs[id].art_id
	return "res://assets/portraits/"+art+".png"
static func render(h,id:String,first_new:int):
	var s=h.world.story
	var view=s.view(id)
	h.dialogue_id=id
	h.start_modal(view.name,view.role+"  /  "+h.world.floor_name())
	var history=h.modal_box
	var scroll:ScrollContainer=history.get_parent()
	var main=scroll.get_parent()
	var entries:Array=s.conversations.get(id,[])
	for i in entries.size():
		var entry:Dictionary=entries[i]
		var block:Control
		var narrator=entry.speaker=="narrator"
		var mine=entry.speaker=="ivan"
		var old_id=h.dialogue_id
		if i<first_new or mine:h.dialogue_id=""
		if narrator:
			var words=h.prose(entry.text,18,history);block=words
			words.add_theme_color_override("default_color",Color("94a39b"))
		else:
			var row=HBoxContainer.new();block=row;row.add_theme_constant_override("separation",12);history.add_child(row)
			if mine:row.add_spacer(false)
			var path=portrait(h,entry.speaker)
			if ResourceLoader.exists(path) and not mine:
				var face=TextureRect.new();face.texture=load(path);face.custom_minimum_size=Vector2(66,78)
				face.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;face.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;row.add_child(face)
			var panel=PanelContainer.new();panel.size_flags_horizontal=Control.SIZE_EXPAND_FILL
			panel.add_theme_stylebox_override("panel",h.style(Color("243229") if mine else Color("1d2a2c"),Color("596247") if mine else Color("3e5350"),1,8));row.add_child(panel)
			var box=h.margin_box(panel,14,10)
			box.add_child(h.label("伊万" if mine else entry.get("name",view.name),13,h.amber if mine else Color("95b6b4")))
			var words=h.prose("「"+entry.text+"」",19,box)
			words.add_theme_color_override("default_color",Color("e0d0ad") if mine else Color("d7d9c9"))
			if not mine:row.add_spacer(false)
			elif ResourceLoader.exists(path):
				var face=TextureRect.new();face.texture=load(path);face.custom_minimum_size=Vector2(66,78)
				face.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;face.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;row.add_child(face)
		if i>=first_new and not mine and not h.typing.is_empty():
			h.typing[-1].root=block;block.visible=false
		h.dialogue_id=old_id
	var options=ScrollContainer.new()
	options.custom_minimum_size.y=180
	options.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	main.add_child(options);main.move_child(options,main.get_child_count()-2)
	var choices=VBoxContainer.new();choices.size_flags_horizontal=Control.SIZE_EXPAND_FILL;choices.add_theme_constant_override("separation",8);options.add_child(choices)
	var available=0
	for option in view.options:
		var o:Dictionary=option
		if not o.enabled:continue
		available+=1
		var row=HBoxContainer.new();choices.add_child(row)
		var b=h.button(o.text,func():h.last_choice=o.text;h.world.perform(o.key,id))
		var category:String=o.get("category","调查")
		var colors={"任务":Color("d9bd80"),"决定":Color("d39e82"),"闲聊":Color("a4b3ac"),"调查":Color("bdc8bc")}
		b.add_theme_color_override("font_color",colors[category])
		var tag=h.label(category,14,colors[category]);tag.custom_minimum_size.x=48;tag.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;row.add_child(tag)
		b.tooltip_text={"任务":"与已知任务、道具或调查进展有关。","决定":"会影响去向、消耗物品或改变关系。","闲聊":"了解人物与日常生活。","调查":"进一步查看现场或了解情况。"}[category]
		h.speech_buttons.append(b);b.disabled=not h.typing.is_empty()
		b.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;b.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(b)
		if o.has("check"):
			var chance=h.label(o.check.tier+" · "+str(o.check.chance)+"%",16,h.amber)
			chance.custom_minimum_size.x=84;chance.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;row.add_child(chance)
	if available==0:choices.add_child(h.label("暂时没有新的话题或操作。",16,h.muted))
	choices.add_child(h.button("结束交谈" if h.world.npcs.has(id) or id in ["armory","main_gate"] else "收起调查",func():h.close(),true,true))
	if h.typing.is_empty() and not entries.is_empty():h.scroll_dialogue_to(scroll,history.get_child(history.get_child_count()-1))
