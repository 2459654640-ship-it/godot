extends "res://tools/visual_capture_v8.gd"
func _initialize():
 folder="/tmp/metro1982-review/v17";call_deferred("run")
func run():
 DirAccess.make_dir_recursive_absolute(folder)
 await open_level("starcity")
 w.hud.visible=false
 camera_at(Vector3(5,0,-3),44);await shot("starcity-overview")
 camera_at(Vector3(0,0,-8),18);await shot("starcity-control")
 camera_at(Vector3(27,0,-10),17);await shot("starcity-test-chamber")
 camera_at(Vector3(14,0,-16),18);await shot("starcity-instruments")
 await dispose()
 await open_level("commune")
 w.interact("commune_grower");await shot("first-meeting-zoya")
 var o=w.story.view("commune_grower").options[0];w.hud.last_choice=o.text;w.perform(o.key,"commune_grower");await shot("first-meeting-name")
 await dispose();quit()
