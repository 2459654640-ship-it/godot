extends CharacterBody3D
## Depth-tested painted figures with physical support on low steps.
var art_id=""
var combat_controlled=false
var stationary=false
var story_waiting=false
var combat_velocity=Vector3.ZERO
var aim_direction=Vector3.ZERO
var is_player = false
var blocked = false
var camera: Camera3D
var visual: Node3D
var left_leg: Node3D
var right_leg: Node3D
var left_arm: Node3D
var right_arm: Node3D
var anchor = Vector3.ZERO
var home_anchor=Vector3.ZERO
var work_area=Rect2(-100,-100,200,200)
var roam_radius=1.05
var clock = 0.0
var walk = 0.0
var gait_distance=0.0
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
var purposeful=false
var reached_anchor=false
const SPEED = 2.65
const ACCEL = 12.0
const DECEL = 17.0

func setup(kit, player: bool, coat: String = "green", hat: bool = false):
	is_player = player
	collision_layer = 4 if player else 2
	collision_mask = 3 if player else 7
	floor_max_angle = deg_to_rad(35)
	floor_snap_length = 0.28
	var cs = CollisionShape3D.new()
	var cap = CapsuleShape3D.new()
	cap.radius = 0.26 if player else 0.30
	cap.height = 1.72
	cs.shape = cap
	cs.position.y = 0.86
	if art_id in ["ambient_child","commune_child"]:cap.radius=.2;cap.height=1.18;cs.position.y=.59
	add_child(cs)
	# A real flat sole supports a foot at a low platform edge. A capsule alone
	# rests on its curved tip there, letting the painted boot enter the riser.
	var sole=CollisionShape3D.new()
	sole.name="FootSupport"
	var foot=CylinderShape3D.new()
	foot.radius=cap.radius
	foot.height=.06
	sole.shape=foot;sole.position.y=.03;add_child(sole)
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
	home_anchor=position
	rest_time=3.0+float(String(name).hash()%50)/10.0

func travel_to(destination:Vector3):
	if destination.distance_to(goal)<0.05:return
	goal=destination
	if navigation and purposeful:
		var world=get_parent()
		path_points=navigation.path_avoiding(position,destination,world.npcs.values()+[world.player],self)
	else:path_points=navigation.path(position,destination) if navigation else PackedVector3Array([destination])
	reached_anchor=false

func npc_motion(delta:float) -> Vector3:
	var world=get_parent()
	var player=get_tree().get_first_node_in_group("player")
	if not player or story_waiting:return Vector3.ZERO
	var talking=is_instance_valid(world.hud) and world.hud.modal_visible() and world.hud.dialogue_actor()==String(name)
	look_target=player if talking else null
	if talking:
		animation_state="talk"
		return Vector3.ZERO
	if is_instance_valid(world.hud) and world.hud.modal_visible():return Vector3.ZERO
	var displaced=Vector2(position.x-home_anchor.x,position.z-home_anchor.z).length()
	if not purposeful and (displaced>roam_radius or (stationary and displaced>.42)):
		if anchor.distance_to(home_anchor)>.05 or path_points.is_empty():
			anchor=home_anchor;goal=Vector3.INF;reached_anchor=false;yield_time=0
			travel_to(home_anchor)
	elif stationary and not purposeful:return Vector3.ZERO
	var away=position-player.position
	away.y=0.0
	# Yield using tested sweeps. Do not select a direction that enters a wall,
	# another NPC, or the player; the larger visual clearance is intentional.
	var player_driving=(player.use_override and player.motion_override.length()>.1) or Input.get_vector("move_left","move_right","move_up","move_down").length()>.1
	if not purposeful and displaced<roam_radius and away.length()<1.10 and yield_time<=0.0 and (player_driving or player.velocity.dot(away)>.05):
		var side=Vector3(-away.z,0,away.x).normalized()
		for candidate in [side,-side,away.normalized()]:
			var destination=position+candidate*.65
			if candidate.length()>0.1 and work_area.has_point(Vector2(destination.x,destination.z)) and destination.distance_to(home_anchor)<roam_radius and not test_move(global_transform,candidate*.65):
				yield_direction=candidate
				yield_time=.50
				break
	if yield_time>0.0:
		yield_time-=delta
		if yield_time<=0:
			anchor=home_anchor;goal=Vector3.INF;reached_anchor=false;path_points.clear()
		return yield_direction*1.25
	if not purposeful and away.length()<1.4 and displaced<.42:return Vector3.ZERO
	if position.distance_to(anchor)>0.55 and not reached_anchor:
		travel_to(anchor)
	elif not purposeful and not patrol.is_empty() and away.length()>2.8 and String(name)!="igor":
		rest_time-=delta
		if rest_time<=0.0:
			patrol_index=(patrol_index+1)%patrol.size()
			anchor=patrol[patrol_index]
			travel_to(anchor)
			rest_time=25.0+float(String(name).hash()%120)/10.0
	if path_points.is_empty():
		reached_anchor=true
		return Vector3.ZERO
	var next=path_points[0]-position
	next.y=0.0
	if next.length()<0.12:
		path_points.remove_at(0)
		if path_points.is_empty():reached_anchor=true
		return Vector3.ZERO
	if Vector2(velocity.x,velocity.z).length()<0.08:blocked_time+=delta
	else:blocked_time=0.0
	if blocked_time>1.2:
		goal=Vector3.INF
		travel_to(anchor)
		blocked_time=0.0
	return next.normalized()*(1.6 if purposeful else .72)

func stride_length() -> float:
	if is_player:return 1.7
	var painter=visual.get_node_or_null("Painter") if is_instance_valid(visual) else null
	var cutout=is_instance_valid(painter) and painter.pose_count<3
	if art_id in ["ambient_child","commune_child"]:return .78 if cutout else .85
	if art_id=="ambient_elder":return .94
	return 1.08 if cutout else 1.15

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
		desired=combat_velocity if combat_controlled else npc_motion(delta)
	var rate=ACCEL if desired.length()>0.01 else DECEL
	velocity.x=move_toward(velocity.x,desired.x,rate*delta)
	velocity.z=move_toward(velocity.z,desired.z,rate*delta)
	velocity.y -= 18.0*delta
	if is_on_floor(): velocity.y=-0.1
	step_up(Vector3(velocity.x,0,velocity.z)*delta)
	move_and_slide()
	var speed=Vector2(velocity.x,velocity.z).length()
	walk=lerpf(walk,speed/SPEED,delta*12)
	if aim_direction.length()>.1:
		visual.rotation.y=lerp_angle(visual.rotation.y,atan2(-aim_direction.x,-aim_direction.z),1-exp(-delta*18))
	elif speed>0.15:
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
	gait_distance+=delta*speed
	visual.position.y=absf(sin(gait_distance*TAU/stride_length()))*.018*walk
	if not is_player: visual.position.y+=sin(clock*1.7)*0.005

func step_up(motion:Vector3):
	if not is_on_floor() or velocity.y>0 or motion.length()<.0001:return
	if not test_move(global_transform,motion):return
	var rise=Vector3.UP*.26
	if test_move(global_transform,rise):return
	var raised=global_transform;raised.origin+=rise
	if test_move(raised,motion):return
	raised.origin+=motion
	var landing=KinematicCollision3D.new()
	if not test_move(raised,Vector3.DOWN*.29,landing):return
	if landing.get_normal().dot(Vector3.UP)<cos(floor_max_angle):return
	var height=raised.origin.y+landing.get_travel().y-global_position.y
	if height<.025 or height>.242:return
	global_position.y+=height
	velocity.y=-.1
