extends SceneTree
var checks=0
var failures:Array[String]=[]
var w
func _initialize():call_deferred("run")
func check(value:bool,msg:String):
	checks+=1
	if not value:failures.append(msg);push_error(msg)
func frames(n:int):
	for i in n:await physics_frame
func overlap(p:Vector3,radius:float=.27)->bool:
	var shape=CapsuleShape3D.new();shape.radius=radius;shape.height=1.7
	var q=PhysicsShapeQueryParameters3D.new();q.shape=shape;q.collision_mask=1;q.transform=Transform3D(Basis.IDENTITY,p+Vector3(0,.9,0))
	return not w.get_world_3d().direct_space_state.intersect_shape(q).is_empty()
func graph_reached()->Dictionary:
	var graph=w.navigation.graph
	var start=graph.get_closest_point(Vector2(w.player.position.x,w.player.position.z))
	var reached={start:true};var queue=[start];var i=0
	while i<queue.size():
		var cell=queue[i];i+=1
		for next in graph.get_point_connections(cell):
			if not reached.has(next):reached[next]=true;queue.append(next)
	return reached
func run():
	w=load("res://scenes/labor.tscn").instantiate();root.add_child(w);await frames(5)
	var reached=graph_reached()
	check(reached.size()>1800,"labor has substantial connected navigation")
	for id in w.targets:
		var end:Vector3=w.targets[id].pos+Vector3(0,1.2,0);var accessible=false
		for cell in reached:
			var p:Vector2=w.navigation.graph.get_point_position(cell)
			if p.distance_to(Vector2(end.x,end.z))>1.6:continue
			if overlap(Vector3(p.x,.04,p.y)):continue
			var q=PhysicsRayQueryParameters3D.create(Vector3(p.x,1.2,p.y),end,1);var hit=w.get_world_3d().direct_space_state.intersect_ray(q)
			if hit.is_empty() or hit.position.distance_to(end)<.48:accessible=true;break
		check(accessible,"labor target reachable with real capsule and line of sight: "+id)
	# Physically cross each doorway in both directions, with NPCs removed from
	# this isolated fixture probe; their real patrols are checked separately.
	for a in w.npcs.values():a.set_physics_process(false);a.collision_layer=0
	w.player.camera=null;w.player.use_override=true
	for door in w.Labor.DOORS:
		for sign in [-1,1]:
			w.player.position=Vector3(door.x,.04,door.y+sign*1.2);w.player.velocity=Vector3.ZERO
			w.player.motion_override=Vector2(0,-sign)
			await frames(60)
			w.player.motion_override=Vector2.ZERO;await frames(10)
			check((w.player.position.z-door.y)*sign<-.4,"real bidirectional doorway traversal: "+str(door)+str(sign))
	w.player.position=Vector3(20,.04,-11.9);w.player.velocity=Vector3.ZERO;w.player.motion_override=Vector2.UP
	await frames(70);w.player.motion_override=Vector2.ZERO
	check(w.player.position.z>-12.6,"sealed main gate physically blocks leaving track area")
	w.player.position=Vector3(3,.04,12.8);w.player.velocity=Vector3.ZERO;w.player.motion_override=Vector2.DOWN
	await frames(65);w.player.motion_override=Vector2.ZERO
	check(w.player.position.z<13.4,"coal gate blocks unregistered access")
	var overlap_samples=[]
	w.player.position=Vector3(-10,.04,1.8);w.player.velocity=Vector3.ZERO
	for a in w.npcs.values():a.collision_layer=2;a.set_physics_process(true)
	for frame in 1200:
		await physics_frame
		if frame%40!=0:continue
		for id in w.npcs:
			if overlap(w.npcs[id].position,.28):overlap_samples.append(id+str(frame))
	check(overlap_samples.is_empty(),"background workers and guards do not penetrate walls/furniture: "+str(overlap_samples))
	# Save on labor, travel upstairs, reload the same file from another floor.
	current_scene=w
	w.save_path="user://d6_v5_floor_test.json"
	w.story.flags.intro_done=true
	w.story.economy.military=37
	w.story.Conversation.reply(w.story,"commander","知道了。","「到正门去。」")
	w.save_game();var saved=w.save_path
	w.travel_floor("life")
	await frames(10);w=current_scene
	check(w.floor_id=="life" and w.story.economy.military==37,"floor transition preserves wallet")
	check(w.story.conversations.has("commander"),"floor transition preserves chat transcript")
	w.save_path=saved;w.load_game();await frames(10);w=current_scene
	check(w.floor_id=="labor" and w.story.economy.military==37,"loading from another floor restores saved floor and wallet")
	check(w.story.conversations.commander.size()==2,"save/load preserves exact chat record")
	DirAccess.remove_absolute(saved)
	w.ambience.stop();w.ambience.stream=null;w.step_audio.stop();w.step_audio.stream=null
	w.queue_free();await frames(3)
	print("FLOOR_CONTRACT_RESULT checks=",checks," failures=",failures.size()," connected_cells=",reached.size())
	quit(0 if failures.is_empty() else 1)
