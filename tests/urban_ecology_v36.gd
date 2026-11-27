extends SceneTree
const Ground=preload("res://scripts/city_ground.gd")
const Story=preload("res://scripts/story.gd")
const District=preload("res://scripts/east_district.gd")
var checks=0
var failures=0
var world

func _initialize():
	call_deferred("run")

func check(condition:bool,reason:String):
	checks+=1
	if not condition:
		failures+=1
		push_error(reason)

func frames(count:int):
	for i in count:await physics_frame

func load_world(id:String):
	var state=Story.new()
	state.flags.intro_done=true
	root.get_node("Session").pending={"story":state.serialize(),"floor":id,"position":Vector3.INF}
	world=load("res://scenes/"+id+".tscn").instantiate()
	root.add_child(world)
	await frames(3)
	world.set_physics_process(false)
	world.combat.set_physics_process(false)
	world.story.flags.comic={"active":false}
	world.hud.comic_active=false
	world.hud.close()
	for npc in world.npcs.values():
		npc.set_physics_process(false)
		npc.collision_layer=0
	world.player.camera=null
	world.player.use_override=true

func close_world():
	world.queue_free()
	await frames(2)

func cross(choke:Vector2,normal:Vector2):
	for sign in [-1,1]:
		var start=choke+normal*sign*1.15
		world.player.position=Vector3(start.x,.04,start.y)
		world.player.velocity=Vector3.ZERO
		world.player.motion_override=-normal*sign
		await frames(58)
		world.player.motion_override=Vector2.ZERO
		var p=Vector2(world.player.position.x,world.player.position.z)
		check((p-choke).dot(normal)*sign<-.55,"%s door at %s, side %d is walkable, player reached %s"%[world.floor_id,choke,sign,p])

func path(to:Vector3,label:String):
	var route=world.navigation.path(world.player.position,to)
	check(not route.is_empty() and route[-1].distance_to(to)<1.25,"Navigation reaches "+label)

func run():
	await load_world("east_district")
	world.grey_camp.set_physics_process(false)
	for guard in world.grey_camp.guards:guard.set_physics_process(false)
	var layout=District.layout()
	check(layout.roads.any(func(road):return road.get("class","")=="walk"),"Pedestrian routes have a distinct authored surface")
	var floor_mesh=world.get_node("FloorOutdoor")
	check(floor_mesh.mesh is ArrayMesh and floor_mesh.get_aabb().position.y<-.5,"Ground mesh contains the depression")
	var space=world.get_world_3d().direct_space_state
	var below=space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(7,1,-63),Vector3(7,-1,-63),1))
	check(not below.is_empty() and absf(below.position.y-Ground.height_at(Vector2(7,-63)))<.02,"Ground collision matches the visible depression")
	world.player.position=Vector3(7,.04,-63)
	await frames(65)
	check(world.player.is_on_floor() and world.player.position.y<-.49,"Player can stand in the real depression")
	world.story.economy.radiation=0
	world.combat.district_exposure(2.0)
	check(world.story.f("district_fallout_warned") and world.story.economy.radiation==0,"Fallout warning precedes accumulated exposure")
	world.combat.district_exposure(3.1)
	check(world.story.economy.radiation==2,"Staying in the contaminated bowl adds radiation")
	world.player.position=Vector3(-4,.04,-63)
	world.combat.district_exposure(10.0)
	check(world.story.economy.radiation==2,"Clear western footway is outside the fallout")
	world.player.position=District.spawn(world.story,"commune")
	for id in ["east_waterworks_entry","city_passenger_roll","raid_container_dispatch_bag","raid_container_heating_parts"]:
		check(world.targets.has(id),"Target is visible to normal interaction flow "+id)
		path(world.targets[id].pos,id)
	var entrance:Vector3=world.targets.east_waterworks_entry.pos
	check(entrance.distance_to(Vector3(-60,0,-31.5))<1.6 and District.spawn(world.story,"waterworks").z<-26,"Waterworks transfer point and return share the loading yard")
	await cross(Vector2(-48,31.5),Vector2.DOWN)
	await cross(Vector2(-51,50.5),Vector2.DOWN)
	world.player.position=world.targets.city_passenger_roll.pos
	for i in 32:world.wall_veil._process(.02)
	check(world.wall_veil.interior_active and not world.wall_veil.interior_roofs.filter(func(mesh):return String(mesh.name).begins_with("ShelterLowerRoof"))[0].visible,"Shelter roof disappears on entry")
	world.story.act("c_city_passenger_roll_read")
	check(world.story.last_action_valid and world.story.f("city_passenger_roll_read"),"Civil-defense evidence works without a quest prerequisite")
	var restored=Story.new()
	restored.restore(JSON.parse_string(JSON.stringify(world.story.serialize())))
	check(restored.f("city_passenger_roll_read") and restored.economy.radiation==2,"Visit and exposure persist through saves")
	await close_world()
	await load_world("commune")
	path(Vector3(-24,.04,12.8),"produce packing room from arrivals")
	await cross(Vector2(-23.5,-15),Vector2.DOWN)
	await cross(Vector2(-13.5,-15),Vector2.DOWN)
	await cross(Vector2(-24,11),Vector2.DOWN)
	await cross(Vector2(27,4),Vector2.DOWN)
	await close_world()
	await load_world("sech")
	path(Vector3(17,.04,-28),"trackside service bay")
	path(Vector3(-10,.04,22),"mending room from arrivals")
	await cross(Vector2(17,-24),Vector2.DOWN)
	await cross(Vector2(-10,20),Vector2.DOWN)
	await close_world()
	await load_world("labor")
	path(Vector3(0,.04,-15.6),"D-6 observation ward")
	await cross(Vector2(0,-13),Vector2.DOWN)
	await close_world()
	await load_world("grey_shelter")
	world.grey_camp.set_physics_process(false)
	for guard in world.grey_camp.guards:guard.set_physics_process(false)
	path(world.targets.raid_container_shelter_salvage.pos,"the reclaimed shelter's salvage and drying room")
	await cross(Vector2(-10,6.5),Vector2.RIGHT)
	await close_world()
	print("URBAN_ECOLOGY_V36_RESULT checks=%d failures=%d"%[checks,failures])
	quit(1 if failures else 0)
