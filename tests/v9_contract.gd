extends SceneTree
const Story=preload("res://scripts/story.gd")
const Journal=preload("res://scripts/journal.gd")
const Campaign=preload("res://scripts/campaign.gd")
var checks=0
var failures=0
func _initialize():call_deferred("run")
func check(ok:bool,why:String):
 checks+=1
 if not ok:failures+=1;push_error(why)
func frames(n:int):
 for i in n:await physics_frame
func act(s,key:String):
 s.act("c_"+key);check(s.last_action_valid,"allowed "+key)
 var restored=Story.new();restored.restore(JSON.parse_string(JSON.stringify(s.serialize())));restored.context=s.context.duplicate(true)
 check(JSON.parse_string(JSON.stringify(restored.flags))==JSON.parse_string(JSON.stringify(s.flags)) and JSON.parse_string(JSON.stringify(restored.economy))==JSON.parse_string(JSON.stringify(s.economy)),"exact state after save "+key)
func run():
 var s=Story.new();s.Comic.start(s,"intro");var nodes=[]
 while s.flags.comic.active:
  var p=s.Comic.panel(s);nodes.append(s.flags.comic.node)
  check(ResourceLoader.exists("res://assets/cinematics/"+p.art+".png"),"prologue illustration exists")
  s.Comic.choose(s,0 if p.has("choices") else -1)
 check(nodes.slice(0,3)==["history_war","history_family","history_years"],"new journey explains war and family before waking")
 check(s.f("intro_done") and s.economy.goods.bread==2,"prologue preserves initial rations")
 s=Story.new();s.context.floor="life";s.route="hatch"
 check(not s.view("exit").options[0].enabled,"unprotected exit is blocked")
 s.economy.military=8;s.act("buy_protection")
 check(s.last_action_valid and s.has("mask") and s.has("filter") and s.economy.military==0,"supply sells matching protection once")
 check(s.view("exit").options[0].enabled,"equipped solo route remains reachable")
 s=Story.new();s.flags.igor_suspicious=true;s.economy.military=0
 for key in ["igor_work","igor_lamp","igor_done"]:s.act(key);check(s.last_action_valid,"no money alternative: "+key)
 check(s.f("igor_settled"),"short chore settles guard without spending required items")
 s.act("igor_done");check(not s.last_action_valid,"guard cannot demand repeat payment")
 # Rejected tasks remain visible, cannot pay out, and cannot block another main line.
 s=Story.new();s.context.floor="waterworks";act(s,"mail_accept");s.Progression.fail(s,["waterworks"],"小队已经离开")
 var task=Journal.tasks(s).filter(func(t):return t.id=="last_mail")[0]
 check(task.failed and task.status=="已失败" and task.step.contains("离开"),"failed side task retains a reason in journal")
 s.act("c_mail_clue");check(not s.last_action_valid,"failed job cannot continue or farm rewards")
 # Three distinct resource-free main chains, five new conclusions.
 var paths=[
 ["commune",["workers_accept","workers_draft","workers_coal"],"coal",["workers_sign","workers_return"],"commune",["workers_deliver"],["ending_workers"]],
 ["sech",["north_accept","north_record","north_chock","north_axle","north_verify"],"sech",[],"sech",[],["ending_train","ending_caravan"]],
 ["starcity",["weather_accept","weather_clock","weather_power","weather_test","weather_return"],"starcity",[],"starcity",[],["ending_weather"]]]
 for path in paths:
  s=Story.new();s.economy.military=0;s.economy.goods={};s.context.floor=path[0];s.flags.star_registered=true;s.flags.father_met=true;s.flags.radio_fixed=true
  for key in path[1]:act(s,key)
  s.context.floor=path[2]
  for key in path[3]:act(s,key)
  s.context.floor=path[4]
  for key in path[5]:act(s,key)
  for ending in path[6]:
   var t=Story.new();t.restore(s.serialize());t.context=s.context.duplicate();act(t,ending);check(t.ending,"new ending reached: "+ending)
 s=Story.new();s.context.floor="waterworks"
 for key in ["pressure_copy_accept","pressure_copy_inspect","pressure_copy_compare","pressure_copy_return"]:act(s,key)
 s.context.floor="coal"
 for key in ["names_accept","names_archive","names_tags","names_return"]:act(s,key)
 s.context.floor="starcity";s.flags.father_met=true
 for key in ["archive_labels_accept","archive_labels_inspect","archive_labels_compare","archive_labels_return","ending_records"]:act(s,key)
 check(s.ending and s.flags.campaign_ending=="records","combined evidence ending requires three different completed chains")
 for chain in [["commune","medicine_seal"],["coal","mine_air"]]:
  s=Story.new();s.context.floor=chain[0]
  for suffix in ["_accept","_inspect","_compare","_return"]:act(s,chain[1]+suffix)
  check(Journal.tasks(s).any(func(t):return t.id==chain[1] and t.done),"new optional chain reaches real completion")
 s=Story.new();s.context.floor="commune"
 act(s,"anna_accept");act(s,"anna_records");s.flags.brother_found=true
 act(s,"commune_coal");s.context.floor="coal";act(s,"coal_return");s.context.floor="commune";act(s,"commune_coal")
 check(s.last_action_valid,"completed main investigation does not strand unfinished coal side tasks")
 check(Campaign.data().endings.size()==14,"fourteen conclusions are authored")
 s=Story.new();s.context.floor="sech";s.flags.star_known=true
 check(not s.view("sech_sergey").options.any(func(o):return o.key=="c_sech_father" and o.enabled),"father-specific question is knowledge gated")
 act(s,"sech_visitors");check(s.last_reply.contains("登记") and not s.last_reply.contains("父亲"),"open visitor question gets a matching answer")
 # Real moving door, physical distraction, return inspection and settlement.
 var w=load("res://scenes/d6.tscn").instantiate();root.add_child(w);current_scene=w;await frames(8)
 w.story.flags.intro_done=true;w.hud.comic_active=false;w.hud.close();w.story.flags.side=true;w.phase=8
 w.interact("side");check(not w.waiting_shift and not w.story.f("side_pass"),"yellow alone never lets the player break in under guard's eyes")
 w.npcs.igor.set_physics_process(false);w.npcs.igor.position=Vector3(2.8,0,1.4);w.story.flags.guard_task=true;w.refresh_guard_context();w.interact("side")
 check(w.waiting_shift and w.story.guard_clear(),"physical line-of-sight distraction unlocks waiting")
 w.phase=8;await frames(16)
 check(w.side_mesh.visible and w.side_mesh.position.y>1.02 and w.side_mesh.position.y<3.32 and not w.side_body.disabled,"door is visibly part-open with moving collision")
 await frames(60);w.story.flags.guard_task=false;w.npcs.igor.position=Vector3(6.3,0,6.6);w.player.position=Vector3(11,.04,4.5);await frames(65)
 check(w.story.f("igor_suspicious") and w.side_mesh.visible and absf(w.side_mesh.position.y-1.02)<.02,"returning guard closes door and becomes suspicious")
 w.story.act("inner_return");await frames(65)
 check(w.story.f("side_inside_release") and w.side_mesh.position.y>3.2,"inside safety latch prevents an unequipped explorer being trapped")
 w.player.position=Vector3(7.5,.04,4.5);await frames(65)
 check(not w.story.f("side_inside_release") and w.side_mesh.position.y<1.1,"safety release closes after returning west")
 check(w.story.view("igor").body.contains("老谢") and w.story.view("igor").body.contains("三发"),"guard's reaction connects suspicion, family and compensation")
 w.hud.show_dialogue("semyon");check(w.hud.typing.size()>1,"multiple speech blocks queued")
 w.hud.advance_typing(.1)
 check(w.hud.typing[0].label.visible_characters>0 and w.hud.typing[1].label.visible_characters==0,"speech blocks reveal strictly in order")
 w.hud.finish_typing();check(w.hud.typing.is_empty(),"skip text reveals every pending block")
 w.hud.close();w.story.act("search_box")
 check(w.hud.receipt_timers.size()>0 and w.hud.highlight_items("获得防毒面具").contains("[color="),"item changes show receipts and highlighted names")
 w.story.flags.nina_job=true;w.story.route="shift";w.story.give("mask");w.story.give("filter");w.pending_route="shift";w.hud.show_departure(false)
 var confirmed=false
 for button in w.hud.modal.find_children("*","Button",true,false):
  if button.text=="确认出发":button.pressed.emit();confirmed=true;break
 check(confirmed and w.story.flags.get("failed_quests",{}).has("pressure"),"confirmed departure fails unresolved D-6 side work")
 check(not w.story.departure_checkpoint.flags.get("failed_quests",{}).has("pressure"),"return checkpoint retains pre-departure tasks instead of permanent failure")
 w.queue_free();await frames(3)
 print("V9_RESULT checks=",checks," failures=",failures)
 quit(0 if failures==0 else 1)
