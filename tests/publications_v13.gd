extends SceneTree
const Publications=preload("res://scripts/publications.gd")
const Story=preload("res://scripts/story.gd")
const Blocks=preload("res://scripts/blocks_game.gd")
var checks=0
var failures=0
func _initialize():call_deferred("run")
func check(ok:bool,message:String):
	checks+=1
	if not ok:failures+=1;push_error(message)
func frames(n:int=4):
	for i in n:await physics_frame
func run():
	var s=Story.new();var entries=Publications.data().entries
	check(entries.size()==26 and Publications.data().series.size()==7,"twenty-six readable publications in seven series")
	var district=entries.filter(func(book):return book.series=="east_district_papers")
	check(district.size()==7 and district.filter(func(book):return book.source.kind=="pickup").size()==6,"the district series includes six new copies and the existing family letter")
	var ids={}
	for book in entries:
		check(not ids.has(book.id) and book.body.length()>150 and book.hint!="","unique publication has authored prose and a contextual hint")
		ids[book.id]=true
		check(Publications.icon(book)!=null,"cover is a real imported asset")
		check(Publications.read(s,book.id).is_empty(),"unknown texts cannot be opened")
	var id=entries[0].id
	check(Publications.acquire(s,id) and not Publications.acquire(s,id),"each copy acquired exactly once")
	check(Publications.count(s)==1 and not s.flags.publications[id].read,"collection progress counts new unread copy")
	check(Publications.read(s,id).body==entries[0].body and s.flags.publications[id].read,"reading reveals real body and records read status")
	var old=Story.new();old.restore({"flags":{"c_done_press_deliver":true},"economy":{}})
	check(Publications.count(old)==1 and not old.flags.publications.values()[0].read,"old quest save receives earned publication without replaying reward")
	var balance=old.economy.military
	check(Publications.reward(old,"press_deliver").is_empty() and old.economy.military==balance,"repeated quest reward grants neither duplicate book nor money")
	var restored=Story.new();restored.restore(s.serialize())
	check(Publications.count(restored)==1 and restored.flags.publications[id].read,"owned and read status survive save/restore")
	var broken=Story.new();broken.restore({"flags":{"publications":42}})
	check(Publications.count(broken)==0,"malformed optional legacy collection value is safely normalized")
	var letter=Story.new();letter.restore({"flags":{"c_done_city_family_read":true},"economy":{}})
	check(Publications.owned(letter,"pub_city_family") and Publications.count(letter,"east_district_papers")==1,"the family letter keeps its ownership when moved into the new series")
	var radio=Story.new();radio.context.floor="east_district";radio.flags.city_radio_online=true
	Publications.acquire(radio,"pub_east_broadcast_edit")
	check(not radio.view("city_radio_panel").body.contains("用铅笔改过"),"a recovered but unread draft does not change what Ivan knows")
	Publications.read(radio,"pub_east_broadcast_edit")
	check(radio.view("city_radio_panel").body.contains("用铅笔改过"),"the existing radio acknowledges its draft after reading and playback")
	var text=Story.new();text.Comic.start(text,"late_s3_home")
	text.flags.late_s3_people_first=true
	check(text.Comic.panel(text).body.contains("借了半碗面粉") and not text.Comic.panel(text).body.contains("搬到床脚"),"the people-first return still shows the grain left behind")
	text.flags.late_s3_all_carried=true
	check(text.Comic.panel(text).body.contains("搬到床脚") and not text.Comic.panel(text).body.contains("借了半碗面粉"),"the full delivery shows the actual grain return")
	text.Comic.start(text,"late_d2_home");text.flags.late_d2_polished=true
	check(text.Comic.panel(text).body.contains("再跑下来") and not text.Comic.panel(text).body.contains("贴上报告抄件"),"the filed supply total leaves residents with conflicting information")
	text.flags.late_d2_polished=false;text.flags.late_d2_truthful=true
	check(text.Comic.panel(text).body.contains("贴上报告抄件"),"the corrected supply report is available to residents")
	var game=Blocks.new();root.add_child(game);await frames()
	game.set_process(false)
	game.bag.clear();var seven={}
	for i in 7:seven[game.take_bag()]=true
	check(seven.size()==7,"seven-piece bag cannot starve a piece")
	game.restart();game.shape=0;game.piece_rotation=1;game.position_cell=Vector2i(7,1)
	game.turn();check(game.valid(game.position_cell,game.piece_rotation),"rotation against wall uses a legal kick")
	check(not game.valid(Vector2i(-5,0),0) and not game.valid(Vector2i(3,20),0),"pieces respect left edge and floor")
	for y in range(16,20):game.board[y].fill(2)
	check(game.clear_rows()==4 and game.board.size()==20 and game.board[0].has(-1),"four complete rows clear together and refill at top")
	game.restart();game.started=true;game.shape=1;game.position_cell=Vector2i(3,0);game.hard_drop()
	var occupied=0
	for row in game.board:
		for cell in row:
			if cell>=0:occupied+=1
	check(occupied==4 and game.score>0 and game.best==game.score,"hard drop locks one piece and updates personal record")
	game.paused=true;var before=game.position_cell;game._process(5)
	check(game.position_cell==before,"pause stops falling")
	game.queue_free();await frames()
	var locations=0
	for floor_id in ["life","labor","waterworks","commune","sech","coal","starcity","star_interior","east_district"]:
		if floor_id=="east_district":
			var outside=Story.new();outside.flags.merge({"intro_done":true,"east_power_restored":true,"east_crossing_open":true,"east_home":"commune"})
			root.get_node("Session").pending={"story":outside.serialize(),"floor":floor_id,"position":Vector3.INF}
		var w=load("res://scenes/"+("d6" if floor_id=="life" else floor_id)+".tscn").instantiate()
		root.add_child(w);current_scene=w;await frames(5);w.hud.close();w.set_physics_process(false)
		w.player.set_physics_process(false)
		for actor in w.npcs.values():actor.set_physics_process(false)
		if is_instance_valid(w.combat):w.combat.set_physics_process(false)
		if is_instance_valid(w.grey_camp):
			w.grey_camp.set_physics_process(false)
			for guard in w.grey_camp.guards:guard.set_physics_process(false)
		var arrival:Vector3=w.player.position
		for book in entries:
			if floor_id=="starcity":
				check(not w.targets.has(book.id),"closed interior exposes no archived pickup: "+book.id);continue
			if book.source.kind!="pickup" or book.source.floor!=floor_id:continue
			locations+=1
			check(w.targets.has(book.id) and w.get_node_or_null("Publication_"+book.id)!=null,"publication has physical copy and interaction on "+floor_id)
			var selected=false;var book_position:Vector3=w.targets[book.id].pos
			var capsule=CapsuleShape3D.new();capsule.radius=.26;capsule.height=1.72
			for point in w.navigation.graph.get_point_ids():
				var p:Vector2=w.navigation.graph.get_point_position(point)
				if p.distance_to(Vector2(book_position.x,book_position.z))>1.65:continue
				var query=PhysicsShapeQueryParameters3D.new();query.shape=capsule;query.collision_mask=3;query.transform=Transform3D(Basis.IDENTITY,Vector3(p.x,.90,p.y))
				if not w.get_world_3d().direct_space_state.intersect_shape(query).is_empty():continue
				w.player.position=Vector3(p.x,.04,p.y);w.find_nearest()
				if floor_id=="east_district" and book.id in w.interaction_candidates:
					if w.navigation.path(arrival,w.player.position).is_empty():continue
					for turn in w.interaction_candidates.size():
						if w.nearest==book.id:break
						w.cycle_interaction(1)
				if w.nearest==book.id:selected=true;break
			check(selected,"a real collision-free approach selects publication through the normal proximity ray: "+book.id)
			if selected:
				var input=InputEventKey.new();input.physical_keycode=KEY_E;input.keycode=KEY_E;input.pressed=true;w._unhandled_input(input)
			else:w.interact(book.id)
			check(Publications.owned(w.story,book.id) and not w.targets.has(book.id) and not w.get_node("Publication_"+book.id).visible,"pickup stores copy and removes physical duplicate")
			if floor_id=="east_district":
				w.hud.show_publication(book.id)
				check(w.hud.modal_visible() and Publications.was_read(w.story,book.id),"the in-game collection reader opens this eastern district document")
				w.hud.close()
			if floor_id=="life":
				var previous=w.story.serialize().duplicate(true);previous.flags.publications.erase(book.id)
				w.story.restore(previous);w.on_story_changed()
				check(w.targets.has(book.id) and w.get_node("Publication_"+book.id).visible,"loading an earlier same-room save restores the uncollected physical copy")
				w.interact(book.id)
		if floor_id=="commune":
			var terminal=w.get_node("CommonRoomTerminal")
			check(terminal.get_meta("terminal_front")==Vector3.RIGHT and w.targets.has("common_blocks"),"dining terminal faces into room and is interactable")
			w.interact("common_blocks");await frames()
			check(w.hud.modal_visible() and is_instance_valid(w.hud.terminal_game),"world interaction opens playable terminal")
			w.hud.terminal_game.score=1234;w.hud.terminal_game.save_record();w.hud.close()
			check(w.story.flags.blocks_best==1234,"terminal record lives in normal save state")
		w.queue_free();await frames()
	check(locations==entries.filter(func(b):return b.source.kind=="pickup" and b.source.floor!="starcity").size(),"every currently open exploration copy exists; archived interior copies remain unavailable")
	print("PUBLICATIONS_V13_RESULT checks=",checks," failures=",failures);quit(0 if failures==0 else 1)
