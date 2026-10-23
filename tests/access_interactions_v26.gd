extends SceneTree
const Story=preload("res://scripts/story.gd")
const Regions=preload("res://scripts/interaction_regions.gd")
const Journal=preload("res://scripts/journal.gd")
var checks=0
var failures=0
func _initialize():call_deferred("run")
func check(ok:bool,why:String):
	checks+=1
	if not ok:failures+=1;push_error(why)
func frames(n:int=4):
	for i in n:await physics_frame
func suspend(w):
	w.set_physics_process(false);w.player.set_physics_process(false)
	for npc in w.npcs.values():npc.set_physics_process(false)
	w.story.flags.intro_done=true;w.story.flags.comic={"active":false};w.hud.comic_active=false;w.hud.close()
func rejected(s,key:String):
	var before=JSON.stringify(s.serialize())
	s.act("c_"+key)
	check(not s.last_action_valid and before==JSON.stringify(s.serialize()),"unauthorised action has no state/resource side effects: "+key)
func run():
	# Every former public-return bypass is checked at action execution.
	for route in ["hatch","permit","shift","official"]:
		var s=Story.new();s.route=route;s.context.floor="commune"
		if route=="official":s.flags.sided_veteran=true
		s.flags.merge({"anna_request":true,"anna_records":true,"workers_draft":true,"anna_warning_seen":true,"d6_returned":true,"departure_official":true,"return_questioned":true,"return_audited":true,"coal_access":true},true)
		s.give("transit_pass")
		check(not s.Campaign.Access.public_entry(s),"old stamps do not erase the actual departure history: "+route)
		for key in ["commune_coal","workers_coal","anna_rescue_depart"]:rejected(s,key)
		s.context.floor="labor"
		for key in ["return_official","return_explain","return_witness","return_audit","return_limited","enter_coal","return_filters","return_assignment","coal_back_d6"]:rejected(s,key)
		check(not s.Chapter.home_access(s),"wanted identity cannot reach the life floor")
		var view=s.view("d6_return_desk")
		check(view.options.filter(func(o):return o.enabled).size()==1 and view.options.any(func(o):return o.key=="c_d6_withdraw" and o.enabled),"stranded old save has an exit, without false permission")
		s.act("c_d6_withdraw");check(s.last_action_valid and s.flags.next_sequence=="d6_checkpoint_withdraw","withdrawal remains available after a declined entry")
		for sequence in ["coal_road","coal_descent","coal_exit_to_d6","coal_return_d6","anna_rescue_road"]:
			s.Comic.start(s,sequence);var p=s.Comic.panel(s)
			check(p.get("end","")=="map:commune" and not p.has("next"),"legacy queued journey cannot enter D-6: "+sequence)
			s.Comic.choose(s);check(s.flags.next_facility=="commune" and not s.ending,"rejected journey safely returns to playable commune")
		s.context.floor="coal";s.flags.brother_found=true
		s.act("c_coal_return");check(s.last_action_valid and s.flags.next_sequence=="d6_mine_withdraw","old in-mine save can leave without entering D-6 proper")
		var restored=Story.new();restored.restore(JSON.parse_string(JSON.stringify(s.serialize())))
		check(restored.has("transit_pass") and restored.f("brother_found") and JSON.parse_string(JSON.stringify(restored.economy))==JSON.parse_string(JSON.stringify(s.economy)),"identity correction preserves items, exploration and resources")
	var loyal=Story.new();loyal.route="official";loyal.context.floor="labor";loyal.flags.d6_returned=true;loyal.flags.departure_official=true
	loyal.act("c_return_official");check(loyal.last_action_valid and loyal.f("coal_access"),"loyal soldier is reviewed using D-6's own records")
	loyal.act("c_enter_coal");check(loyal.last_action_valid and loyal.flags.next_sequence=="coal_descent","approved formal mine entry remains playable")
	loyal.flags.d6_cargo_returned=true;check(loyal.Chapter.home_access(loyal),"actual loyal cargo handover still permits going home")
	loyal.flags.anna_records=true;check(not loyal.Campaign.available(loyal,"d6_entry_question"),"loyal approved visitor is not told he needs a clandestine contact")
	for flag in ["commune_member","sech_member","d6_wanted"]:
		loyal.flags[flag]=true;check(not loyal.Campaign.Access.public_entry(loyal) and not loyal.Chapter.home_access(loyal),"prior official departure cannot override later identity: "+flag)
		if flag!="d6_wanted":check(not loyal.view("d6_return_desk").body.contains("擅离记录"),"an opposing-faction restriction does not invent an earlier desertion: "+flag)
		loyal.flags.erase(flag)
	var pending=Story.new();pending.route="hatch";pending.flags.anna_rescue_started=true;pending.flags.c_done_anna_rescue_depart=true;pending.Comic.start(pending,"anna_rescue_road")
	var saved=pending.serialize().duplicate(true);saved.floor="commune"
	var old=Story.new();old.restore(saved)
	check(not old.f("anna_rescue_started") and not old.f("c_done_anna_rescue_depart"),"declining an old pending journey leaves Anna at home rather than stranding her in the mine")
	saved.floor="coal";old.restore(saved);check(old.f("anna_rescue_started"),"already-started in-mine story is not rolled back")
	var clue=Story.new();clue.route="hatch";clue.context.floor="commune";clue.flags.anna_request=true;clue.flags.anna_records=true
	var task=Journal.tasks(clue).filter(func(t):return t.id=="anna")[0]
	check(task.target=="commune_printer" and task.step.contains("不能用于通行") and not task.failed,"journal explains blocked access without failing Anna's quest")
	check(Story.ITEMS.transit_pass[2]!="通行","seeking records are no longer presented as a pass")
	# Real scenes: activity available at many separated, walkable spots in a
	# single room, never from the neighbouring hall or over an NPC/book target.
	for pair in [["commune","commune_hall","commune_member","assembly_done"],["sech","sech_meeting","sech_member","north_job"]]:
		var w=load("res://scenes/"+pair[0]+".tscn").instantiate();root.add_child(w);current_scene=w;await frames();suspend(w);w.story.flags[pair[2]]=true
		var id:String=pair[1];var tested=0
		check(Regions.active(w.story,id),"activity opens only after its required commitment: "+id)
		for p in w.navigation.points.values():
			var pos=Vector3(p.x,.04,p.y)
			if not Regions.contains(w.story,id,pos) or pos.distance_to(w.targets[id].pos)<3.5:continue
			w.player.position=pos;w.find_nearest()
			check(id in w.interaction_candidates,"activity is found away from its original point: "+id)
			tested+=1
			if tested>=12:break
		check(tested==12,"twelve distant walkable participation positions exist: "+id)
		w.player.position=Vector3(.5,.04,-3) if pair[0]=="commune" else Vector3(1,.04,-4)
		w.find_nearest();check(id not in w.interaction_candidates,"no activity prompt through the wall/in adjacent room: "+id)
		w.player.position=Vector3(-3,.04,-6) if pair[0]=="commune" else Vector3(1,.04,-12)
		w.find_nearest();w.chosen_interaction=id;w.find_nearest();w.hud.set_prompt(id)
		check(w.hud.prompt.text.contains("参与区域"),"actual HUD explains area participation: "+id)
		if pair[0]=="commune":
			var npc=w.npcs.commune_leader;w.player.position=npc.position+Vector3(0,0,.9);w.chosen_interaction="";w.find_nearest()
			check("commune_leader" in w.interaction_candidates and id in w.interaction_candidates and w.nearest!="commune_hall","nearby NPC takes priority over the room activity")
			check(w.cycle_interaction(1),"wheel cycling remains available for overlapping activity and NPC")
			w.player.position=Vector3(-3,.04,-6);w.interact(id);w.hud.finish_typing()
			check(w.hud.modal.find_children("*","Button",true,false).any(func(b):return b.text==w.story.Campaign.data().actions.commune_assembly.text),"E opens the actual meeting choice")
			w.perform("c_commune_assembly",id);check(w.story.f("assembly_done"),"meeting completes through the real area interaction")
			w.hud.close();w.player.position=Vector3(-3,.04,-6);w.find_nearest();check(id not in w.interaction_candidates,"completed meeting no longer fills the whole room with prompts")
		w.queue_free();await frames()
	# Scene transitions enforce the same rule even with an old pending destination.
	var w=load("res://scenes/commune.tscn").instantiate();root.add_child(w);current_scene=w;await frames();suspend(w);w.story.route="hatch";w.story.flags.coal_access=true
	for destination in ["life","labor","coal"]:
		w.hud.close();w.travel_campaign(destination)
		check(w.floor_id=="commune" and w.story.flags.comic.sequence=="d6_return_blocked" and not root.get_node("Session").pending.has("floor"),"direct transition rejects unauthorised destination: "+destination)
	w.queue_free();await frames()
	print("ACCESS_INTERACTIONS_V26_RESULT checks=",checks," failures=",failures);quit(0 if failures==0 else 1)
