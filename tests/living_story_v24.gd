extends SceneTree
const Story=preload("res://scripts/story.gd")
const Campaign=preload("res://scripts/campaign.gd")
var checks=0
var failures=0
func _initialize():call_deferred("run")
func check(ok:bool,msg:String):
 checks+=1
 if not ok:failures+=1;push_error(msg)
func act(s,key:String):
 s.act("c_"+key);check(s.last_action_valid,"authorized phase "+key+" / "+s.last_reply.left(50))
func panels(s,key:String,choice:int=0):
 s.Comic.start(s,key);var n=0
 while s.flags.comic.active and n<20:
  var p=s.Comic.panel(s);check(not p.is_empty(),"real illustrated panel "+str(s.flags.comic.node))
  check(ResourceLoader.exists("res://assets/cinematics/"+p.get("art","")+".png"),"matching illustration")
  s.Comic.choose(s,choice if p.has("choices") else -1);n+=1
 check(n<20 and not s.ending,"returns to exploration without premature ending")
func roundtrip(s):
 var t=Story.new();t.restore(JSON.parse_string(JSON.stringify(s.serialize())));t.context=s.context.duplicate(true);return t
func run():
 var s=Story.new();s.context.floor="commune";s.flags.anna_lesson_seen=true
 check(not Campaign.available(s,"anna_accept"),"school introduction doesn't silently offer the brother investigation")
 act(s,"anna_walk_invite");check(not Campaign.available(s,"anna_walk_talk"),"conversation waits for actual arrival")
 s=roundtrip(s);check(s.f("anna_walk_started") and not s.f("anna_request"),"walking invitation is persistent, separate from investigative consent")
 s.flags.anna_walk_arrived=true;act(s,"anna_walk_talk");panels(s,"anna_supper",1)
 check(s.f("anna_conversation_ready") and not s.f("anna_request"),"dreams and flaws precede the explicit request")
 act(s,"anna_accept")
 check(preload("res://scripts/journal.gd").tasks(s).any(func(q):return q.id=="anna" and q.kind=="支线"),"Anna investigation is correctly categorized as an optional character story")
 s.flags.moro_known=true;s.flags.memory_known=true
 check(not Campaign.available(s,"moro_accept") and not Campaign.available(s,"memory_accept"),"one long branch at a time, no task dump")
 s.flags.anna_first_news=true;check(Campaign.available(s,"moro_accept"),"resolved phase releases next character's offer")
 for concession in 2:
  var t=roundtrip(s);act(t,"moro_accept")
  check(not Campaign.available(t,"moro_parts"),"can't repair without Moro physically there")
  t.flags.moro_at_workshop=true;act(t,"moro_parts");t.flags.moro_at_boiler=true;act(t,"moro_power_plan")
  act(t,"moro_repair");t.flags.moro_at_guard=true;act(t,"moro_permission")
  check(not t.f("moro_schedule"),"opening negotiation is not automatic consent")
  panels(t,"moro_council",concession)
  check(t.f("moro_schedule") and t.f("moro_terms_agreed"),"both negotiated concessions remain viable")
  for key in ["moro_listeners","moro_paper","moro_poster_people"]:act(t,key)
  check(not Campaign.available(t,"moro_public"),"rehearsal precedes public performance")
  t.flags.moro_at_stage=true;act(t,"moro_rehearse");panels(t,"moro_rehearsal",concession)
  check(Campaign.available(t,"moro_public") and Campaign.available(t,"moro_private"),"rehearsal retains public/private choice")
  act(t,"moro_public");t.Comic.start(t,"moro_public_night")
  var performance=t.Comic.panel(t).body
  check(performance.contains("关掉扩音设备") if concession==0 else performance.contains("晚班完成交接"),"negotiated terms appear in the real performance")
  check(performance.contains("孩子已经睡着") if concession==0 else performance.contains("没有替任何人保证将来"),"rehearsal feedback changes actual lyrics")
  panels(t,"moro_public_night");act(t,"moro_thanks")
  var reward=t.economy.handmade;t.act("c_moro_thanks");check(not t.last_action_valid and t.economy.handmade==reward,"no duplicate performance reward")
 s=Story.new();s.context.floor="railfront";s.flags.sided_veteran=true;s.flags.field_mission="c1"
 act(s,"veteran_defense_accept");check(not Campaign.available(s,"veteran_defense_finish"),"acceptance cannot complete defense")
 s.flags.veteran_defense_safe=true;act(s,"veteran_defense_finish");panels(s,"veteran_shelter")
 check(s.f("veteran_defense_done") and not s.ending,"shared defense leaves a playable aftermath")
 var old=Story.new();old.flags.anna_request=true;old.flags.moro_schedule=true;old.flags.moro_booked=true
 var saved=old.serialize();saved.content_revision=22;s=Story.new();s.restore(saved)
 check(s.f("anna_conversation_ready") and s.f("moro_terms_agreed") and s.f("moro_rehearsed"),"legacy accepted/completed phases preserved without stripping progress")
 for id in Campaign.data().interactions:
  var v=s.view(id);check(v.has("options"),"all views still render "+id)
 print("LIVING_STORY_V24_RESULT checks=",checks," failures=",failures);quit(0 if failures==0 else 1)
