extends "res://tools/visual_capture_v9.gd"
func _initialize():
 folder="res://docs/screenshots/visual-v15";call_deferred("run")
func run():
 DirAccess.make_dir_recursive_absolute(folder)
 await open_level("d6")
 w.hud.visible=false;w.player.position=Vector3(12,.04,-2)
 camera_at(Vector3(11.5,1,-3.4),7);await shot("supply-poster")
 w.player.position=Vector3(-13,.04,-4)
 camera_at(Vector3(-12.7,1,-7.3),6);await shot("bedroom-poster")
 await dispose()
 await open_level("commune")
 w.hud.visible=false;w.player.position=Vector3(-8,.04,-9.2)
 camera_at(Vector3(-8,1,-11.3),8);await shot("assembly-poster-doorway")
 await dispose();quit()
