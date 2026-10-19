extends SceneTree
const Story=preload("res://scripts/story.gd")
const Journal=preload("res://scripts/journal.gd")
var checks=0
var failures=0
var w
func _initialize():call_deferred("run")
func check(ok:bool,why:String):
	checks+=1
	if not ok:failures+=1;push_error(why)
func frames(n:int=3):
	for i in n:await physics_frame
func press_action(id:String,key:String):
	w.interact(id);await frames()
	var choice=""
	for option in w.story.view(id).options:
		if option.key==key and option.enabled:choice=option.text
	for b in w.hud.modal.find_children("*","Button",true,false):
		if choice!="" and b.text==choice:b.pressed.emit();await frames();return
	check(false,"authored dialogue callback exists: "+key)
func run():
	var s=Story.new();s.context.floor="life"
	check(Journal.tasks(s).is_empty(),"unaccepted tasks never populate the journal")
	check(not Journal.leads(s).is_empty() and not JSON.stringify(Journal.leads(s)).contains("谢尔盖"),"leads suggest local people without future spoilers")
	s.flags.intro_done=true
	check(Journal.active(s).id=="journey","opening main route is the default focus")
	s.flags.nina_job=true;s.flags.cook_job=true
	Journal.track(s,"kitchen")
	check(Journal.active(s).id=="kitchen","player can choose one active quest while others stay pending")
	check(Journal.tasks(s).filter(func(t):return not t.done and t.id!="kitchen").size()==4,"accepted backlog stays separate from focused work")
	s.flags.valve=true
	check(not Journal.tasks(s).filter(func(t):return t.id=="kitchen")[0].done,"repair is not complete until reward hand-in")
	s.flags.soup_claimed=true
	check(Journal.active(s).id!="kitchen","completed focus moves to the next accepted task")
	s.give("photo");check(not JSON.stringify(Journal.tasks(s)).contains('"id":"photo"'),"found photo is a lead until player accepts it")
	s.flags.quest_photo=true;check(Journal.tasks(s).any(func(t):return t.id=="photo"),"explicitly accepting photo lead adds the quest")
	s.context.floor="waterworks";check(Journal.active(s).is_empty(),"inaccessible old tasks do not override local exploration")
	s.act("c_plant_brief");check(Journal.active(s).target=="plant_diagram" and Journal.active(s).step.contains("入口"),"waterworks guidance identifies the actual entrance desk")
	s.act("c_plant_read");check(Journal.active(s).target=="plant_bypass","guidance advances after a real discovery")
	var t=Story.new();t.restore(JSON.parse_string(JSON.stringify(s.serialize())));t.context=s.context.duplicate()
	check(Journal.active(t).target==Journal.active(s).target,"focus and quest stages survive a save")
	# Long reading never depletes food; movement is intentionally forgiving.
	s=Story.new();s.Economy.advance(s,3600,false)
	check(s.economy.food==60 and s.economy.health==100,"one hour reading causes no hunger or damage")
	s.Economy.advance(s,1200,true)
	check(s.economy.food==50,"twenty minutes of walking costs only ten satiety")
	s.economy.food=0;s.economy.health=35;s.Economy.advance(s,7200,true)
	check(s.economy.food==0 and s.economy.health==35,"even two hours hungry cannot kill or drain health")
	s.economy.food=60;s.Economy.advance(s,180,true)
	check(s.economy.health==37,"well-fed light recovery is slow and bounded")
	s.context.floor="life";s.economy.food=10;s.act("meal_cook")
	check(s.last_action_valid and s.economy.food==75,"free daily shelter meal prevents a resource trap")
	s.economy.food=20;s.act("meal_cook");check(not s.last_action_valid and s.economy.food==20,"daily meals cannot be spammed")
	s.flags.story_day=17;s.act("meal_cook");check(s.last_action_valid,"meal renews on the next actual story day")
	# Informational dialogue is read once, saved as history, never re-rewarded.
	s=Story.new();s.act("semyon_morning");check(s.last_action_valid,"new personal topic is initially available")
	s.act("semyon_morning");check(not s.last_action_valid,"read personal topic is not repeatedly clickable")
	t=Story.new();t.restore(JSON.parse_string(JSON.stringify(s.serialize())));t.act("semyon_morning")
	check(not t.last_action_valid,"read topic state persists after load")
	var legacy=s.serialize().duplicate(true);legacy.erase("read_topics")
	s.Conversation.reply(s,"semyon",s.Narrative.CHAT.semyon_morning[1],s.last_reply)
	legacy.conversations=s.conversations.duplicate(true);t.restore(legacy)
	t.act("semyon_morning");check(not t.last_action_valid,"v6 conversation history migrates actually read topics")
	t.act("semyon_advice");check(t.last_action_valid,"legacy history does not hide topics the player never read")
	w=load("res://scenes/d6.tscn").instantiate();root.add_child(w);await frames()
	w.story.flags.intro_done=true;w.story.flags.cook_job=true;w.story.flags.nina_job=true
	w.hud.refresh_status();w.hud.show_journal();await frames()
	var texts=[]
	for b in w.hud.find_children("*","Button",true,false):texts.append(b.text)
	check(not texts.has("M  地图") and texts.has("J  手记"),"one HUD journal button replaces separate map and journal entries")
	check(w.hud.health_bar.value==100 and w.hud.food_bar.value==60,"health and satiety are actually visible")
	for tab in ["tasks","map","lore","leads","history","closed"]:w.hud.show_journal(tab);await frames();check(w.hud.modal_visible(),"unified journal tab renders: "+tab)
	check(not w.hud.prompt.visible,"interaction prompt does not overlap a modal")
	check(w.step_audio.bus=="Footsteps" and w.step_audio.volume_db<=-12 and w.step_samples.size()==4,"quiet varied footsteps use an independent audio bus")
	w.queue_free();await frames()
	w=load("res://scenes/starcity.tscn").instantiate();root.add_child(w);current_scene=w;await frames()
	w.story.flags.story_day=22;w.story.flags.story_time="18:10"
	await press_action("star_perimeter_call","c_star_perimeter_name")
	check(w.story.f("star_inquiry_filed") and not w.story.f("star_access"),"real perimeter dialogue records inquiry without granting access")
	check(w.story.flags.story_day==22 and w.story.flags.story_time=="18:10","perimeter conversation preserves current time")
	var save="user://refinement_perimeter.json";w.save_path=save;w.save_game();w.load_game();await frames(10);w=current_scene
	check(w.story.f("star_inquiry_filed") and w.story.context.floor=="starcity","perimeter dialogue state survives real scene reload")
	check(not w.story.Campaign.available(w.story,"star_perimeter_name"),"inquiry cannot be repeated as a new topic")
	DirAccess.remove_absolute(save)
	w.queue_free();await frames()
	print("REFINEMENT_RESULT checks=",checks," failures=",failures)
	quit(0 if failures==0 else 1)
