extends CharacterBody3D
## Depth-tested painterly figures. Movement/physics retain v1 behavior.
var is_player = false
var blocked = false
var camera: Camera3D
var visual: Node3D
var left_leg: Node3D
var right_leg: Node3D
var left_arm: Node3D
var right_arm: Node3D
var anchor = Vector3.ZERO
var clock = 0.0
var walk = 0.0
var yield_time=0.0
var yield_direction=Vector3.ZERO
var motion_override = Vector2.ZERO
var use_override = false
var navigation
var path_points=PackedVector3Array()
var goal=Vector3.INF
var patrol:Array[Vector3]=[]
var patrol_index=0
var rest_time=4.0
var look_target:Node3D
var animation_state="idle"
var blocked_time=0.0
const SPEED = 2.65
const ACCEL = 12.0
const DECEL = 17.0

func setup(kit, player: bool, coat: String = "green", hat: bool = false):
	is_player = player
	collision_layer = 4 if player else 2
	collision_mask = 3 if player else 7
	floor_max_angle = deg_to_rad(35)
	floor_snap_length = 0.15
	var cs = CollisionShape3D.new()
	var cap = CapsuleShape3D.new()
	cap.radius = 0.26 if player else 0.30
	cap.height = 1.72
	cs.shape = cap
	cs.position.y = 0.86
	add_child(cs)
	visual = Node3D.new()
	add_child(visual)
	# Preserve the original controller's limb pivots and animation contract;
	# the authored visual is independent of these invisible helper nodes.
	left_leg=Node3D.new()
	right_leg=Node3D.new()
	left_arm=Node3D.new()
	right_arm=Node3D.new()
	for pivot in [left_leg,right_leg,left_arm,right_arm]:visual.add_child(pivot)
	var painting=preload("res://scripts/painted_actor.gd").new()
	painting.name="Painter"
	visual.add_child(painting)
	painting.setup(self)
	anchor=position
	rest_time=3.0+float(String(name).hash()%50)/10.0

func travel_to(destination:Vector3):
	if destination.distance_to(goal)<0.05:return
	goal=destination
	path_points=navigation.path(position,destination) if navigation else PackedVector3Array([destination])

func npc_motion(delta:float) -> Vector3:
	var world=get_parent()
	var player=get_tree().get_first_node_in_group("player")
	if not player:return Vector3.ZERO
	var talking=is_instance_valid(world.hud) and world.hud.modal_visible() and world.hud.dialogue_id==String(name)
	look_target=player if talking else null
	if talking:
		animation_state="talk"
		return Vector3.ZERO
	if is_instance_valid(world.hud) and world.hud.modal_visible():return Vector3.ZERO
	var away=position-player.position
	away.y=0.0
	# Yield using tested sweeps. Do not select a direction that enters a wall,
	# another NPC, or the player; the larger visual clearance is intentional.
	if away.length()<1.10 and yield_time<=0.0:
		var side=Vector3(-away.z,0,away.x).normalized()
		for candidate in [side,-side,away.normalized()]:
			if candidate.length()>0.1 and not test_move(global_transform,candidate*.65):
				yield_direction=candidate
				yield_time=.50
				break
	if yield_time>0.0:
		yield_time-=delta
		return yield_direction*1.25
	if position.distance_to(anchor)>0.55:
		travel_to(anchor)
	elif not patrol.is_empty() and away.length()>2.8 and String(name)!="igor":
		rest_time-=delta
		if rest_time<=0.0:
			patrol_index=(patrol_index+1)%patrol.size()
			anchor=patrol[patrol_index]
			travel_to(anchor)
			rest_time=9.0+float(String(name).hash()%60)/10.0
	if path_points.is_empty():
		goal=Vector3.INF
		return Vector3.ZERO
	var next=path_points[0]-position
	next.y=0.0
	if next.length()<0.12:
		path_points.remove_at(0)
		return Vector3.ZERO
	if Vector2(velocity.x,velocity.z).length()<0.08:blocked_time+=delta
	else:blocked_time=0.0
	if blocked_time>1.2:
		goal=Vector3.INF
		travel_to(anchor)
		blocked_time=0.0
	return next.normalized()*(1.15 if String(name)=="igor" else .85)

func _physics_process(delta):
	clock += delta
	var desired=Vector3.ZERO
	if is_player:
		if not blocked:
			var input=motion_override if use_override else Input.get_vector("move_left","move_right","move_up","move_down")
			if camera:
				var r=camera.global_basis.x
				var f=camera.global_basis.z
				r.y=0
				f.y=0
				desired=(r.normalized()*input.x+f.normalized()*input.y)*SPEED
			else:desired=Vector3(input.x,0,input.y)*SPEED
	else:
		desired=npc_motion(delta)
	var rate=ACCEL if desired.length()>0.01 else DECEL
	velocity.x=move_toward(velocity.x,desired.x,rate*delta)
	velocity.z=move_toward(velocity.z,desired.z,rate*delta)
	velocity.y -= 18.0*delta
	if is_on_floor(): velocity.y=-0.1
	move_and_slide()
	var speed=Vector2(velocity.x,velocity.z).length()
	walk=lerpf(walk,speed/SPEED,delta*12)
	if speed>0.15:
		visual.rotation.y=lerp_angle(visual.rotation.y,atan2(-velocity.x,-velocity.z),1-exp(-delta*12))
	elif is_instance_valid(look_target):
		var towards=look_target.global_position-global_position
		visual.rotation.y=lerp_angle(visual.rotation.y,atan2(-towards.x,-towards.z),1-exp(-delta*8))
	if speed>0.15:animation_state="walk"
	elif not is_instance_valid(look_target):animation_state="idle"
	var stride=sin(clock*10)*0.40*walk
	left_leg.rotation.x=stride
	right_leg.rotation.x=-stride
	left_arm.rotation.x=-stride*0.75
	right_arm.rotation.x=stride*0.75
	visual.position.y=absf(sin(clock*10))*0.025*walk
	if not is_player: visual.position.y+=sin(clock*1.7)*0.005
