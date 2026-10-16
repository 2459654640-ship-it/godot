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
const HEIGHTS={"ivan":1.46,"semyon":1.42,"nina":1.40,"mikhail":1.43,"cook":1.39,"supply":1.42,"commander":1.48,"igor":1.53,"resident":1.43,"diner":1.40,"queue":1.48}

func setup(body):
	actor=body
	actor_id="ivan" if body.is_player else String(body.name)
	pose_count=3 if actor_id=="ivan" else 1
	sprite=MeshInstance3D.new()
	sprite.name="PaintedFigure"
	var quad=QuadMesh.new()
	quad.subdivide_width=8
	quad.subdivide_depth=12
	var height:float=HEIGHTS.get(actor_id,1.46)
	quad.size=Vector2(height*208.0/324.0,height*352.0/324.0)
	quad.center_offset=Vector3(0,quad.size.y/2-height*10.0/324.0,0)
	sprite.mesh=quad
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
	cycle+=delta*speed*0.95
	var pose=0
	if speed>0.2 and pose_count>1:
		pose=[1,0,2,0][floori(cycle*2.0)%4]
	material.set_shader_parameter("frame_origin",Vector2(column*.2,float(pose)/pose_count))
	material.set_shader_parameter("mirror",angle_slot>4)
	material.set_shader_parameter("focus",1.0 if focused else 0.0)
	material.set_shader_parameter("gait",cycle*PI*2)
	material.set_shader_parameter("motion",clampf(speed/2.65,0,1) if pose_count==1 else 0.0)
	# Painted key/fill remains readable, with a restrained room-color tint.
	var warm=clampf((1.8-actor.global_position.z)*0.04,-.04,.05)
	material.set_shader_parameter("light_tint",Vector3(.94+warm,.91,.84-warm))
