extends "res://tools/visual_capture_v9.gd"
func _initialize():folder="res://docs/screenshots/visual-v12";call_deferred("run")
func run():
 await open_level("commune");w.hud.hide();w.player.camera=null;w.player.use_override=true;w.player.set_physics_process(true)
 w.player.position=Vector3(4,.04,-9);w.player.velocity=Vector3.ZERO;w.player.motion_override=Vector2.UP
 for i in 30:await physics_frame
 w.player.set_physics_process(false);camera_at(w.player.position+Vector3.UP,5);await shot("stage-edge-support")
 w.player.set_physics_process(true)
 for i in 18:await physics_frame
 w.player.motion_override=Vector2.ZERO
 for i in 20:await physics_frame
 w.player.set_physics_process(false);camera_at(Vector3(4,1,-10.8),5);await shot("stage-feet-on")
 w.player.set_physics_process(true);w.player.motion_override=Vector2.DOWN
 for i in 60:await physics_frame
 w.player.motion_override=Vector2.ZERO
 for i in 20:await physics_frame
 w.player.set_physics_process(false);camera_at(w.player.position+Vector3.UP,5);await shot("stage-feet-off")
 await dispose();quit()
