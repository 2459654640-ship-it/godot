extends SceneTree
const Story=preload("res://scripts/story.gd")
var failures:Array[String]=[]
var checks=0
var w
func check(ok:bool,message:String):
	checks+=1
	if not ok:
		failures.append(message)
		push_error("FAIL: "+message)
func _initialize():call_deferred("run")
func actions(s,keys:Array):
	for k in keys:s.act(k)
func story_tests():
	var s=Story.new()
	s.act("use_permit")
	check(not s.f("gate"),"cannot open gate without permit")
	s.act("get_kit")
	check(not s.has("mask"),"cannot claim formal equipment without order")
	actions(s,["read_notice","accept","get_kit","leave_official"])
	check(s.f("accepted") and s.f("kit") and s.has("mask") and s.has("filter"),"official route prepared before exit confirmation")
	var n=s.items.size()
	s.act("get_kit")
	check(s.items.size()==n,"equipment cannot duplicate")
	s=Story.new()
	actions(s,["borrow_wrench","nina_job","get_fuse","fix_relay","claim_permit","use_permit"])
	check(s.route=="permit" and s.f("gate") and s.has("mask"),"repair permit route complete")
	check(not s.has("fuse") and s.has("wrench"),"fuse consumed and wrench retained")
	s=Story.new()
	actions(s,["search_box","open_cache","use_vodka"])
	check(s.route=="bribe" and not s.has("vodka") and s.f("gate"),"vodka exchanged exactly once")
	n=s.items.size()
	s.act("search_box")
	s.act("open_cache")
	check(s.items.size()==n and not s.has("vodka"),"empty cache cannot regenerate vodka")
	s=Story.new()
	actions(s,["search_box","map","trade_smoke","use_shift"])
	check(s.f("side") and s.f("shift") and not s.has("cigarettes") and s.has("map"),"smoke/intel side route unlocked")
	check(not s.has("mask"),"intel route does not invent equipment")
	s=Story.new()
	actions(s,["borrow_wrench","cook_job","fix_valve","claim_soup","give_soup","use_shift"])
	check(s.f("side") and s.f("valve") and not s.has("soup"),"labor/soup alternate intel route complete")
	s=Story.new()
	actions(s,["search_box","hatch_knife"])
	check(s.route=="hatch" and not s.has("knife") and not s.has("mask"),"knife hatch route has its stated cost")
	s=Story.new()
	actions(s,["borrow_wrench","hatch_wrench"])
	check(s.route=="hatch" and s.has("wrench"),"wrench hatch route retains tool")
	actions(s,["tune","chalk","search_box","father","vitamins","give_vitamins"])
	check(s.f("father") and s.has("photo") and s.has("frequency"),"father and signal remain optional clues")
	check(not s.has("vitamins") and s.f("vitamins_given"),"vitamins have persistent use")
	var restored=Story.new()
	restored.restore(JSON.parse_string(JSON.stringify(s.serialize())))
	check(restored.serialize()==s.serialize(),"state roundtrip preserves inventory, flags, intel and route")

func step(frames:int):
	for i in frames:await physics_frame
func place(p:Vector3):
	w.player.position=p+Vector3(0,0.04,0)
	w.player.velocity=Vector3.ZERO
	w.player.motion_override=Vector2.ZERO
	await step(2)
func drive(dir:Vector2,frames:int=60):
	w.player.motion_override=dir
	await step(frames)
	w.player.motion_override=Vector2.ZERO
	await step(10)
func travel(a:Vector3,b:Vector3,name:String):
	await place(a)
	var dir=Vector2(b.x-a.x,b.z-a.z).normalized()
	await drive(dir,ceili(a.distance_to(b)/2.65*60)+15)
	var end=Vector2(w.player.position.x,w.player.position.z)
	check(end.distance_to(Vector2(b.x,b.z))<0.9,name+" traversal")

func connectivity(open_exit:bool=false):
	var free:Dictionary={}
	var cap=CapsuleShape3D.new()
	cap.radius=0.27
	cap.height=1.72
	var query=PhysicsShapeQueryParameters3D.new()
	query.shape=cap
	query.collision_mask=1
	for x in range(59):
		for z in range(37):
			var point=Vector3(-14.5+x*0.5,0.92,-8.5+z*0.5)
			query.transform=Transform3D(Basis.IDENTITY,point)
			if w.get_world_3d().direct_space_state.intersect_shape(query).is_empty():free[Vector2i(x,z)]=point
	var start=Vector2i(8,11)
	if not free.has(start):
		check(false,"connectivity spawn cell clear")
		return
	var reached:Dictionary={start:true}
	var queue:Array[Vector2i]=[start]
	var index=0
	while index<queue.size():
		var here=queue[index]
		index+=1
		for dir in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
			var next=here+dir
			if free.has(next) and not reached.has(next):
				reached[next]=true
				queue.append(next)
	for id in w.targets:
		var t=w.targets[id]
		var accessible=false
		for cell in reached:
			var point:Vector3=free[cell]
			var end:Vector3=t.pos+Vector3(0,1.2,0)
			if Vector2(point.x-t.pos.x,point.z-t.pos.z).length()>1.62:continue
			var ray=PhysicsRayQueryParameters3D.create(Vector3(point.x,1.2,point.z),end,1)
			var hit=w.get_world_3d().direct_space_state.intersect_ray(ray)
			if hit.is_empty() or hit.position.distance_to(end)<0.48:
				accessible=true
				break
		if id=="exit" and not open_exit:check(not accessible,"extension exit inaccessible before opening a route")
		else:check(accessible,"target reachable with capsule clearance and line of sight: "+id)
	print("CONNECTIVITY: ",reached.size()," reachable half-metre cells; east exit open=",open_exit)

func physics_tests():
	w=load("res://scenes/d6.tscn").instantiate()
	root.add_child(w)
	await step(4)
	w.hud.toast_time=0
	w.player.camera=null
	w.player.use_override=true
	# Test isolated fixtures first; yielding NPC behavior is exercised separately below.
	for a in w.npcs.values():
		a.set_physics_process(false)
		a.collision_layer=0
	connectivity(false)
	for x in [-10.5,-3.5,5.2,12.3]:
		await travel(Vector3(x,0,-1.1),Vector3(x,0,1.4),"north doorway "+str(x))
		await travel(Vector3(x,0,1.2),Vector3(x,0,-1.2),"north doorway reverse "+str(x))
	for x in [-11.0,-3.4,5.6]:
		await travel(Vector3(x,0,2),Vector3(x,0,4.5),"south doorway "+str(x))
		await travel(Vector3(x,0,4.4),Vector3(x,0,2),"south doorway reverse "+str(x))
	await travel(Vector3(-13,0,1.6),Vector3(13,0,1.6),"main corridor including overhead pipes")
	await place(Vector3(8,0,6.7))
	await drive(Vector2.RIGHT,80)
	check(w.player.position.x<8.7,"main gate blocks player while locked")
	await place(Vector3(8,0,4.5))
	await drive(Vector2.RIGHT,80)
	check(w.player.position.x<8.7,"side door blocks player while locked")
	await place(Vector3(12.3,0,2.2))
	await drive(Vector2.DOWN,80)
	check(w.player.position.z<3,"extension cannot be entered from main corridor")
	w.story.flags.gate=true
	w.on_story_changed()
	await step(3)
	connectivity(true)
	await travel(Vector3(7.9,0,6.7),Vector3(10.4,0,6.7),"unlocked main gate")
	await travel(Vector3(10.4,0,6.7),Vector3(7.9,0,6.7),"unlocked main gate return")
	w.story.flags.side=true
	w.phase=1
	w.interact("side")
	check(w.waiting_shift,"waiting action begins instead of granting immediate transit")
	w.phase=8
	await step(4)
	check(w.story.route=="shift" and w.side_body.disabled,"yellow phase opens timed side door")
	await travel(Vector3(8.0,0,4.5),Vector3(10.4,0,4.5),"timed side door")
	check(w.story.f("side_crossed"),"timed crossing latches safety state")
	w.phase=0
	await step(3)
	check(w.side_body.disabled,"side door never shuts on returning player after crossing")
	# Try to walk through every exposed face of fixtures and every wall section.
	var probes=0
	var fixtures=0
	for solid in w.kit.solids:
		if solid.top<0.10 or solid.bottom>1.70 or solid.name in ["LockedMainGate","LockedSideDoor"]:continue
		var r:Rect2=solid.rect
		var center=r.get_center()
		var faces=[
			[Vector2(r.position.x-0.65,center.y),Vector2.RIGHT],
			[Vector2(r.end.x+0.65,center.y),Vector2.LEFT],
			[Vector2(center.x,r.position.y-0.65),Vector2.DOWN],
			[Vector2(center.x,r.end.y+0.65),Vector2.UP]]
		var did_probe=false
		for face in faces:
			var p:Vector2=face[0]
			if not Rect2(-14.7,-8.7,29.4,18.4).has_point(p):continue
			var query=PhysicsShapeQueryParameters3D.new()
			var cap=CapsuleShape3D.new()
			cap.radius=0.27
			cap.height=1.72
			query.shape=cap
			query.transform=Transform3D(Basis.IDENTITY,Vector3(p.x,0.92,p.y))
			query.collision_mask=1
			if not w.get_world_3d().direct_space_state.intersect_shape(query).is_empty():continue
			await place(Vector3(p.x,0,p.y))
			await drive(face[1],35)
			var result=Vector2(w.player.position.x,w.player.position.z)
			check((result-p).dot(face[1])<0.50,"solid fixture blocks passage: "+solid.name+" face "+str(face[1]))
			check(w.player.position.y<0.12,"cannot climb onto "+solid.name)
			# Retreat must work, proving we did not wedge the capsule in a corner.
			var before=result
			await drive(-face[1],22)
			check(Vector2(w.player.position.x,w.player.position.z).distance_to(before)>0.3,"can retreat from "+solid.name)
			probes+=1
			did_probe=true
		if did_probe:fixtures+=1
	var corner_probes=0
	for solid in w.kit.solids:
		if solid.top<0.10 or solid.bottom>1.70 or solid.name in ["LockedMainGate","LockedSideDoor"]:continue
		var r:Rect2=solid.rect
		for sides in [Vector2(-1,-1),Vector2(1,-1),Vector2(-1,1),Vector2(1,1)]:
			var corner=Vector2(r.position.x if sides.x<0 else r.end.x,r.position.y if sides.y<0 else r.end.y)
			var p=corner+sides*0.55
			if not Rect2(-14.7,-8.7,29.4,18.4).has_point(p):continue
			var query=PhysicsShapeQueryParameters3D.new()
			var cap=CapsuleShape3D.new()
			cap.radius=0.27
			cap.height=1.72
			query.shape=cap
			query.transform=Transform3D(Basis.IDENTITY,Vector3(p.x,0.92,p.y))
			query.collision_mask=1
			if not w.get_world_3d().direct_space_state.intersect_shape(query).is_empty():continue
			await place(Vector3(p.x,0,p.y))
			await drive(-sides.normalized(),35)
			var result=Vector2(w.player.position.x,w.player.position.z)
			check(not r.grow(-0.01).has_point(result),"corner excludes player: "+solid.name)
			await drive(sides.normalized(),22)
			check(Vector2(w.player.position.x,w.player.position.z).distance_to(result)>0.3,"escape corner without wedging: "+solid.name)
			corner_probes+=1
	check(corner_probes>100,"substantial corner coverage")
	print("CORNER_COVERAGE: ",corner_probes," accessible corners tested")
	check(probes>100,"substantial fixture coverage, not a zero-probe run")
	print("FIXTURE_COVERAGE: ",fixtures," fixtures/wall sections; ",probes," exposed-face movement probes")
	# Representative wall corners, furniture circulation and hatch access.
	for pair in [
		[Vector3(1.6,0,-1.1),Vector3(1.6,0,-5.9),"canteen west aisle"],
		[Vector3(5.1,0,-1.2),Vector3(5.1,0,-6.6),"canteen central aisle"],
		[Vector3(-6,0,-2),Vector3(-6,0,-4.4),"workshop crate approach"],
		[Vector3(6.4,0,8.7),Vector3(7.7,0,8.7),"hatch approach"]]:await travel(pair[0],pair[1],pair[2])
	# NPC physically yields while the player presses through the former position.
	var npc=w.npcs.resident
	npc.position=Vector3(-3.4,0,3.2)
	npc.anchor=npc.position
	npc.collision_layer=2
	npc.set_physics_process(true)
	await travel(Vector3(-3.4,0,2),Vector3(-3.4,0,4.7),"NPC yields in a door")
	check(npc.position.distance_to(npc.anchor)>0.3,"NPC actually displaced, not non-solid")
	# No interaction across a full wall even within Euclidean interaction distance.
	await place(Vector3(-7.5,0,0.8))
	w.find_nearest()
	check(w.nearest=="chalk","reachable corridor clue selected")
	# Real filesystem save/reload through the game layer, using an isolated test slot.
	w.save_path="user://d6_test_save.json"
	w.story.give("photo")
	w.save_game()
	var oldpos=w.player.position
	w.story.take("photo")
	w.player.position=Vector3.ZERO
	w.load_game()
	check(w.story.has("photo") and w.player.position.distance_to(oldpos)<0.05,"actual save file restores position and inventory")
	DirAccess.remove_absolute(w.save_path)
	w.queue_free()
	await step(2)

func ui_tests():
	w=load("res://scenes/d6.tscn").instantiate()
	root.add_child(w)
	await step(4)
	w.player.camera=w.camera
	w.player.use_override=false
	var start=w.player.position
	Input.action_press("move_right")
	await step(25)
	Input.action_release("move_right")
	await step(20)
	check(w.player.position.x>start.x and w.player.position.z<start.z,"WASD uses camera-relative screen right")
	check(Vector2(w.player.velocity.x,w.player.velocity.z).length()<0.05,"deceleration comes to rest")
	for id in w.targets:
		w.hud.show_dialogue(id)
		await step(1)
		check(w.hud.modal_visible(),"dialogue renders: "+id)
	w.hud.show_inventory()
	await step(1)
	check(w.hud.modal_visible(),"empty inventory renders")
	w.hud.show_journal()
	await step(1)
	w.hud.show_map()
	await step(1)
	check(is_instance_valid(w.hud.map_large),"expanded map renders")
	w.hud.show_pause()
	var paused_pos=w.player.position
	Input.action_press("move_up")
	await step(30)
	Input.action_release("move_up")
	check(w.player.position.distance_to(paused_pos)<0.08,"modal UI stops movement")
	w.hud.close()
	check(w.ambience.stream.loop_mode==AudioStreamWAV.LOOP_FORWARD,"machinery ambience uses actual loop playback")
	# End-to-end official departure preflight does not overwrite an alternative route.
	actions(w.story,["accept","get_kit"])
	w.story.route="hatch"
	w.perform("leave_official","lift")
	check(w.pending_route=="official" and w.story.route=="hatch","departure cancellation preserves alternative route")
	w.hud.close()
	w.pending_route="official"
	w.story.route="official"
	w.story.ending=true
	w.hud.show_departure(true)
	await step(2)
	check(w.hud.modal_visible() and w.hud.is_departure,"departure summary renders")
	w.hud.close()
	w.story=Story.new()
	w.story.changed.connect(w.on_story_changed)
	w.story.act("borrow_wrench")
	w.perform("hatch_wrench","hatch")
	await step(2)
	check(w.player.position.x>9.5 and w.story.route=="hatch","hatch action reaches far side physically")
	w.queue_free()
	await step(2)

func run():
	story_tests()
	await physics_tests()
	await ui_tests()
	print("D6_TEST_RESULT checks=",checks," failures=",failures.size())
	if not failures.is_empty():
		for item in failures:print("FAILED: ",item)
	quit(0 if failures.is_empty() else 1)
