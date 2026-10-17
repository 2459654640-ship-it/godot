extends RefCounted
static func render(h,sequence:String=""):
	var s=h.world.story
	if not s.flags.get("comic",{}).get("active",false):
		if sequence=="":return
		s.Comic.start(s,sequence)
	var p=s.Comic.panel(s)
	h.comic_active=true
	h.dialogue_id=""
	h.start_modal(p.title,"地铁 1982 / "+("序幕" if s.flags.comic.sequence=="intro" else "旅程"),true)
	h.modal.position=Vector2(180,94);h.modal.size=Vector2(1240,770)
	var row=HBoxContainer.new();row.add_theme_constant_override("separation",28);h.modal_box.add_child(row)
	var art=TextureRect.new();art.texture=load("res://assets/cinematics/"+p.art+".png")
	art.custom_minimum_size=Vector2(650,385);art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;row.add_child(art)
	var words=VBoxContainer.new();words.size_flags_horizontal=Control.SIZE_EXPAND_FILL;words.add_theme_constant_override("separation",14);row.add_child(words)
	for entry in s.Conversation.split_text(p.body,"speaker"):
		var rich=h.prose(entry.text,21,words)
		rich.add_theme_color_override("default_color",Color("dec89c") if entry.speaker!="narrator" else Color("bac3b7"))
		var total=rich.get_total_character_count();rich.visible_characters=0
		h.typing.append({"label":rich,"total":total,"elapsed":0.0,"rate":maxf(180,float(total)/1.2)})
	var main=h.modal_box.get_parent().get_parent()
	var options=VBoxContainer.new();options.add_theme_constant_override("separation",8)
	main.add_child(options);main.move_child(options,main.get_child_count()-2)
	main.get_child(main.get_child_count()-1).text="空格 / 点击正文 显示全文 · ESC 暂停 / 背包 / 保存"
	if p.has("choices"):
		for i in p.choices.size():
			var index=i
			options.add_child(h.button(p.choices[i].text,func():h.comic_choose(index)))
	else:options.add_child(h.button("穿上外套，出门" if p.get("end","")=="intro" else ("收好这段旅程" if p.has("end") else "继续"),func():h.comic_choose()))
