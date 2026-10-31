extends SceneTree
const Story=preload("res://scripts/story.gd")
const Journal=preload("res://scripts/journal.gd")
var checks=0
var failures=0
func _initialize():call_deferred("run")
func check(ok:bool,why:String):
 checks+=1
 if not ok:failures+=1;push_error(why)
func enabled(s,key:String)->bool:
 return s.view("sech_quartermaster").options.any(func(o):return o.key==key and o.enabled)
func roundtrip(s):
 var restored=Story.new();restored.restore(JSON.parse_string(JSON.stringify(s.serialize())));restored.context=s.context.duplicate();return restored
func run():
 var s=Story.new();s.context.floor="sech";s.FirstMeetings.begin(s,"sech_quartermaster")
 check(not enabled(s,"c_watch_brief") and not enabled(s,"c_watch_accept"),"stranger must first introduce himself, before patrol details or acceptance")
 s.act("meet_sech_quartermaster_name");s.act("meet_sech_quartermaster_topic0")
 check(enabled(s,"c_watch_brief") and not enabled(s,"c_watch_accept"),"acquaintance may ask about patrol work without knowing the specific junction problem")
 var before=s.serialize().duplicate(true);s.act("c_watch_accept")
 check(not s.last_action_valid and s.serialize()==before,"direct acceptance cannot bypass learning about the problem")
 var reply=s.act("c_watch_brief")
 check(s.last_action_valid and reply.contains("分岔口") and reply.contains("塌方") and reply.contains("西北调度"),"Peter explains the junction, actual danger and first destination")
 check(s.f("watch_briefed") and not s.f("watch_job") and not Journal.tasks(s).any(func(t):return t.id=="sech_watch"),"hearing the explanation does not accept a task or create a journal entry")
 s=roundtrip(s);check(enabled(s,"c_watch_accept"),"remembered briefing survives save/load and still permits voluntary acceptance")
 s.act("c_watch_accept");check(s.last_action_valid and s.f("watch_job"),"explicit acceptance starts the quest")
 var task=Journal.tasks(s).filter(func(t):return t.id=="sech_watch")[0]
 check(task.target=="sech_manual" and task.step.contains("西北调度台"),"first current objective points to the actual diagram interaction")
 s.act("c_watch_map");s=roundtrip(s)
 task=Journal.tasks(s).filter(func(t):return t.id=="sech_watch")[0]
 check(task.target=="sech_signal" and task.step.contains("北端站台") and task.step.contains("西线"),"next objective clearly identifies the junction and known safe direction")
 s.act("c_watch_return");check(not s.last_action_valid,"cannot collect patrol reward before fixing signs")
 s.act("c_watch_set");s.act("c_watch_stop");var ammo=s.economy.military;s.act("c_watch_return")
 check(s.last_action_valid and s.f("watch_done") and s.economy.military==ammo+4,"full existing puzzle still grants exactly its original reward")
 s.act("c_watch_return");check(not s.last_action_valid and s.economy.military==ammo+4,"completed job cannot be repeated for reward")
 for progress in ["watch_job","watch_route","watch_ready","watch_done"]:
  var old=Story.new();old.context.floor="sech";old.flags.watch_job=true;old.flags.c_done_watch_accept=true
  if progress!="watch_job":old.flags.watch_route=true
  if progress in ["watch_ready","watch_done"]:old.flags.watch_signal=true;old.flags.watch_ready=true
  if progress=="watch_done":old.flags.watch_done=true;old.flags.c_done_watch_return=true
  old=roundtrip(old)
  check(not old.f("watch_briefed") and not enabled(old,"c_watch_brief"),"legacy task does not require a new introductory conversation: "+progress)
  if progress=="watch_job":old.act("c_watch_map");check(old.last_action_valid,"legacy accepted task can read records immediately")
  if progress=="watch_route":old.act("c_watch_set");old.act("c_watch_stop");check(old.last_action_valid,"legacy investigation can proceed to sign repair")
  if progress=="watch_ready":old.act("c_watch_return");check(old.last_action_valid and old.f("watch_done"),"legacy finished repair can still turn in")
  if progress=="watch_done":check(not enabled(old,"c_watch_accept") and old.view("sech_quartermaster").body.contains("今晚走西线"),"legacy completion shows natural follow-up and no repeat job")
 # Related introductory choices must be grounded in what the NPC has introduced.
 var newcomer=Story.new();newcomer.context.floor="sech"
 var elder=newcomer.view("sech_elder")
 check(elder.body.contains("电台") and elder.body.contains("旧列车"),"elder introduces the two repair opportunities before the player can name either")
 newcomer.context.floor="commune"
 check(not newcomer.Campaign.available(newcomer,"moro_accept"),"music task remains unavailable before Moro shares his plans")
 var music=newcomer.act("c_moro_music")
 check(newcomer.last_action_valid and music.contains("组个乐队") and newcomer.f("moro_known") and not newcomer.f("moro_job"),"asking about guitar music reveals the band plan without autoaccepting its quest")
 # Actual HUD: the undiscovered task choice must be absent, not merely disabled.
 var w=load("res://scenes/sech.tscn").instantiate();root.add_child(w);current_scene=w
 for i in 5:await process_frame
 w.story.flags.intro_done=true;w.story.flags.comic={"active":false};w.hud.comic_active=false;w.hud.close();w.story.flags.first_meeting_sech_quartermaster=2
 w.interact("sech_quartermaster");w.hud.finish_typing()
 var accept_text=Story.Campaign.data().actions.watch_accept.text
 check(not w.hud.modal.find_children("*","Button",true,false).any(func(b):return b.text==accept_text),"actual dialogue omits acceptance until explanation has been heard")
 w.perform("c_watch_brief","sech_quartermaster");w.hud.finish_typing()
 check(is_instance_valid(load("res://tests/ui_test_driver.gd").option(w.hud,accept_text)),"actual dialogue offers explicit acceptance after Peter's explanation has been read")
 check(not w.story.f("watch_job") and w.story.conversations.sech_quartermaster.any(func(e):return e.text.contains("分岔口")),"HUD records the actual explanation but leaves task unaccepted")
 w.queue_free()
 for i in 3:await process_frame
 print("WATCH_DIALOGUE_V26_RESULT checks=",checks," failures=",failures);quit(0 if failures==0 else 1)
