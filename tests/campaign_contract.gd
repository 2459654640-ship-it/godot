extends SceneTree
const Story=preload("res://scripts/story.gd")
const Campaign=preload("res://scripts/campaign.gd")
var checks=0
var failed:Array[String]=[]
var w
func _initialize():call_deferred("run")
func check(ok:bool,msg:String):
	checks+=1
	if not ok:failed.append(msg);push_error(msg)
func frames(n:int=3):
	for i in n:await physics_frame
func action(s,key:String):
	s.act("c_"+key)
	check(s.last_action_valid,"action allowed: "+key)
func restore(s):
	var t=Story.new();t.restore(JSON.parse_string(JSON.stringify(s.serialize())));t.context=s.context.duplicate(true)
	check(JSON.parse_string(JSON.stringify(t.flags))==JSON.parse_string(JSON.stringify(s.flags)) and t.items==s.items and JSON.parse_string(JSON.stringify(t.economy))==JSON.parse_string(JSON.stringify(s.economy)),"campaign save roundtrip retains exact state")
	return t
func overlap(p:Vector3)->bool:
	var cap=CapsuleShape3D.new();cap.radius=.27;cap.height=1.7
	var q=PhysicsShapeQueryParameters3D.new();q.shape=cap;q.collision_mask=1;q.transform=Transform3D(Basis.IDENTITY,p+Vector3(0,.9,0))
	return not w.get_world_3d().direct_space_state.intersect_shape(q).is_empty()
func reachable()->Dictionary:
	var g=w.navigation.graph;var start=g.get_closest_point(Vector2(w.player.position.x,w.player.position.z));var seen={start:true};var queue=[start];var i=0
	while i<queue.size():
		var p=queue[i];i+=1
		for other in g.get_point_connections(p):
			if not seen.has(other):seen[other]=true;queue.append(other)
	return seen
func comic(s,seq:String,branch:int=0):
	s.Comic.start(s,seq)
	var n=0
	while s.flags.comic.active and n<40:
		var p:Dictionary=s.Comic.panel(s)
		check(not p.is_empty() and ResourceLoader.exists("res://assets/cinematics/"+p.art+".png"),"authored travel node and art exist: "+str(s.flags.comic.node))
		if p.is_empty():break
		s.Comic.choose(s,mini(branch,p.get("choices",[0]).size()-1) if p.has("choices") else -1)
		s=restore(s);n+=1
	check(n<40 and not s.flags.comic.active,"travel completes without loop: "+seq)
	return s
func run():
	# Scope gates, puzzle ordering and repeat-safe rewards.
	var s=Story.new();s.context.floor="waterworks"
	s.act("c_plant_open");check(not s.last_action_valid and not s.has("water_core"),"sealed warehouse cannot be opened before pressure puzzle")
	for key in ["plant_brief","plant_read","plant_bleed","plant_fuse","plant_power","plant_open"]:action(s,key);s=restore(s)
	check(s.f("water_secured") and s.has("water_core"),"waterworks objective is actually completed")
	action(s,"plant_log");var quantity=s.economy.goods.bandage
	s.act("c_plant_log");check(not s.last_action_valid and s.economy.goods.bandage==quantity,"side-quest reward cannot be farmed")
	var plant=restore(s)
	for branch in [0,1,2]:
		var t=comic(restore(plant),"return_crossing",branch)
		check((t.flags.get("next_facility","")==("commune" if branch==1 else "labor") and not t.ending),"each return choice reaches an ending or playable facility")
	# Anna's chain never skips proof or the patient's consent.
	s=Story.new();s.context.floor="commune"
	for key in ["commune_join","anna_accept","anna_records","greenhouse_inspect","greenhouse_restart"]:action(s,key)
	s=restore(s);s.context.floor="coal";s.flags.coal_access=true
	s.act("c_coal_brother");check(not s.last_action_valid and not s.f("brother_found"),"patient encounter requires confirmed identity and care")
	for key in ["coal_register","coal_archive","coal_medic","coal_brother"]:action(s,key)
	s=restore(s);s.context.floor="commune";action(s,"anna_result");action(s,"anna_home")
	check(s.f("commune_member") and not s.ending,"Anna follow-up opens a continued life in the commune")
	# Solo routes connect through two different maps.
	for branch in [0,1]:
		s=comic(Story.new(),"companions",branch)
		check(s.flags.next_facility in ["sech","commune"],"solo route enters a real facility")
	s=Story.new();s.context.floor="sech"
	s.act("c_radio_tune");check(not s.last_action_valid,"radio cannot tune without power")
	for key in ["sech_join","radio_manual","radio_power","radio_tune","sech_books","sech_water"]:action(s,key)
	check(s.f("star_known") and s.f("radio_fixed"),"radio repair reveals Star City through play")
	action(s,"sech_stay");check(s.f("sech_member") and not s.ending,"Sech commitment opens its continuing chapter")
	var alternate=Story.new();alternate.context.floor="sech";alternate.economy.goods.battery=1
	action(alternate,"radio_manual");action(alternate,"radio_battery")
	check(alternate.f("radio_power") and not alternate.economy.goods.has("battery"),"battery is consumed by the alternate radio repair")
	alternate.act("c_radio_battery");check(not alternate.last_action_valid,"spent battery cannot power the receiver twice")
	# Father line and all four Star City conclusions.
	s=Story.new();s.context.floor="starcity"
	s.act("c_father_meet");check(not s.last_action_valid,"father reveal is gated by actual access")
	for key in ["star_name","star_manual","star_isolate","star_meter","star_bypass","star_archive","father_meet","father_semyon","father_truth","star_listen"]:action(s,key);s=restore(s)
	for key in ["father_absence","star_handover_accept","weather_clock","weather_power","weather_test","weather_return","star_handover_finish"]:action(s,key)
	for pair in [["ending_starcity","starcity"],["ending_bridge","bridge"],["star_reply","signal"],["star_coordinates","ocean"]]:
		var t=restore(s);action(t,pair[0])
		if pair[1]=="signal":action(t,"ending_signal")
		if pair[1]=="ocean":action(t,"ending_ocean")
		check(t.ending and t.flags.campaign_ending==pair[1],"reachable Star City ending: "+pair[1])
	# Every authored travel target resolves, including revisits.
	for seq in Campaign.data().panels:
		var panel:Dictionary=Campaign.data().panels[seq]
		for c in panel.get("choices",[]):check(Campaign.data().panels.has(c.next) or s.Comic.authored().has(c.next),"choice destination exists: "+c.next)
		if panel.has("next"):check(Campaign.data().panels.has(panel.next) or s.Comic.authored().has(panel.next),"next destination exists: "+panel.next)
	# Real interiors: nav connectivity, interaction sight lines, doors crossed by the actual controller.
	for id in Campaign.NAMES:
		w=load("res://scenes/"+id+".tscn").instantiate();root.add_child(w);current_scene=w;await frames(6)
		check(w.initialized and w.floor_id==id,"facility starts: "+id)
		if id=="starcity":
			var gate_position=w.campaign_gate.position
			w.player.camera=null;w.player.use_override=true;w.player.position=Vector3(gate_position.x,.04,gate_position.z+1.2);w.player.motion_override=Vector2.UP
			await frames(60);w.player.motion_override=Vector2.ZERO
			check(w.player.position.z>gate_position.z+.25,"blue inner door physically blocks entry before isolation")
			w.player.use_override=false
		w.story.flags.intro_done=true;w.story.flags.battle_pump=true;w.story.flags.battle_workshop=true;w.story.flags.battle_warehouse=true;w.story.flags.star_access=true;w.story.flags.plant_power=true;w.on_story_changed();await frames(80)
		w.navigation=preload("res://scripts/route_grid.gd").new();w.navigation.setup(w)
		var seen=reachable();check(seen.size()>1000,"substantial connected floor: "+id)
		for target_id in w.targets:
			var end:Vector3=w.targets[target_id].pos+Vector3(0,1.2,0);var visible=false
			for cell in seen:
				var p:Vector2=w.navigation.graph.get_point_position(cell)
				if p.distance_to(Vector2(end.x,end.z))>1.6 or overlap(Vector3(p.x,.04,p.y)):continue
				var hit=w.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(p.x,1.2,p.y),end,1))
				if hit.is_empty() or hit.position.distance_to(end)<.48:visible=true;break
			check(visible,"reachable interaction with capsule and sight line: "+id+"/"+target_id)
		for a in w.npcs.values():a.set_physics_process(false);a.collision_layer=0
		w.player.camera=null;w.player.use_override=true
		for spec in w.CampaignMaps.door_specs(id):
			if spec.get("exterior",false):continue # Closed factory exit is verified with its animated leaves in v10_contract.
			var door:Vector2=spec.position
			var normal=Vector2.RIGHT if spec.axis=="x" else Vector2.DOWN
			for sign in [-1,1]:
				w.player.position=Vector3(door.x+normal.x*sign*1.2,.04,door.y+normal.y*sign*1.2);w.player.velocity=Vector3.ZERO
				w.player.motion_override=-normal*sign;await frames(65)
				w.player.motion_override=Vector2.ZERO;await frames(5)
				check((Vector2(w.player.position.x,w.player.position.z)-door).dot(normal)*sign<-.4,"physical doorway both directions: "+id+str(door)+str(sign))
		w.player.use_override=false;w.hud.show_map();await frames();check(w.hud.modal_visible(),"facility map renders: "+id)
		w.hud.close()
		# Save on each new floor and read it through the real loader.
		w.save_path="user://campaign_contract_"+id+".json";w.story.flags.test_saved=true;w.save_game();w.story.flags.test_saved=false;var test_path=w.save_path;w.load_game();await frames(8);w=current_scene
		check(w.story.f("test_saved"),"real save/load on facility: "+id);DirAccess.remove_absolute(test_path)
		w.queue_free();await frames()
	print("CAMPAIGN_CONTRACT_RESULT checks=",checks," failures=",failed.size())
	quit(0 if failed.is_empty() else 1)
