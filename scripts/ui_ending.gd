extends RefCounted
## An earned conclusion with clear continuation and an independent pre-final save.
static func render(h):
 h.world.autosave()
 var s=h.world.story;var id:String=s.flags.get("campaign_ending","");var outcome:Dictionary=s.Campaign.Complete.data().endings[id]
 h.start_modal(outcome.title,"",true,"ending")
 for child in h.modal.get_children(true):h.modal.remove_child(child);child.queue_free()
 h.modal.position=Vector2.ZERO;h.modal.size=Vector2(1600,1000);h.modal.add_theme_stylebox_override("panel",h.style(Color("0b1414"),Color.TRANSPARENT,0,0));h.scrim.color=Color.BLACK
 var stage=Control.new();stage.name="CinematicStage";h.modal.add_child(stage)
 var art=TextureRect.new();art.position=Vector2.ZERO;art.size=Vector2(1000,1000);art.texture=load("res://assets/cinematics/"+outcome.art+".png");art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED;stage.add_child(art)
 var gradient=Gradient.new();gradient.set_color(0,Color(0,0,0,0));gradient.set_color(1,Color("0b1414"));var fill=GradientTexture2D.new();fill.gradient=gradient;fill.fill_from=Vector2.ZERO;fill.fill_to=Vector2.RIGHT
 var shade=TextureRect.new();shade.position=Vector2(550,0);shade.size=Vector2(500,1000);shade.texture=fill;stage.add_child(shade)
 var label=h.label("МЕТРО / 1982",18,h.amber);label.position=Vector2(70,55);stage.add_child(label)
 var column=VBoxContainer.new();column.position=Vector2(930,120);column.size=Vector2(590,780);column.add_theme_constant_override("separation",24);stage.add_child(column);h.modal_box=column
 column.add_child(h.label("旅程落幕",17,h.amber));var title=h.label(outcome.title,48,h.text_color);title.add_theme_font_override("font",h.serif);column.add_child(title)
 var text=h.label(outcome.body,24,h.text_color);text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;column.add_child(text)
 var line=ColorRect.new();line.color=Color("5c6556");line.custom_minimum_size.y=1;column.add_child(line)
 var note=h.label("本轮行动已经完成。人物后续、已读经历与未完支线保留在手记中。",19,h.muted);note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;column.add_child(note)
 var space=Control.new();space.size_flags_vertical=Control.SIZE_EXPAND_FILL;column.add_child(space)
 column.add_child(h.button("继续终局后的探索",func():s.ending=false;s.changed.emit();h.world.autosave();h.close()))
 column.add_child(h.button("保存这段旅程",func():h.show_saves(true)))
 column.add_child(h.button("读取“最终行动前”",func():h.world.load_game(h.world.SaveStore.FINAL),not h.world.SaveStore.read(h.world.SaveStore.FINAL).is_empty()))
 column.add_child(h.button("返回主菜单",func():h.world.autosave();h.get_tree().change_scene_to_file("res://scenes/main_menu.tscn")))
 var footer=h.label("感谢你走完这段旅程。",17,Color("b5baa8"));footer.position=Vector2(72,932);stage.add_child(footer)
