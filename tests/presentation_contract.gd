extends SceneTree
const Story=preload("res://scripts/story.gd")
const Plans=preload("res://scripts/facility_layouts.gd")
var checks=0
var failures=0
var w
func _initialize():call_deferred("run")
func check(value:bool,message:String):
	checks+=1
	if not value:failures+=1;push_error(message)
func frames(n:int=5):
	for i in n:await physics_frame
func run():
	var s=Story.new();s.Comic.start(s,"official")
	var seen=[];var guard=0
	while s.flags.comic.active and guard<30:
		var p=s.Comic.panel(s);seen.append(s.flags.comic.node)
		check(p.has("lines") and p.lines.all(func(line):return line.speaker!=""),"every narrative fragment has an explicit voice")
		s.Comic.choose(s,0 if p.has("choices") else -1);guard+=1
	check("official_lenin" in seen and "official_inscription" in seen and "official_loss" in seen,"first surface journey includes landscape, inscription and losses before plant")
	check(seen.find("official_loss")<seen.find("official_plant"),"only three survivors arrive at waterworks")
	var footprints=[]
	for id in Plans.PLANS:
		var shape=[]
		for room in Plans.rooms(id):shape.append(str(room.rect))
		footprints.append(JSON.stringify(shape))
		var day=int(s.flags.get("story_day",17));s.Comic.start(s,"arrive_"+id)
		check(s.flags.story_day==day and s.Comic.panel(s).get("end","")=="map:"+id,"location introduction neither skips a day nor changes destination: "+id)
	check(footprints.size()==6 and footprints.all(func(shape):return footprints.count(shape)==1),"six facilities have separately authored footprints")
	var save="user://presentation_menu_test.json";DirAccess.remove_absolute(save)
	var menu=load("res://scenes/main_menu.tscn").instantiate();menu.save_path=save;root.add_child(menu);current_scene=menu;await frames()
	check(menu.continue_button.disabled,"main menu handles a missing save without entering a broken game")
	menu.show_settings();await frames();check(menu.dialog.find_children("*","HSlider",true,false).size()==4,"main menu settings drive four real audio buses")
	menu.close_dialog()
	s=Story.new();s.flags.intro_done=true;s.flags.plant_briefed=true
	var data=s.serialize();data.floor="waterworks";data.position=[15,.04,9];data.layout_revision=8
	FileAccess.open(save,FileAccess.WRITE).store_string(JSON.stringify(data));menu.read_save();menu.continue_game();await frames(12);w=current_scene
	check(w.floor_id=="waterworks" and w.story.f("plant_briefed"),"continue button loads the actual saved facility and quest state")
	check(w.player.art_id=="ivan_masked" and w.npcs.plant_guide.art_id=="commander_masked" and w.npcs.plant_veteran.art_id=="veteran_masked","all three factory survivors have mask artwork")
	var closed=w.campaign_gate.position;w.story.flags.plant_power=true;w.on_story_changed();await frames(12)
	check(w.campaign_gate.visible and w.campaign_gate.position.x>closed.x and w.campaign_gate.position.x<closed.x+2.35,"warehouse door visibly moves through an intermediate position")
	check(not w.campaign_gate.get_child(0).get_child(0).disabled,"door collision moves with its visible leaf instead of vanishing")
	await frames(75);check(is_equal_approx(w.campaign_gate.position.x,closed.x+2.35),"door reaches its open pocket")
	w.story.context.floor="waterworks";w.story.flags.arrival_v8_commune=false;w.travel_campaign("commune");await frames()
	check(w.hud.comic_active and w.story.flags.comic.node=="arrive_commune","travel introduces a new facility before entering its map")
	w.hud.comic_choose();await frames(12);w=current_scene
	check(w.floor_id=="commune" and w.npcs.commune_leader.art_id=="commune_leader","arrival returns to the intended distinct map and cast")
	var original=w.npcs.commune_leader.position;w.npcs.commune_leader.set_physics_process(false);w.npcs.commune_leader.position=original+Vector3(2,0,0);w.nearest="commune_leader";w.hud.comic_active=false;w.hud.close();w.hud.set_prompt("commune_leader")
	var expected=w.camera.unproject_position(w.npcs.commune_leader.global_position+Vector3(0,2.2,0))
	check(absf(w.hud.target_label.position.y-(expected.y-20))<1,"name cue follows the living actor rather than its authored spawn")
	var legacy=w.story.serialize();legacy.floor="commune";legacy.position=[100,.04,100]
	w.save_path=save;FileAccess.open(save,FileAccess.WRITE).store_string(JSON.stringify(legacy));w.load_game();await frames()
	check(w.player.position.distance_to(Plans.PLANS.commune.spawn)<.15 and w.story.f("plant_briefed"),"old map positions migrate to a safe entrance without losing story progress")
	w.return_menu();await frames(12);menu=current_scene
	check(menu.has_method("continue_game"),"pause flow can return to the main menu")
	menu.start_new();await frames(12);w=current_scene
	check(w.floor_id=="life" and not w.story.f("intro_done"),"new journey clears transient state and starts at the prologue")
	if DisplayServer.get_name()!="headless":check(w.hud.comic_active,"new journey actually presents the prologue on screen")
	w.queue_free();await frames()
	w=load("res://scenes/labor.tscn").instantiate();root.add_child(w);current_scene=w;await frames()
	w.npcs.armorer.set_physics_process(false);w.npcs.armorer.position+=Vector3(1.5,0,0);w.hud.set_prompt("armory")
	expected=w.camera.unproject_position(w.npcs.armorer.global_position+Vector3(0,2.2,0))
	check(absf(w.hud.target_label.position.y-(expected.y-20))<1,"aliased armory interaction also follows the moving quartermaster")
	w.queue_free();await frames()
	DirAccess.remove_absolute(save)
	print("PRESENTATION_RESULT checks=",checks," failures=",failures)
	quit(0 if failures==0 else 1)
