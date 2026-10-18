extends SceneTree
var checks=0
var failures=0
func _initialize():call_deferred("run")
func check(ok:bool,msg:String):
 checks+=1
 if not ok:failures+=1;push_error(msg)
func frames(n:int=5):
 for i in n:await physics_frame
func run():
 var w=load("res://scenes/commune.tscn").instantiate();root.add_child(w);current_scene=w;await frames(8);w.hud.close();w.set_physics_process(false)
 for actor in w.npcs.values():actor.set_physics_process(false);actor.collision_layer=0
 var p=w.player;p.camera=null;p.use_override=true
 for height in [.08,.20,.24]:
  var platform=w.kit.box("StepTest",Vector3(3,height/2,2),Vector3(2,height,2),"wood",true);await frames()
  p.position=Vector3(3,.04,4.2);p.velocity=Vector3.ZERO;p.motion_override=Vector2.UP;await frames(50);p.motion_override=Vector2.ZERO;await frames(8)
  check(p.position.z<2.7 and absf(p.position.y-height)<.008,"real body climbs low surface and soles meet its top: "+str(height))
  p.motion_override=Vector2.DOWN;await frames(58);p.motion_override=Vector2.ZERO;await frames(8)
  check(p.position.z>3.8 and absf(p.position.y)<.008,"stepping down returns to floor without remaining elevated: "+str(height))
  platform.queue_free();await frames()
 var barrier=w.kit.box("TallStepTest",Vector3(3,.2,2),Vector3(2,.4,2),"wood",true);await frames()
 p.position=Vector3(3,.04,4.2);p.velocity=Vector3.ZERO;p.motion_override=Vector2.UP;await frames(70);p.motion_override=Vector2.ZERO
 check(p.position.z>3.2 and p.position.y<.01,"tall fixtures cannot be stepped through")
 barrier.queue_free();await frames()
 var low=w.kit.box("HeadroomStep",Vector3(3,.1,2),Vector3(2,.2,2),"wood",true)
 var ceiling=w.kit.box("LowCeilingTest",Vector3(3,1.84,2),Vector3(3,.1,3),"concrete",true);await frames()
 p.position=Vector3(3,.04,4.2);p.velocity=Vector3.ZERO;p.motion_override=Vector2.UP;await frames(70);p.motion_override=Vector2.ZERO
 check(p.position.z>3.2 and p.position.y<.01,"step-up refuses insufficient headroom")
 low.queue_free();ceiling.queue_free();await frames()
 p.position=Vector3(4,.04,-9);p.velocity=Vector3.ZERO;p.motion_override=Vector2.UP;await frames(48);p.motion_override=Vector2.ZERO;await frames(8)
 check(p.position.z< -10.4 and absf(p.position.y-.2)<.008,"actual commune stage is walkable with correct body height")
 var saved=w.save_snapshot();var arrival=w.clear_arrival(p.position)
 check(arrival.distance_to(p.position)<.01,"loading on the stage keeps the valid elevated position")
 w.save_path="user://platform_v12.json";w.save_game();p.position=Vector3(4,.04,-9);w.load_game();await frames(8)
 check(p.position.z< -10.4 and absf(p.position.y-.2)<.008,"real save/load restores stage placement rather than ejecting actor")
 DirAccess.remove_absolute("user://platform_v12.json")
 # Every actual low solid is traversable by the shared controller; the stage
 # can now participate in NPC pathfinding instead of being a forbidden void.
 w.navigation.setup(w)
 var target=w.navigation.graph.get_closest_point(Vector2(4,-10.5))
 check(w.navigation.graph.get_point_position(target).distance_to(Vector2(4,-10.5))<.26,"navigation includes the walkable stage surface")
 w.queue_free();await frames()
 print("PLATFORM_V12_RESULT checks=",checks," failures=",failures);quit(0 if failures==0 else 1)
