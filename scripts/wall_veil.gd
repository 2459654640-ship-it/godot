extends Node
## Visual-only occlusion. Complete 2.7m walls and all collision stay in place.
## Acquire after 90ms, release after 450ms, and ease coverage over ~300ms.
var world
var states:Array[Dictionary]=[]
const ACQUIRE=0.09
const HOLD=0.45
const FADED=0.12

func setup(owner_world):
	world=owner_world
	for mesh in world.kit.wall_meshes:
		states.append({"mesh":mesh,"bounds":mesh.get_aabb(),"opacity":1.0,"acquire":0.0,"hold":0.0,"active":false,"switches":0})
		# Fixed parallel view: establish a painter's order once. Camera follow
		# cannot swap it, unlike distance-sorted large transparent thin sheets.
		var centre=mesh.get_aabb().get_center()
		var priority=clampi(roundi((centre.x*.65+centre.z*.76)*3),-120,120)
		for i in mesh.mesh.get_surface_count():mesh.mesh.surface_get_material(i).render_priority=priority
		for entry in world.kit.veil_materials.get(mesh.get_instance_id(),[]):entry.material.render_priority=priority

func obstruction(bounds:AABB,padding:float=0.0) -> bool:
	var camera:Camera3D=world.camera
	var p:Vector3=world.player.global_position
	var area=bounds.grow(padding)
	# Nine nearby sight lines reveal a useful space around the whole figure,
	# rather than a tiny face-sized hole. Rear walls never intersect these rays.
	for offset in [Vector3(0,0.35,0),Vector3(0,1.65,0),Vector3(-1.4,0.8,0),Vector3(1.4,0.8,0),Vector3(0,0.8,-1.4),Vector3(0,0.8,1.4),Vector3(-1,0.8,-1),Vector3(1,0.8,1),Vector3(0,0.9,0)]:
		var end=p+offset
		# Orthographic sight rays are parallel; not rays to the camera origin.
		var start=end+camera.global_basis.z*65.0
		if area.intersects_segment(start,end)!=null:return true
	return false

func _process(delta):
	if not is_instance_valid(world) or not world.initialized:return
	for state in states:
		var hit=obstruction(state.bounds,0.35 if state.active else 0.0)
		if world.overview and state.mesh.get_meta("foreground",false):hit=true
		if hit:
			state.acquire+=delta
			state.hold=HOLD
			if state.acquire>=ACQUIRE and not state.active:
				state.active=true
				state.switches+=1
		else:
			state.acquire=0.0
			state.hold=maxf(0.0,state.hold-delta)
			if state.hold<=0.0 and state.active:
				state.active=false
				state.switches+=1
		state.opacity=move_toward(state.opacity,FADED if state.active else 1.0,delta*2.8)
		state.mesh.set_meta("veil_opacity",state.opacity)
		for i in state.mesh.mesh.get_surface_count():
			state.mesh.mesh.surface_get_material(i).set_shader_parameter("visibility",state.opacity)
		for entry in world.kit.veil_materials.get(state.mesh.get_instance_id(),[]):
			entry.material.set_shader_parameter("visibility",state.opacity)
