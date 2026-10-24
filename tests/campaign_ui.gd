extends SceneTree
var w
var checks=0
var errors=0
func _initialize():call_deferred("run")
func frames(n:int=5):
	for i in n:await process_frame
func check(ok:bool,msg:String):
	checks+=1
	if not ok:errors+=1;push_error(msg)
func press_action(id:String,key:String):
	w.interact(id);await frames()
	var text=""
	for o in w.story.view(id).options:
		if o.key==key and o.enabled:text=o.text
	check(text!="","enabled authored UI action: "+key)
	for b in w.hud.modal.find_children("*","Button",true,false):
		if b.text==text:b.pressed.emit();await frames(6);return
	check(false,"button callback found: "+key)
func press_text(text:String):
	for b in w.hud.modal.find_children("*","Button",true,false):
		if b.text==text:b.pressed.emit();await frames(8);return
	check(false,"button exists: "+text)
func run():
	# The old v5 endpoint must lead to a playable facility through an actual button.
	w=load("res://scenes/d6.tscn").instantiate();root.add_child(w);current_scene=w;await frames()
	w.story.flags.intro_done=true;w.story.flags.comic={"active":false};w.story.flags.chapter_endpoint="waterworks_exterior";w.story.ending=true
	w.hud.comic_active=false;w.hud.show_chapter_end();await frames()
	await press_text("进入水处理厂");w=current_scene
	check(w.hud.comic_active and w.story.flags.comic.node=="arrive_waterworks","first facility entry introduces the location")
	await press_text("进入设施");w=current_scene
	check(w.floor_id=="waterworks" and not w.story.ending,"v5 endpoint migrates to waterworks map")
	await press_action("plant_diagram","c_plant_read")
	await press_action("plant_bypass","c_plant_bleed")
	await press_action("plant_bench","c_plant_fuse")
	await press_action("plant_power","c_plant_power")
	await press_action("plant_store","c_plant_open")
	await press_action("plant_exit","c_plant_leave")
	for i in 65:await physics_frame # Wait for the visible steel gate to finish opening.
	check(w.hud.comic_active and w.story.flags.comic.node=="return_crossing","real exit callback starts full-screen journey")
	check(w.hud.modal.position==Vector2.ZERO and w.hud.modal.size==w.hud.get_viewport_rect().size,"journey covers entire viewport")
	var save="user://campaign_ui_transit.json";w.save_path=save;w.save_game()
	var original=w.story.flags.comic.node;w.hud.comic_choose(0);w.load_game();await frames(10);w=current_scene
	check(w.story.flags.comic.node==original and w.hud.comic_active,"saving mid-journey resumes at the unread node")
	var panels=0
	while w.floor_id=="waterworks" and w.story.flags.get("comic",{}).get("active",false) and panels<20:
		var p:Dictionary=w.story.Comic.panel(w.story)
		w.hud.comic_choose(1 if w.story.flags.comic.node=="return_standoff" else (0 if p.has("choices") else -1))
		await frames(10);w=current_scene;panels+=1
	check(panels<20,"expanded checkpoint and reception route does not loop")
	check(w.floor_id=="commune" and w.story.f("water_secured"),"novel choice enters commune retaining waterworks state")
	# Cross-facility load restores the original floor and active full-screen comic.
	w.save_path=save;w.load_game();await frames(10);w=current_scene
	check(w.floor_id=="waterworks" and w.story.flags.comic.active,"cross-facility loader restores transit in the correct map")
	DirAccess.remove_absolute(save)
	check(AudioServer.get_bus_index("Music")>=0 and AudioServer.get_bus_index("Effects")>=0,"separate music and effect controls exist")
	check(w.ambience.get_meta("score_source","")=="shift_below.ogg" and w.step_audio.stream.resource_path.ends_with("step.wav"),"music and footstep use intended assets, not ventilation noise")
	var session=root.get_node("Session");var old=session.volume("Effects");session.set_volume("Effects",.25,false)
	check(is_equal_approx(session.volume("Effects"),.25),"volume slider changes the actual audio bus")
	session.set_volume("Effects",old,false)
	w.queue_free();await frames()
	print("CAMPAIGN_UI_RESULT checks=",checks," failures=",errors)
	quit(0 if errors==0 else 1)
