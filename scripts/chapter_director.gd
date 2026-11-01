extends Node
## Physical cast, journeys and aftermath. Saves preserve positions and route stages.
var w
var owned:Array[String]=[]
const Props=preload("res://scripts/production_props.gd")
const Complete=preload("res://scripts/complete_campaign.gd")
static func dress(world):
 var k=world.kit
 Props.prepare(k)
 if world.floor_id=="east_district":
  # The old freight yard's own service stair; clear of the road and existing shed entrance.
  k.box("FreightStairApron",Vector3(53,.05,25),Vector3(3.6,.10,3.6),"institution_floor")
  for x in [51.4,54.6]:
   k.box("FreightStairCheek",Vector3(x,.9,23.7),Vector3(.18,1.8,2.8),"concrete",true)
   k.pipe(Vector3(x,1.3,23),Vector3(x,1.3,26.2),.035,"dark_steel")
  k.box("FreightStairDark",Vector3(53,.02,23),Vector3(2.8,.035,1.3),"black")
  k.box("FreightStairDoor",Vector3(53,1.1,22.5),Vector3(2.8,2.2,.18),"dark_steel",true)
  k.lamp(Vector3(52,2.3,22.7),true,.9,7)
  k.label("СЛУЖЕБНЫЙ СПУСК",Vector3(53,2.4,22.62),16)
 if world.floor_id=="labor":
  Props.bevel(k,"LivingWaterPump",Vector3(-6.3,.5,-3.8),Vector3(1.0,1.0,.8),"institution_enamel",null,true)
  for y in [.6,1.3]:k.pipe(Vector3(-5.45,y,-3),Vector3(-5.45,y,-5.2),.065,"dark_steel")
  for z in [-3.4,-4.3]:
   var wheel=k.cyl("LivingBranchHandwheel",Vector3(-5.7,1.3,z),.16,.045,"red");wheel.rotation.z=PI/2
  Props.console(k,Vector3(-6.3,1,-3.8),PI,.7)
 if world.floor_id=="starcity":
  k.box("ExternalServiceRoutePost",Vector3(8.8,1.1,11),Vector3(.12,2.2,.12),"metal")
  k.box("ExternalServiceArrow",Vector3(8.8,1.7,11.05),Vector3(1.1,.25,.035),"paper")
static func encounters(s,floor:String)->Dictionary:
 if floor=="junction":
  var job=Complete.active_job(s);var id="junction_"+(job if job!="" else "final")
  return {id:{"rect":Rect2(-7,-8,14,18),"need":"late_junction_active","skip":"unused_late_skip","name":"轨道间的兽群","spawns":[Vector3(-5,.04,-5),Vector3(4,.04,-1),Vector3(1,.04,-7)],"enemy_kind":"mutant"}}
 if floor=="relay":
  var e={"relay_feeder":{"rect":Rect2(1,-15,26,32),"need":"late_relay_assigned","skip":"unused_late_skip","name":"馈线场里的动静","spawns":[Vector3(10,.04,-9),Vector3(23,.04,2),Vector3(9,.04,7)],"enemy_kind":"mutant"}}
  if s.f("late_final_started"):
   e={"relay_final":{"rect":Rect2(1,-23,29,43),"need":"late_final_started","skip":"unused_late_skip","name":"外线接应点的威胁","spawns":[Vector3(23,.04,-6),Vector3(7,.04,4),Vector3(21,.04,18),Vector3(29,.04,1)],"enemy_kind":"mutant","boss_title":"外线巢兽"}}
  return e
 return {}
func setup(world):
 w=world
 if w.floor_id=="junction":w.story.flags.late_junction_active=true
 if w.floor_id=="relay" and w.story.f("late_d3_started"):w.story.flags.late_d3_entered=true
 var active=Complete.active_job(w.story)
 if w.floor_id==Complete.home(w.story) and active=="s2" and w.story.f("late_s2_evacuated"):w.story.flags.late_s2_home_arrived=true
 sync()
func target(id:String,p:Vector3):
 if not w.targets.has(id):w.target(id,p,Complete.data().interactions[id].name,"inspect")
func actor(id:String,p:Vector3,art:String,present:bool=true):
 if not present:
  if not w.npcs.has(id):return
  w.npcs[id].queue_free();w.npcs.erase(id);w.living.routes.erase(id)
  if w.targets.has(id):
   for item in [w.targets[id].ring,w.targets[id].marker]:
    if is_instance_valid(item):item.queue_free()
   w.targets.erase(id)
  return
 if not w.npcs.has(id):
  w.person(id,w.living.snap(w.clear_arrival(p),id),"cloth",false,art);w.living.configure(w.npcs[id]);owned.append(id)
  var records:Dictionary=w.story.flags.get("late_actor_positions",{}).get(w.floor_id,{})
  var record=w.arrival_data.get("npc_positions",{}).get(id,{})
  if record.get("position",[]).size()==3:records=records.duplicate();records[id]=record.position
  if records.get(id,[]).size()==3:
   var a=records[id];w.npcs[id].position=w.clear_arrival(Vector3(a[0],0,a[2]))
 if Complete.data().interactions.has(id):
  if not w.targets.has(id):w.target(id,w.npcs[id].position,Complete.data().interactions[id].name,"talk")
  w.targets[id].kind="talk";w.targets[id].pos=w.npcs[id].position
func sync():
 var s=w.story
 if s.f("late_father_truth_seen") and s.flags.get("tracked_quest","")=="late_family":s.flags.tracked_quest="late_warning"
 match w.floor_id:
  "east_district":
   if Complete.active_job(s) in ["c2","s1","s3","d1"] or s.f("late_star_admitted"):target("late_junction_entry",Vector3(53,0,25.5))
   if s.f("late_d3_started") or s.f("late_relay_assigned"):target("late_street_probe",Vector3(-82,0,42))
  "labor":
   if s.f("late_d2_started"):target("late_d6_meter",Vector3(-8,0,-3.6))
   if s.f("late_d1_done"):
    actor("late_wounded_one",Vector3(1,0,-9),"ambient_worker");actor("late_wounded_two",Vector3(-2,0,-9),"ambient_elder")
  "starcity":
   if s.f("late_relay_assigned") or s.f("late_d3_started") or s.f("late_star_admitted"):target("late_perimeter_relay",Vector3(8,0,11))
  "junction":
   actor("junction_yuri",Vector3(-18,0,-14),"ambient_worker",s.f("late_c2_started") and not s.f("late_c2_home_arrived"))
   if s.f("late_s1_started") and not s.f("late_s1_home_arrived"):actor("late_driver",Vector3(2,0,12),"resident")
   if s.f("late_d1_started") and not s.f("late_d1_home_arrived"):
    target("junction_patients",Vector3(14,0,-11))
    actor("late_junction_medic",Vector3(20,0,-12),"coal_medic")
    for i in 2:actor("late_junction_patient_"+str(i),Vector3(13+i*2,0,-11),["ambient_worker","ambient_elder"][i])
   if s.f("late_s3_started") and not s.f("late_s3_home_arrived"):
    for i in 4:actor("late_family_"+str(i),Vector3(13+i*1.4,0,-10),["ambient_woman","ambient_child","ambient_elder","ambient_worker"][i])
  "grey_shelter":actor("late_captive",Vector3(5,0,5),"ambient_worker",s.f("late_s2_started") and not s.f("late_s2_home_arrived"))
  "commune":actor("junction_yuri",Vector3(-7,0,12),"ambient_worker",s.f("late_c2_home_arrived"))
  "sech":actor("late_captive",Vector3(-12,0,2.7),"ambient_worker",s.f("late_s2_home_arrived"))
  "star_interior":
   actor("late_star_guard",Vector3(-6,0,15),"star_guard");actor("late_father",Vector3(-8,0,-4),"father");actor("late_lev",Vector3(21,0,3),"star_technician")
   actor("late_scientist_one",Vector3(22,0,-14),"star_technician");actor("late_technician_two",Vector3(-24,0,-2),"ambient_worker")
  "relay":
   if s.f("late_final_escort"):
    target("relay_evac_group",Vector3(-21,0,-10))
    actor("late_final_woman",Vector3(-22,0,-10),"ambient_woman");actor("late_final_worker",Vector3(-19,0,-10),"ambient_worker")
 # Existing resident's actual daily location changes after the heating diagnosis.
 if w.floor_id=="commune" and s.f("late_c3_cold_confirmed") and w.npcs.has("commune_baranova"):
  if "commune_baranova" not in owned:owned.append("commune_baranova")
 # Scene changes are explicit, rather than a dialogue-only claim.
 for node in w.find_children("RelayGeneratorHousing*","MeshInstance3D",true,false):
  if s.f("late_watch_power"):node.set_meta("power_restored",true)
func walk(id:String,route:Array,finish:String,offset:Vector3=Vector3.ZERO)->bool:
 if not w.npcs.has(id):return false
 if w.story.f(finish):return true
 var stages:Dictionary=w.story.flags.get("late_walk_stages",{}).duplicate(true)
 var stage=clampi(int(stages.get(id,0)),0,route.size()-1)
 var point:Vector3=route[stage]+offset
 if w.living.direct(id,"late_"+id+"_"+str(stage),point,true):
  if stage+1<route.size():stages[id]=stage+1;w.story.flags.late_walk_stages=stages
  else:w.living.mark(finish);return true
 return false
func tick(_delta):
 if w.hud.modal_visible() or w.departure_animating:return
 var s=w.story
 if w.floor_id=="junction":
  if s.f("late_c2_escort"):walk("junction_yuri",[Vector3(-18,0,-4),Vector3(-18,0,13),Vector3(-10,0,13),Vector3(0,0,20)],"late_c2_evacuated")
  if s.f("late_s1_ready"):walk("late_driver",[Vector3(0,0,18),Vector3(0,0,21)],"late_s1_driver_arrived")
  if s.f("late_s3_depart_ready"):
   var arrived=true
   for i in 4:
    if not walk("late_family_"+str(i),[Vector3(12,0,-12),Vector3(0,0,-12),Vector3(0,0,3),Vector3(0,0,21)],"late_family_"+str(i)+"_safe",Vector3((i-1.5)*.75,0,0)):arrived=false
   if arrived:w.living.mark("late_s3_evacuated","乘车的四名住户都已抵达南口，司机可以核对上车。")
  if s.f("late_d1_dispatched"):
   var arrived=true
   for i in 2:
    if not walk("late_junction_patient_"+str(i),[Vector3(12,0,-12),Vector3(0,0,-12),Vector3(0,0,3),Vector3(0,0,21)],"late_patient_"+str(i)+"_safe",Vector3((i-.5)*1.0,0,0)):arrived=false
   if arrived:w.living.mark("late_d1_evacuated","医护已将伤员接到南口，可以跟车返站。")
 if w.floor_id=="grey_shelter" and s.f("late_s2_escort"):walk("late_captive",[Vector3(5,0,1),Vector3(0,0,5),Vector3(-7.5,0,7.7)],"late_s2_evacuated")
 if w.floor_id=="commune" and s.f("late_c3_cold_confirmed") and w.npcs.has("commune_baranova"):
  var dest=Vector3(20.6,0,19.5) if s.f("late_c3_heat_restored") else Vector3(-7,0,12.6)
  w.living.direct("commune_baranova","late_warm_home" if s.f("late_c3_heat_restored") else "late_warm_wait",dest)
 if w.floor_id=="relay" and s.f("late_final_escort"):
  var arrived=true
  for id in ["late_final_woman","late_final_worker"]:
   if not walk(id,[Vector3(-20,0,-4),Vector3(-25,0,8),Vector3(-24,0,22)],id+"_safe",Vector3(0 if id=="late_final_woman" else 1,0,0)):arrived=false
  if arrived:w.living.mark("late_final_execution_done","改道住户已到接应处，回测控台核对回执即可完成交接。")
 for pair in [["junction_family","late_family_0"],["junction_patients","late_junction_patient_0"],["relay_evac_group","late_final_woman"]]:
  if w.targets.has(pair[0]) and w.npcs.has(pair[1]):w.targets[pair[0]].pos=w.npcs[pair[1]].position
 for id in owned:
  if w.npcs.has(id) and w.targets.has(id):w.targets[id].pos=w.npcs[id].position
func capture():
 var records:Dictionary=w.story.flags.get("late_actor_positions",{}).duplicate(true);var local={}
 for id in owned:
  if not w.npcs.has(id):continue
  var p:Vector3=w.npcs[id].position;local[id]=[p.x,p.y,p.z]
 records[w.floor_id]=local;w.story.flags.late_actor_positions=records
