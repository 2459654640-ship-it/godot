extends Node3D
## Eight-direction painterly figures in the existing 3D physics world.
## Five authored angles are mirrored; the player's two strides form a cycle.
var actor
var sprite:MeshInstance3D
var material:ShaderMaterial
var angle_slot=0
var direction_ready=false
var cycle=0.0
var focused=false
var pose_count=1
var actor_id="ivan"
var reaction=""
var reaction_time=0.0
var current_pose=0
const HEIGHTS={"commune_printer":1.69,"commune_grower":1.64,"sech_quartermaster":1.78,"star_technician":1.76,"commune_leader":1.65,"sech_elder":1.70,"sergey":1.79,"coal_clerk":1.71,"coal_medic":1.64,"coal_brother":1.72,"star_guard":1.74,"veteran_masked":1.77,"commander_masked":1.78,"ivan_masked":1.75,"anna":1.68,"father":1.73,"ivan":1.75,"semyon":1.70,"nina":1.68,"mikhail":1.72,"cook":1.66,"supply":1.70,"commander":1.78,"igor":1.84,"resident":1.72,"diner":1.68,"queue":1.78}

func setup(body):
	actor=body
	actor_id=body.art_id if body.art_id!="" else ("ivan" if body.is_player else String(body.name))
	var manifest=JSON.parse_string(FileAccess.get_file_as_string("res://assets/characters/atlas.json"))
	pose_count=int(manifest[actor_id].poses)
	sprite=MeshInstance3D.new()
	sprite.name="PaintedFigure"
	var quad=QuadMesh.new()
	quad.subdivide_width=8
	quad.subdivide_depth=12
	# Upright Y-axis billboard: true world height and geometric depth.
	# Keep painted width proportional to the fixed 40-degree projected height.
	var height:float=HEIGHTS.get(actor_id,1.75)
	quad.size=Vector2(height*.762*float(manifest[actor_id].cell[0])/324.0,height*352.0/324.0)
	quad.center_offset=Vector3(0,quad.size.y/2-height*10.0/324.0,0)
	sprite.mesh=quad
	sprite.extra_cull_margin=1.0
	sprite.ignore_occlusion_culling=true
	sprite.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	material=ShaderMaterial.new()
	material.shader=load("res://assets/visual/painted_actor.gdshader")
	var texture:Texture2D=load("res://assets/characters/"+actor_id+".png")
	material.set_shader_parameter("painted_map",texture)
	material.set_shader_parameter("frame_size",Vector2(0.2,1.0/pose_count))
	material.set_shader_parameter("texel_size",Vector2.ONE/Vector2(texture.get_size()))
	sprite.material_override=material
	add_child(sprite)
	# Cheap volumetric casters and a soft contact shadow integrate the drawing
	# with real room lighting without replacing navigation or collision.
	for spec in [[Vector3(0,.95,0),.18,1.30],[Vector3(0,1.60,0),.10,.26]]:
		var shadow=MeshInstance3D.new()
		var capsule=CapsuleMesh.new()
		capsule.radius=spec[1]
		capsule.height=spec[2]
		capsule.radial_segments=8
		capsule.rings=3
		shadow.mesh=capsule
		shadow.position=spec[0]
		shadow.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
		body.add_child(shadow)
	var contact=MeshInstance3D.new()
	contact.name="ContactShadow"
	var plane=PlaneMesh.new()
	plane.size=Vector2(.68,.48)
	contact.mesh=plane
	# Above the shallow carpet too, so a character on the rug stays grounded.
	contact.position.y=.052
	contact.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var ink=ShaderMaterial.new()
	ink.shader=load("res://assets/visual/contact_shadow.gdshader")
	contact.material_override=ink
	body.add_child(contact)

func react(kind:String):
	reaction=kind
	reaction_time=1.0

func _process(delta):
	if not is_instance_valid(actor):return
	var camera=get_viewport().get_camera_3d()
	if not camera:return
	# The node inherits smooth actor yaw; the billboard itself faces camera.
	var f=-actor.visual.global_basis.z
	var towards=camera.global_basis.z
	towards.y=0.0
	var right=camera.global_basis.x
	right.y=0.0
	var angle=atan2(f.dot(right.normalized()),f.dot(towards.normalized()))
	var proposed=posmod(roundi(angle/(PI/4)),8)
	var previous_angle=angle_slot*(PI/4)
	if not direction_ready or absf(angle_difference(previous_angle,angle))>PI/8+0.055:
		angle_slot=proposed
		direction_ready=true
	var column=mini(angle_slot,8-angle_slot)
	var speed=Vector2(actor.velocity.x,actor.velocity.z).length()
	cycle+=delta*speed*(.95 if actor.is_player else 1.65)
	var pose=0
	if speed>0.2 and pose_count>1:
		pose=[1,0,2,0][floori(cycle*2.0)%4]
	elif actor.animation_state=="talk" and pose_count>3:pose=3
	current_pose=pose
	reaction_time=maxf(0.0,reaction_time-delta)
	material.set_shader_parameter("reaction",(1.0 if reaction=="success" else -1.0)*reaction_time if reaction_time>0 else 0.0)
	material.set_shader_parameter("frame_origin",Vector2(column*.2,float(pose)/pose_count))
	material.set_shader_parameter("mirror",angle_slot>4)
	material.set_shader_parameter("focus",1.0 if focused else 0.0)
	material.set_shader_parameter("gait",cycle*PI*2)
	material.set_shader_parameter("motion",0.0)
	# Painted key/fill remains readable, with a restrained room-color tint.
	var warm=clampf((1.8-actor.global_position.z)*0.04,-.04,.05)
	var floor=actor.get_parent().get("floor_id")
	if floor=="waterworks":warm=-.05
	elif floor=="commune":warm=.07
	elif floor in ["starcity","coal"]:warm=-.04
	material.set_shader_parameter("light_tint",Vector3(.94+warm,.91,.84-warm))
