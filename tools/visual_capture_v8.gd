extends SceneTree
const Plans=preload("res://scripts/facility_layouts.gd")
var w
var folder="res://docs/screenshots/visual-v8"
func _initialize():call_deferred("run")
func settle(n:int=3):
	for i in n:await process_frame
	await RenderingServer.frame_post_draw
func freeze():
	w.set_physics_process(false);w.player.set_physics_process(false)
	for actor in w.npcs.values():actor.set_physics_process(false)
	w.story.flags.intro_done=true;w.story.flags.comic={"active":false};w.hud.comic_active=false;w.hud.close();w.hud.toast_time=0;w.hud.toast_label.text=""
func camera_at(position:Vector3,zoom:float):
	w.camera.position=position+Vector3(23,30,27);w.camera.look_at(position);w.camera.size=zoom
	for i in 80:w.wall_veil._process(1.0/60)
	for room in w.zones:
		if room.rect.has_point(Vector2(w.player.position.x,w.player.position.z)):w.room_name=room.name;break
	w.find_nearest()
func shot(name:String):
	if is_instance_valid(w):w.hud.finish_typing();w.hud.tick(0)
	await settle();root.get_texture().get_image().save_png(folder+"/"+name+".png");print("CAPTURE ",name)
func dispose():
	w.queue_free();await settle();w=null
func open_level(id:String):
	w=load("res://scenes/"+id+".tscn").instantiate();root.add_child(w);current_scene=w;await settle();freeze()
func run():
	DirAccess.make_dir_recursive_absolute(folder)
	var menu=load("res://scenes/main_menu.tscn").instantiate();root.add_child(menu);current_scene=menu;await settle();await shot("main-menu");menu.queue_free();await settle()
	await open_level("d6")
	for pair in [["intro_semyon","prologue-voice"],["official_surface","first-sky"],["official_inscription","lenin-inscription"],["official_loss","road-loss"]]:
		w.hud.comic_active=false;w.story.flags.comic={"active":false};w.hud.show_comic(pair[0]);await shot(pair[1])
	w.hud.comic_active=false;w.story.flags.comic={"active":false};w.hud.close();w.player.position=Vector3(13,.04,-3);camera_at(Vector3(13,.7,-4),15);await shot("d6-service-edge")
	await dispose()
	for id in Plans.PLANS:
		await open_level(id)
		var bounds:Rect2=w.zones[0].rect
		for room in w.zones:bounds=bounds.merge(room.rect)
		w.hud.visible=false
		var center=bounds.get_center();camera_at(Vector3(center.x,0,center.y),maxf(33,(bounds.size.x+bounds.size.y)*.48));await shot(id+"-overview");w.hud.visible=true
		if id=="waterworks":
			w.player.position=Vector3(12,.04,8.5);camera_at(Vector3(11,1,7),15);w.story.flags.plant_briefed=true;w.hud.refresh_status();await shot("waterworks-survivors")
			w.hud.show_dialogue("plant_veteran");await shot("veteran-dialogue");w.hud.close()
			w.player.position=Vector3(12,.04,1.2);camera_at(Vector3(12,1,0),11);await shot("warehouse-closed")
			w.story.flags.plant_power=true;w.on_story_changed();w.gate_tween.pause();w.gate_tween.custom_step(.48);await shot("warehouse-opening")
			w.gate_tween.custom_step(1);await shot("warehouse-open")
		elif id=="commune":
			w.player.position=Vector3(-2,.04,5);camera_at(Vector3(-2,1,3),19);await shot("commune-square")
			w.player.position=Vector3(-5,.04,-5);camera_at(Vector3(-5,1,-6),12);w.hud.show_dialogue("commune_leader");await shot("commune-leader")
			w.hud.close();w.story.give("frequency");w.hud.show_dialogue("commune_leader")
			click_choice("commune_leader","c_commune_route");await shot("commune-call-sign");w.hud.close()
			w.player.position=Vector3(20,.04,-2);camera_at(Vector3(19,1,-6),14);w.hud.show_dialogue("commune_printer")
			click_choice("commune_printer","c_press_accept");await shot("printer-commission");w.hud.close()
			w.story.act("c_grow_accept");w.story.act("c_press_ledger");w.story.flags.tracked_quest="commune_press";w.hud.show_journal();await shot("accepted-journal");w.hud.close()
		elif id=="sech":
			w.player.position=Vector3(8,.04,-1);camera_at(Vector3(5,1,-3),18);await shot("sech-carriages")
		elif id=="coal":
			w.player.position=Vector3(10,.04,-4);camera_at(Vector3(9,1,-6),16);await shot("coal-care")
		elif id=="starcity":
			w.story.flags.star_access=true;w.on_story_changed();w.gate_tween.custom_step(2)
			w.player.position=Vector3(1,.04,-7);camera_at(Vector3(0,1,-8),18);await shot("starcity-control")
			w.player.position=Vector3(18,.04,2);camera_at(Vector3(16,1,0),14);w.hud.show_dialogue("star_technician");await shot("starcity-technician")
		await dispose()
	quit()
func click_choice(id:String,key:String):
	var options=w.story.view(id).options.filter(func(o):return o.key==key)
	assert(options.size()==1 and options[0].enabled)
	for b in w.hud.modal.find_children("*","Button",true,false):
		if b.text==options[0].text:b.pressed.emit();return
	assert(false,"visible dialogue choice "+key)
