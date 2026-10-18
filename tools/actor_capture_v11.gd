extends "res://tools/visual_capture_v9.gd"
## Controlled animation samples in the real rooms, not a recorded playthrough.
func _initialize():call_deferred("run")
func sequence(actor,tag:String,direction:Vector2):
 var output="/tmp/metro-v11-gait/"+tag;DirAccess.make_dir_recursive_absolute(output)
 camera_at(actor.position+Vector3.UP*.85,5.5)
 var vector=w.camera.global_basis.x*direction.x+w.camera.global_basis.z*direction.y;vector.y=0
 actor.velocity=vector.normalized()*1.5;actor.visual.rotation.y=atan2(-vector.x,-vector.z)
 var painter=actor.visual.get_node("Painter");painter.set_process(false);painter.direction_ready=false
 for frame in range(12):
  painter.cycle=float(frame)/12;painter._process(0);await settle(2)
  root.get_texture().get_image().save_png(output+"/%02d.png"%frame)
 print("ACTOR_CAPTURE ",tag)
func run():
 await open_level("d6");w.hud.hide();w.player.position=Vector3(-3,.04,-4)
 await sequence(w.player,"ivan-right-down",Vector2(1,1))
 await sequence(w.player,"ivan-left-down",Vector2(-1,1))
 await sequence(w.player,"ivan-side",Vector2(1,0))
 await dispose();await open_level("commune");w.hud.hide()
 await sequence(w.npcs.commune_child,"child-walk",Vector2(1,1))
 await dispose();quit()
