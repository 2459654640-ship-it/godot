extends SceneTree
const Story=preload("res://scripts/story.gd")
const Campaign=preload("res://scripts/campaign.gd")
var checks=0
var errors=0
func _initialize():call_deferred("run")
func check(ok:bool,msg:String):
 checks+=1
 if not ok:errors+=1;push_error(msg)
func action(s,key:String):
 var result=s.act("c_"+key);check(s.last_action_valid,"valid action "+key+" / "+result.left(40));return result
func reload(s):
 var n=Story.new();n.restore(s.serialize());n.context.floor="commune";return n
func comic(s):
 s.Comic.start(s,s.flags.next_sequence);s.flags.erase("next_sequence")
 var count=0
 while s.flags.comic.active and count<10:s.Comic.choose(s,0 if s.Comic.panel(s).has("choices") else -1);count+=1
 check(count<10 and not s.flags.comic.active,"side sequence resumes exploration, not an ending")
func frames(n:int):
 for i in n:await physics_frame
func run():
 var s=Story.new();s.context.floor="commune"
 for key in ["grow_accept","press_accept","workers_accept","meal_accept","medicine_seal_accept"]:check(not Campaign.available(s,key),"newcomer has no unrelated offer: "+key)
 for key in ["moro_work","moro_roots","moro_music"]:action(s,key)
 check(not s.f("moro_job") and not preload("res://scripts/journal.gd").tasks(s).any(func(q):return q.id=="moro_band"),"ordinary acquaintance never accepts music quest")
 action(s,"moro_decline");check(not Campaign.available(s,"moro_accept") and not s.f("moro_job"),"refusal adds no quest and costs nothing")
 action(s,"moro_reconsider");check(Campaign.available(s,"moro_accept"),"player can explicitly reconsider later")
 for mode in ["public","private"]:
  var t=reload(s)
  t.flags.moro_at_workshop=true;t.flags.moro_at_boiler=true;t.flags.moro_at_guard=true;t.flags.moro_at_stage=true
  # These state-unit fixtures stand in for arrivals; living_world_v24 physically walks every leg.
  for key in ["moro_accept","moro_parts","moro_power_plan","moro_repair","moro_permission","moro_listeners","moro_paper","moro_poster_people","moro_rehearse","moro_"+mode]:
   action(t,key)
   if key in ["moro_permission","moro_rehearse"]:comic(t)
   t=reload(t)
  check(not t.f("moro_played") and not t.f("moro_done"),"booking alone does not complete performance")
  comic(t);check(t.f("moro_played") and not t.ending,"music event finishes and continues playing")
  action(t,"moro_thanks");var money=t.economy.military;action(t,"moro_work") if Campaign.available(t,"moro_work") else null
  t.act("c_moro_thanks");check(not t.last_action_valid and t.economy.military==money,"music reward cannot be repeated")
  check(t.has("moro_card") and t.f("moro_done"),"music keeps its souvenir and completion across save/load")
 for mode in ["public","private"]:
  s=Story.new();s.context.floor="commune";s.flags.meal_done=true;s.flags.press_done=true
  for key in ["memory_hint","memory_accept","memory_record","memory_guard","memory_grower","memory_"+mode,"memory_print","memory_return"]:action(s,key);s=reload(s)
  check(not s.f("memory_done"),"delivery waits for reading and conversation")
  comic(s);check(s.f("memory_read") and not s.ending,"family reading resumes room exploration")
  action(s,"memory_finish");check(s.has("memory_card") and s.f("memory_done") and s.f("memory_"+mode),"family consent and record retained: "+mode)
 # Old accepted work bypasses only the new offer gate, never loses progress.
 s=Story.new();s.context.floor="commune";s.flags.grow_job=true;s.flags.grow_clue=true
 check(Campaign.available(s,"grow_shade"),"accepted legacy mushroom work remains completable")
 s=Story.new();s.context.floor="commune";s.flags.greenhouse_fixed=true
 check(Campaign.available(s,"press_accept") and Campaign.available(s,"grow_accept"),"later work opens after first local work")
 action(s,"press_accept");check(not Campaign.available(s,"workers_accept"),"same NPC does not offer another assignment during current one")
 s=Story.new();s.context.floor="commune";s.flags.commune_member=true
 for key in ["commune_assembly","commune_join"]:action(s,key)
 var journal=preload("res://scripts/journal.gd")
 check(journal.tasks(s).filter(func(q):return q.id=="commune_chapter")[0].target=="commune_greenhouse","membership chapter guides actual first work instead of a locked later assignment")
 for key in ["greenhouse_inspect","greenhouse_restart"]:action(s,key)
 check(journal.tasks(s).filter(func(q):return q.id=="commune_chapter")[0].target=="commune_leader","finished greenhouse guides back to the next assignment")
 action(s,"commune_main_work")
 check(journal.tasks(s).filter(func(q):return q.id=="commune_chapter")[0].target=="commune_records","chapter journal follows the actual worker draft desk")
 s.flags.workers_done=true;s.flags.greenhouse_fixed=false
 check(journal.tasks(s).filter(func(q):return q.id=="commune_chapter")[0].target=="commune_greenhouse","legacy parallel assignment guides to unfinished greenhouse after worker turn-in")
 var w=load("res://scenes/commune.tscn").instantiate();root.add_child(w);await frames(8);w.hud.close();w.set_physics_process(false)
 var rooms={}
 for z in w.zones:rooms[z.code]=z.rect
 check(rooms["04"].get_area()<=190 and rooms["01"].get_area()>550,"assembly is halved and farm substantially enlarged")
 for id in ["10","11","12","13"]:check(rooms.has(id),"military and production room "+id)
 check(w.find_children("*","MeshInstance3D",true,false).filter(func(m):return m.get_meta("design_id","")=="DoubleBedFrame").size()==4,"four family alcoves contain double beds")
 check(w.kit.solids.filter(func(x):return x.name=="FamilyAlcoveWall").size()==8,"alcoves have physical walls with door openings")
 check(w.find_children("*","MeshInstance3D",true,false).filter(func(m):return m.get_meta("design_id","")=="MilitiaRifleStock").size()>=3 and w.npcs.has("commune_guard"),"armed guard department has NPC and weapons")
 check(w.npcs.commune_moro.stationary and w.npcs.commune_guard.stationary,"new idle-only roles do not slide around")
 # All interaction targets can be reached from the actual entry component.
 var graph=w.navigation.graph;var start=graph.get_closest_point(Vector2(25,2));var seen={start:true};var queue=[start];var cursor=0
 while cursor<queue.size():
  var at=queue[cursor];cursor+=1
  for other in graph.get_point_connections(at):
   if not seen.has(other):seen[other]=true;queue.append(other)
 for id in w.targets:
  var target:Vector3=w.targets[id].pos;var near=INF
  for point in seen:near=minf(near,graph.get_point_position(point).distance_to(Vector2(target.x,target.z)))
  check(near<1.65,"reachable commune interaction "+id+" distance="+str(near))
 # Actual capsules cross both the workshop doors and family alcove doors.
 for actor in w.npcs.values():actor.set_physics_process(false);actor.collision_layer=0
 w.player.camera=null;w.player.use_override=true
 for door in [[-9.5,-12,"z"],[-7,-14,"z"],[.5,-14,"z"],[8,-14,"z"],[-11,-13,"x"],[12,-13,"x"],[16.4,10.2,"x"],[18.6,10.2,"x"],[16.4,20.5,"x"],[18.6,20.5,"x"]]:
  var normal=Vector2.RIGHT if door[2]=="x" else Vector2.DOWN
  for sign in [-1,1]:
   w.player.position=Vector3(door[0]+normal.x*sign*1.2,.04,door[1]+normal.y*sign*1.2);w.player.velocity=Vector3.ZERO
   w.player.motion_override=-normal*sign;await frames(65);w.player.motion_override=Vector2.ZERO
   check((Vector2(w.player.position.x,w.player.position.z)-Vector2(door[0],door[1])).dot(normal)*sign<-.4,"physical new doorway "+str(door)+str(sign))
 w.player.use_override=false
 w.hud.show_dialogue("commune_moro");w.hud.finish_typing();await frames(5)
 check(not w.hud.speech_buttons.is_empty(),"Moro's real dialogue UI renders")
 w.queue_free();await frames(3)
 print("COMMUNE_V12_RESULT checks=",checks," failures=",errors);quit(0 if errors==0 else 1)
