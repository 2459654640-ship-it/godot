extends "res://tools/visual_capture_v8.gd"
func _initialize():folder="/tmp/metro1982-review/v18";call_deferred("run")
func run():
 DirAccess.make_dir_recursive_absolute(folder)
 await open_level("commune")
 w.hud.visible=false;camera_at(Vector3(1,0,1),37);await shot("commune-overview")
 for point in [["public",Vector3(-2,0,2),17],["assembly",Vector3(.5,0,-8),17],["homes",Vector3(16.5,0,19),15]]:
  camera_at(point[1],point[2]);await shot("crowds-"+point[0])
 var group=w.get_node("ResidentGroup_workers");camera_at(group.position,9)
 for i in range(5):
  group._process(.7);await shot("crowd-idle-%02d"%i)
 await dispose()
 await open_level("sech")
 camera_at(Vector3(0,0,-9),17);await shot("sech-npcs")
 await dispose()
 await open_level("d6")
 w.interact("radio");await shot("bedroom-radio-choice")
 await dispose();quit()
