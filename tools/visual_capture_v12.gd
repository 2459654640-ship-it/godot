extends "res://tools/visual_capture_v9.gd"
func _initialize():
 folder="res://docs/screenshots/visual-v12";call_deferred("run")
func run():
 DirAccess.make_dir_recursive_absolute(folder);await open_level("commune");w.hud.hide()
 w.player.position=Vector3(0,.04,2);camera_at(Vector3(-1,0,0),54);await shot("commune-overview")
 w.player.position=Vector3(.5,.04,-5);camera_at(Vector3(.5,1,-8),19);await shot("small-assembly")
 w.player.position=Vector3(0,.04,-13);camera_at(Vector3(.5,1,-18),24);await shot("production-wing")
 w.player.position=Vector3(6.2,.04,-15);camera_at(Vector3(8,1,-18),14);await shot("boiler-room")
 w.player.position=Vector3(-23,.04,-13);camera_at(Vector3(-20,1,-11),28);await shot("expanded-farm")
 w.player.position=Vector3(17.5,.04,18);camera_at(Vector3(17.5,1,16),23);await shot("family-alcoves")
 w.player.position=Vector3(7,.04,19);camera_at(Vector3(7,1,20),15);await shot("militia-room")
 w.player.position=Vector3(6.2,.04,-15);camera_at(Vector3(8,1,-18),15);w.hud.show();w.hud.show_dialogue("commune_moro");await shot("moro-first-talk");w.hud.close()
 for seq in ["moro_public_night","moro_quiet_night","memory_reading"]:
  w.hud.comic_active=false;w.story.flags.comic={"active":false};w.hud.show_comic(seq);await shot(seq)
 await dispose();quit()
