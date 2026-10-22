extends Node
## Narrative itineraries drive real bodies over the existing conservative route grid.
## No teleporting catch-up, background deadlines, or off-screen civilian casualties.
var w
var routes:Dictionary={}
var route_points:Dictionary={}
var notices:Dictionary={}
var _tick_delta=1.0/60.0
var evac_ids=["evac_first","evac_second","evac_third"]
var evac_starts=[Vector3(-17,0,3),Vector3(-19,0,5),Vector3(-16,0,6.5)]
var evac_ends=[Vector3(-20,0,18.6),Vector3(-16,0,19.4),Vector3(-18,0,19.2)]
func setup(world):
 w=world
 if w.floor_id=="railfront" and w.npcs.has("plant_veteran"):
  w.target("front_veteran",w.npcs.plant_veteran.position,"老兵 / 西侧接应口","talk")
  w.combat.encounters["living_passage"]={"rect":Rect2(-24,-24,48,48),"need":"veteran_defense_started","skip":"veteran_defense_safe","name":"守住西侧交叉口","spawns":[Vector3(-5,.04,10),Vector3(-3,.04,15),Vector3(-6,.04,18)]}
  # The optional passage defense begins first; expedition waves retain their own progress.
  w.combat.encounters["living_passage_rear"]={"rect":Rect2(-24,-24,48,48),"need":"evac_first_safe","skip":"veteran_defense_safe","name":"接应第二组 · 东侧来袭","spawns":[Vector3(-4,.04,8),Vector3(-3,.04,15)]}
  w.combat.encounters["living_passage_last"]={"rect":Rect2(-24,-24,48,48),"need":"evac_second_safe","skip":"veteran_defense_safe","name":"最后一人 · 守住南侧交叉口","spawns":[Vector3(-4,.04,16),Vector3(-5,.04,10)]}
  var priority={"living_passage":w.combat.encounters.living_passage,"living_passage_rear":w.combat.encounters.living_passage_rear,"living_passage_last":w.combat.encounters.living_passage_last}
  priority.merge(w.combat.encounters);w.combat.encounters=priority
 sync()
 restore_visitors()
func sync():
 if not is_instance_valid(w):return
 if w.floor_id=="commune":
  var absent=w.story.f("anna_dead") or (w.story.f("anna_rescue_started") and not w.story.f("anna_outcome_done"))
  reconcile("commune_anna",not absent,Vector3(-4,0,20),"anna")
  reconcile("commune_aleksei",w.story.f("anna_outcome_done"),Vector3(-2.9,0,20),"coal_brother")
 if w.floor_id=="coal":
  reconcile("coal_brother",w.CampaignMaps.coal_patient_available(w.story),Vector3(10,0,-6),"coal_brother")
 if w.floor_id=="railfront" and w.story.f("veteran_defense_started"):
  for i in evac_ids.size():
   var id:String=evac_ids[i]
   if not w.npcs.has(id):
    var p:Vector3=evac_ends[i] if w.story.f(id+"_safe") else evac_starts[i]
    w.person(id,p,"cloth",false,["diner","resident","mikhail"][i]);configure(w.npcs[id])
    # Dynamic actors also restore their exact saved position, just like ordinary NPCs.
    var entry:Dictionary=w.arrival_data.get("npc_positions",{}).get(id,{})
    if entry.get("position",[]).size()==3:
     var a=entry.position;w.npcs[id].position=w.clear_arrival(Vector3(a[0],.04,a[2]))
func reconcile(id:String,present:bool,p:Vector3,art:String):
 if present and not w.npcs.has(id):
  w.person(id,p,"cloth",false,art);configure(w.npcs[id]);w.target(id,w.npcs[id].position,w.story.Campaign.data().interactions[id].name,"talk")
 elif not present and w.npcs.has(id):
  var actor=w.npcs[id];w.npcs.erase(id);w.targets.erase(id);routes.erase(id);actor.queue_free()
func configure(actor):
 actor.navigation=w.navigation;actor.stationary=true;actor.patrol.clear();actor.home_anchor=actor.position;actor.anchor=actor.position
func mark(key:String,message:String=""):
 if w.story.f(key):return
 w.story.flags[key]=true
 if message!="":w.hud.toast(message,6)
 w.story.changed.emit();w.autosave()
func snap(p:Vector3,except_id:String="")->Vector3:
 var nav=w.navigation;var grid=nav.graph
 if grid.get_point_count()==0:return p
 var cell=Vector2i(roundi(p.x/nav.STEP),roundi(p.z/nav.STEP))
 var best=p;var distance=INF
 for dx in range(-3,4):
  for dz in range(-3,4):
   var key=cell+Vector2i(dx,dz)
   if not nav.cells.has(key):continue
   var q:Vector2=nav.points[nav.cells[key]];var occupied=false
   for id in w.npcs:
    if id==except_id:continue
    var body=w.npcs[id]
    if body.collision_layer!=0 and q.distance_to(Vector2(body.position.x,body.position.z))<.80:occupied=true;break
   var d=q.distance_to(Vector2(p.x,p.z))
   if not occupied and d<distance:distance=d;best=Vector3(q.x,0,q.y)
 return best
func direct(id:String,stage:String,destination:Vector3,wait_for_player:bool=false)->bool:
 if not w.npcs.has(id):return false
 var a=w.npcs[id]
 var point:Vector3=route_points.get(id,destination)
 if routes.get(id,"")!=stage:
  point=snap(destination,id);route_points[id]=point
  configure(a);a.goal=Vector3.INF;a.anchor=point;a.home_anchor=point;a.purposeful=true;a.reached_anchor=false;a.travel_to(point);routes[id]=stage
 # Followers stop to let the player catch up. They resume at their current position.
 a.story_waiting=wait_for_player and a.position.distance_to(w.player.position)>7.0
 if a.story_waiting and not notices.has(stage):
  notices[stage]=true;w.hud.toast("同行者会在原地等你；回来靠近后继续。手记地图可查看当前位置。",6)
 var reached=Vector2(a.position.x-point.x,a.position.z-point.z).length()<.42
 if not reached and a.path_points.is_empty() and a.reached_anchor:
  a.rest_time-=_tick_delta
  if a.rest_time<=0:
   a.goal=Vector3.INF;a.travel_to(point);a.rest_time=1.0
 if reached:
  a.purposeful=false;a.stationary=true;a.path_points.clear();a.story_waiting=false
 return reached
func tick(_delta:float):
 _tick_delta=maxf(_delta,1.0/60.0)
 if w.hud.modal_visible() or w.departure_animating:return
 var s=w.story
 if w.floor_id=="commune":
  if w.npcs.has("commune_anna"):
   if s.f("anna_walk_started") and not s.f("anna_conversation_ready"):
    if direct("commune_anna","anna_supper",Vector3(-6,0,13),true):mark("anna_walk_arrived","安娜已在食堂等你，可以过去继续交谈。")
   elif s.f("anna_alive"):
    # After the rescue she now spends time beside her brother, then teaches again.
    direct("commune_anna","anna_recovery" if not s.f("anna_new_lesson_seen") else "anna_teaches_again",Vector3(-4,0,20) if not s.f("anna_new_lesson_seen") else Vector3(-7,0,18.5))
   elif s.f("anna_request"):
    direct("commune_anna","anna_prepares" if s.f("anna_warning_seen") else "anna_desk",Vector3(-4,0,20))
  if s.f("moro_job") and w.npcs.has("commune_moro"):
   var stage="moro_workshop";var destination=Vector3(-7.5,0,-17)
   if s.f("moro_parts_found") and not s.f("moro_power_checked"):stage="moro_power";destination=Vector3(7.5,0,-18)
   elif s.f("moro_power_checked") and not s.f("moro_amp_fixed"):stage="moro_repair";destination=Vector3(-7.5,0,-17)
   elif s.f("moro_amp_fixed") and not s.f("moro_schedule"):stage="moro_council";destination=Vector3(6.5,0,18)
   elif s.f("moro_schedule") and not s.f("moro_ready"):stage="moro_posters";destination=Vector3(6.2,0,-16.5)
   elif s.f("moro_ready") and not s.f("moro_done"):
    stage="moro_stage";destination=Vector3(6.2,0,-16.5) if s.f("moro_private") else Vector3(-1,0,-8.5)
   elif s.f("moro_done"):stage="moro_next_shift";destination=Vector3(6.2,0,-16.5)
   if direct("commune_moro",stage,destination):
    var flags={"moro_workshop":"moro_at_workshop","moro_power":"moro_at_boiler","moro_repair":"moro_at_workshop","moro_council":"moro_at_guard","moro_stage":"moro_at_stage"}
    if flags.has(stage):mark(flags[stage])
   # Arrival facts apply only to the present itinerary, never a visit hours ago.
   for pair in [["moro_at_workshop",["moro_workshop","moro_repair"]],["moro_at_boiler",["moro_power"]],["moro_at_guard",["moro_council"]],["moro_at_stage",["moro_stage"]]]:
    if stage not in pair[1]:s.flags.erase(pair[0])
 if w.floor_id=="railfront" and s.f("veteran_defense_started") and not s.f("veteran_defense_safe"):
  var safe=0
  for i in evac_ids.size():
   var id:String=evac_ids[i]
   if s.f(id+"_safe"):safe+=1;continue
   # One person at a time, while both defenders hold the nearby crossing.
   var a=w.npcs.get(id)
   if not is_instance_valid(a):continue
   if i>safe or w.player.position.distance_to(Vector3(-10,0,12))>14 or not s.f("veteran_defense_deployed"):
    a.story_waiting=true;continue
   if direct(id,id+"_south",evac_ends[i]):mark(id+"_safe");safe+=1
  s.flags.veteran_evac_count=safe
  if safe==3 and ["battle_living_passage","battle_living_passage_rear","battle_living_passage_last"].all(func(flag):return s.f(flag)):mark("veteran_defense_safe","三名转移者均已抵达候车区。回西侧通道口与老兵核对人数。")
 for id in w.targets:
  var a=w.target_actor(id)
  if id=="front_veteran":a=w.npcs.get("plant_veteran")
  if is_instance_valid(a):w.targets[id].pos=a.position
func veteran_guard_point()->Vector3:
 if w.floor_id=="railfront" and w.story.f("veteran_defense_started") and not w.story.f("veteran_defense_done"):
  var point=snap(Vector3(-10.5,0,12),"plant_veteran")
  if is_instance_valid(w.combat.veteran) and w.combat.veteran.position.distance_to(point)<2:mark("veteran_defense_deployed")
  return point
 return Vector3.INF

func reset_for_load():
 routes.clear();route_points.clear();notices.clear()
 for id in ["commune_anna","commune_moro","commune_aleksei"]:
  if not w.npcs.has(id):continue
  var a=w.npcs[id];configure(a);a.purposeful=false;a.story_waiting=false;a.path_points.clear();a.goal=Vector3.INF;a.reached_anchor=false
 sync()

func capture():
 var remembered:Dictionary=w.story.flags.get("living_positions",{}).duplicate(true)
 for id in ["commune_anna","commune_moro"]+evac_ids:
  if not w.npcs.has(id):continue
  var a=w.npcs[id]
  remembered[w.floor_id+":"+id]={"position":[a.position.x,a.position.y,a.position.z],"facing":a.visual.rotation.y,"stage":routes.get(id,"")}
 w.story.flags.living_positions=remembered
func restore_visitors():
 if w.arrival_data.get("floor","")==w.floor_id:return # ordinary snapshot restoration already handled
 var remembered:Dictionary=w.story.flags.get("living_positions",{})
 for id in ["commune_anna","commune_moro"]+evac_ids:
  if not w.npcs.has(id):continue
  var record:Dictionary=remembered.get(w.floor_id+":"+id,{})
  if record.is_empty():continue
  if id=="commune_anna" and w.story.f("anna_alive") and record.get("stage","") not in ["anna_recovery","anna_teaches_again"]:continue
  var p=record.position;var a=w.npcs[id]
  a.position=w.clear_arrival(Vector3(p[0],p[1],p[2]));a.visual.rotation.y=record.get("facing",0)
