extends SceneTree

const Story=preload("res://scripts/story.gd")
const ComicUI=preload("res://scripts/ui_comic.gd")
var w
var checks=0
var failures=0

func _initialize():
	call_deferred("run")

func check(ok:bool,why:String):
	checks+=1
	if not ok:
		failures+=1
		push_error(why)

func frames(n:int=4):
	for i in n:await physics_frame

func open(floor:String,packet:Dictionary,position:Vector3=Vector3.INF):
	root.get_node("Session").pending={"story":packet,"floor":floor,"position":position}
	w=load("res://scenes/"+floor+".tscn").instantiate()
	root.add_child(w)
	current_scene=w
	await frames()
	w.set_physics_process(false)
	w.player.set_physics_process(false)
	w.combat.set_physics_process(false)
	w.hud.close()

func dispose():
	w.queue_free();await frames();w=null

func path_to(id:String):
	check(w.targets.has(id),"interaction placed "+id)
	if not w.targets.has(id):return
	var point:Vector3=w.targets[id].pos
	var path=w.navigation.path(w.player.position,point)
	check(w.player.position.distance_to(point)<1.6 or (not path.is_empty() and path[-1].distance_to(point)<1.6),"reachable interaction "+id)

func follow(id:String,completed:String,trail:Vector3):
	check(w.npcs.has(id),"escort spawned "+id)
	if not w.npcs.has(id):return
	var start:Vector3=w.npcs[id].position
	var restored=false
	var floor:String=w.floor_id
	for i in 4200:
		w.player.position=w.clear_arrival(w.npcs[id].position+trail+Vector3.UP*.04)
		w.living.tick(1.0/60)
		w.chapter_director.tick(1.0/60)
		await physics_frame
		if i==100:
			var old_pos:Vector3=w.npcs[id].position
			var p:Vector3=w.player.position
			var packet:Dictionary=JSON.parse_string(JSON.stringify(w.save_snapshot()))
			await dispose()
			await open(floor,packet,p)
			check(w.npcs[id].position.distance_to(old_pos)<.9,"actor position restored mid-escort "+id)
			restored=true
		if w.story.f(completed):break
	if not w.story.f(completed):
		print("ROUTE_DIAG ",id," position=",w.npcs[id].position," goal=",w.npcs[id].goal,
			" path=",w.npcs[id].path_points," stage=",w.story.flags.get("late_walk_stages",{}).get(id,0))
	check(w.story.f(completed),"actor reaches destination "+completed)
	check(restored,"route exercises saved resume "+id)
	check(w.npcs[id].position.distance_to(start)>3,"actor physically traversed the room "+id)
	check(w.npcs[id].position.distance_to(w.targets[id].pos)<.25,"interaction stays on walking actor "+id)

func state(flags:Dictionary,route:String="")->Dictionary:
	var s=Story.new()
	s.flags.intro_done=true
	s.flags.merge(flags,true)
	s.route=route
	return s.serialize()

func test_d6():
	var d6={"d6_cargo_returned":true,"d6_returned":true,"departure_official":true,"late_d1_done":true,
		"arc_d6_accepted":true,"arc_d6_heard":true,"arc_d6_patient_heard":true,"arc_d6_clearance":true,"arc_d6_signed":true,"arc_d6_walk":true}
	await open("labor",state(d6,"official"))
	var old_position=Vector3(0,.04,-16.65)
	check(w.clear_arrival(old_position).distance_to(old_position)>.32,"an old D-6 save wakes clear of the new glass")
	path_to("arc_d6_mother");path_to("arc_d6_son");path_to("arc_d6_glass")
	await follow("arc_d6_mother","arc_d6_at_glass",Vector3.BACK*1.8)
	check(w.story.Campaign.available(w.story,"arc_d6_visit"),"visit opens beside the glass")
	w.interact("arc_d6_glass")
	w.perform("c_arc_d6_visit","arc_d6_glass")
	await frames()
	check(w.hud.comic_active and w.story.Comic.panel(w.story).art=="window_eleven","actual interaction runs the ward cinematic")
	await dispose()

func test_sech():
	var sech={"sech_member":true,"sech_joined":true,"late_s1_done":true,"c_done_field_s1_accept":true,"arc_sech_accepted":true,
		"arc_sech_signals_learned":true,"arc_sech_checked_card":true,"arc_sech_incoming":true,"arc_sech_walk":true}
	await open("sech",state(sech))
	var old_position=Vector3(15.52,.04,-19.15)
	check(w.clear_arrival(old_position).distance_to(old_position)>.32,"an old Sech save wakes clear of the signal stand")
	path_to("arc_sech_aglaya");path_to("arc_sech_lantern");path_to("arc_sech_varya")
	await follow("arc_sech_varya","arc_sech_at_bridge",Vector3.FORWARD*1.8)
	path_to("sech_elder")
	w.interact("sech_elder")
	w.perform("c_arc_sech_negotiate","sech_elder")
	await frames()
	check(w.hud.comic_active and w.story.Comic.panel(w.story).art=="signal_return","actual interaction runs the Sech negotiation")
	await dispose()

func test_commune():
	var commune={"commune_member":true,"commune_joined":true,"field_c1_done":true,"arc_commune_accepted":true,
		"arc_commune_tag_checked":true,"arc_commune_heard":true,"arc_commune_terms":true,"arc_commune_named":true}
	await open("commune",state(commune))
	path_to("arc_commune_bundle");path_to("arc_commune_liuba");path_to("commune_guard")
	await follow("arc_commune_liuba","arc_commune_at_table",Vector3.LEFT*1.8)
	w.interact("arc_commune_bundle")
	w.perform("c_arc_commune_transfer","arc_commune_bundle")
	await frames()
	check(w.hud.comic_active and w.story.Comic.panel(w.story).art=="truce_table","actual interaction runs the truce exchange")
	if w.hud.comic_active:
		w.hud.comic_choose()
		w.hud.comic_choose()
	await frames()
	check(not w.get_node("TruceClothParcel").visible and not w.get_node("TruceParcelTie").visible,"collected parcel is physically gone")
	await dispose()

func test_star():
	await open("star_interior",state({"late_four_plans_seen":true,"late_final_mode":"watch","arc_sech_done":true}))
	w.interact("late_planning")
	w.perform("c_late_final_confirm","late_planning")
	await frames()
	var p:Dictionary=w.story.Comic.panel(w.story)
	check(p.art=="star_dead_line" and w.hud.comic_active,"new scene plays through final action")
	var before:Dictionary=w.SaveStore.read(w.SaveStore.FINAL)
	check(not before.is_empty() and not before.flags.get("arc_first_dispatch_pending",false),"pre-action save predates the emergency")
	check(w.hud.speech_buttons.is_empty(),"choices do not appear before the conversation")
	w.story.flags.comic.line_index=ComicUI.paragraphs(w.hud,p).size()-1
	w.hud.show_comic()
	await frames()
	check(w.hud.speech_buttons.size()==3 and "谢契" in w.hud.speech_buttons[2].text,"game UI presents the earned backup choice")
	var screen=Rect2(Vector2.ZERO,Vector2(1600,1000))
	for b in w.hud.speech_buttons:
		check(screen.encloses(b.get_global_rect()),"final choice stays in the cinematic view")
	w.hud.comic_choose(2)
	check(w.story.f("arc_dispatch_sech"),"choosing through HUD commits the intended route")
	await dispose()

func run():
	await test_d6()
	await test_sech()
	await test_commune()
	await test_star()
	print("RESULT story_arcs_world ",checks," checks, ",failures," failed")
	quit(0 if failures==0 else 1)
