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
	check(entries.size()==18 and Publications.data().series.size()==6,"eighteen readable publications in six series")
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
	for floor_id in ["life","labor","waterworks","commune","sech","coal","starcity"]:
		var w=load("res://scenes/"+("d6" if floor_id=="life" else floor_id)+".tscn").instantiate()
		root.add_child(w);current_scene=w;await frames(5);w.hud.close();w.set_physics_process(false)
		w.player.set_physics_process(false)
		for actor in w.npcs.values():actor.set_physics_process(false)
		if is_instance_valid(w.combat):w.combat.set_physics_process(false)
		for book in entries:
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
				if w.nearest==book.id:selected=true;break
			check(selected,"a real collision-free approach selects publication through the normal proximity ray: "+book.id)
			if selected:
				var input=InputEventKey.new();input.physical_keycode=KEY_E;input.keycode=KEY_E;input.pressed=true;w._unhandled_input(input)
			else:w.interact(book.id)
			check(Publications.owned(w.story,book.id) and not w.targets.has(book.id) and not w.get_node("Publication_"+book.id).visible,"pickup stores copy and removes physical duplicate")
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
	check(locations==12,"all twelve exploration copies exist across actual maps")
	print("PUBLICATIONS_V13_RESULT checks=",checks," failures=",failures);quit(0 if failures==0 else 1)
