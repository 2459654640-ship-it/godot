extends "res://tools/visual_capture_v9.gd"
func _initialize():
	folder="res://docs/screenshots/visual-v14";call_deferred("run")
func run():
	DirAccess.make_dir_recursive_absolute(folder)
	await open_level("commune");w.hud.hide()
	w.player.position=Vector3(-2.5,.04,-8.3);camera_at(Vector3(-4,1,-8),8)
	await shot("ivan-and-residents");await dispose()
	await open_level("waterworks");w.hud.hide();w.combat.set_physics_process(false);w.story.flags.weapon_drawn=true
	var actors=[w.player,w.combat.veteran,w.npcs.plant_guide]
	for actor in actors:
		for other in actors:other.visible=actor==other
		actor.position=Vector3(-13,.04,-4);actor.velocity=Vector3.ZERO
		camera_at(actor.position+Vector3.UP*.85,6.5)
		var painter=actor.visual.get_node("Painter")
		for i in 60:painter._process(1.0/30)
		await shot("factory-"+actor.art_id)
	await dispose();quit()
