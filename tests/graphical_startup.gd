extends SceneTree
var checks=0
var failed=0
var w
func _initialize():call_deferred("run")
func frames(n:int=3):
	for i in n:await process_frame
	await RenderingServer.frame_post_draw
func check(ok:bool,msg:String):
	checks+=1
	if not ok:failed+=1;push_error(msg)
func press(text:String):
	for control in w.hud.modal.find_children("*","Button",true,false):
		if control.text==text:control.pressed.emit();return
	check(false,"UI button exists: "+text)
func run():
	w=load("res://scenes/d6.tscn").instantiate();root.add_child(w);current_scene=w
	await frames(4)
	check(w.hud.comic_active and w.story.flags.comic.node=="history_war","normal graphical launch starts historical prologue")
	for node in ["history_family","history_years","intro_wake","intro_semyon"]:
		press("继续");await frames();check(w.story.flags.comic.node==node,"chronological prologue "+node)
	check(w.story.flags.comic.node=="intro_semyon","continue opens Semyon's conscription conversation")
	press(w.story.Comic.panel(w.story).choices[0].text);await frames()
	check(w.story.flags.comic.node=="intro_errand","Semyon gives vitamin errand before reporting")
	press("穿上外套，出门");await frames()
	check(w.story.f("intro_done") and not w.hud.modal_visible(),"opening returns control to player")
	check(w.story.objective().contains("维生素"),"first task is the vitamin ration")
	w.player.position=Vector3(12,.04,-5.3);w.player.velocity=Vector3.ZERO
	w.interact("supply");await frames()
	var ration_text=""
	for o in w.story.view("supply").options:
		if o.key=="vitamins":ration_text=o.text
	press(ration_text);await frames()
	check(w.story.f("vitamins_taken") and w.story.has("vitamins"),"actual dialogue callback grants daily ration")
	check(w.story.objective().contains("作业层"),"reporting task follows the ration")
	w.hud.close();w.perform("travel_down","lift");await frames(8);w=current_scene
	check(w.floor_id=="labor" and w.story.f("vitamins_taken"),"actual stairs callback transfers story to labor floor")
	check(w.story.conversations.has("supply") and w.story.economy.military==18,"stairs retain chat and ammunition")
	w.ambience.stop();w.ambience.stream=null;w.step_audio.stop();w.step_audio.stream=null
	await frames();w.queue_free();await frames()
	print("GRAPHICAL_STARTUP_RESULT checks=",checks," failures=",failed)
	quit(0 if failed==0 else 1)
