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
func restored(s):
	var next=Story.new();next.restore(JSON.parse_string(JSON.stringify(s.serialize())));next.context=s.context.duplicate(true)
	return next
func run():
	var flows=[
		["waterworks","last_mail",["mail_accept","mail_clue","mail_wrong","mail_take","mail_return"],2],
		["waterworks","spare_seals",["seal_accept","seal_measure","seal_wrong","seal_pick","seal_return"],3],
		["commune","commune_press",["press_accept","press_ledger","press_private","press_deliver"],4],
		["commune","mushroom_light",["grow_accept","grow_read","grow_wrong","grow_shade","grow_return"],0],
		["sech","sech_watch",["watch_accept","watch_map","watch_wrong","watch_set","watch_stop","watch_return"],4],
		["sech","sech_books",["sech_books","books_read","books_fire","books_dry","books_return"],2],
		["coal","coal_linen",["linen_accept","linen_tags","linen_wrong","linen_sort","linen_return"],0],
		["coal","coal_names",["names_accept","names_archive","names_tags","names_return"],3]]
	for flow in flows:
		var s=Story.new();s.context.floor=flow[0]
		var prerequisites={"last_mail":"plant_diagram","spare_seals":"plant_bled","commune_press":"greenhouse_fixed","mushroom_light":"greenhouse_fixed","coal_linen":"brother_care","coal_names":"linen_done","father_letters":"father_answered"}
		if prerequisites.has(flow[1]):s.flags[prerequisites[flow[1]]]=true
		if flow[1]=="father_letters":s.flags.father_met=true;s.flags.star_access=true
		if flow[1]=="sech_watch":s.act("c_watch_brief");check(s.last_action_valid and not s.f("watch_job"),"hear patrol problem before choosing whether to help")
		check(not Journal.tasks(s).any(func(t):return t.id==flow[1]),"unaccepted quest hidden: "+flow[1])
		s.act("c_"+flow[2][-1]);check(not s.last_action_valid,"cannot claim before completing work: "+flow[1])
		for index in flow[2].size():
			var action:String=flow[2][index]
			s.act("c_"+action);check(s.last_action_valid,"authored solution actually works: "+action)
			s=restored(s)
			var task=Journal.tasks(s).filter(func(t):return t.id==flow[1])
			check(task.size()==1 and task[0].done==(index==flow[2].size()-1),"journal state survives save mid-quest: "+action)
			check(not Journal.leads(s).has(Campaign.data().quests.filter(func(q):return q.id==flow[1])[0].lead),"accepted work stops showing as an unaccepted hint")
		check(s.economy.military==18+flow[3],"exact one-time ammunition reward: "+flow[1])
		var economy=JSON.stringify(s.economy);var flags=JSON.stringify(s.flags)
		s.act("c_"+flow[2][-1]);check(not s.last_action_valid and JSON.stringify(s.economy)==economy and JSON.stringify(s.flags)==flags,"save/reload cannot farm turn-in: "+flow[1])
		check(s.economy.health==100 and s.economy.food==60,"optional work does not silently rebalance survival stats")
	# Both political choices are playable, preserve privacy and exclude one another.
	for choice in ["press_private","press_public"]:
		var s=Story.new();s.context.floor="commune";s.flags.greenhouse_fixed=true
		for key in ["press_accept","press_ledger",choice,"press_deliver"]:s.act("c_"+key);check(s.last_action_valid,"press choice reaches a real turn-in: "+key)
		s.act("c_"+("press_public" if choice=="press_private" else "press_private"));check(not s.last_action_valid,"press identity choice is mutually exclusive")
	var s=Story.new();s.context.floor="starcity";s.flags.father_met=true;s.flags.star_access=true;s.flags.father_answered=true
	for key in ["letter_accept","letter_read","letter_note","letter_plain"]:
		s.act("c_"+key);check(not s.last_action_valid,"archived internal letter task cannot be advanced from outside")
	# A late clue and reward are rejected on another facility, even if the UI is bypassed.
	s.context.floor="sech";s.act("c_tape_read");check(not s.last_action_valid,"remote facility action rejected")
	s=Story.new();s.context.floor="commune";s.give("frequency");s.flags.signal_heard=true
	var answer=s.act("c_commune_route")
	check(answer.contains("星城") and answer.contains("呼号") and answer.contains("不能") and answer.contains("姓名"),"Elena answers the exact call-sign question and admits her knowledge limit")
	check(Campaign.data().interactions.commune_leader.body.contains("推翻") and Campaign.data().interactions.commune_leader.body.contains("中央苏维埃"),"commune opposition is explicit in the encounter")
	check(Campaign.data().interactions.coal_clerk.body.contains("中央苏维埃") and Campaign.data().interactions.sech_elder.body.contains("哥萨克"),"D-6 jurisdiction and Cossack identity are stated")
	var parts=s.Conversation.split_text("电台亮了。\n谢尔盖：「星城还在。」\n东方-7 值班员：「请报姓名。」","sech_radio")
	check(parts.size()==3 and parts[1].name=="谢尔盖" and parts[2].name=="东方-7 值班员","radio conversation attributes each quotation to its own speaker")
	var legacy=s.serialize().duplicate(true);legacy.content_revision=7;legacy.flags.c_done_mail_return=true
	legacy.conversations={"commune_leader":[{"speaker":"commune_leader","text":"旧问答记录"}]}
	s=Story.new();s.restore(legacy);s.context.floor="commune"
	check(Campaign.available(s,"commune_route") and s.f("c_done_mail_return"),"old save reopens corrected information while preserving reward locks")
	check(s.conversations.commune_leader[0].text=="旧问答记录" and s.conversations.commune_leader.size()==2,"old witnessed conversation retained with a correction note")
	s.act("c_commune_route");s=restored(s)
	check(not Campaign.available(s,"commune_route"),"corrected answer is one-shot again after a v8 save")
	check(s.economy.military==legacy.economy.military and s.items==legacy.items,"dialogue migration does not grant or remove inventory")
	# Real UI button dispatch: different questions must keep their own key and reply.
	var w=load("res://scenes/commune.tscn").instantiate();root.add_child(w);current_scene=w
	for i in 8:await physics_frame
	w.story.flags.intro_done=true;w.hud.comic_active=false;w.hud.close();w.story.give("frequency");w.story.flags.signal_heard=true
	w.story.flags.first_meeting_commune_leader=2;w.hud.show_dialogue("commune_leader")
	for expected in [["c_commune_route","星城"],["c_commune_politics","守备"]]:
		var option=w.story.view("commune_leader").options.filter(func(o):return o.key==expected[0])[0]
		var found=false
		var b=load("res://tests/ui_test_driver.gd").option(w.hud,option.text)
		if is_instance_valid(b):b.pressed.emit();found=true
		check(found and w.story.last_reply.contains(expected[1]),"real question button selects its own answer: "+expected[0])
		var transcript=w.story.conversations.commune_leader
		check(transcript.any(func(e):return e.speaker=="ivan" and e.text==option.text.trim_prefix("「").trim_suffix("」")),"player question is recorded beside the corresponding answer")
		check(not w.story.view("commune_leader").options.any(func(o):return o.key==expected[0] and o.enabled),"answered one-shot topic cannot repeat-click")
	w.queue_free();for i in 3:await physics_frame
	print("EXPLORATION_RESULT checks=",checks," failures=",failures)
	quit(0 if failures==0 else 1)
