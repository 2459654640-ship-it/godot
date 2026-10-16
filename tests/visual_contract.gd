extends SceneTree
## Checks for the v2 visual pass: stable opaque walls and v1 game compatibility.
var failures:Array[String]=[]
var checks=0
var w

func _initialize():call_deferred("run")
func check(value:bool,message:String):
	checks+=1
	if not value:
		failures.append(message)
		push_error(message)
func frames(n:int):
	for i in n:await physics_frame

func run():
	w=load("res://scenes/d6.tscn").instantiate()
	root.add_child(w)
	await frames(3)
	check(FileAccess.get_sha256("res://scripts/story.gd")=="6d6049b905a859acda892f3d2cf7fdd83ba776783346a76d635fd61df7b5ec59","story file remains byte-identical to v1")
	var actor_source=FileAccess.get_file_as_string("res://scripts/actor.gd")
	var physics_source=actor_source.substr(actor_source.find("func _physics_process"))
	check(physics_source.sha256_text()=="62f9573d85f8d9dc88a7e1d87f00af92ac348c215e03f0ad384657c868c5a8ba","movement and NPC yielding remain byte-identical to v1")
	check(FileAccess.file_exists("res://tests/fixtures/visual_v1_baseline.json"),"v1 baseline fixture is bundled")
	if FileAccess.file_exists("res://tests/fixtures/visual_v1_baseline.json"):
		var baseline=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/visual_v1_baseline.json"))
		check(w.npcs.size()==baseline.npc.size(),"NPC count unchanged")
		for id in baseline.npc:
			var p=baseline.npc[id]
			check(w.npcs[id].anchor.is_equal_approx(Vector3(p[0],p[1],p[2])),"original NPC anchor: "+id)
		check(w.targets.size()==baseline.targets.size(),"interaction ID count unchanged")
		for id in baseline.targets:
			if w.npcs.has(id):continue
			var p=baseline.targets[id]
			check(w.targets[id].pos.is_equal_approx(Vector3(p[0],p[1],p[2])),"original target coordinate: "+id)
		var retained=[]
		for solid in w.kit.solids:
			if not solid.name.begins_with("SemyonRoom"):retained.append(solid)
		check(JSON.parse_string(JSON.stringify(retained))==baseline.solids,"every original solid envelope retained; only authorized bedroom partition added")
	var caps:Array[Rect2]=[]
	var triangle_count=0
	var bad_winding=0
	var duplicate_faces=0
	for instance in w.kit.wall_meshes:
		check(instance.get_meta("fixed_cutaway",false),"wall has a fixed opaque cutaway")
		for surface in instance.mesh.get_surface_count():
			var material:StandardMaterial3D=instance.mesh.surface_get_material(surface)
			check(material.transparency==BaseMaterial3D.TRANSPARENCY_DISABLED,"masonry material is fully opaque")
			var arrays=instance.mesh.surface_get_arrays(surface)
			var verts:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
			var normals:PackedVector3Array=arrays[Mesh.ARRAY_NORMAL]
			for i in range(0,verts.size(),3):
				if (verts[i+1]-verts[i]).cross(verts[i+2]-verts[i]).dot(normals[i])>=0:bad_winding+=1
				triangle_count+=1
			if surface==1:
				for i in range(0,verts.size(),6):
					var rect=Rect2(Vector2(verts[i].x,verts[i].z),Vector2.ZERO)
					for j in range(6):rect=rect.expand(Vector2(verts[i+j].x,verts[i+j].z))
					for previous in caps:
						if rect.intersection(previous).get_area()>0.0001:duplicate_faces+=1
					caps.append(rect)
	check(triangle_count>100,"real connected 3D masonry is present")
	check(bad_winding==0,"all masonry triangles have Godot clockwise winding and correct outward normals")
	check(duplicate_faces==0,"no overlapping masonry cap faces, including corners and T-junctions")
	for pier in w.find_children("DoorPier*","MeshInstance3D",true,false):
		check(is_equal_approx(pier.position.y+pier.mesh.size.y/2,2.28),"door piers stop beneath the beam, no coplanar beam/pier top")
	for map_name in ["wall","floor","cement","steel","oxide","timber","weave"]:
		var texture:Texture2D=load("res://assets/visual/"+map_name+".png")
		check(texture.get_image().has_mipmaps(),"3D material has mipmaps: "+map_name)
	for id in w.story.ITEMS:
		check(ResourceLoader.exists("res://assets/visual/item_"+id+".png"),"inventory illustration: "+id)
	for id in w.targets:
		check(not w.targets[id].ring is MeshInstance3D,"ground ring removed: "+id)
	# Load an unchanged v1-format state through the actual game save/load path.
	var legacy={"version":1,"flags":{"searched":true,"accepted":true,"kit":true},"items":["knife","cigarettes","photo","order","mask","filter"],"intel":["储水只够两周；正式征召需要登记和防护装备。"],"route":"","ending":false,"position":[-10.5,0.04,-3.4]}
	w.save_path="user://d6_visual_legacy_test.json"
	var file=FileAccess.open(w.save_path,FileAccess.WRITE)
	file.store_string(JSON.stringify(legacy))
	file.close()
	w.load_game()
	check(w.story.has("knife") and w.story.f("kit") and w.story.f("accepted"),"v1 save loads existing items and flags without migration")
	check(w.player.position.is_equal_approx(Vector3(-10.5,0.04,-3.4)),"v1 saved location is preserved")
	DirAccess.remove_absolute(w.save_path)
	for npc in w.npcs.values():
		npc.set_physics_process(false)
		npc.collision_layer=0
	w.player.use_override=true
	w.player.camera=null
	# A v1 save may have stood exactly where the authorized new partition is.
	# Physics must recover that capsule without changing the file/schema.
	w.player.position=Vector3(-11.95,0.04,-6.0)
	w.player.velocity=Vector3.ZERO
	w.player.motion_override=Vector2.ZERO
	await frames(25)
	check(absf(w.player.position.x+11.95)>0.30 and w.player.position.y<0.12,"legacy position inside new divider is recovered by normal collision handling")
	w.player.position=Vector3(-11.2,0.04,-6.0)
	w.player.velocity=Vector3.ZERO
	w.player.motion_override=Vector2.LEFT
	await frames(45)
	check(w.player.position.x>-11.7,"new bedroom partition actually blocks movement")
	w.player.position=Vector3(-11.1,0.04,-3.65)
	w.player.velocity=Vector3.ZERO
	await frames(52)
	check(w.player.position.x<-12.5,"new bedroom doorway is actually traversable")
	w.player.motion_override=Vector2.ZERO
	await frames(12)
	w.player.motion_override=Vector2.RIGHT
	await frames(55)
	check(w.player.position.x>-11.5,"new bedroom doorway supports returning")
	w.player.motion_override=Vector2.ZERO
	# Camera/player motion cannot swap wall visibility, material or transforms.
	var signatures=[]
	for mesh in w.kit.wall_meshes:signatures.append([mesh.visible,mesh.transform,mesh.mesh.get_instance_id()])
	w.player.position=Vector3(-12,0.04,1.5)
	w.player.motion_override=Vector2.RIGHT
	await frames(90)
	for i in w.kit.wall_meshes.size():
		var mesh=w.kit.wall_meshes[i]
		check(signatures[i]==[mesh.visible,mesh.transform,mesh.mesh.get_instance_id()],"wall geometry and visibility stable during camera follow")
	print("VISUAL_GEOMETRY: ",triangle_count," triangles; ",caps.size()," cap quads; bad winding=",bad_winding," overlapping caps=",duplicate_faces)
	print("VISUAL_CONTRACT_RESULT checks=",checks," failures=",failures.size())
	w.queue_free()
	w=null
	await frames(3)
	quit(0 if failures.is_empty() else 1)
