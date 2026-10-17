extends SceneTree
## Capture the running game, including actual CharacterBody3D motion at a wall.
var w
var folder="res://docs/screenshots/visual-v2"
var sample_frames:Array=[]

func _initialize():call_deferred("run")

func settle(frames:int=12):
	for i in frames:await process_frame
	await RenderingServer.frame_post_draw

func snapshot(name:String):
	await settle(3)
	var pixels=root.get_texture().get_image()
	pixels.save_png(folder+"/"+name+".png")
	print("CAPTURE: ",name," ",pixels.get_size()," fps=",Engine.get_frames_per_second()," draw_calls=",Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	pixels=null

func camera_at(focus:Vector3,size:float):
	w.camera_size=size
	w.camera.size=size
	w.camera.position=focus+Vector3(23,30,27)
	w.camera.look_at(focus)

func run():
	DirAccess.make_dir_recursive_absolute(folder)
	w=load("res://scenes/d6.tscn").instantiate()
	root.add_child(w)
	await settle()
	w.set_physics_process(false)
	w.hud.toast_time=0
	w.hud.toast_label.text=""
	for npc in w.npcs.values():npc.set_physics_process(false)
	camera_at(Vector3(0,0,0.8),31)
	await snapshot("overview")
	camera_at(Vector3(-11.3,0,-4.6),11.8)
	await snapshot("bedroom-close")
	# Keep all original NPC anchors. Only the test player moves, with the real
	# controller and unchanged acceleration/capsule, along the residential wall.
	w.player.position=Vector3(-12.9,0.04,1.20)
	w.player.velocity=Vector3.ZERO
	w.player.camera=null
	w.player.use_override=true
	w.player.motion_override=Vector2.RIGHT
	# Low masonry patches remain inside the scene, clear of HUD panels and
	# moving cast shadows, so temporal samples measure surfaces rather than UI.
	var points=[Vector3(-11.824,.45,-5.8),Vector3(-7.874,.52,-5),Vector3(-13.5,.45,.126)]
	for frame in range(96):
		await physics_frame
		camera_at(Vector3(w.player.position.x*0.78,0.4,-1.6),14)
		w.find_nearest()
		if frame in [0,47,95]:await snapshot("wall-walk-%02d" % frame)
		if frame%6==0:
			await RenderingServer.frame_post_draw
			var pixels=root.get_texture().get_image()
			var samples=[]
			for point in points:
				var uv=w.camera.unproject_position(point)
				var color=Color(0,0,0,0)
				for x in range(-1,2):
					for y in range(-1,2):color+=pixels.get_pixel(clampi(roundi(uv.x)+x,0,pixels.get_width()-1),clampi(roundi(uv.y)+y,0,pixels.get_height()-1))
				color/=9
				samples.append([color.r,color.g,color.b])
			sample_frames.append({"frame":frame,"player_x":w.player.position.x,"samples":samples})
			pixels.save_png("/tmp/d6-wall-motion-%02d.png" % (frame/6))
			pixels=null
	w.player.motion_override=Vector2.ZERO
	await settle()
	var sample_file=FileAccess.open(folder+"/wall-motion-samples.json",FileAccess.WRITE)
	sample_file.store_string(JSON.stringify(sample_frames,"\t"))
	sample_file.close()
	camera_at(Vector3(-11.7,0,-1.3),10)
	w.player.position=Vector3(-11.4,0.04,-2.5)
	w.find_nearest()
	w.hud.show_dialogue("semyon")
	await snapshot("dialogue")
	w.hud.close()
	# Inventory demonstration populates a transient test state, never a save.
	for id in ["knife","vodka","photo","map","mask","wrench"]:w.story.give(id)
	w.hud.show_inventory()
	await snapshot("inventory")
	w.hud.show_map()
	await snapshot("map")
	w.hud.close()
	w.ambience.stop()
	w.step_audio.stop()
	await settle(3)
	w.queue_free()
	w=null
	await settle(3)
	quit()
