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
 var w=load("res://scenes/waterworks.tscn").instantiate();root.add_child(w);current_scene=w;await frames(8)
 w.hud.close();w.set_physics_process(false);w.player.set_physics_process(false);w.combat.set_physics_process(false)
 for actor in w.npcs.values():actor.set_physics_process(false);actor.collision_layer=0
 check(w.find_children("FactoryTileSplashback*","MeshInstance3D",true,false).is_empty(),"no independent wall overlay can span archive doorway")
 check(w.find_children("RoomSkirting*","MeshInstance3D",true,false).is_empty() and w.find_children("ThresholdPatch*","MeshInstance3D",true,false).is_empty(),"no fake raised floor strips in waterworks")
 for mesh in w.find_children("*","MeshInstance3D",true,false):
  if mesh.name.begins_with("SnowDrift"):
   var rect=Rect2(Vector2(mesh.position.x-.75,mesh.position.z-1.6),Vector2(1.5,3.2))
   check(not w.zones.any(func(z):return z.rect.intersects(rect)),"snow stays beyond actual room footprint")
  if mesh.get_meta("factory_decal",false):
   check(absf(mesh.rotation.y)<.001 and mesh.position.y>.2,"wall/box labels face their supporting north surface")
   check(not (absf(mesh.position.z-4)<.3 and absf(mesh.position.x+17)<1.7),"archive entrance remains clear of decorations")
 check(w.kit.wall_room_profiles.size()==w.zones.size() and w.kit.wall_finish_theme=="factory","every actual factory room has a shell face finish")
 var floors={}
 for floor in w.find_children("Floor_*","MeshInstance3D",true,false):floors[floor.get_meta("floor_finish")]=true
 check(floors.size()>=3,"dry archive, wet plant and electrical room floors differ")
 # Both real capsule passage and ray sight line through the formerly hidden door.
 for sign in [-1,1]:
  w.player.position=Vector3(-17,.04,4+1.2*sign);w.player.velocity=Vector3.ZERO
  for i in 85:
   await physics_frame;w.player.velocity=Vector3(0,-.5,-2*sign);w.player.move_and_slide()
  check((w.player.position.z-4)*sign<-.5,"actual archive doorway crossed in both directions")
 var c=w.combat;c.active=true;w.toggle_weapon()
 for actor in [w.player,c.veteran]:
  var painter=actor.visual.get_node("Painter");painter.set_process(false)
  for angle in range(8):
   actor.visual.rotation.y=angle*PI/4;actor.velocity=Vector3(1,0,1);painter.direction_ready=false
   var frames_seen={}
   for phase in [0.0,.25,.5,.75]:
    painter.cycle=phase;painter._process(0);frames_seen[painter.current_pose]=true
   check(frames_seen.size()==3 and frames_seen.has(0),"armed movement has two authored opposite strides and neutral transition: "+str(actor.name)+str(angle))
  actor.velocity=Vector3.ZERO;painter._process(0);check(painter.current_pose==0,"stopping returns to planted aiming stance")
 c.active=false;w.player.position=Vector3(-13,.04,-2);c.begin("pump");await frames()
 check(c.enemies.size()==3 and c.enemies.filter(func(e):return e.enemy_kind=="pouncer").size()==1,"first fight combines three enemies including one telegraphed pouncer")
 for e in c.enemies:e.set_physics_process(false)
 var e=c.enemies[0];var hp=w.story.economy.health;e.position=w.player.position+Vector3(.6,0,0);e.arrival_time=0;e.cooldown=0;e.windup=0
 e._physics_process(.01);check(e.windup>=.4 and w.story.economy.health==hp,"bite is visibly telegraphed before damage")
 e._physics_process(.2);check(w.story.economy.health==hp,"telegraph gives time to move")
 w.player.position+=Vector3(2,0,0);e._physics_process(.3);check(w.story.economy.health==hp,"moving out of bite range actually avoids damage")
 var file="user://factory_v12_active.json";w.save_path=file;w.save_game()
 check(FileAccess.file_exists(file) and w.SaveStore.read(file).get("combat_state",{}).get("enemies",[]).size()==3,"active encounter saves the actual three enemies instead of a partial room state")
 for foe in c.enemies.duplicate():foe.damage(200)
 w.save_game();check(FileAccess.file_exists(file),"cleared encounter can be manually saved")
 DirAccess.remove_absolute(file)
 w.queue_free();await frames()
 print("FACTORY_V12_RESULT checks=",checks," failures=",failures);quit(0 if failures==0 else 1)
