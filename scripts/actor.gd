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
