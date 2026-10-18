extends "res://tools/visual_capture_v9.gd"
func _initialize():
 folder="res://docs/screenshots/visual-v10";call_deferred("run")
func run():
 DirAccess.make_dir_recursive_absolute(folder)

 if "--pilot-only" not in OS.get_cmdline_user_args():await capture_facilities()
 quit()
func capture_facilities():
 for id in ["commune","waterworks"]:
  await open_level(id)
  w.hud.visible=false
  var bounds:Rect2=w.zones[0].rect
  for room in w.zones:bounds=bounds.merge(room.rect)
  var center=bounds.get_center();camera_at(Vector3(center.x,0,center.y),33);await shot(id+"-overview");w.hud.visible=true
  if id=="commune":
   w.player.position=Vector3(-2,.04,4);camera_at(Vector3(-2,1,2),19);await shot("commune-hall")
   w.player.position=Vector3(-17,.04,-5);camera_at(Vector3(-18,1,-6),13);await shot("commune-greenhouse")
   w.hud.show_dialogue("commune_grower");await shot("zoya-before");w.hud.close()
   for key in ["c_grow_accept","c_grow_read","c_grow_shade","c_grow_return"]:w.story.act(key)
   freeze();w.on_story_changed();w.hud.show_dialogue("commune_grower");await shot("zoya-after");w.hud.close()
   w.hud.comic_active=false;w.story.flags.comic={"active":false};w.hud.show_comic("arrive_commune");await shot("commune-male-ivan");w.hud.comic_active=false;w.hud.close()
  else:
   w.player.position=Vector3(-12,.04,-7);camera_at(Vector3(-12,1,-9),17);await shot("waterworks-pumps")
   w.player.position=Vector3(14,.04,9.8);camera_at(Vector3(15,1,11),11);await shot("factory-exit-closed")
   for leaf in w.factory_exit_leaves:leaf.rotation.y=leaf.get_meta("opening_angle")*.5
   await shot("factory-exit-opening")
   for leaf in w.factory_exit_leaves:leaf.rotation.y=0
   w.story.flags.water_secured=true;w.story.flags.plant_power=true;w.story.give("water_core");w.on_story_changed();w.hud.show_dialogue("plant_guide");await shot("lieutenant-cargo");w.hud.close()
   w.hud.show_dialogue("plant_veteran");await shot("veteran-cargo");w.hud.close()
   for pair in [["arrive_waterworks","plant-interior-story"],["return_crossing","filter-return-story"],["return_standoff","filter-choice"]]:
    w.hud.comic_active=false;w.story.flags.comic={"active":false};w.hud.show_comic(pair[0]);await shot(pair[1]);w.hud.comic_active=false;w.hud.close()
  await dispose()