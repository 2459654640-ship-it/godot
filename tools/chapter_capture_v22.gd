extends "res://tools/visual_capture_v8.gd"
func _initialize():
 folder=OS.get_environment("METRO_REVIEW_DIR") if OS.has_environment("METRO_REVIEW_DIR") else "/tmp/metro1982-review/v22";call_deferred("run")
func freeze():
 super.freeze()
 if is_instance_valid(w.combat):w.combat.set_physics_process(false);w.combat.enabled=false
func run():
 DirAccess.make_dir_recursive_absolute(folder)
 await open_level("railfront")
 w.hud.visible=false;camera_at(Vector3(0,0,0),51);await shot("railfront-overview")
 w.player.position=Vector3(14,.04,14);camera_at(Vector3(15,.8,13),16);await shot("railfront-control-room")
 w.hud.visible=true;w.story.flags.commune_member=true;w.story.context.floor="commune";w.story.act("c_field_c1_accept");w.hud.show_journal();await shot("faction-journal")
 await dispose()
 await open_level("commune")
 w.player.position=Vector3(-6,.04,18.7);camera_at(Vector3(-5,1,20),13);await shot("anna-classroom-corner")
 for node in ["anna_class","anna_after_class","rescue_review","anna_loss_home","anna_living_lesson","anna_surface_visit","field_s2_interlude"]:
  w.story.flags.anna_rescue_started=true;w.story.flags.rescue_medic_ready=true;w.story.flags.rescue_transport_ready=true;w.story.flags.rescue_route_ready=true
  w.hud.comic_active=false;w.story.flags.comic={"active":false};w.hud.show_comic(node);await shot(node)
 await dispose()
 await open_level("labor")
 w.player.position=Vector3(0,.04,-4);camera_at(Vector3(0,1,-8),14);await shot("d6-ward-corner")
 w.hud.comic_active=false;w.story.flags.comic={"active":false};w.hud.show_comic("lower_ward");await shot("d6-ward-broadcast")
 await dispose()
 print("CHAPTER_CAPTURE_V22 complete");quit()
