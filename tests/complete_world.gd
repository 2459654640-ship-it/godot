extends SceneTree
const Story=preload("res://scripts/story.gd")
var checks=0
var failures=0
var w
func _initialize():call_deferred("run")
func check(ok:bool,why:String):
 checks+=1
 if not ok:failures+=1;push_error(why)
func frames(n:int=4):
 for i in n:await physics_frame
func open(floor:String,s):
 root.get_node("Session").pending={"story":s.serialize(),"floor":floor,"position":Vector3.INF}
 w=load("res://scenes/"+floor+".tscn").instantiate();root.add_child(w);current_scene=w;await frames()
 w.set_physics_process(false);w.player.set_physics_process(false);w.combat.set_physics_process(false);w.hud.close()
 if is_instance_valid(w.grey_camp):
  w.grey_camp.set_physics_process(false)
  for g in w.grey_camp.guards:g.set_physics_process(false)
func dispose():
 w.queue_free();await frames();w=null
func paths():
 for id in w.targets:
  var point:Vector3=w.targets[id].pos
  var p=w.navigation.path(w.player.position,point)
  check(w.player.position.distance_to(point)<1.7 or (not p.is_empty() and p[-1].distance_to(point)<1.7),"reachable target "+w.floor_id+" / "+id)
func follow(ids:Array,completed:String,limit:int=9000):
 var start:Vector3=w.npcs[ids[0]].position;var traveled=0.0;var oldpos=start;var saved=false
 for i in limit:
  var guide:String=ids[0];var stages:Dictionary=w.story.flags.get("late_walk_stages",{});var minimum=100
  for id in ids:
   if w.story.flags.get("late_route_complete",{}).get(id,false):continue
   var n=int(stages.get(id,0))
   if n<minimum:minimum=n;guide=id
  w.player.position=w.clear_arrival(w.npcs[guide].position+Vector3(1.8,.04,0))
  w.living.tick(1./60);w.chapter_director.tick(1./60)
  await physics_frame
  traveled+=w.npcs[ids[0]].position.distance_to(oldpos);oldpos=w.npcs[ids[0]].position
  if i==200 and not saved:
   var data=w.save_snapshot();var pos:Vector3=w.npcs[ids[0]].position;var floor:String=w.floor_id
   w.queue_free();await frames();root.get_node("Session").pending={"story":data,"floor":floor,"position":Vector3(data.position[0],.04,data.position[2])}
   w=load("res://scenes/"+floor+".tscn").instantiate();root.add_child(w);current_scene=w;await frames();w.set_physics_process(false);w.player.set_physics_process(false);w.combat.set_physics_process(false);w.hud.close()
   if is_instance_valid(w.grey_camp):
    w.grey_camp.set_physics_process(false)
    for g in w.grey_camp.guards:g.set_physics_process(false)
   check(w.npcs[ids[0]].position.distance_to(pos)<.9,"load resumes physical escort "+completed);oldpos=w.npcs[ids[0]].position;saved=true
  if w.story.f(completed):break
 if not w.story.f(completed):
  for id in ids:print("ESCORT_DIAG ",id," p=",w.npcs[id].position," goal=",w.npcs[id].goal," path=",w.npcs[id].path_points," waiting=",w.npcs[id].story_waiting," stage=",w.story.flags.get("late_walk_stages",{}).get(id,0))
 check(w.story.f(completed),"real escort reaches destination "+completed)
 check(traveled>4,"escort really moves "+completed)
func base():
 var s=Story.new();s.flags.intro_done=true;s.flags.commune_member=true;s.flags.commune_joined=true;s.give("mask");s.give("filter");s.give("revolver");s.economy.handmade=100;return s
func cross_floor_return():
 var s=base();s.flags.c1_revised=true;s.flags.field_c1_done=true;s.flags.field_c1_accepted=true;s.flags.late_c2_home_arrived=true
 var packet=s.serialize();packet.floor="railfront";packet.npc_positions={"c1_lidiya":{"position":[-21,0,18]},"junction_yuri":{"position":[-19,0,-13]}}
 root.get_node("Session").pending={"story":packet,"floor":"commune","position":Vector3.INF}
 w=load("res://scenes/commune.tscn").instantiate();root.add_child(w);current_scene=w;await frames()
 check(w.npcs.has("c1_lidiya") and w.npcs.c1_lidiya.position.distance_to(Vector3(-8,0,18.7))<1.5,"returned medic uses clinic placement, not previous map coordinates")
 check(w.npcs.has("junction_yuri") and w.npcs.junction_yuri.position.distance_to(Vector3(-7,0,12))<3,"returned courier uses dining placement, not previous map coordinates")
 await dispose()
func run():
 for id in ["junction","relay","star_interior"]:
  var s=base();s.flags.late_relay_assigned=true;s.flags.late_star_admitted=true;s.flags.late_c2_started=true;s.flags.late_active_job="c2"
  await open(id,s);paths()
  for code in ["late_father","late_star_guard","late_lev"]:
   if w.npcs.has(code):check(w.npcs[code].position.distance_to(w.targets[code].pos)<.2,"body and interaction agree "+code)
  await dispose()
 var s=base();s.flags.late_c2_started=true;s.flags.late_active_job="c2";s.flags.late_c2_escort=true
 await open("junction",s);await follow(["junction_yuri"],"late_c2_evacuated");check(w.targets.junction_yuri.pos.distance_to(w.npcs.junction_yuri.position)<.3,"courier target follows body");await dispose()
 s=base();s.flags.late_s1_started=true;s.flags.late_active_job="s1";s.flags.late_s1_ready=true
 await open("junction",s);await follow(["late_driver"],"late_s1_driver_arrived");await dispose()
 s=base();s.flags.late_s3_started=true;s.flags.late_active_job="s3";s.flags.late_s3_depart_ready=true
 await open("junction",s);await follow(["late_family_0","late_family_1","late_family_2","late_family_3"],"late_s3_evacuated",15000);await dispose()
 s=base();s.flags.late_d1_started=true;s.flags.late_active_job="d1";s.flags.late_d1_dispatched=true
 await open("junction",s);await follow(["late_junction_patient_0","late_junction_patient_1"],"late_d1_evacuated",12000);await dispose()
 s=base();s.flags.late_s2_started=true;s.flags.late_active_job="s2";s.flags.late_s2_escort=true
 await open("grey_shelter",s);await follow(["late_captive"],"late_s2_evacuated");await dispose()
 s=base();s.flags.late_final_escort=true;s.flags.late_final_started=true;s.flags.late_final_mode="shared"
 await open("relay",s);await follow(["late_final_woman","late_final_worker"],"late_final_execution_done",12000);await dispose()
 await cross_floor_return()
 print("COMPLETE_WORLD_RESULT checks=",checks," failures=",failures);quit(1 if failures else 0)
