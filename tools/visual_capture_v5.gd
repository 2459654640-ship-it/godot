extends SceneTree
var w
var folder="res://docs/screenshots/visual-v5"
func _initialize():call_deferred("run")
func settle(n:int=3):
	for i in n:await process_frame
	await RenderingServer.frame_post_draw
func view_at(focus:Vector3,sz:float):
	w.camera.position=focus+Vector3(23,30,27);w.camera.look_at(focus);w.camera.size=sz
	for i in 65:w.wall_veil._process(1.0/60)
	if not w.hud.modal_visible():w.find_nearest()
func shot(id:String):
	w.hud.finish_typing();await settle()
	root.get_texture().get_image().save_png(folder+"/"+id+".png");print("CAPTURE ",id)
func freeze():
	w.set_physics_process(false);w.player.set_physics_process(false)
	for a in w.npcs.values():a.set_physics_process(false)
	w.hud.toast_time=0;w.hud.toast_label.text=""
func dispose():
	w.ambience.stop();w.ambience.stream=null;w.step_audio.stop();w.step_audio.stream=null
	await settle();w.queue_free();await settle()
func run():
	DirAccess.make_dir_recursive_absolute(folder)
	w=load("res://scenes/d6.tscn").instantiate();root.add_child(w);await settle();freeze()
	if "--labor-only" not in OS.get_cmdline_user_args():
		view_at(Vector3(-11,.4,-4),12)
		w.hud.show_comic("intro");await shot("opening")
		w.hud.comic_active=false;w.hud.close();w.story.flags.comic.active=false;w.story.flags.intro_done=true
		w.hud.show_dialogue("semyon");w.hud.last_choice="「老爹，说实话，我有点怕。」";w.perform("semyon_fear","semyon")
		await shot("chat-history")
		w.hud.close();w.hud.show_shop();await shot("shop")
		w.hud.close();w.hud.show_journal();await shot("journal")
		w.hud.close();w.overview=true;view_at(Vector3(-5.5,0,-1),40);await shot("life-overview")
		w.overview=false;w.player.position=Vector3(12,.04,6.6);view_at(Vector3(13,.4,6.4),12);await shot("open-ramp")
		w.story.Comic.start(w.story,"official");w.story.flags.comic.node="official_train";w.hud.show_comic();await shot("official-trolley")
		w.story.flags.comic.node="official_surface";w.hud.show_comic();await shot("surface")
		w.story.Comic.start(w.story,"solo");w.story.flags.comic.node="solo_sergey";w.hud.show_comic();await shot("sergey")
	await dispose()
	w=load("res://scenes/labor.tscn").instantiate();root.add_child(w);await settle();freeze()
	w.overview=true;view_at(Vector3(1,0,.5),44);w.hud.tick(0);await shot("labor-overview")
	w.overview=false;w.player.position=Vector3(18,.04,-10);w.room_name="正门候车区";view_at(Vector3(20,.5,-8.5),18);w.hud.tick(0);await shot("main-gate")
	w.player.position=Vector3(0,.04,-5.2);w.room_name="医务间";view_at(Vector3(.2,.4,-8),16);w.hud.tick(0);await shot("medical")
	w.player.position=Vector3(10,.04,-5.2);w.room_name="装备库";view_at(Vector3(10,.4,-8),16);w.hud.tick(0);await shot("armory")
	w.hud.show_map();await shot("labor-map")
	await dispose();quit()
