extends RefCounted
## Several samples soften partial obstruction by furniture. Callers blend the
## resulting target over time, so crossing a pipe never changes exposure at once.
static func tint(floor_id:String)->Vector3:
	match floor_id:
		"commune":return Vector3(1.01,.91,.77)
		"waterworks":return Vector3(.89,.91,.89)
		"surface":return Vector3(.94,.99,1.02)
		"starcity","coal":return Vector3(.90,.91,.88)
	return Vector3(.94,.91,.84)

static func sample(world:Node3D,origin:Vector3,lamps:Array,excluded:Array[RID]=[])->Vector3:
	var energy=.34
	var color=Vector3(.30,.34,.34)*energy
	for lamp in lamps:
		if not is_instance_valid(lamp) or not lamp.visible:continue
		var distance=origin.distance_to(lamp.global_position-Vector3.UP*.8)
		if distance>lamp.omni_range:continue
		var strength=pow(maxf(0,1-distance/lamp.omni_range),2)*lamp.light_energy*.48
		if strength<.004:continue
		var visibility=0.0
		for offset in [Vector3(-.16,.85,0),Vector3(.16,1.15,0),Vector3(0,1.5,0)]:
			var ray=PhysicsRayQueryParameters3D.create(origin+offset,lamp.global_position,1)
			ray.exclude=excluded
			visibility+=1.0 if world.get_world_3d().direct_space_state.intersect_ray(ray).is_empty() else .22
		strength*=visibility/3.0
		energy+=strength
		color+=Vector3(lamp.light_color.r,lamp.light_color.g,lamp.light_color.b)*strength
	var level=clampf(.46+energy*.25,.49,1.02)
	if world.floor_id=="surface":level=clampf(.79+energy*.08,.81,.95)
	return tint(world.floor_id)*Vector3.ONE.lerp(color/maxf(.01,energy),.12)*level
