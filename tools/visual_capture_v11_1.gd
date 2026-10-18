extends "res://tools/visual_capture_v9.gd"
func _initialize():
 folder="res://docs/screenshots/visual-v11-1";call_deferred("run")
func run():
 DirAccess.make_dir_recursive_absolute(folder)
 await open_level("commune")
 if "--dialogue-only" in OS.get_cmdline_user_args():
  w.player.position=Vector3(-4,.04,19);camera_at(Vector3(-5,1,21),16);w.hud.show_dialogue("commune_anna");await shot("anna-clear-request");await dispose();quit();return
 w.hud.visible=false
 w.player.position=Vector3(0,.04,2);camera_at(Vector3(0,0,1),49);await shot("commune-overview")
 w.player.position=Vector3(8,.04,4);camera_at(Vector3(.5,.7,-3.8),15)
 var door=w.find_children("*","Node3D",false,false).filter(func(n):return n.get_script()==load("res://scripts/assembly_door.gd"))[0]
 door.set_physics_process(false)
 if is_instance_valid(door.motion):door.motion.kill()
 for leaf in door.leaves:leaf.rotation.y=0
 await shot("assembly-door-closed")
 door.set_physics_process(true);w.player.position=Vector3(.5,.04,-1.5)
 for i in 70:await physics_frame
 await shot("assembly-door-open")
 w.player.position=Vector3(-18,.04,-8);camera_at(Vector3(-19,1,-8),12);await shot("greenhouse-canopy")
 w.player.position=Vector3(-20,.04,-10.9);camera_at(Vector3(-19,1,-9),11);await shot("canopy-visibility")
 w.player.position=Vector3(-4,.04,19);camera_at(Vector3(-5.5,1,21),13);await shot("medical-screen")
 w.player.position=Vector3(-3.6,.04,11);camera_at(Vector3(-4,1,11),16);await shot("dining-room")
 w.player.position=Vector3(17,.04,16);camera_at(Vector3(17,1,16),16);await shot("family-rooms")
 w.hud.visible=true;w.hud.show_dialogue("commune_anna");await shot("anna-clear-request");w.hud.close()
 await dispose();quit()
