extends "res://tools/visual_capture_v9.gd"
func _initialize():
 folder="/tmp/metro1982-review/v16";call_deferred("run")
func run():
 DirAccess.make_dir_recursive_absolute(folder);await open_level("commune");w.hud.visible=false
 for entry in [["workers",Vector3(-2.8,.04,2.0),Vector3(-4,1,1.5)],["family",Vector3(15.3,.04,21.5),Vector3(14.7,1,20.3)],["assembly",Vector3(-2.3,.04,-7.1),Vector3(-4.6,1,-8.3)],["militia",Vector3(24.6,.04,2.6),Vector3(26.0,1,1.5)]]:
  w.player.position=entry[1];camera_at(entry[2],8);await shot("resident-group-"+entry[0])
 await dispose();quit()
