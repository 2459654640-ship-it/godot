extends SceneTree
const Story=preload("res://scripts/story.gd")
var checks=0
var failures=0
func check(ok:bool,why:String):
 checks+=1
 if not ok:failures+=1;push_error(why)
func action(s,key:String,floor:String):
 s.context.floor=floor;s.act("c_"+key);check(s.last_action_valid,"available action "+key)
func film(s):
 if not s.flags.has("next_sequence"):return
 var id=s.flags.next_sequence;s.flags.erase("next_sequence");s.Comic.start(s,id)
 var count=0
 while s.flags.comic.active and count<30:
  var panel=s.Comic.panel(s);check(not panel.is_empty(),"resolved panel "+str(s.flags.comic.node))
  if panel.is_empty():break
  s.Comic.choose(s,0 if panel.has("choices") else -1);count+=1
 check(count<30,"no circular film "+id)
 s.flags.erase("next_facility");s.flags.erase("resume_dialogue")
func fixture(faction:String):
 var s=Story.new();s.flags.intro_done=true;s.give("mask");s.give("filter");s.give("revolver");s.economy.handmade=80
 if faction=="commune":s.flags.commune_member=true;s.flags.field_c1_done=true
 if faction=="sech":s.flags.sech_member=true
 if faction=="d6":s.flags.d6_cargo_returned=true;s.flags.d6_patrol_done=true;s.flags.departure_official=true;s.route="official"
 return s
func returned(s,id:String):
 var j=s.Campaign.Complete.data().jobs[id]
 action(s,"late_junction_return","junction");film(s);check(s.f("late_"+id+"_home_arrived"),"physical completion permits home handover "+id)
 action(s,"late_"+id+"_report",j.home);film(s)
func _initialize():call_deferred("run")
func run():
 var c=Story.new().Campaign.data()
 for q in Story.new().Campaign.Complete.data().quests:
  for st in q.stages:check(c.interactions.has(st.target) or st.target in ["nina","d6_surface_gate","grey_shelter_exit"],"quest target resolves "+st.target)
 for p in Story.new().Campaign.Complete.data().panels.values():check(ResourceLoader.exists("res://assets/cinematics/"+p.art+".png"),"film art exists "+p.art)
 var old=Story.new();old.restore({"version":1,"flags":{"star_access":true,"field_c2_done":true},"items":[],"economy":{}})
 check(not old.f("late_star_admitted") and old.f("late_c2_done"),"legacy work preserved without inventing new admission")
 var comm=fixture("commune")
 action(comm,"field_c2_accept","commune");check(not comm.Campaign.available(comm,"field_c3_accept"),"long work opens in order")
 action(comm,"late_c2_family","commune");action(comm,"late_c2_depart","commune");film(comm)
 action(comm,"late_junction_return","junction");film(comm);check(not comm.f("late_c2_home_arrived"),"early withdrawal does not teleport the missing courier")
 action(comm,"late_c2_find","junction");action(comm,"late_c2_consent","junction");comm.flags.late_c2_evacuated=true
 action(comm,"late_junction_return","junction");film(comm);action(comm,"late_c2_letters","commune");action(comm,"late_c2_report","commune");film(comm)
 check(comm.f("late_c2_done") and not comm.has("late_mailbag"),"courier and letters are handed over separately")
 action(comm,"field_c3_accept","commune")
 for key in ["cold","diagram","parts","isolate","repair","meeting"]:action(comm,"late_c3_"+key,"commune")
 action(comm,"late_c3_report","commune");film(comm);check(comm.Campaign.Complete.completed_route(comm),"commune route reaches the technical contact")
 var sech=fixture("sech")
 action(sech,"field_s1_accept","sech");action(sech,"late_s1_depart","sech");film(sech)
 for key in ["inspect","spare","brake","switch"]:action(sech,"late_s1_"+key,"junction")
 sech.flags.late_s1_driver_arrived=true;returned(sech,"s1")
 action(sech,"field_s2_accept","sech");action(sech,"late_s2_brief","sech");action(sech,"late_s2_depart","sech");film(sech);action(sech,"late_s2_release","grey_shelter")
 sech.flags.late_s2_evacuated=true;sech.flags.late_s2_home_arrived=true
 action(sech,"late_s2_account","sech");action(sech,"late_s2_report","sech");film(sech)
 action(sech,"field_s3_accept","sech");action(sech,"late_s3_depart","sech");film(sech)
 for key in ["manifest","coupling","repair","both"]:action(sech,"late_s3_"+key,"junction")
 check(not sech.Campaign.available(sech,"late_s3_people"),"dispatch cannot be chosen a second time")
 sech.flags.late_s3_evacuated=true;returned(sech,"s3");check(sech.Campaign.Complete.completed_route(sech),"sech route reaches the technical contact")
 var central=fixture("d6")
 action(central,"late_d1_accept","labor");action(central,"late_d1_depart","labor");film(central)
 for key in ["inspect","parts","repair","both"]:action(central,"late_d1_"+key,"junction")
 central.flags.late_d1_evacuated=true;returned(central,"d1")
 action(central,"late_d2_accept","labor");action(central,"late_d2_meter","labor");action(central,"late_d2_nina","life");action(central,"late_d2_repair","labor");action(central,"late_d2_truth","labor");action(central,"late_d2_report","labor");film(central)
 action(central,"late_d3_accept","labor");action(central,"late_d3_depart","labor");film(central);action(central,"late_d3_street","east_district");action(central,"late_relay_depart","starcity");film(central);action(central,"late_d3_relay","relay");action(central,"late_d3_report","labor");film(central)
 check(central.Campaign.Complete.completed_route(central),"d6 has its own continuing route")
 for s in [comm,sech,central]:
  action(s,"late_north_contact",s.Campaign.Complete.home(s));film(s)
  action(s,"late_star_request","starcity");film(s)
  check(not s.Campaign.available(s,"late_star_decontam"),"a family claim and letter do not bypass verified repair")
  for key in ["late_relay_isolate","late_relay_cable","late_relay_calibrate","late_relay_wind"]:action(s,key,"relay")
  var selected=s.equipped_weapon();action(s,"late_star_decontam","starcity");film(s)
  check(not s.has("revolver") and s.f("late_arms_deposited"),"actual weapons are held during admission")
  action(s,"late_identity","star_interior");check(not s.Campaign.available(s,"late_father_photo"),"missing photograph does not become a fictional option")
  action(s,"late_father_meet","star_interior");film(s)
  for key in ["late_work_brief","late_lab_isolate","late_lab_reference"]:action(s,key,"star_interior");film(s)
  action(s,"late_archive","star_interior");action(s,"late_father_truth","star_interior");film(s)
  action(s,"late_sheltered_probe","east_district");action(s,"late_weather_review","star_interior");action(s,"late_network_plan","star_interior");film(s)
  check(not s.ending and "方案" in s.objective(),"reunion continues to actual final preparation")
  action(s,"late_star_exit","star_interior");film(s);check(s.has("revolver") and s.equipped_weapon()==selected,"leaving returns the original weapon and selected slot")
 var base=comm.serialize().duplicate(true)
 for mode in ["shared","central","distributed","watch"]:
  var s=Story.new();s.restore(base)
  action(s,"late_plan_"+mode,"star_interior");check(not s.ending and not s.f("late_final_started"),"choosing a plan does not prematurely end the game")
  action(s,"late_final_confirm","star_interior");film(s)
  var floors={"late_shared_packet":"star_interior","late_shared_receiver":"junction","late_shared_evac":"relay","late_central_agreement":"star_interior","late_central_train":"junction","late_central_alarm":"relay","late_distributed_copy":"star_interior","late_distributed_modules":"relay","late_distributed_handover":"junction","late_watch_power":"relay","late_watch_shift":"junction","late_watch_broadcast":"star_interior"}
  for key in s.Campaign.Complete.data().endings["warning_"+mode].steps:action(s,key,floors[key])
  if mode=="shared":check(not s.f("late_final_execution_done"),"shared route waits for the real escort");s.flags.late_final_execution_done=true
  action(s,"late_finish","star_interior");film(s)
  check(s.ending and s.f("late_campaign_complete") and s.flags.campaign_ending=="warning_"+mode,"complete executed ending "+mode)
  check(s.flags.get("failed_quests",{}).is_empty(),"ending does not fail unrelated optional stories")
 print("COMPLETE_CAMPAIGN_RESULT checks=",checks," failures=",failures);quit(1 if failures else 0)
