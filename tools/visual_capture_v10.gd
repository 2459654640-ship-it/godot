extends "res://tools/visual_capture_v9.gd"
func _initialize():
 folder="res://docs/screenshots/visual-v10";call_deferred("run")
func run():
 DirAccess.make_dir_recursive_absolute(folder)
 if "--maps-only" not in OS.get_cmdline_user_args():await capture_pilot()
 if "--pilot-only" not in OS.get_cmdline_user_args():await capture_facilities()
 quit()
func capture_pilot():
 var menu_scene=load("res://scenes/main_menu.tscn").instantiate();menu_scene.save_path="user://visual_v10_missing.json";root.add_child(menu_scene);current_scene=menu_scene;await shot("main-menu-sample-entry");menu_scene.queue_free();await settle()
 var lab=load("res://scenes/ivan_pilot.tscn").instantiate();root.add_child(lab);current_scene=lab;await settle(8)
 lab.automatic=false;lab.moving=false;lab.reset()
 # Both figures face the same screen direction, at native gameplay distance.
 for actor in lab.originals:
  actor.set_physics_process(false);actor.visual.rotation.y=atan2(-lab.camera.global_basis.z.x,-lab.camera.global_basis.z.z)
 await shot("ivan-warm")
 lab.set_lighting(1);await shot("ivan-cold")
 lab.set_lighting(2);await shot("ivan-dark")
 lab.set_lighting(0)
 lab.originals[1].velocity=Vector3(1.1,0,0);lab.originals[0].velocity=Vector3(1.1,0,0)
 lab.pilot.set_process(false)
 var old_painter=lab.originals[0].visual.get_node("Painter");old_painter.set_process(false)
 DirAccess.make_dir_recursive_absolute("/tmp/metro-v10-ivan-movie")
 for i in range(16):
  lab.pilot.distance=float(i)*float(lab.pilot.metadata.stride_meters)/16;lab.pilot._process(0)
  old_painter.cycle=float(i)/8;old_painter._process(0)
  await settle(2)
  var frame=root.get_texture().get_image()
  var a:Vector2=lab.camera.unproject_position(lab.originals[0].position+Vector3(0,2,0))
  var b:Vector2=lab.camera.unproject_position(lab.originals[1].position)
  var region=Rect2i(Vector2i(a)-Vector2i(85,45),Vector2i(b-a)+Vector2i(180,115))
  frame.get_region(region).save_png("/tmp/metro-v10-ivan-movie/%02d.png" % i)
  if i==6:frame.save_png(folder+"/ivan-stride.png")
 lab.queue_free();await settle()
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