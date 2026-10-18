extends SceneTree
const Story=preload("res://scripts/story.gd")
var checks=0
var failures:Array[String]=[]
var w
func _initialize():call_deferred("run")
func check(ok:bool,why:String):
	checks+=1
	if not ok:failures.append(why);push_error(why)
func steps(n:int):
	for i in n:await physics_frame
func enabled(s,id:String,key:String)->bool:
	for o in s.view(id).options:
		if o.key==key:return o.enabled
	return false
func act(s,keys:Array):
	for key in keys:s.act(key);check(s.last_action_valid,"valid action: "+key)
func story_checks():
	var s=Story.new()
	act(s,["search_box"])
	s.act("hatch_knife")
	check(not s.last_action_valid and s.has("knife") and not s.f("hatch"),"guard blocks tool use without consuming knife")
	s.act("nina_reckless")
	s.act("borrow_wrench")
	check(not s.has("wrench"),"unsafe answer does not grant the tool")
	act(s,["nina_safety","heat_job","borrow_wrench","take_rag","fix_heating","claim_report","guard_report"])
	check(s.has("report") and not s.has("rag") and s.has("wrench"),"repair report has persistent item cost and tool remains")
	check(not enabled(s,"hatch","hatch_wrench"),"guard's promise alone cannot open hatch")
	s.context.hatch_clear=true
	act(s,["hatch_wrench","hatch_pass","return_pipe"])
	check(s.route=="hatch" and s.has("wrench"),"deterministic alternative completes hatch route")
	for roll in [0.0,99.99]:
		s=Story.new()
		s.roll_override=roll
		act(s,["guard_greet","guard_listen","guard_appeal"])
		var won=roll<75.0
		check(s.f("guard_task")==won,"success and failure branch reflect displayed probability")
		check(s.flags.social_checks.guard_appeal.chance==75,"listening raises appeal chance to 75 percent")
		check(not enabled(s,"igor","guard_appeal"),"attempted wording cannot be spammed")
		var original=s.flags.social_checks.duplicate(true)
		var loaded=Story.new()
		loaded.restore(JSON.parse_string(JSON.stringify(s.serialize())))
		loaded.roll_override=99.99-roll
		loaded.act("guard_appeal")
		check(JSON.parse_string(JSON.stringify(loaded.flags.social_checks))==JSON.parse_string(JSON.stringify(original)),"saved roll persists after reload")
		if not won:
			act(s,["nina_safety","borrow_wrench","take_rag","fix_heating","claim_report","guard_report"])
			check(s.f("guard_task"),"failed persuasion never blocks guaranteed record path")
	var legacy={"version":1,"flags":{"searched":true},"items":["knife"],"intel":[],"route":"","ending":false}
	var a=Story.new();var b=Story.new()
	a.restore(legacy);b.restore(legacy)
	check(a.flags.social_seed==b.flags.social_seed and a.has("knife"),"old save seed backfill is deterministic and preserves items")
	check(a.serialize().version==1,"existing save format retained")
	var before=a.serialize().duplicate(true)
	a.act("guard_bluff");var outcome=a.flags.social_checks.guard_bluff
	b.restore(before);b.act("guard_bluff")
	check(b.flags.social_checks.guard_bluff==outcome,"reloading before check does not reroll")

func live_checks():
	w=load("res://scenes/d6.tscn").instantiate()
	root.add_child(w)
	await steps(5)
	w.player.position=Vector3(5,0.04,8.4)
	w.player.velocity=Vector3.ZERO
	var atlas=JSON.parse_string(FileAccess.get_file_as_string("res://assets/characters/atlas.json"))
	for id in w.npcs:
		check(atlas[id].poses==4 and atlas[id].clips.has("talk"),"authored idle, two strides and talk: "+id)
		check(atlas[id].rear_diagonal_normalized,"rear diagonal art normalization: "+id)
	for id in w.npcs:
		var npc=w.npcs[id]
		for stop in npc.patrol:
			var route=w.navigation.path(npc.position,stop)
			check((not route.is_empty() and route[-1].distance_to(stop)<.56) or (route.is_empty() and npc.position.distance_to(stop)<.25),"routine stop has physical clearance: "+id+str(stop))
		check(not npc.path_points.is_empty() or npc.position.distance_to(npc.anchor)<.65,"NPC has a reachable routine: "+id)
	w.story.give("report")
	w.story.give("wrench")
	w.perform("guard_report","igor")
	check(w.hud.modal_visible(),"guard reaction keeps dialogue available")
	check(not w.story.guard_clear(),"no instant clearance on accepting request")
	var guard_start=w.npcs.igor.position
	await steps(90)
	check(w.npcs.igor.position.distance_to(guard_start)<.05,"guard waits while reply is open")
	w.hud.close()
	var traces=[]
	for i in 1200:
		await physics_frame
		if i%60==0:traces.append([w.npcs.igor.position.x,w.npcs.igor.position.z])
		if w.story.guard_clear() and w.guard_away_time>0:break
	check(w.story.guard_clear() and w.npcs.igor.position.z<2.6,"guard physically walks through door and out of sight; "+str(traces))
	check(w.guard_away_time>40,"inspection window starts on arrival")
	var left=w.guard_away_time
	w.hud.show_dialogue("hatch")
	await steps(120)
	check(absf(w.guard_away_time-left)<.05,"inspection clock pauses for reading")
	w.perform("hatch_wrench","hatch")
	check(w.story.f("hatch") and w.player.position.x>9.5,"real hatch action reaches far side after diversion")
	w.perform("return_pipe","pipe_exit")
	check(w.player.position.x<9 and w.story.route=="hatch","return passage is usable without losing route")
	w.hud.close()
	w.guard_away_time=.03
	await steps(8)
	check(not w.story.f("guard_task") and not w.story.guard_clear(),"guard window expires and restores supervision")
	check(enabled(w.story,"igor","guard_report"),"record can request another inspection")
	# Speech is ordered; skip remains available for players who read faster.
	w.hud.show_dialogue("igor")
	check(not w.hud.typing.is_empty(),"conversation starts typewriter")
	var entry=w.hud.typing[0]
	check(entry.label.visible_characters<entry.total,"initial text is partial")
	w.hud.advance_typing(1.21)
	check(entry.label.visible_characters>0 and entry.label.visible_characters<=entry.total,"first speech block advances at the readable sequential rate")
	w.hud.show_reply("igor","「没事，慢慢说。」\n伊戈尔放下铅笔。")
	w.hud.finish_typing()
	check(w.hud.typing.is_empty(),"skip immediately reveals prose")
	await steps(12)
	check(w.npcs.igor.animation_state=="talk","active interlocutor uses conversation pose")
	w.hud.close()
	# Actual eight camera-relative diagonals, away from fixtures.
	w.player.use_override=true
	for pair in [[Vector2(-1,-1).normalized(),5],[Vector2(1,-1).normalized(),3],[Vector2(1,1).normalized(),1],[Vector2(-1,1).normalized(),7],[Vector2.UP,4],[Vector2.DOWN,0],[Vector2.LEFT,6],[Vector2.RIGHT,2]]:
		w.player.position=Vector3(-3,0.04,1.6)
		w.player.velocity=Vector3.ZERO
		w.player.motion_override=pair[0]
		await steps(14)
		var painter=w.player.visual.get_node("Painter")
		painter._process(.02)
		check(painter.angle_slot==pair[1],"camera-relative rear diagonal uses correct atlas slot: "+str(pair))
	w.player.motion_override=Vector2.ZERO
	w.player.position=Vector3(-10.5,.04,-3.4)
	w.story.flags.guard_task=false
	var visited={}
	var pose_seen={}
	var overlaps=[]
	for id in w.npcs:visited[id]=w.npcs[id].position;pose_seen[id]=[]
	for frame in 1800:
		await physics_frame
		for id in w.npcs:
			var npc=w.npcs[id]
			var painter=npc.visual.get_node("Painter")
			painter._process(0)
			if painter.current_pose not in pose_seen[id]:pose_seen[id].append(painter.current_pose)
			# Brief local steps can fit between two half-second collision samples.
			if frame%30!=0:continue
			var shape=CapsuleShape3D.new()
			shape.radius=.285;shape.height=1.69
			var query=PhysicsShapeQueryParameters3D.new()
			query.shape=shape
			query.collision_mask=1
			query.transform=Transform3D(Basis.IDENTITY,npc.position+Vector3(0,.87,0))
			if not w.get_world_3d().direct_space_state.intersect_shape(query).is_empty():overlaps.append([id,frame,npc.position])
	check(overlaps.is_empty(),"NPC patrol capsules never penetrate walls/furniture: "+str(overlaps))
	for id in w.npcs:
		if id=="semyon":continue # The nearby player keeps him available for conversation.
		if not w.npcs[id].patrol.is_empty():check(pose_seen[id].has(1) or pose_seen[id].has(2),"NPC uses articulated strides during a local routine: "+id+str(pose_seen[id]))
	w.ambience.stop();w.ambience.stream=null
	w.step_audio.stop();w.step_audio.stream=null
	w.queue_free()
	await steps(3)
func run():
	story_checks()
	await live_checks()
	print("RESIDENT_CONTRACT_RESULT checks=",checks," failures=",failures.size())
	quit(0 if failures.is_empty() else 1)
