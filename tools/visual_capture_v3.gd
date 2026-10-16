extends SceneTree
## Actual running Godot frames; generated character art is never a scene backdrop.
var w
var folder="res://docs/screenshots/visual-v3"
var samples:Array=[]
var opacity_history:Array=[]
var metrics:Array=[]

func _initialize():call_deferred("run")
func settle(n:int=4):
	for i in n:await process_frame
	await RenderingServer.frame_post_draw
func veil_settle():
	for i in 65:w.wall_veil._process(1.0/60)
func view_at(focus:Vector3,size:float):
	w.camera.size=size
	w.camera.position=focus+Vector3(23,30,27)
	w.camera.look_at(focus)
func shot(id:String):
	await settle(2)
	var image=root.get_texture().get_image()
	image.save_png(folder+"/"+id+".png")
	image=null
	var row={"image":id,"fps_software_renderer":Engine.get_frames_per_second(),"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)}
	metrics.append(row)
	print("CAPTURE ",JSON.stringify(row))
func json_file(id:String,data):
	var file=FileAccess.open(folder+"/"+id+".json",FileAccess.WRITE)
	file.store_string(JSON.stringify(data,"\t"))
	file.close()

func run():
	DirAccess.make_dir_recursive_absolute(folder)
	w=load("res://scenes/d6.tscn").instantiate()
	root.add_child(w)
	await settle(3)
	w.set_physics_process(false)
	w.player.set_physics_process(false)
	for npc in w.npcs.values():npc.set_physics_process(false)
	w.hud.toast_label.text=""
	w.hud.toast_time=0
	# The overview is a visual presentation mode, preserving complete geometry.
	w.overview=true
	view_at(Vector3(0,.0,.8),31)
	veil_settle()
	await shot("overview")
	w.overview=false
	view_at(Vector3(-11.3,.2,-4.7),10.5)
	veil_settle()
	await shot("bedroom-close")
	w.hud.visible=false
	view_at(Vector3(-11.4,.65,-2.8),5.8)
	await shot("ivan-and-semyon")
	# An unchanged room with all complete wall shells fully opaque proves
	# geometry is present above the former 82cm cut; no collision is touched.
	w.wall_veil.set_process(false)
	for state in w.wall_veil.states:
		for i in state.mesh.mesh.get_surface_count():state.mesh.mesh.surface_get_material(i).set_shader_parameter("visibility",1.0)
		for entry in w.kit.veil_materials.get(state.mesh.get_instance_id(),[]):entry.material.set_shader_parameter("visibility",1.0)
	view_at(Vector3(-11.3,.4,-4.7),11)
	await shot("walls-complete")
	w.wall_veil.set_process(true)
	veil_settle()
	# Real controller movement along a full-height corridor wall and doorways.
	w.player.position=Vector3(-13.0,.04,1.20)
	w.player.velocity=Vector3.ZERO
	w.player.camera=null
	w.player.use_override=true
	w.player.motion_override=Vector2.RIGHT
	w.player.set_physics_process(true)
	var points=[Vector3(-13.5,1.40,.126),Vector3(-8.65,1.40,.126)]
	for frame in (0 if "--quick-refresh" in OS.get_cmdline_user_args() else 96):
		await physics_frame
		view_at(Vector3(w.player.position.x*.85,.45,1.2),12)
		if frame in [0,24,48,72,95]:await shot("wall-walk-%02d" % frame)
		var opacities=[]
		for state in w.wall_veil.states:opacities.append(snappedf(state.opacity,.00001))
		opacity_history.append({"frame":frame,"physics_step":Engine.get_physics_frames(),"player_x":w.player.position.x,"opacity":opacities})
		if frame%8==0:
			await RenderingServer.frame_post_draw
			var image=root.get_texture().get_image()
			var patches=[]
			var ray_veils=[]
			for point in points:
				var uv=w.camera.unproject_position(point)
				var color=Color(0,0,0,0)
				for x in range(-1,2):
					for y in range(-1,2):color+=image.get_pixel(clampi(roundi(uv.x)+x,0,image.get_width()-1),clampi(roundi(uv.y)+y,0,image.get_height()-1))
				color/=9.0
				patches.append([color.r,color.g,color.b])
				var ray_layers={}
				for index in w.wall_veil.states.size():
					var state=w.wall_veil.states[index]
					if state.bounds.grow(.005).intersects_segment(point+w.camera.global_basis.z*65.0,point)!=null:ray_layers[str(index)]=snappedf(state.opacity,.00001)
				ray_veils.append(ray_layers)
			samples.append({"frame":frame,"physics_step":Engine.get_physics_frames(),"player_x":w.player.position.x,"patches":patches,"ray_veils":ray_veils})
			image.save_png("/tmp/d6-v3-motion-%02d.png" % (frame/8))
			image=null
	w.player.motion_override=Vector2.ZERO
	w.player.set_physics_process(false)
	if not samples.is_empty():json_file("wall-patches",samples)
	if not opacity_history.is_empty():json_file("wall-opacity",opacity_history)
	w.hud.visible=true
	w.player.position=Vector3(-11.4,.04,-2.5)
	view_at(Vector3(-11.3,.15,-2),10.5)
	veil_settle()
	w.hud.show_dialogue("semyon")
	await shot("dialogue")
	w.hud.show_reply("nina",w.story.Narrative.CHAT.nina_semyon[2])
	await shot("everyday-conversation")
	w.hud.close()
	for id in w.story.ITEMS:w.story.give(id)
	w.hud.show_inventory()
	await shot("inventory")
	w.hud.show_map()
	await shot("map")
	w.hud.close()
	# Cast presentation uses the actual in-game atlas assets and is explicitly
	# labeled as an art review board, not a gameplay screenshot.
	var board=CanvasLayer.new()
	board.layer=50
	w.hud.visible=false
	root.add_child(board)
	var bg=ColorRect.new()
	bg.color=Color("101714")
	bg.size=Vector2(1600,1000)
	board.add_child(bg)
	var title=Label.new()
	title.text="D–6  /  居民角色素材览图"
	title.add_theme_font_override("font",w.kit.font)
	title.add_theme_font_size_override("font_size",32)
	title.position=Vector2(55,32)
	board.add_child(title)
	var names={"ivan":"伊万 · 23","semyon":"谢苗诺夫 · 工程兵","nina":"妮娜 · 维修工","mikhail":"米哈伊尔 · 库管","cook":"加琳娜 · 厨房","supply":"柳德米拉 · 配给员","commander":"科瓦廖夫 · 中尉","igor":"伊戈尔 · 岗哨","resident":"帕维尔 · 居民","diner":"维拉 · 居民","queue":"阿廖沙 · 居民"}
	var index=0
	for id in names:
		var texture=AtlasTexture.new()
		texture.atlas=load("res://assets/characters/"+id+".png")
		texture.region=Rect2(0,0,208,352)
		var figure=TextureRect.new()
		figure.texture=texture
		texture=null
		figure.size=Vector2(208,352)
		figure.position=Vector2(55+(index%6)*253,108+(index/6)*430)
		board.add_child(figure)
		var caption=Label.new()
		caption.text=names[id]
		caption.add_theme_font_override("font",w.kit.font)
		caption.add_theme_font_size_override("font_size",18)
		caption.add_theme_color_override("font_color",Color("d2bd94"))
		caption.position=figure.position+Vector2(-5,356)
		board.add_child(caption)
		index+=1
	await shot("cast-art-review")
	board.queue_free()
	json_file("capture-metrics",metrics)
	w.ambience.stop()
	w.step_audio.stop()
	await settle(3)
	w.queue_free()
	w=null
	await settle(3)
	quit()
