extends SceneTree
const Radio=preload("res://scripts/public_radio.gd")
const Publications=preload("res://scripts/publications.gd")
var checks=0
var failures=0
func _initialize():call_deferred("run")
func check(ok:bool,message:String):
 checks+=1
 if not ok:failures+=1;push_error(message)
func frames(n:int=3):
 for i in n:await physics_frame
func wheel(w,direction:int):
 var event=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_WHEEL_DOWN if direction>0 else MOUSE_BUTTON_WHEEL_UP;event.pressed=true
 w._unhandled_input(event)
func clear_capsule(w,p:Vector3)->bool:
 var capsule=CapsuleShape3D.new();capsule.radius=.26;capsule.height=1.72
 var q=PhysicsShapeQueryParameters3D.new();q.shape=capsule;q.collision_mask=3;q.transform=Transform3D(Basis.IDENTITY,p+Vector3(0,.86,0))
 return w.get_world_3d().direct_space_state.intersect_shape(q).is_empty()
func freeze(w):
 w.set_physics_process(false);w.player.set_physics_process(false)
 for a in w.npcs.values():a.set_physics_process(false)
 if is_instance_valid(w.combat):w.combat.set_physics_process(false)
 w.story.flags.intro_done=true;w.story.flags.comic={"active":false};w.hud.comic_active=false;w.hud.close()
func run():
 var sample:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/radio.json"))
 var absent=Radio.with_optional_channels(sample,func(_f):return false)
 var partial=Radio.with_optional_channels(sample,func(f):return f=="moon_heart.mp3")
 var complete=Radio.with_optional_channels(sample,func(_f):return true)
 check(absent.stations.size()==3 and partial.stations.size()==3,"optional channel never exposes missing or partial audio")
 check(complete.stations.size()==4 and complete.tracks.moon_heart.file.ends_with(".mp3") and complete.tracks.only_you.zh=="我只在乎你","both supplied MP3s enable the configured Ocean Watch channel")
 var all_tracks={}
 var old_story
 for floor_id in Radio.SITES:
  var scene="d6" if floor_id=="life" else floor_id
  var w=load("res://scenes/"+scene+".tscn").instantiate();root.add_child(w);current_scene=w;await frames();freeze(w)
  var r=w.public_radio;r.set_process(false)
  check(not r.enabled and not r.audio.playing and r.audio.stream==null,"receiver never starts by itself: "+floor_id)
  check(w.targets.has("public_radio"),"public receiver interaction exists: "+floor_id)
  var table=w.get_node("PublicRadioTable");var bounds:Rect2=Rect2(Vector2(table.position.x-table.mesh.size.x/2,table.position.z-table.mesh.size.z/2),Vector2(table.mesh.size.x,table.mesh.size.z))
  var conflicts=[]
  for s in w.kit.solids:
   if s.name in ["PublicRadioTable","PublicRadioTableHull"] or s.top<=.24 or s.bottom>=1.75:continue
   if bounds.intersects(s.rect):conflicts.append(s.name)
  check(conflicts.is_empty(),"table is clear of walls and existing furniture: "+floor_id+str(conflicts))
  var receiver=w.get_node("public_radio")
  var foot=receiver.get_node("RadioRubberFoot")
  check(is_equal_approx(foot.global_position.y-foot.mesh.size.y/2,table.position.y+table.mesh.size.y/2),"radio feet rest exactly on the tabletop: "+floor_id)
  var front:Vector3=receiver.get_meta("radio_front")
  var approach:Vector3=r.global_position+front*1.15+Vector3(0,.04,0)
  check(clear_capsule(w,approach),"listener can stand on the control side without clipping: "+floor_id)
  w.player.position=approach;w.find_nearest()
  check("public_radio" in w.interaction_candidates,"normal proximity/line of sight reaches radio: "+floor_id)
  w.chosen_interaction="public_radio";w.find_nearest()
  w.interact(w.nearest);await frames()
  check(w.hud.radio_open and w.hud.modal_visible(),"real interaction opens music controls: "+floor_id)
  check(w.hud.typing.is_empty(),"radio menu does not enter NPC dialogue typing: "+floor_id)
  if floor_id=="life":
   old_story=w.story.serialize().duplicate(true)
   check(r.catalog.stations.size()==3 and r.catalog.tracks.size()==7,"three complete stations remain playable while optional large attachments are unavailable")
   for station in r.catalog.stations:
    check(station.ru!="" and station.name!="","bilingual station identity")
    for id in station.tracks:
     all_tracks[id]=true
     var song:Dictionary=r.catalog.tracks[id];var stream=load("res://assets/audio/radio/"+song.file)
     check(song.zh!="" and song.ru!="" and (stream is AudioStreamOggVorbis or stream is AudioStreamMP3) and stream.get_length()>100 and not stream.loop,"bilingual, decodable full-length song with finite playback: "+id)
   check(all_tracks.size()==7,"every supplied song appears in the programme")
   # Trigger actual UI callbacks, including channel buttons and playlist rows.
   var buttons=w.hud.modal.find_children("*","Button",true,false)
   for b in buttons:
    if b.text.begins_with("70.2"):b.pressed.emit();break
   check(r.station==1 and r.enabled and r.audio.playing,"channel button starts the actual audio player")
   r.toggle();check(r.paused and r.audio.stream_paused,"pause preserves playback position")
   r.toggle();check(not r.paused and not r.audio.stream_paused,"resume reuses the current stream")
   r.select_track(1);r.audio.finished.emit()
   check(r.track==0 and r.enabled,"end of programme wraps to first song in same channel")
   r.update_mix(1)
   check(r.audible>.99 and w.ambience.volume_db< -20,"nearby radio ducks the shelter melody")
   w.player.position=r.global_position+Vector3(30,.04,0);r.update_mix(1)
   check(r.audible==0 and r.audio.volume_db<=-79,"distance is measured from player, becoming inaudible far away")
   w.player.position=approach;w.hud.dialogue_id="semyon";r.update_mix(1)
   check(not r.suppressed and not r.audio.stream_paused,"NPC dialogue leaves music playing")
   w.hud.dialogue_id="";w.hud.comic_active=true;r.update_mix(1)
   check(r.suppressed,"full-screen narration pauses music")
   w.hud.comic_active=false;r.update_mix(1)
   check(not r.suppressed and not r.audio.stream_paused,"music resumes after narration")
   w.hud.close();check(not w.hud.radio_open and r.enabled,"closing controls leaves the receiver playing")
   r.stop();r.update_mix(1)
   check(not r.audio.playing and r.audio.stream==null and w.ambience.volume_db> -8.1,"power off releases stream and restores ambience")
   check(w.story.serialize()==old_story,"listening changes no inventory, quest or story state")
   var before=w.story.economy.military
   w.story.Economy.buy(w.story,"portable_radio")
   check(w.story.economy.goods.get("portable_radio",0)==1 and w.story.economy.military==before-12,"optional portable receiver is bought once for twelve standard rounds")
   w.story.Economy.buy(w.story,"portable_radio")
   check(w.story.economy.goods.portable_radio==1 and w.story.economy.military==before-12,"repeat purchase cannot charge or duplicate the receiver")
   var restored=preload("res://scripts/story.gd").new();restored.restore(w.story.serialize())
   check(restored.economy.goods.get("portable_radio",0)==1,"portable ownership survives save/restore")
   var legacy=w.story.Economy.restored({"stock":{"bread":4}})
   check(legacy.stock.portable_radio==1 and legacy.stock.bread==4,"older saves gain only the new receiver stock without replenishing old goods")
   w.hud.show_inventory()
   var radio_cell=w.hud.modal.find_child("InventoryCell_portable_radio",true,false)
   check(is_instance_valid(radio_cell),"owned receiver has a selectable inventory cell")
   if is_instance_valid(radio_cell):radio_cell.pressed.emit()
   for b in w.hud.modal.find_children("*","Button",true,false):
    if b.text=="收听随身收音机":b.pressed.emit();break
   check(r.portable and w.hud.radio_open and w.hud.dialog_title.text=="随身收音机","inventory listen button opens the owned portable radio")
   r.play_track();w.player.position=r.global_position+Vector3(40,.04,0);r.update_mix(1)
   check(r.audible==1 and r.audio.playing,"portable receiver remains audible away from the public table")
   w.hud.close();r.stop();r.portable=false
   # Reproduce the crowded book/crate interaction in Semyon's room.
   var book="pub_prewar_crisis";var found=false
   for point in w.navigation.graph.get_point_ids():
    var p:Vector2=w.navigation.graph.get_point_position(point)
    if p.distance_to(Vector2(-12.3,-4.85))>1.6:continue
    var pos=Vector3(p.x,.04,p.y)
    if not clear_capsule(w,pos):continue
    w.player.position=pos;w.chosen_interaction="";w.find_nearest()
    if book in w.interaction_candidates and w.interaction_candidates.size()>1:found=true;break
   check(found,"real book and nearby interactable can both be reached from a clear stance")
   if found:
    var size=w.camera_size;var start=w.nearest
    wheel(w,1)
    check(w.nearest!=start and w.camera_size==size,"wheel changes interaction instead of zooming when targets overlap")
    var selected=w.nearest;w.find_nearest();check(w.nearest==selected,"explicit target selection persists across proximity refresh")
    for i in w.interaction_candidates.size():
     if w.nearest==book:break
     wheel(w,1)
    check(w.nearest==book and w.hud.prompt.text.contains("滚轮切换"),"wheel can select the book and exposes target count")
    var event=InputEventKey.new();event.physical_keycode=KEY_E;event.keycode=KEY_E;event.pressed=true;w._unhandled_input(event)
    check(Publications.owned(w.story,book),"E acts on the selected book, not its nearby crate/NPC")
    w.find_nearest();check(w.chosen_interaction=="" and book not in w.interaction_candidates,"removed collectible cannot leave a stale selected target")
   var empty=false
   for point in w.navigation.graph.get_point_ids():
    var p:Vector2=w.navigation.graph.get_point_position(point);w.player.position=Vector3(p.x,.04,p.y);w.find_nearest()
    if w.interaction_candidates.size()<2:empty=true;break
   check(empty,"an uncrowded area is available")
   var size=w.camera_size;wheel(w,1);check(w.camera_size==size+1,"wheel retains zoom in uncrowded areas")
  if floor_id=="waterworks":
   r.play_track();w.combat.active=true;r.update_mix(1);check(r.suppressed and r.audio.stream_paused,"combat suspends the waterworks receiver")
   w.combat.active=false;r.update_mix(1);r.stop()
  w.queue_free();await frames()
 # A running portable receiver follows the player across a real floor load.
 var carry=load("res://scenes/d6.tscn").instantiate();root.add_child(carry);current_scene=carry;await frames();freeze(carry)
 carry.story.economy.goods.portable_radio=1;carry.public_radio.open_controls(true);carry.public_radio.select_station(1);carry.public_radio.select_track(1);carry.hud.close()
 var saved=carry.story.serialize();carry.queue_free();await frames()
 var session=root.get_node("Session")
 check(not session.radio_transfer.is_empty(),"floor teardown retains an active portable programme")
 session.pending={"story":saved,"position":Vector3.INF,"floor":"labor"}
 carry=load("res://scenes/labor.tscn").instantiate();root.add_child(carry);current_scene=carry;await frames();freeze(carry)
 check(carry.public_radio.portable and carry.public_radio.enabled and carry.public_radio.station==1 and carry.public_radio.track==1,"next floor resumes the same owned portable programme")
 carry.public_radio.stop();carry.queue_free();await frames();session.clear()
 print("PUBLIC_RADIO_V16_RESULT checks=",checks," failures=",failures)
 quit(0 if failures==0 else 1)
