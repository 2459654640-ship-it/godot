extends "res://tools/visual_capture_v9.gd"
func _initialize():
 folder="res://docs/screenshots/visual-v11";call_deferred("run")
func freeze():
 super.freeze()
 if is_instance_valid(w.combat):w.combat.set_physics_process(false)
func run():
 DirAccess.make_dir_recursive_absolute(folder)
 var menu=load("res://scenes/main_menu.tscn").instantiate();menu.save_path="user://v11_capture_missing.json";root.add_child(menu);current_scene=menu;await shot("main-menu");menu.queue_free();await settle()
 for id in ([] if "--actor-only" in OS.get_cmdline_user_args() else ["commune","sech","coal","waterworks"]):
  await open_level(id)
  var bounds:Rect2=w.zones[0].rect
  for room in w.zones:bounds=bounds.merge(room.rect)
  var center=bounds.get_center();w.hud.hide();camera_at(Vector3(center.x,0,center.y),maxf(35,(bounds.size.x+bounds.size.y)*.50));await shot(id+"-overview");w.hud.show()
  if id=="commune":
   w.player.position=Vector3(0,.04,-8);camera_at(Vector3(0,.8,-13),20);await shot("commune-assembly")
   w.player.position=Vector3(-4,.04,10);camera_at(Vector3(-1,.8,11),19);await shot("commune-dining")
   for key in ["c_commune_stay","c_commune_assembly","c_commune_main_work","c_commune_heat_accept","c_meal_accept"]:w.story.act(key)
   w.story.flags.erase("next_sequence");w.hud.show_journal();await shot("commune-continuing-tasks");w.hud.close()
  if id=="sech":
   w.player.position=Vector3(-10,.04,11);camera_at(Vector3(-10,.8,13),17);await shot("sech-homes")
   w.player.position=Vector3(0,.04,3);camera_at(Vector3(-4,.8,1),20);await shot("sech-public-kitchen")
   w.player.position=Vector3(17,.04,9);camera_at(Vector3(21,.8,9),17);await shot("sech-track-platform")
  if id=="waterworks":
   w.player.position=Vector3(-12,.04,-3);w.story.flags.plant_diagram=true;w.combat.begin("pump")
   for enemy in w.combat.enemies:enemy.set_physics_process(false)
   w.combat.aim=Vector3(-17,.65,-6);w.player.aim_direction=w.combat.aim-w.player.position
   var direction:Vector3=w.player.aim_direction;w.player.visual.rotation.y=atan2(-direction.x,-direction.z)
   w.combat.reticle.position=w.camera.unproject_position(w.combat.aim)
   w.npcs.plant_veteran.position=Vector3(-11,.04,-2);camera_at(Vector3(-12,.8,-5),15);w.combat.reticle.position=w.camera.unproject_position(w.combat.aim)
   await shot("waterworks-first-fight")
   w.combat.shoot();await shot("waterworks-shot")
  await dispose()
 await open_level("d6")
 w.hud.hide();w.player.position=Vector3(-3,.04,1.5);camera_at(Vector3(-3,.9,1.5),7)
 var painter=w.player.visual.get_node("Painter");painter.set_process(false)
 DirAccess.make_dir_recursive_absolute("/tmp/metro-v11-walk")
 w.player.velocity=w.camera.global_basis.x+w.camera.global_basis.z
 var direction=w.player.velocity;direction.y=0;w.player.visual.rotation.y=atan2(-direction.x,-direction.z)
 for frame in range(24):
  painter.cycle=float(frame)/24;painter._process(0)
  await settle(2);root.get_texture().get_image().save_png("/tmp/metro-v11-walk/%02d.png"%frame)
 w.hud.show();w.story.act("search_box");w.story.economy.goods.bread=2;w.story.economy.goods.bandage=1
 w.hud.show_shop("","sell");await shot("supply-sell")
 w.hud.show_saves(false);await shot("save-slots")
 w.hud.show_dialogue("nina");await shot("dialogue-categories");w.hud.close()
 for pair in [["commune_checkpoint","commune-arrival-checkpoint"],["sech_checkpoint","sech-arrival-checkpoint"],["coal_road","d6-return-checkpoint"]]:
  w.story.flags.comic={"active":false};w.hud.comic_active=false;w.hud.show_comic(pair[0]);await shot(pair[1]);w.hud.comic_active=false;w.hud.close()
 await dispose();quit()
