extends RefCounted
## Full-screen art and deliberately paced subtitles. No scrolling reader.
static func paragraphs(h,p:Dictionary)->Array:
 var out=[]
 for entry in p.get("lines",h.world.story.Conversation.split_text(p.body,"旁白")):
  var remaining:String=entry.text
  while remaining.length()>160:
   var cut=160
   for i in range(90,160):
    if remaining[i] in ["。","！","？","；","\n"]:cut=i+1
   var part=entry.duplicate();part.text=remaining.substr(0,cut);out.append(part);remaining=remaining.substr(cut)
  var part=entry.duplicate();part.text=remaining;out.append(part)
 return out
static func render(h,sequence:String=""):
 var s=h.world.story
 if not s.flags.get("comic",{}).get("active",false):
  if sequence=="":return
  s.Comic.start(s,sequence)
 var p=s.Comic.panel(s)
 if p.is_empty():return
 h.world.sync_event_music(p.get("music",""));h.comic_active=true;h.dialogue_id=""
 h.start_modal(p.title,"",true,"cinema")
 for child in h.modal.get_children(true):h.modal.remove_child(child);child.queue_free()
 h.modal.position=Vector2.ZERO;h.modal.size=Vector2(1600,1000)
 h.modal.add_theme_stylebox_override("panel",h.style(Color("080d0d"),Color.TRANSPARENT,0,0))
 h.modal.set_meta("cinematic_live",true);h.scrim.color=Color.BLACK
 var stage=Control.new();stage.name="CinematicStage";h.modal.add_child(stage)
 var art=TextureRect.new();art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);art.texture=load("res://assets/cinematics/"+p.art+".png");art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED;art.mouse_filter=Control.MOUSE_FILTER_STOP;stage.add_child(art)
 art.gui_input.connect(func(e):
  if e is InputEventMouseButton and e.pressed and e.button_index==MOUSE_BUTTON_LEFT:advance(h);art.accept_event())
 var grad=Gradient.new();grad.offsets=PackedFloat32Array([0,.40,.59,.77,1]);grad.colors=PackedColorArray([Color(0,0,0,.22),Color(0,0,0,.03),Color(.015,.025,.024,.68),Color(.015,.025,.024,.97),Color(.015,.025,.024,1)])
 var fill=GradientTexture2D.new();fill.gradient=grad;fill.fill_from=Vector2(0,0);fill.fill_to=Vector2(0,1)
 var shade=TextureRect.new();shade.texture=fill;shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);shade.mouse_filter=Control.MOUSE_FILTER_IGNORE;stage.add_child(shade)
 var chapter=h.label(p.get("location","МОСКВА / 1982"),14,h.amber);chapter.position=Vector2(72,35);stage.add_child(chapter)
 h.dialog_title=h.label(p.title,29,h.text_color);h.dialog_title.add_theme_font_override("font",h.serif);h.dialog_title.position=Vector2(72,62);stage.add_child(h.dialog_title)
 var pause=h.button("暂停  Esc",func():h.show_comic_pause(),true,true);pause.position=Vector2(1380,40);pause.size=Vector2(148,42);stage.add_child(pause)
 var entries=paragraphs(h,p);var index=clampi(int(s.flags.comic.get("line_index",0)),0,maxi(0,entries.size()-1));s.flags.comic.line_index=index
 var entry:Dictionary=entries[index] if not entries.is_empty() else {"speaker":"旁白","text":p.body}
 var dense=p.get("choices",[]).size()>3 and index==entries.size()-1
 var caption=VBoxContainer.new();caption.position=Vector2(80,570 if dense else 620);caption.size=Vector2(1440,132);caption.add_theme_constant_override("separation",12);stage.add_child(caption);h.modal_box=caption
 var narration=entry.speaker in ["narrator","旁白"]
 if not narration:caption.add_child(h.label(entry.get("name",String(entry.speaker).trim_prefix("voice_")),17,h.amber))
 var rich=h.prose(entry.text if narration else "「"+entry.text+"」",26,caption);rich.add_theme_color_override("default_color",Color("eee8d7"));rich.custom_minimum_size=Vector2(1440,90);rich.visible_characters=0
 h.typing.append({"label":rich,"total":rich.get_total_character_count(),"elapsed":0.0,"rate":46.0,"root":caption})
 var buttons=GridContainer.new();buttons.columns=2 if dense else 1;buttons.position=Vector2(80,748 if dense else 810);buttons.size=Vector2(1440,192 if dense else 150);buttons.add_theme_constant_override("h_separation",14);buttons.add_theme_constant_override("v_separation",9);stage.add_child(buttons)
 if index<entries.size()-1:
  var b=h.button("继续  ›",func():advance(h));b.custom_minimum_size.y=46;buttons.add_child(b)
 elif p.has("choices"):
  for i in p.choices.size():
   var choice=i;var b=h.button(str(i+1)+"  ·  "+p.choices[i].text,func():h.comic_choose(choice));b.custom_minimum_size.y=58 if dense else 43;b.size_flags_horizontal=Control.SIZE_EXPAND_FILL;b.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;buttons.add_child(b);h.speech_buttons.append(b)
 else:
  var b=h.button("穿上外套，出门" if p.get("end","")=="intro" else ("继续  ›" if not p.get("end","").begins_with("map:") else "继续前行  ›"),func():advance(h));b.custom_minimum_size.y=46;buttons.add_child(b)
 h.modal_hint=h.label("空格 / 点击画面  ·  补全文字后继续    |    "+str(index+1)+" / "+str(maxi(1,entries.size())),13,Color("8f9c92"));h.modal_hint.position=Vector2(80,964);stage.add_child(h.modal_hint)
static func advance(h):
 if not h.comic_active or not h.modal.get_meta("cinematic_live",false):return
 for item in h.typing:
  if is_instance_valid(item.label) and item.label.visible_characters<item.total:h.finish_typing();return
 var s=h.world.story;var p=s.Comic.panel(s);var entries=paragraphs(h,p);var index=int(s.flags.comic.get("line_index",0))
 if index+1<entries.size():s.flags.comic.line_index=index+1;render(h)
 elif not p.has("choices"):h.comic_choose()
