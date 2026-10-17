extends SceneTree
var w
var folder="res://docs/screenshots/visual-v6"
func _initialize():call_deferred("run")
func settle(n:int=4):
	for i in n:await process_frame
	await RenderingServer.frame_post_draw
func freeze():
	w.set_physics_process(false);w.player.set_physics_process(false)
	for a in w.npcs.values():a.set_physics_process(false)
	w.story.flags.intro_done=true
	w.hud.comic_active=false;w.story.flags.comic={"active":false};w.hud.close()
	w.hud.toast_time=0;w.hud.toast_label.text=""
func view_at(p:Vector3,sz:float):
	w.camera.position=p+Vector3(23,30,27);w.camera.look_at(p);w.camera.size=sz
	for i in 80:w.wall_veil._process(1.0/60)
	for zone in w.zones:
		if zone.rect.has_point(Vector2(w.player.position.x,w.player.position.z)):w.room_name=zone.name;break
	if w.floor_id=="labor" and w.player.position.x< -10 and w.player.position.z>4:w.room_name="生活层楼梯间"
	w.hud.tick(0)
func shot(id:String):
	w.hud.finish_typing();await settle()
	root.get_texture().get_image().save_png(folder+"/"+id+".png");print("CAPTURE ",id)
func dispose():
	w.queue_free();await settle()
func run():
	DirAccess.make_dir_recursive_absolute(folder)
	if "--stairs-only" in OS.get_cmdline_user_args():
		w=load("res://scenes/labor.tscn").instantiate();root.add_child(w);await settle();freeze()
		w.overview=true;view_at(Vector3(1,0,.5),44);await shot("labor-overview")
		w.overview=false;w.player.position=Vector3(-12.2,.04,5);view_at(Vector3(-12,1,6.3),12);await shot("stairwell")
		await dispose();quit();return
	w=load("res://scenes/d6.tscn").instantiate();root.add_child(w);await settle();freeze()
	w.hud.show_comic("intro");w.story.flags.comic.node="intro_semyon";w.hud.show_comic();await shot("fullscreen-opening")
	w.hud.show_comic_pause();await shot("audio-settings")
	await dispose()
	w=load("res://scenes/labor.tscn").instantiate();root.add_child(w);await settle();freeze()
	w.overview=true;view_at(Vector3(1,0,.5),44);await shot("labor-overview")
	w.overview=false;w.player.position=Vector3(-12.2,.04,5);view_at(Vector3(-12,1,6.3),12);await shot("stairwell")
	await dispose()
	for id in ["waterworks","commune","sech","coal","starcity"]:
		w=load("res://scenes/"+id+".tscn").instantiate();root.add_child(w);await settle();freeze()
		w.overview=true;view_at(Vector3(0,0,0),39 if id!="commune" else 42);await shot(id+"-overview")
		w.overview=false
		var focus={"waterworks":Vector3(-12,0,-7),"commune":Vector3(-13,0,-7),"sech":Vector3(0,0,-6),"coal":Vector3(10,0,-5),"starcity":Vector3(13,0,-8)}[id]
		w.player.position=focus+Vector3(0,.04,2);view_at(focus+Vector3(0,.5,0),16);await shot(id+"-detail")
		if id=="starcity":
			w.story.flags.star_access=true;w.story.flags.father_met=true;w.story.flags.father_answered=true
			w.story.flags.father_semyon=true;w.story.flags.water_secured=true;w.story.flags.radio_fixed=true
			for item in ["knife","photo","frequency","archive","anna_note"]:w.story.give(item)
			w.hud.refresh_status()
			w.hud.show_dialogue("star_father");await shot("father-dialogue")
			w.story.Campaign.finish(w.story,"bridge");w.hud.show_chapter_end();await shot("ending")
		await dispose()
	quit()
