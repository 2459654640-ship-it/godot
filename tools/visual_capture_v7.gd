extends SceneTree
var w
var folder="res://docs/screenshots/visual-v7"
func _initialize():call_deferred("run")
func settle(n:int=4):
	for i in n:await process_frame
	await RenderingServer.frame_post_draw
func freeze():
	w.set_physics_process(false);w.player.set_physics_process(false)
	for a in w.npcs.values():a.set_physics_process(false)
	w.story.flags.intro_done=true;w.story.flags.comic={"active":false};w.hud.comic_active=false;w.hud.close()
	w.hud.toast_time=0;w.hud.toast_label.text=""
func view_at(pos:Vector3,sz:float):
	w.camera.position=pos+Vector3(23,30,27);w.camera.look_at(pos);w.camera.size=sz
	for i in 80:w.wall_veil._process(1.0/60)
	for z in w.zones:
		if z.rect.has_point(Vector2(w.player.position.x,w.player.position.z)):w.room_name=z.name;break
	w.hud.tick(0)
func shot(name:String):
	w.hud.finish_typing();w.hud.tick(0);await settle()
	root.get_texture().get_image().save_png(folder+"/"+name+".png");print("CAPTURE ",name)
func dispose():
	w.queue_free();await settle()
func run():
	DirAccess.make_dir_recursive_absolute(folder)
	w=load("res://scenes/d6.tscn").instantiate();root.add_child(w);await settle();freeze()
	w.story.flags.nina_job=true;w.story.flags.cook_job=true;w.story.flags.vitamins_taken=true;w.story.flags.tracked_quest="kitchen"
	w.story.economy.health=68;w.story.economy.food=32;w.hud.refresh_status()
	w.player.position=Vector3(5,.04,-3.8)
	view_at(Vector3(5,.4,-4.3),16);await shot("hud-and-benches")
	w.hud.show_journal();await shot("journal-tasks")
	w.hud.show_journal("leads");await shot("journal-leads")
	w.hud.show_journal("map");await shot("journal-map")
	w.hud.close();w.hud.show_pause();await shot("audio-settings")
	await dispose()
	w=load("res://scenes/labor.tscn").instantiate();root.add_child(w);await settle();freeze()
	w.player.position=Vector3(-12.2,.04,5);view_at(Vector3(-12.2,1,6.7),13);await shot("stairwell")
	await dispose()
	w=load("res://scenes/waterworks.tscn").instantiate();root.add_child(w);await settle();freeze()
	w.story.act("c_plant_brief");w.player.position=Vector3(10,.04,6);view_at(Vector3(9,.6,5.7),16);await shot("waterworks-guide")
	w.hud.show_journal("map");await shot("waterworks-map")
	w.hud.show_comic("return_crossing");await shot("waterworks-cinematic")
	await dispose()
	w=load("res://scenes/commune.tscn").instantiate();root.add_child(w);await settle();freeze()
	w.player.position=Vector3(1,.04,4);view_at(Vector3(1,.5,6.2),10);w.hud.show_dialogue("commune_anna");await shot("anna")
	w.hud.show_comic("solo_commune");await shot("commune-cinematic")
	await dispose()
	w=load("res://scenes/starcity.tscn").instantiate();root.add_child(w);await settle();freeze()
	w.story.flags.star_access=true;w.on_story_changed();w.player.position=Vector3(13,.04,-5);view_at(Vector3(13,.5,-7.5),12)
	w.hud.show_dialogue("star_father");await shot("father")
	w.hud.show_comic("father_reunion");await shot("father-cinematic")
	await dispose();quit()
