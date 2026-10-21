extends SceneTree
const Story=preload("res://scripts/story.gd")
const Campaign=preload("res://scripts/campaign.gd")
const Comic=preload("res://scripts/comic.gd")
const Store=preload("res://scripts/save_store.gd")
var checks=0
var failures=0
func _initialize():call_deferred("run")
func check(ok:bool,msg:String):
 checks+=1
 if not ok:failures+=1;push_error(msg)
func act(s,key:String):
 s.act("c_"+key);check(s.last_action_valid,"allowed: "+key)
func roundtrip(s):
 var t=Story.new();t.restore(JSON.parse_string(JSON.stringify(s.serialize())));t.context=s.context.duplicate(true)
 check(JSON.parse_string(JSON.stringify(t.flags))==JSON.parse_string(JSON.stringify(s.flags)),"exact chapter flags roundtrip")
 return t
func walk(s,sequence:String,wanted:String=""):
 Comic.start(s,sequence);var guard=0
 while s.flags.comic.active and guard<50:
  var p=Comic.panel(s);check(not p.is_empty(),"resolved panel "+str(s.flags.comic.node))
  if p.is_empty():break
  check(ResourceLoader.exists("res://assets/cinematics/"+p.art+".png"),"illustration "+p.art)
  if p.get("music","")!="":check(ResourceLoader.exists("res://assets/audio/"+p.music+".wav"),"score "+p.music)
  var index=-1
  if p.has("choices"):
   index=0
   for i in p.choices.size():
    if p.choices[i].next==wanted:index=i
  Comic.choose(s,index);guard+=1;s=roundtrip(s)
 check(guard<50 and not s.flags.comic.active,"finite branch "+sequence)
 return s
func run():
 var s=Story.new();s.context.floor="commune"
 s.act("c_anna_accept");check(not s.last_action_valid,"Anna does not begin with an unsolicited rescue commission")
 act(s,"anna_lesson");s=walk(s,"anna_class")
 check(s.f("anna_lesson_seen") and not s.f("anna_request"),"classroom acquaints player without autoaccepting quest")
 act(s,"anna_accept");act(s,"anna_records")
 check(not Campaign.available(s,"anna_warning"),"mine crisis waits for first visit and real field experience")
 s.context.floor="coal";s.flags.coal_access=true
 for key in ["coal_register","coal_archive","coal_medic","coal_brother"]:act(s,key)
 s.context.floor="commune";act(s,"anna_result");s=walk(s,"anna_first_letter")
 check(s.f("anna_first_news") and not s.f("anna_outcome_done"),"first verified news is not the rescue conclusion")
 s.flags.chapter_first_field=true;act(s,"anna_warning");s=walk(s,"anna_warning_letter")
 # All eight combinations have a safe pause; inadequate preparation never silently kills Anna.
 for mask in 8:
  var t=roundtrip(s);t.context.floor="coal";t.flags.anna_rescue_started=true
  var flags=["rescue_medic_ready","rescue_transport_ready","rescue_route_ready"]
  for i in 3:t.flags[flags[i]]=bool(mask&(1<<i))
  Comic.start(t,"rescue_review");var choices=Comic.panel(t).choices
  check(choices.any(func(c):return c.next=="rescue_wait"),"can postpone for preparation "+str(mask))
  check(choices.any(func(c):return c.next=="rescue_safe_start")== (mask==7),"safe route reflects all actual preparation "+str(mask))
  check(choices.any(func(c):return c.next=="rescue_risk_confirm")== (mask!=7),"risk is never misrepresented as safe "+str(mask))
  t=walk(t,"rescue_review","rescue_wait");check(not t.f("anna_dead") and not t.f("anna_outcome_done"),"reading/pausing never advances death "+str(mask))
 # Recover every missing preparation onsite with zero money and no medicine item.
 var safe=roundtrip(s);safe.context.floor="coal";safe.flags.anna_rescue_started=true;safe.economy.military=0;safe.economy.goods={}
 for key in ["rescue_onsite_medic","rescue_onsite_transport","rescue_air_map","rescue_air_open"]:act(safe,key)
 safe=walk(safe,"rescue_review","rescue_safe_start")
 check(safe.f("anna_alive") and safe.f("anna_outcome_done") and not safe.f("anna_dead"),"prepared rescue saves Anna without money or vitamin gate")
 safe.context.floor="commune";act(safe,"anna_return_life");safe=walk(safe,"anna_living_lesson")
 check(safe.f("anna_aftermath_done") and not safe.ending,"survival includes an aftermath and remains playable")
 var tragic=roundtrip(s);tragic.context.floor="coal";tragic.flags.anna_rescue_started=true
 Comic.start(tragic,"rescue_review");var choices=Comic.panel(tragic).choices
 for i in choices.size():
  if choices[i].next=="rescue_risk_confirm":Comic.choose(tragic,i);break
 check(not tragic.f("anna_dead") and Comic.panel(tragic).choices.size()==2,"risk requires a second explicit informed confirmation")
 tragic=walk(tragic,"rescue_risk_confirm","rescue_bad_start")
 check(tragic.f("anna_dead") and not tragic.f("anna_alive") and not tragic.ending,"tragic outcome is distinct and cannot terminate main story")
 tragic.context.floor="commune";act(tragic,"anna_memorial");tragic=walk(tragic,"anna_memorial","anna_account_family")
 check(tragic.f("anna_aftermath_done") and tragic.f("anna_record_family"),"tragedy includes family's decision about the record")
 check(not Campaign.available(tragic,"anna_return_life") and not Campaign.available(tragic,"anna_accept"),"dead Anna cannot offer living dialogue")
 # Two complete faction paths, with serialized mission states, non-farmable resources and late Star gate.
 for faction in ["commune","sech"]:
  s=Story.new();s.context.floor=faction;s.flags[faction+"_member"]=true;s.flags[faction+"_joined"]=true;s.flags.radio_fixed=true;s.flags.north_done=true;s.flags.star_known=true
  s.give("mask");s.give("filter");var prefix="c" if faction=="commune" else "s"
  check(not Campaign.available(s,faction+"_star"),"early radio/chores cannot bypass long mainline "+faction)
  for num in range(1,4):
   var id=prefix+str(num);act(s,"field_"+id+"_accept");act(s,"field_"+id+"_depart")
   s=walk(s,id+"_intro");check(s.flags.next_facility=="railfront","sortie reaches playable map")
   s.context.floor="railfront";act(s,"front_supply");var ammo=s.economy.handmade
   s.act("c_front_supply");check(not s.last_action_valid and s.economy.handmade==ammo,"one supply parcel per sortie")
   act(s,"front_read_routes");s.act("c_front_take_evidence");check(not s.last_action_valid,"evidence remains behind actual first encounter")
   s.flags["battle_"+id+"_west"]=true;act(s,"front_take_evidence");s=walk(s,"field_"+id+"_interlude")
   s.act("c_front_restore_signal");check(not s.last_action_valid,"north signal waits for second encounter")
   s.flags["battle_"+id+"_north"]=true;act(s,"front_restore_signal");s=roundtrip(s)
   act(s,"front_return");check(s.flags.next_sequence=="front_back_"+faction,"retreat remembers sponsoring faction")
   s.context.floor=faction;act(s,"field_"+id+"_report");var reward=s.economy.military
   s.act("c_field_"+id+"_report");check(not s.last_action_valid and s.economy.military==reward,"single mission reward")
   s=walk(s,id+"_after");check(not s.ending,"membership fieldwork never produces premature ending")
   if num<3:check(not Campaign.available(s,faction+"_star"),"north remains later than sortie "+id)
  act(s,"north_inquiry");check(Campaign.available(s,faction+"_star"),"supported perimeter travel after all three main sorties "+faction)
  var opposite="sech_stay" if faction=="commune" else "commune_stay"
  s.act("c_"+opposite);check(not s.last_action_valid,"no casual dual membership")
  act(s,"cross_contact");check(Campaign.available(s,faction+"_"+("sech" if faction=="commune" else "commune")),"specific sponsored cross-faction visit")
 # No state may accidentally open archived research interior.
 check(not Campaign.data().unreleased_star_actions.is_empty(),"interior retains explicit unreleased action list")
 for key in Campaign.data().unreleased_star_actions:check(not Campaign.available(s,key),"interior closed "+key)
 var legacy=s.serialize().duplicate(true);legacy.content_revision=20;legacy.flags.anna_reunited=true;legacy.items.append("photo")
 var migrated=Story.new();migrated.restore(legacy)
 check(migrated.f("anna_first_news") and migrated.has("photo") and not migrated.f("anna_dead"),"legacy visit becomes earlier chapter without loss or forced tragedy")
 # Every new authored link resolves, and every choice has a non-empty natural-language consequence.
 for key in Comic.authored():
  var q:Dictionary=Comic.authored()[key]
  for c in q.get("choices",[]):check(Comic.authored().has(c.next) or Campaign.data().panels.has(c.next) or Comic.PANELS.has(c.next),"panel link "+key+" -> "+c.next)
 print("CHAPTER_V22_RESULT checks=",checks," failures=",failures);quit(0 if failures==0 else 1)
