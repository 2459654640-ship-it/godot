extends "res://tests/campaign_contract.gd"
func run():
 w=load("res://scenes/starcity.tscn").instantiate();root.add_child(w);current_scene=w;await frames(5)
 check(w.initialized,"refurbished Star City starts")
 check(w.zones.any(func(r):return r.code=="07") and w.zones.any(func(r):return r.code=="08"),"independent environmental chamber and instrument preparation room")
 var finishes={}
 for node in w.find_children("*","MeshInstance3D",false,false):
  if node.has_meta("floor_finish"):finishes[node.get_meta("floor_finish")]=true
 check(finishes.size()>=4,"floors differ by research/service/public use")
 check(w.kit.solids.filter(func(s):return s.name=="ResearchChamferWall").size()>=8,"main hall and chamber have real chamfered shells")
 check(w.find_children("VacuumVessel*","MeshInstance3D",false,false).size()==1,"physical cylindrical environmental test vessel")
 check(overlap(Vector3(27,.04,-10)),"test vessel has physical collision")
 for node in w.find_children("TelemetryConsole*","Node3D",false,false):
  if not node.name.begins_with("TelemetryConsole") or node is MeshInstance3D:continue
  if node.position.x>-7 and node.position.x<7 and node.position.z<0:
   check((node.global_basis*Vector3.BACK).dot(Vector3.FORWARD)>.9,"control desks face the northern main display")
 w.story.flags.star_access=true;w.story.flags.intro_done=true;w.on_story_changed();await frames(80)
 w.navigation=preload("res://scripts/route_grid.gd").new();w.navigation.setup(w)
 var seen=reachable();check(seen.size()>1600,"all research wings connect to the public entrance after authorization")
 for id in w.targets:
  var end:Vector3=w.targets[id].pos+Vector3(0,1.2,0);var visible=false
  for cell in seen:
   var p:Vector2=w.navigation.graph.get_point_position(cell)
   if p.distance_to(Vector2(end.x,end.z))>1.6 or overlap(Vector3(p.x,.04,p.y)):continue
   var hit=w.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(p.x,1.2,p.y),end,1))
   if hit.is_empty() or hit.position.distance_to(end)<.48:visible=true;break
  check(visible,"real capsule approach and line of sight to "+id)
 for actor in w.npcs.values():actor.set_physics_process(false);actor.collision_layer=0
 w.player.camera=null;w.player.use_override=true
 for d in [[7,-10.5,"x"],[21,-10.5,"x"],[14,-12,"z"]]:
  var door=Vector2(d[0],d[1]);var normal=Vector2.RIGHT if d[2]=="x" else Vector2.DOWN
  for sign in [-1,1]:
   w.player.position=Vector3(door.x+normal.x*sign*1.2,.04,door.y+normal.y*sign*1.2);w.player.velocity=Vector3.ZERO;w.player.motion_override=-normal*sign
   await frames(65);w.player.motion_override=Vector2.ZERO;await frames(4)
   check((Vector2(w.player.position.x,w.player.position.z)-door).dot(normal)*sign<-.4,"new research doorway physically traversable both ways: "+str(d)+str(sign))
 w.player.use_override=false
 w.story.context.floor="starcity"
 for key in ["star_vacuum_read","star_instrument_read"]:
  var reply=w.story.act("c_"+key);check(w.story.last_action_valid and reply.length()>50,"research exhibits can actually be read: "+key)
 var snapshot=w.save_snapshot();snapshot.layout_revision=13;snapshot.position=[27,.04,-10];snapshot.flags.test_old_starcity=true
 var path="user://starcity_v17_migration.json";w.SaveStore.write(path,snapshot,"manual");w.load_game(path);await frames(5)
 check(w.story.f("test_old_starcity") and w.player.position.distance_to(w.CampaignMaps.LAYOUTS.starcity.spawn)<.2,"old layout save relocates safely without losing story")
 DirAccess.remove_absolute(path)
 w.queue_free();await frames(3)
 print("STARCITY_V17_RESULT checks=",checks," failures=",failed.size());quit(0 if failed.is_empty() else 1)
