extends CharacterBody3D
## Deliberately stylized, original low-poly stand-ins, not final character art.
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
const SPEED = 2.65
const ACCEL = 12.0
const DECEL = 17.0

func setup(kit, player: bool, coat: String = "green", hat: bool = false):
	is_player = player
	collision_layer = 4 if player else 2
	collision_mask = 3 if player else 1
	floor_max_angle = deg_to_rad(35)
	floor_snap_length = 0.15
	var cs = CollisionShape3D.new()
	var cap = CapsuleShape3D.new()
	cap.radius = 0.26 if player else 0.23
	cap.height = 1.72
	cs.shape = cap
	cs.position.y = 0.86
	add_child(cs)
	visual = Node3D.new()
	add_child(visual)
	# Anatomical pivots and clothing silhouette, total height 1.75m.
	kit.cyl("CoatHem",Vector3(0,0.79,0),0.28,0.36,coat,visual,0.23).scale.z=0.68
	kit.cyl("Jacket",Vector3(0,1.15,0),0.225,0.46,coat,visual,0.27).scale.z=0.65
	kit.ellipsoid("Shoulders",Vector3(0,1.31,0),Vector3(0.29,0.15,0.16),coat,visual)
	kit.box("Belt",Vector3(0,0.92,-0.007),Vector3(0.5,0.075,0.32),"boot",false,visual)
	kit.box("Buckle",Vector3(0,0.93,-0.175),Vector3(0.075,0.06,0.025),"brass",false,visual)
	kit.box("Shirt",Vector3(0,1.30,-0.16),Vector3(0.12,0.18,0.03),"dark",false,visual)
	kit.box("Scarf",Vector3(0,1.40,0),Vector3(0.32,0.12,0.33),"cream" if player else "cloth",false,visual)
	for x in [-0.15,0.15]:
		kit.box("ChestPocket",Vector3(x,1.14,-0.16),Vector3(0.11,0.14,0.035),"cloth",false,visual)
		kit.box("PocketFlap",Vector3(x,1.19,-0.18),Vector3(0.13,0.035,0.02),coat,false,visual)
		kit.cyl("Button",Vector3(0,1.07+x,-0.185),0.018,0.018,"brass",visual).rotation.x=PI/2
	kit.cyl("Neck",Vector3(0,1.46,0),0.095,0.14,"skin",visual)
	kit.ellipsoid("Head",Vector3(0,1.585,-0.012),Vector3(0.145,0.165,0.14),"skin",visual)
	kit.ellipsoid("Hair",Vector3(0,1.70,0.02),Vector3(0.151,0.05,0.145),"wood",visual)
	kit.ellipsoid("HairBack",Vector3(0,1.65,0.10),Vector3(0.14,0.09,0.06),"wood",visual)
	kit.ellipsoid("Nose",Vector3(0,1.60,-0.151),Vector3(0.027,0.04,0.043),"skin",visual)
	for x in [-0.065,0.065]:kit.box("Eyes",Vector3(x,1.65,-0.14),Vector3(0.035,0.018,0.012),"dark",false,visual)
	if hat:
		kit.cyl("Ushanka",Vector3(0,1.76,0),0.17,0.12,"boot",visual)
		for x in [-0.15,0.15]:kit.box("EarFlap",Vector3(x,1.65,0.02),Vector3(0.055,0.18,0.25),"boot",false,visual)
		kit.box("CapStar",Vector3(0,1.77,-0.16),Vector3(0.055,0.045,0.012),"red",false,visual)
	for side in [-1,1]:
		var leg = Node3D.new()
		visual.add_child(leg)
		leg.position=Vector3(side*0.13,0.73,0)
		kit.cyl("Trousers",Vector3(0,-0.22,0),0.10,0.44,"cloth",leg,0.115)
		kit.box("Boot",Vector3(0,-0.55,-0.04),Vector3(0.20,0.34,0.29),"boot",false,leg)
		kit.box("Sole",Vector3(0,-0.70,-0.04),Vector3(0.22,0.055,0.31),"dark",false,leg)
		var arm=Node3D.new()
		visual.add_child(arm)
		arm.position=Vector3(side*0.31,1.32,0)
		kit.cyl("Sleeve",Vector3(0,-0.22,0),0.085,0.46,coat,arm,0.105)
		kit.ellipsoid("Glove",Vector3(0,-0.49,-0.015),Vector3(0.075,0.085,0.085),"boot",arm)
		if side<0:
			left_leg=leg
			left_arm=arm
		else:
			right_leg=leg
			right_arm=arm
	if player:
		kit.box("Backpack",Vector3(0,1.14,0.24),Vector3(0.38,0.43,0.23),"cloth",false,visual)
		kit.box("Bedroll",Vector3(0,1.38,0.28),Vector3(0.48,0.14,0.18),"wood",false,visual)
		for x in [-0.18,0.18]:kit.box("Strap",Vector3(x,1.21,-0.18),Vector3(0.035,0.34,0.035),"boot",false,visual)
	anchor=position

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
		# NPCs yield to the player instead of sealing a corridor. They remain solid.
		var p=get_tree().get_first_node_in_group("player")
		if p:
			var away=global_position-p.global_position
			away.y=0
			if away.length()<1.10 and yield_time<=0:
				var side=Vector3(-away.z,0,away.x).normalized()
				if test_move(global_transform,side*0.65):side=-side
				yield_direction=(side+away.normalized()*0.45).normalized()
				yield_time=0.75
			if yield_time>0:
				yield_time-=delta
				desired=yield_direction*1.85
			elif position.distance_to(anchor)>0.12 and away.length()>1.25:
				desired=(anchor-position).normalized()*0.55
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
	var stride=sin(clock*10)*0.40*walk
	left_leg.rotation.x=stride
	right_leg.rotation.x=-stride
	left_arm.rotation.x=-stride*0.75
	right_arm.rotation.x=stride*0.75
	visual.position.y=absf(sin(clock*10))*0.025*walk
	if not is_player: visual.position.y+=sin(clock*1.7)*0.005
