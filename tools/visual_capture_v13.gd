extends "res://tools/visual_capture_v9.gd"
const DIRECTIONS=[["front",Vector2(0,1)],["right-down",Vector2(1,1)],["left-down",Vector2(-1,1)],["side",Vector2(1,0)],["rear-right",Vector2(1,-1)],["back",Vector2(0,-1)]]
func _initialize():
	folder="res://docs/screenshots/visual-v13";call_deferred("run")
func gait(actor,tag:String,direction:Vector2,reload_mode:bool=false):
	var path="/tmp/metro-v13/gait/"+tag;DirAccess.make_dir_recursive_absolute(path)
	camera_at(actor.position+Vector3.UP*.85,4.5)
	var vector=w.camera.global_basis.x*direction.x+w.camera.global_basis.z*direction.y;vector.y=0
	actor.velocity=vector.normalized()*1.5;actor.visual.rotation.y=atan2(-vector.x,-vector.z)
	var painter=actor.visual.get_node("Painter");painter.set_process(false);painter.direction_ready=false;painter.focused=false
	if reload_mode:
		if actor.is_player:w.combat.reload_time=1.5
		else:w.combat.veteran_reload=1.5
	for frame in range(4):
		painter.cycle=float(frame)/4;painter._process(0);await settle(2)
		root.get_texture().get_image().save_png(path+"/%02d.png"%frame)
	w.combat.reload_time=0;w.combat.veteran_reload=0
	actor.velocity=Vector3.ZERO
func run():
	DirAccess.make_dir_recursive_absolute(folder)
	if "--factory-only" in OS.get_cmdline_user_args():
		await open_level("waterworks");await factory_rooms();await dispose();quit();return
	if "--factory-gaits" in OS.get_cmdline_user_args():
		await open_level("waterworks");await factory_people();await dispose();quit();return
	await open_level("commune")
	w.player.position=Vector3(-2.5,.04,-8.3);w.hud.hide();camera_at(Vector3(-4,1,-8),8);await shot("ivan-and-seated-residents")
	w.player.position=Vector3(-4,.04,-2)
	for spec in DIRECTIONS:await gait(w.player,"ivan-"+spec[0],spec[1])
	w.story.give("revolver");w.story.flags.weapon_drawn=true
	for spec in DIRECTIONS:await gait(w.player,"ivan-unmasked-armed-"+spec[0],spec[1])
	w.story.flags.weapon_drawn=false
	w.player.position=Vector3(7.5,.04,-17);camera_at(Vector3(6.8,1,-17.3),8);await shot("moro-and-ivan")
	w.player.position=Vector3(-9.7,.04,11);camera_at(Vector3(-8,1,11),9);await shot("commune-terminal")
	w.hud.show();w.hud.show_blocks();await shot("terminal-game")
	w.hud.terminal_game.started=true
	for i in 6:w.hud.terminal_game.hard_drop()
	await shot("terminal-playing");w.hud.close()
	w.hud.show_journal("collection");await shot("unknown-collection");w.hud.close()
	var first=preload("res://scripts/publications.gd").data().entries[0].id
	preload("res://scripts/publications.gd").acquire(w.story,first)
	w.hud.show_publication(first);await shot("publication-reader");w.hud.close()
	w.hud.hide();camera_at(Vector3(0,0,0),54);await shot("commune-overview")
	await dispose();await open_level("waterworks");await factory_rooms()
	await factory_people()
	await dispose();quit()
func factory_people():
	w.hud.hide();w.combat.set_physics_process(false)
	w.story.flags.weapon_drawn=true;w.combat.active=true
	var actors=[w.player,w.combat.veteran,w.npcs.plant_guide]
	for actor in actors:
		# Show each figure alone: teleporting all three to the comparison mark
		# would superimpose earlier figures and invalidate proportion review.
		for other in actors:other.visible=other==actor
		actor.position=Vector3(-13,.04,-4)
		var tag="ivan-armed" if actor==w.player else ("veteran" if actor==w.combat.veteran else "lieutenant")
		for spec in DIRECTIONS:await gait(actor,tag+"-"+spec[0],spec[1])
		if tag!="lieutenant":await gait(actor,tag+"-reload",Vector2(1,1),true)
func factory_rooms():
	w.hud.hide();w.combat.set_physics_process(false)
	w.player.position=Vector3(-12,.04,-5);camera_at(Vector3(-10,1,-5),19);await shot("waterworks-pump")
	w.player.position=Vector3(-17,.04,6);camera_at(Vector3(-16,1,7),15);await shot("waterworks-archive")
	w.player.position=Vector3(10,.04,-5);camera_at(Vector3(11,1,-5),19);await shot("waterworks-storage")
