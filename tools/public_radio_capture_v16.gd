extends "res://tools/visual_capture_v9.gd"
const Radio=preload("res://scripts/public_radio.gd")
func _initialize():
 folder="/tmp/metro1982-review/v16";call_deferred("run")
func run():
 DirAccess.make_dir_recursive_absolute(folder)
 for id in Radio.SITES:
  await open_level("d6" if id=="life" else id)
  var r=w.public_radio;var p:Vector3=r.global_position;var front:Vector3=w.get_node("public_radio").get_meta("radio_front")
  w.player.position=p+front*1.2+Vector3(0,.04,0)
  camera_at(p+Vector3(0,.8,0),7);w.hud.visible=false;await shot(id+"-public-radio");w.hud.visible=true
  if id=="life":
   w.interact("public_radio");r.select_station(0);r.select_track(1);await shot("radio-programme-ui");w.hud.close();r.stop()
   for point in w.navigation.graph.get_point_ids():
    var pos:Vector2=w.navigation.graph.get_point_position(point)
    if pos.distance_to(Vector2(-12.3,-4.85))>1.6:continue
    w.player.position=Vector3(pos.x,.04,pos.y);w.find_nearest()
    if "pub_prewar_crisis" in w.interaction_candidates and w.interaction_candidates.size()>1:break
   w.chosen_interaction="pub_prewar_crisis";camera_at(Vector3(-12.3,.8,-4.9),9);w.find_nearest();await shot("wheel-selected-book")
  await dispose()
 quit()
