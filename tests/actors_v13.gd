extends SceneTree
var checks=0
var failures=0
func _initialize():call_deferred("run")
func check(ok:bool,message:String):
	checks+=1
	if not ok:failures+=1;push_error(message)
func frames(n:int=5):
	for i in n:await physics_frame
func phases(painter)->Dictionary:
	var seen={}
	for phase in [0.0,.25,.5,.75]:
		painter.cycle=phase;painter._process(0);seen[painter.current_pose]=true
	return seen
func run():
	var w=load("res://scenes/waterworks.tscn").instantiate();root.add_child(w);current_scene=w;await frames(8)
	w.hud.close();w.set_physics_process(false);w.player.set_physics_process(false);w.combat.set_physics_process(false)
	for actor in w.npcs.values():actor.set_physics_process(false)
	w.story.flags.weapon_drawn=true
	for actor in [w.player,w.combat.veteran]:
		var painter=actor.visual.get_node("Painter");painter.set_process(false)
		for direction in 8:
			actor.visual.rotation.y=direction*PI/4;painter.direction_ready=false;actor.velocity=Vector3(1,0,1)
			w.combat.reload_time=1.2 if actor.is_player else 0.0
			w.combat.veteran_reload=0.0 if actor.is_player else 1.2
			var seen=phases(painter)
			check(seen.size()==3 and seen.has(2) and seen.has(5) and seen.has(6),"moving reload keeps both actual stride drawings and planted transition: "+str(actor.name)+str(direction))
			actor.velocity=Vector3.ZERO;painter._process(0)
			check(painter.current_pose==2,"standing reload uses stationary loading pose")
			w.combat.reload_time=0;w.combat.veteran_reload=0;actor.velocity=Vector3(1,0,1)
			painter.react("shot");seen=phases(painter)
			check(seen.size()==3 and seen.has(0) and seen.has(3) and seen.has(4),"firing while moving preserves lower-body gait")
		actor.velocity=Vector3.ZERO;painter.reaction_time=0
	var lieutenant=w.npcs.plant_guide;lieutenant.velocity=Vector3(1,0,1)
	var painter=lieutenant.visual.get_node("Painter");painter.set_process(false)
	check(painter.pose_count>=3 and not lieutenant.stationary,"masked lieutenant has a genuine walk atlas and can move")
	for direction in 8:
		lieutenant.visual.rotation.y=direction*PI/4;painter.direction_ready=false
		var seen=phases(painter)
		check(seen.size()==3 and seen.has(0) and seen.has(1) and seen.has(2),"masked lieutenant animates both steps in all directions")
	# Change actual physical light obstruction. The rendered target must change,
	# but its displayed tint cannot snap on the first sample frame.
	var actor=w.player;actor.position=Vector3(12,.04,7);actor.velocity=Vector3.ZERO
	painter=actor.visual.get_node("Painter");painter.set_process(false)
	var lamp=OmniLight3D.new();w.add_child(lamp);lamp.position=actor.position+Vector3(2,1.3,0);lamp.omni_range=10;lamp.light_energy=12
	painter.room_lamps=[lamp];painter.light_ready=false;painter.light_clock=.2;painter._process(0)
	var lit:Vector3=painter.sampled_light
	var shield=w.kit.box("LightTestShield",actor.position+Vector3(1,1,0),Vector3(.1,2,3),"metal",true)
	await frames();painter.light_clock=.2;painter._process(1.0/60)
	check(lit.distance_to(painter.sampled_light)<.06,"new obstruction cannot cause a one-frame exposure jump")
	for i in 60:painter._process(1.0/60)
	check(lit.distance_to(painter.sampled_light)>.12,"character still becomes darker after entering an occluded light pool")
	shield.queue_free();lamp.queue_free();w.queue_free();await frames()
	w=load("res://scenes/commune.tscn").instantiate();root.add_child(w);current_scene=w;await frames(6)
	check(w.npcs.commune_moro.stationary and w.npcs.commune_child.stationary,"single-pose residents cannot slide as fake walkers")
	var plan=w.story.Campaign.data().panels.return_standoff
	check(plan.choices[1].text=="支持老兵离队，让中尉把两箱净水滤芯运回 D-6，并和老兵一同前往公社。","requested companion choice is exact")
	w.queue_free();await frames()
	print("ACTORS_V13_RESULT checks=",checks," failures=",failures);quit(0 if failures==0 else 1)
