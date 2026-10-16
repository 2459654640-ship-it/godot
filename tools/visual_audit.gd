extends SceneTree
## Scene audit. --record-baseline explicitly writes a new external baseline.
func _initialize():
	call_deferred("run")

func run():
	var w=load("res://scenes/d6.tscn").instantiate()
	root.add_child(w)
	await physics_frame
	var data={"npc":{},"targets":{},"solids":w.kit.solids,"story":w.story.serialize()}
	for id in w.npcs:data.npc[id]=[w.npcs[id].anchor.x,w.npcs[id].anchor.y,w.npcs[id].anchor.z]
	for id in w.targets:
		var p:Vector3=w.targets[id].pos
		data.targets[id]=[p.x,p.y,p.z]
	if "--record-baseline" in OS.get_cmdline_user_args() and not FileAccess.file_exists("/tmp/d6-visual-baseline.json"):
		var file=FileAccess.open("/tmp/d6-visual-baseline.json",FileAccess.WRITE)
		file.store_string(JSON.stringify(data,"\t"))
		file.close()
	print("SCENE AUDIT: ",w.npcs.size()," NPCs; ",w.targets.size()," targets; ",w.kit.solids.size()," solid records")
	print("MASONRY: ",w.kit.wall_meshes.size()," fixed cutaway meshes")
	w.queue_free()
	await process_frame
	quit()
