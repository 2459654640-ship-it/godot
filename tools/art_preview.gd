extends SceneTree
var w
func _initialize():call_deferred("run")
func frames(n:int):
	for i in n:await process_frame
func run():
	w=load("res://scenes/d6.tscn").instantiate()
	root.add_child(w)
	await frames(3)
	w.set_physics_process(false)
	w.player.set_physics_process(false)
	for npc in w.npcs.values():npc.set_physics_process(false)
	w.hud.visible=false
	w.camera.size=6.8
	var focus=Vector3(-11.5,0.8,-2.9)
	w.camera.position=focus+Vector3(23,30,27)
	w.camera.look_at(focus)
	w.player.visual.rotation.y=-2.4
	for i in 40:w.wall_veil._process(1.0/60)
	await frames(3)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/d6-art-preview.png")
	print("PREVIEW_SAVED /tmp/d6-art-preview.png")
	w.queue_free()
	await frames(3)
	quit()
