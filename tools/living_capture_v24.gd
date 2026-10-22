extends "res://tools/visual_capture_v8.gd"
func _initialize():
 folder=OS.get_environment("METRO_REVIEW_DIR") if OS.has_environment("METRO_REVIEW_DIR") else "/tmp/metro1982-review/v24";call_deferred("run")
func freeze():
 super.freeze()
 if is_instance_valid(w.combat):w.combat.set_physics_process(false)
func run():
 DirAccess.make_dir_recursive_absolute(folder)
 await open_level("commune")
 for node in ["anna_supper","anna_supper_class","moro_council","moro_rehearsal","veteran_shelter"]:
  w.hud.comic_active=false;w.story.flags.comic={"active":false};w.hud.show_comic(node);await shot(node)
 w.hud.comic_active=false;w.story.flags.comic={"active":false};w.hud.close()
 if is_instance_valid(w.hud.receipt_box):w.hud.receipt_box.hide()
 w.story.flags.anna_lesson_seen=true;w.story.flags.anna_walk_started=true
 w.player.position=Vector3(-4,.04,15)
 w.npcs.commune_anna.set_physics_process(true);w.living.tick(0)
 for i in 175:w.living.tick(1.0/60);await physics_frame
 w.npcs.commune_anna.set_physics_process(false);camera_at(Vector3(-5,1,14),13);await shot("anna-canteen-walk")
 w.hud.show_journal();await shot("anna-walk-journal");w.hud.close()
 await dispose()
 await open_level("railfront")
 w.story.flags.sided_veteran=true;w.story.flags.veteran_defense_started=true;w.living.sync()
 # This review fixture puts the original veteran at the checkpoint, as the
 # normal sided-veteran arrival does. The playable test uses the real setup.
 if not w.npcs.has("plant_veteran"):
  w.person("plant_veteran",Vector3(-10.5,0,12),"green",true,"veteran_masked");w.npcs.plant_veteran.set_physics_process(false)
 w.player.position=Vector3(-12,.04,12);w.story.flags.weapon_drawn=true
 w.hud.visible=false;camera_at(Vector3(-15,.6,13),24);await shot("passage-evacuation-layout")
 await dispose()
 print("LIVING_CAPTURE_V24 complete");quit()
