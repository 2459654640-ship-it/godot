extends SceneTree
## Complete solid walls, stable visual-only fading and v1 game compatibility.
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
	check(FileAccess.file_exists("res://tests/fixtures/story-v2-contract.json"),"prior-version quest state/action gate fixture is bundled; validated by narrative_contract.gd")
	check(w.player.SPEED==2.65 and w.player.ACCEL==12.0 and w.player.DECEL==17.0,"player motion tuning retained")
	check(w.npcs.igor.collision_mask==7,"NPCs collide with walls, each other and player")
	check(FileAccess.file_exists("res://tests/fixtures/visual_v1_baseline.json"),"v1 baseline fixture is bundled")
	if FileAccess.file_exists("res://tests/fixtures/visual_v1_baseline.json"):
		var baseline=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/visual_v1_baseline.json"))
		check(w.npcs.size()==baseline.npc.size()-1,"commander moved to labor floor; other life NPCs retained")
		for id in baseline.npc:
			if id=="commander":continue
			var p=baseline.npc[id]
			if id not in ["mikhail","resident","diner"]:check(w.npcs[id].anchor.is_equal_approx(Vector3(p[0],p[1],p[2])),"retained story NPC anchor: "+id)
		check(w.targets.size()==baseline.targets.size()+10,"original interactions plus residential, return, safety latch and two collectible publications")
		for id in baseline.targets:
			if w.npcs.has(id) or id=="commander":continue
			var p=baseline.targets[id]
			check(w.targets[id].pos.is_equal_approx(Vector3(p[0],p[1],p[2])),"original target coordinate: "+id)
		for old in baseline.solids:
			if old.name=="SinkBase":
				var pedestal=w.kit.solids.filter(func(solid):return solid.name=="SinkBase")[0]
				check(pedestal.top<.725 and pedestal.rect.size.y<2.7,"washbasin pedestal is inset below the lip, with no coplanar overlapping ends")
				continue
			if old.name in ["West","SouthCut","EastCut"]:continue # Authorized new west-wing entrance.
			if old.name=="Crate" and old.rect.begins_with("[P: (12.95, 8.675)"):continue # Open ramp replaces this crate.
			var retained=false
			for solid in w.kit.solids:
				if JSON.parse_string(JSON.stringify(solid))==old:retained=true;break
			check(retained,"original solid retained: "+old.name)
	var caps:Array[Rect2]=[]
	var triangle_count=0
	var bad_winding=0
	var duplicate_faces=0
	for instance in w.kit.wall_meshes:
		check(instance.get_meta("complete_masonry",false),"wall is complete solid masonry")
		check(is_equal_approx(instance.mesh.get_aabb().size.y,2.7),"every wall segment has complete 2.7m height")
		for surface in instance.mesh.get_surface_count():
			var material:ShaderMaterial=instance.mesh.surface_get_material(surface)
			check(material.shader.resource_path.ends_with("masonry_veil.gdshader"),"masonry uses one depth-writing veil shader")
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
	for map_name in ["wall","floor","cement","steel","oxide","timber","weave","corrugated"]:
		var texture:Texture2D=load("res://assets/visual/"+map_name+".png")
		check(texture.get_image().has_mipmaps(),"3D material has mipmaps: "+map_name)
	for id in w.story.ITEMS:
		check(ResourceLoader.exists(w.hud.item_icon(id)),"inventory illustration: "+id)
	for id in ["ivan","semyon","nina","mikhail","cook","supply","commander","igor","resident","diner","queue"]:
		var texture:Texture2D=load("res://assets/characters/"+id+".png")
		check(texture.get_image().has_mipmaps(),"painted character mipmaps: "+id)
		check(ResourceLoader.exists("res://assets/portraits/"+id+".png"),"matching portrait: "+id)
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
	# Use actual geometric sight-line hits, then simulate a brief interruption.
	w.wall_veil.set_process(false)
	w.player.motion_override=Vector2.ZERO
	w.player.set_physics_process(false)
	w.player.position=Vector3(-10.5,.04,-3.4)
	w.set_camera(0,true)
	for state in w.wall_veil.states:
		state.opacity=1.0;state.active=false;state.acquire=0.0;state.hold=0.0;state.switches=0
	for i in 60:w.wall_veil._process(1.0/60)
	var blockers=[]
	for state in w.wall_veil.states:
		if state.active:blockers.append(state)
	check(not blockers.is_empty(),"real complete walls obstruct bedroom sight rays and fade")
	for state in blockers:
		check(state.opacity>=(w.wall_veil.ROOF_FADED if state.roof else w.wall_veil.FADED)-.001 and state.opacity<.90,"occlusion opacity follows coverage within the readable minimum")
		check(state.switches==1,"stationary wall acquires exactly once")
	var original_player=w.player.position
	w.player.position=Vector3(70,0,70)
	for i in 8:w.wall_veil._process(1.0/60)
	for state in blockers:check(state.active and state.switches==1,"brief sight-line interruption does not flash wall opaque")
	w.player.position=original_player
	for i in 40:w.wall_veil._process(1.0/60)
	for state in blockers:check(state.active and state.switches==1,"reacquiring during hold avoids visibility toggle")
	w.player.position=Vector3(70,0,70)
	for i in 90:w.wall_veil._process(1.0/60)
	for state in blockers:check(not state.active and is_equal_approx(state.opacity,1.0),"wall returns to complete opacity after leaving")
	print("VISUAL_GEOMETRY: ",triangle_count," triangles; ",caps.size()," cap quads; bad winding=",bad_winding," overlapping caps=",duplicate_faces)
	print("VISUAL_CONTRACT_RESULT checks=",checks," failures=",failures.size())
	w.queue_free()
	w=null
	await frames(3)
	quit(0 if failures.is_empty() else 1)
