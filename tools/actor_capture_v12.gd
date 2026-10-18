extends "res://tools/visual_capture_v9.gd"
func _initialize():call_deferred("run")
func sequence(actor,tag:String,direction:Vector2):
 var output="/tmp/metro-v12-gait/"+tag;DirAccess.make_dir_recursive_absolute(output)
 camera_at(actor.position+Vector3.UP*.85,4.5)
 var vector=w.camera.global_basis.x*direction.x+w.camera.global_basis.z*direction.y;vector.y=0
 actor.velocity=vector.normalized()*1.5;actor.visual.rotation.y=atan2(-vector.x,-vector.z)
 var painter=actor.visual.get_node("Painter");painter.set_process(false);painter.direction_ready=false
 for frame in range(4):
  painter.cycle=float(frame)/4;painter._process(0);await settle(2)
  root.get_texture().get_image().save_png(output+"/%02d.png"%frame)
 print("ACTOR_CAPTURE ",tag)
func run():
 await open_level("d6");w.hud.hide();w.player.position=Vector3(-3,.04,-4)
 for spec in [["front",Vector2(0,1)],["right-down",Vector2(1,1)],["left-down",Vector2(-1,1)],["side",Vector2(1,0)],["rear-right",Vector2(1,-1)],["back",Vector2(0,-1)]]:await sequence(w.player,"ivan-"+spec[0],spec[1])
 w.story.give("revolver");w.toggle_weapon()
 for spec in [["right-down",Vector2(1,1)],["left-down",Vector2(-1,1)]]:await sequence(w.player,"unmasked-armed-"+spec[0],spec[1])
 await dispose();await open_level("waterworks");w.hud.hide();w.combat.set_physics_process(false);w.player.position=Vector3(-13,.04,-4)
 for spec in [["right-down",Vector2(1,1)],["left-down",Vector2(-1,1)]]:await sequence(w.player,"masked-"+spec[0],spec[1])
 w.combat.active=true;w.story.flags.weapon_drawn=true
 for actor in [w.player,w.combat.veteran]:
  actor.position=Vector3(-13,.04,-4)
  for spec in [["front",Vector2(0,1)],["right-down",Vector2(1,1)],["left-down",Vector2(-1,1)],["side",Vector2(1,0)],["rear-right",Vector2(1,-1)],["back",Vector2(0,-1)]]:await sequence(actor,("armed-ivan-" if actor==w.player else "veteran-")+spec[0],spec[1])
 await dispose();quit()
