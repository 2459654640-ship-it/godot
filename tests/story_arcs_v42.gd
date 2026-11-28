extends SceneTree

const Story=preload("res://scripts/story.gd")
var failures=0
var checks=0

func _initialize():
	call_deferred("run")

func check(ok:bool,why:String):
	checks+=1
	if not ok:
		failures+=1
		push_error(why)

func step(s,key:String,floor:String):
	s.context.floor=floor
	s.act("c_"+key)
	check(s.last_action_valid,"available "+key+" at "+floor)

func film(s,selected_flag:String=""):
	var id:String=s.flags.get("next_sequence","")
	s.flags.erase("next_sequence")
	check(id!="","cinematic entered")
	if id=="":return
	s.Comic.start(s,id)
	var seen:Array[String]=[]
	while s.flags.comic.active and seen.size()<20:
		var node:String=s.flags.comic.node
		var p:Dictionary=s.Comic.panel(s)
		check(not p.is_empty(),"authored node "+node)
		if p.is_empty():break
		seen.append(node)
		var selected=-1
		if p.has("choices"):
			selected=0
			if selected_flag!="":
				selected=p.choices.find_custom(func(o):return o.get("flag","")==selected_flag)
				check(selected>=0,"choice visible "+selected_flag)
				selected=maxi(selected,0)
		s.Comic.choose(s,selected)
	check(not s.flags.comic.active,"cinematic returned to play "+id)
	s.flags.erase("next_facility")
	s.flags.erase("resume_dialogue")

func check_done(s,id:String,expected:String):
	var rows:Array=s.Campaign.side_tasks(s)
	var own=rows.filter(func(q):return q.id==id)
	check(own.size()==1 and own[0].done and expected in own[0].step,"journal records completed branch "+id)

func finish_d6(s,formal:bool):
	var floor="labor"
	step(s,"arc_d6_offer",floor)
	step(s,"arc_d6_hear",floor);film(s)
	step(s,"arc_d6_patient",floor);film(s)
	step(s,"arc_d6_public" if formal else "arc_d6_private",floor)
	check(not s.Campaign.available(s,"arc_d6_public") and not s.Campaign.available(s,"arc_d6_private"),"one level of consent")
	step(s,"arc_d6_walk",floor)
	check(not s.Campaign.available(s,"arc_d6_visit"),"no cinematic before escort arrives")
	s.flags.arc_d6_at_glass=true
	step(s,"arc_d6_visit",floor);film(s)
	check(s.f("arc_d6_done") and s.f("arc_d6_signed")==formal,"D-6 outcome matches decision")
	check_done(s,"arc_d6","军务处" if formal else "按床号")
	step(s,"arc_d6_followup",floor)
	check(not s.Campaign.available(s,"arc_d6_followup"),"D-6 contact cannot repeat reward")

func finish_sech(s,roster:bool):
	var floor="sech"
	step(s,"arc_sech_offer",floor);film(s)
	step(s,"arc_sech_read",floor)
	step(s,"arc_sech_hold",floor)
	check(not s.f("arc_sech_incoming"),"wrong railway signal has no irreversible effect")
	step(s,"arc_sech_flash",floor)
	step(s,"arc_sech_receive",floor);film(s)
	check(not s.Campaign.available(s,"arc_sech_negotiate"),"waiting for the escorted resident to arrive")
	s.flags.arc_sech_at_bridge=true
	step(s,"arc_sech_negotiate",floor);film(s,"arc_sech_roster" if roster else "arc_sech_guest")
	check(s.f("arc_sech_done") and s.f("arc_sech_roster")==roster,"Sech outcome matches decision")
	check_done(s,"arc_sech","三班" if roster else "临时客铺")
	step(s,"arc_sech_followup",floor)

func finish_commune(s,named:bool):
	var floor="commune"
	step(s,"arc_commune_offer",floor)
	step(s,"arc_commune_check",floor)
	step(s,"arc_commune_listen",floor);film(s)
	step(s,"arc_commune_broker",floor);film(s,"arc_commune_named" if named else "arc_commune_sealed")
	check(not s.Campaign.available(s,"arc_commune_transfer"),"no truce handover before Liu Ba arrives")
	s.flags.arc_commune_at_table=true
	step(s,"arc_commune_transfer",floor);film(s)
	check(s.f("arc_commune_done") and s.f("arc_commune_named")==named,"truce recorded")
	check_done(s,"arc_commune","公开记录" if named else "工牌编号")
	step(s,"arc_commune_followup",floor)

func fixture(faction:String):
	var s=Story.new()
	s.flags.intro_done=true
	match faction:
		"d6":
			s.route="official"
			s.flags.merge({"d6_cargo_returned":true,"late_d1_done":true})
		"sech":s.flags.merge({"sech_member":true,"late_s1_done":true})
		"commune":s.flags.merge({"commune_member":true,"field_c1_done":true})
	return s

func check_final(base,first_call:String,mode:String):
	var s=Story.new()
	s.restore(JSON.parse_string(JSON.stringify(base.serialize())))
	s.flags.merge({"late_four_plans_seen":true,"late_final_mode":mode,"late_risk_confirmed":true,"late_father_truth_seen":true},true)
	step(s,"late_final_confirm","star_interior")
	check(s.Campaign.available(s,"arc_star_resume") and not s.Campaign.available(s,"late_finish"),"initial decision gates continued work")
	var before=Story.new()
	before.restore(JSON.parse_string(JSON.stringify(s.serialize())))
	step(before,"arc_star_resume","star_interior")
	var id:String=before.flags.next_sequence
	before.Comic.start(before,id)
	var choice:Dictionary=before.Comic.panel(before)
	check(choice.choices.size()==(3 if first_call in ["arc_dispatch_d6","arc_dispatch_sech","arc_dispatch_commune"] else 2),"only witnessed friendships grant a second line")
	before.flags.comic.line_index=3
	var during=Story.new()
	during.restore(JSON.parse_string(JSON.stringify(before.serialize())))
	check(during.flags.comic.line_index==3 and during.Comic.panel(during).choices.size()==choice.choices.size(),"save during call preserves line and available choices")
	var selected:int=during.Comic.panel(during).choices.find_custom(func(o):return o.get("flag","")==first_call)
	check(selected>=0,"intended call choice available "+first_call)
	during.Comic.choose(during,maxi(0,selected))
	var answered=Story.new()
	answered.restore(JSON.parse_string(JSON.stringify(during.serialize())))
	step(answered,"arc_star_resume","star_interior");film(answered)
	check(answered.f("arc_first_dispatch_done") and answered.f(first_call),"recovery keeps the chosen first call")
	check(answered.Campaign.StoryArcs.CALLS.filter(func(flag):return answered.f(flag)).size()==1,"first dispatch is mutually exclusive")
	var floors={"late_shared_packet":"star_interior","late_central_agreement":"star_interior","late_distributed_copy":"star_interior","late_watch_power":"relay"}
	var first_step:String=answered.Campaign.Complete.data().endings["warning_"+mode].steps[0]
	answered.context.floor=floors[first_step]
	check(answered.Campaign.available(answered,first_step),"existing finale resumes after the first call")
	answered.flags.late_final_execution_done=true
	step(answered,"late_finish","star_interior");film(answered)
	check(answered.f("late_campaign_complete") and answered.flags.campaign_ending=="warning_"+mode,"original ending remains reachable")
	var recorded:Array=answered.flags.get("comic_records",[]).map(func(entry):return entry.title)
	check("诊所地窖里的点名" in recorded and "装卸棚的第七个人" in recorded,"both roll calls are part of the actual ending")
	check(answered.Campaign.StoryArcs.data().panels["arc_after_"+mode].title in recorded,"selected ending has its own aftermath")
	var journal:String=answered.Campaign.StoryArcs.result(answered,"late_warning")
	match first_call:
		"arc_dispatch_train":check("维克托去世" in journal,"clinic loss recorded after freight priority")
		"arc_dispatch_clinic":check("安德烈遇难" in journal,"rail worker loss recorded after clinic priority")
		_:check("人员齐备" in journal,"faction communication confirms both civilian groups")

func run():
	var nobody=fixture("")
	nobody.route="official"
	nobody.flags.d6_wanted=true
	nobody.flags.late_d1_done=true
	nobody.context.floor="labor"
	check(not nobody.Campaign.available(nobody,"arc_d6_offer"),"deserters cannot unlock a legal D-6 ward visit")
	check(not nobody.Campaign.side_tasks(nobody).any(func(q):return q.id.begins_with("arc_")),"unaccepted tasks stay out of journal")
	check_final(nobody,"arc_dispatch_train","shared")
	check_final(nobody,"arc_dispatch_clinic","central")
	for outcome in [true,false]:
		var d6=fixture("d6")
		finish_d6(d6,outcome)
		check_final(d6,"arc_dispatch_d6","watch")
		var sech=fixture("sech")
		finish_sech(sech,outcome)
		check_final(sech,"arc_dispatch_sech","distributed")
		var commune=fixture("commune")
		finish_commune(commune,outcome)
		check_final(commune,"arc_dispatch_commune","shared")
	var legacy=fixture("")
	legacy.flags.merge({"late_four_plans_seen":true,"late_final_started":true,"late_final_mode":"shared","late_final_execution_done":true})
	legacy.context.floor="star_interior"
	check(legacy.Campaign.available(legacy,"late_shared_packet"),"older confirmed finale requires no new decision")
	step(legacy,"late_finish","star_interior");film(legacy)
	check(legacy.f("late_campaign_complete") and not legacy.flags.comic_records.any(func(r):return r.title=="诊所地窖里的点名"),"older finale has no invented casualties")
	for panel in Story.Campaign.StoryArcs.data().panels.values():
		check(ResourceLoader.exists("res://assets/cinematics/"+panel.art+".png"),"cinematic resource "+panel.art)
	print("RESULT story_arcs ",checks," checks, ",failures," failed")
	quit(0 if failures==0 else 1)
