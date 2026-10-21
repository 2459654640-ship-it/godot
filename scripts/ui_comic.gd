extends RefCounted
## A full-screen chapter reader. The world HUD is completely covered while the story is active.
static func render(h,sequence:String=""):
	var s=h.world.story
	if not s.flags.get("comic",{}).get("active",false):
		if sequence=="":return
		s.Comic.start(s,sequence)
	var p=s.Comic.panel(s)
	if p.is_empty():return
	h.world.sync_event_music(p.get("music",""))
	h.comic_active=true
	h.dialogue_id=""
	h.start_modal(p.title,"МЕТРО 1982   /   "+p.get("location","序幕" if s.flags.comic.sequence=="intro" else "旅程"),true)
	h.make_cinematic()
	var row=HBoxContainer.new();row.add_theme_constant_override("separation",40);h.modal_box.add_child(row)
	var art=TextureRect.new();art.texture=load("res://assets/cinematics/"+p.art+".png")
	art.custom_minimum_size=Vector2(860,500);art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;row.add_child(art)
	var words=VBoxContainer.new();words.custom_minimum_size.x=560;words.size_flags_horizontal=Control.SIZE_EXPAND_FILL;words.add_theme_constant_override("separation",16);row.add_child(words)
	words.add_child(h.label("──  "+p.title+"  ──",17,h.amber))
	var lines:Array=p.get("lines",s.Conversation.split_text(p.body,"旁白"))
	for entry in lines:
		var group=VBoxContainer.new();words.add_child(group)
		var narration=entry.speaker in ["narrator","旁白"]
		if not narration:group.add_child(h.label(entry.speaker,16,h.amber))
		var rich=h.prose(entry.text if narration else "「"+entry.text+"」",23,group)
		rich.add_theme_color_override("default_color",Color("e4d1a8") if not narration else Color("bac3b7"))
		var total=rich.get_total_character_count();rich.visible_characters=0
		group.visible=false
		h.typing.append({"label":rich,"total":total,"elapsed":0.0,"rate":48.0,"root":group})
	if p.get("note","")!="":words.add_child(h.label(p.note,16,h.muted))
	var main=h.modal_box.get_parent().get_parent()
	var options=VBoxContainer.new();options.add_theme_constant_override("separation",10)
	main.add_child(options);main.move_child(options,main.get_child_count()-2)
	main.get_child(main.get_child_count()-1).text="空格 / 点击正文 显示全文     ·     ESC 暂停、背包与保存     ·     选择后继续"
	if p.has("choices"):
		for i in p.choices.size():
			var index=i
			var b=h.button(p.choices[i].text,func():h.comic_choose(index));b.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;options.add_child(b)
	else:options.add_child(h.button("穿上外套，出门" if p.get("end","")=="intro" else ("进入设施" if p.get("end","").begins_with("map:") else ("继续这段旅程" if p.has("end") else "继续")),func():h.comic_choose()))
