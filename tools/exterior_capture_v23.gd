extends "res://tools/visual_capture_v8.gd"
func _initialize():
 folder="/tmp/metro1982-review/v23";call_deferred("run")
func freeze():
 super.freeze()
 if is_instance_valid(w.combat):
  w.combat.set_physics_process(false)
  if is_instance_valid(w.combat.label):w.combat.label.hide()
  if is_instance_valid(w.combat.reticle):w.combat.reticle.hide()
func run():
 DirAccess.make_dir_recursive_absolute(folder)
 await open_level("starcity");w.hud.visible=false;camera_at(Vector3(8,0,29),19);await shot("ruined-building")
 camera_at(Vector3(0,0,5),42);await shot("starcity-overview")
 camera_at(Vector3(-8,.7,7.7),15);await shot("starcity-shelter")
 await dispose()
 await open_level("surface");w.hud.visible=false;camera_at(Vector3(0,0,0),45);await shot("pumpstation-overview")
 camera_at(Vector3(-15,1,-9),18);await shot("pumpstation-ruin")
 w.hud.visible=true;w.story.flags.departure_committed=true;w.story.flags.accepted=true;w.story.flags.kit=true;w.story.flags.vitamins_taken=true;w.story.route="official"
 w.story.flags.surface_job=true;w.story.flags.signal_heard=true;w.story.flags.tracked_quest="signal_trace";w.story.flags.surface_notes=true;w.story.flags.surface_drain_open=true;w.story.flags.surface_sample_sealed=true;w.story.context.floor="surface"
 w.hud.observing=false;w.hud.observe_progress();w.hud.toast_time=0;w.hud.toast_label.text=""
 for receipt in w.hud.find_children("Receipt*","Control",true,false):receipt.hide()
 w.hud.show_journal();await shot("pumpstation-journal")
 for panel in ["surface_back_commune","surface_back_sech"]:
  w.story.flags.comic={"active":false};w.hud.comic_active=false;w.hud.show_comic(panel);await shot(panel)
  w.hud.comic_choose();await shot(panel+"-checkpoint")
 await dispose();quit()
