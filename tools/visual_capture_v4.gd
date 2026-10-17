extends SceneTree
var w
var folder="res://docs/screenshots/visual-v4"
func _initialize():call_deferred("run")
func settle(n:int=3):
	for i in n:await process_frame
	await RenderingServer.frame_post_draw
func view_at(focus:Vector3,size:float):
	w.camera.size=size
	w.camera.position=focus+Vector3(23,30,27)
	w.camera.look_at(focus)
	for i in 65:w.wall_veil._process(1.0/60)
func shot(id:String):
	w.hud.finish_typing()
	await settle()
	root.get_texture().get_image().save_png(folder+"/"+id+".png")
	print("CAPTURE ",id)
func run():
	DirAccess.make_dir_recursive_absolute(folder)
	w=load("res://scenes/d6.tscn").instantiate()
	root.add_child(w)
	await settle()
	w.set_physics_process(false)
	w.player.set_physics_process(false)
	for npc in w.npcs.values():npc.set_physics_process(false)
	w.hud.toast_time=0
	w.hud.toast_label.text=""
	if "--guard-only" not in OS.get_cmdline_user_args():
		w.overview=true
		view_at(Vector3(-6,0,-1.5),39)
		await shot("overview")
		w.overview=false
		w.player.position=Vector3(-24.2,.04,-1.0)
		view_at(Vector3(-24,.4,-4.2),16)
		w.room_name="西翼居民区"
		w.hud.tick(0)
		await shot("residential-wing")
		w.hud.show_dialogue("resident")
		await shot("resident-conversation")
		w.hud.close()
		w.story.act("guard_greet")
		w.story.act("guard_listen")
		w.player.position=Vector3(5.0,.04,6.2)
		w.room_name="东侧维修岗"
		w.hud.tick(0)
		view_at(Vector3(4.5,.4,6),13)
		w.hud.show_dialogue("igor")
		await shot("guard-options")
		w.hud.close()
		w.hud.show_map()
		await shot("map")
		w.hud.close()
		w.player.position=Vector3(-10.5,.04,-3.4)
		w.room_name="伊万的卧室"
		w.hud.tick(0)
		view_at(Vector3(-11.3,.4,-4.7),11)
		await shot("bedroom-close")
		# Real controller movement with a faster simulation clock, never a staged
		# replacement character. Physics remains responsible for every step.
		w.player.position=Vector3(-7,.04,1.3)
		w.room_name="居住层主通道"
		w.hud.tick(0)
		w.player.camera=null
		w.player.use_override=true
		w.player.motion_override=Vector2.RIGHT
		w.player.set_physics_process(true)
		Engine.time_scale=3.0
		view_at(Vector3(-5,.4,1.1),11)
		for frame in 24:
			await physics_frame
			if frame in [5,17,23]:await shot("wall-walk-%02d" % frame)
		w.player.motion_override=Vector2.ZERO
		w.player.set_physics_process(false)
		Engine.time_scale=1.0
		# North-west and north-east use the real camera-relative input controller.
		w.hud.visible=false
		w.player.camera=w.camera
		for pair in [[Vector2(-1,-1).normalized(),"upper-left"],[Vector2(1,-1).normalized(),"upper-right"]]:
			w.player.position=Vector3(-3,.04,1.5)
			w.player.velocity=Vector3.ZERO
			w.player.motion_override=pair[0]
			w.player.set_physics_process(true)
			view_at(Vector3(-3,.6,1),5.5)
			for i in 12:await physics_frame
			w.player.set_physics_process(false)
			await shot(pair[1])
		w.hud.visible=true
		w.player.motion_override=Vector2.ZERO
	w.player.position=Vector3(5.0,.04,8.5)
	w.npcs.igor.set_physics_process(true)
	w.room_name="东侧维修岗"
	w.hud.tick(0)
	w.story.give("wrench")
	w.story.give("report")
	w.perform("guard_report","igor")
	await shot("guard-reaction")
	w.hud.close()
	Engine.time_scale=6.0
	w.npcs.igor.anchor=Vector3(2.8,0,1.4)
	view_at(Vector3(5.3,.7,3.7),11.5)
	var door_captured=false
	for i in 1200:
		await physics_frame
		w.refresh_guard_context()
		if not door_captured and w.npcs.igor.position.z<3.4:
			door_captured=true
			w.npcs.igor.set_physics_process(false)
			w.npcs.igor.visual.get_node("Painter")._process(.2)
			await shot("guard-through-door")
			w.npcs.igor.set_physics_process(true)
		if w.story.guard_clear() and w.npcs.igor.position.distance_to(Vector3(2.8,0,1.4))<.65:
			w.npcs.igor.set_physics_process(false)
			await shot("guard-at-manifold")
			break
	Engine.time_scale=1.0
	w.refresh_guard_context()
	assert(w.story.guard_clear(),"Capture must show real out-of-sight clearance")
	w.hud.show_dialogue("hatch")
	await shot("hatch-after-diversion")
	w.ambience.stop();w.ambience.stream=null
	w.step_audio.stop();w.step_audio.stream=null
	await settle()
	w.queue_free()
	await settle()
	quit()
