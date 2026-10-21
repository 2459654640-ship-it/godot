extends Node3D
## Eight-direction painterly figures in the existing 3D physics world.
## Ivan uses eight explicit views. Older residents retain five authored views.
var actor
var sprite:MeshInstance3D
var material:ShaderMaterial
var angle_slot=0
var direction_ready=false
var cycle=0.0
var focused=false
var pose_count=1
var source_count=5
var actor_id="ivan"
var reaction=""
var reaction_time=0.0
var current_pose=0
var current_column=0
var current_beat=0
var idle_clock=0.0
var room_lamps:Array=[]
var atlas_id=""
var light_clock=.2
var sampled_light=Vector3(.75,.72,.66)
var light_target=Vector3(.75,.72,.66)
var light_ready=false
const PaintedLight=preload("res://scripts/painted_light.gd")
var manifest:Dictionary={}
const HEIGHTS={"commune_moro":1.78,"commune_guard":1.70,"commune_cook":1.65,"sech_cook":1.64,"commune_child":1.19,"ambient_worker":1.76,"ambient_woman":1.65,"ambient_child":1.19,"ambient_elder":1.61,"commune_printer":1.69,"commune_grower":1.64,"sech_quartermaster":1.78,"star_technician":1.76,"commune_leader":1.65,"sech_elder":1.70,"sergey":1.79,"coal_clerk":1.71,"coal_medic":1.64,"coal_brother":1.72,"star_guard":1.74,"veteran_masked":1.77,"commander_masked":1.78,"ivan_masked":1.75,"anna":1.68,"father":1.73,"ivan":1.75,"semyon":1.70,"nina":1.68,"mikhail":1.72,"cook":1.66,"supply":1.70,"commander":1.78,"igor":1.84,"resident":1.72,"diner":1.68,"queue":1.78}

func setup(body):
	actor=body
	actor_id=body.art_id if body.art_id!="" else ("ivan" if body.is_player else String(body.name))
	manifest=JSON.parse_string(FileAccess.get_file_as_string("res://assets/characters/atlas.json"))
	pose_count=int(manifest[actor_id].poses)
	source_count=int(manifest[actor_id].get("source_angles",5))
	atlas_id=actor_id
	room_lamps=actor.get_parent().find_children("*","OmniLight3D",false,false)
	sprite=MeshInstance3D.new()
	sprite.name="PaintedFigure"
	var quad=QuadMesh.new()
	quad.subdivide_width=20
	quad.subdivide_depth=32
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
	material.set_shader_parameter("gait_scale",height/1.75)
	material.set_shader_parameter("painted_map",texture)
	material.set_shader_parameter("frame_size",Vector2(1.0/source_count,1.0/pose_count))
	material.set_shader_parameter("texel_size",Vector2.ONE/Vector2(texture.get_size()))
	sprite.material_override=material
	add_child(sprite)
	# Cheap volumetric casters and a soft contact shadow integrate the drawing
	# with real room lighting without replacing navigation or collision.
	for spec in [[Vector3(0,.95,0),.18,1.30],[Vector3(0,1.60,0),.10,.26]]:
		var shadow=MeshInstance3D.new()
		var capsule=CapsuleMesh.new()
		capsule.radius=spec[1]*height/1.75
		capsule.height=spec[2]*height/1.75
		capsule.radial_segments=8
		capsule.rings=3
		shadow.mesh=capsule
		shadow.position=spec[0]*height/1.75
		shadow.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
		body.add_child(shadow)
	var contact=MeshInstance3D.new()
	contact.name="ContactShadow"
	var plane=PlaneMesh.new()
	plane.size=Vector2(.68,.48)*minf(1.0,height/1.75)
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
	reaction_time=.14 if kind=="shot" else 1.0

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
	var world=actor.get_parent()
	idle_clock+=delta
	var director=world.get("combat")
	var armed=(actor.is_player and world.story.weapon_drawn()) or (is_instance_valid(director) and director.enabled and actor_id=="veteran_masked")
	var chosen=(actor_id+"_combat") if armed and manifest.has(actor_id+"_combat") else actor_id
	if chosen!=atlas_id:
		atlas_id=chosen;pose_count=int(manifest[chosen].poses);source_count=int(manifest[chosen].get("source_angles",5))
		var texture:Texture2D=load("res://assets/characters/"+chosen+".png")
		var height:float=HEIGHTS.get(actor_id,1.75)
		sprite.mesh.size=Vector2(height*.762*float(manifest[chosen].cell[0])/324.0,height*352.0/324.0)
		sprite.mesh.subdivide_width=48 if armed else 20
		for ink in [material]:
			ink.set_shader_parameter("painted_map",texture);ink.set_shader_parameter("frame_size",Vector2(1.0/source_count,1.0/pose_count));ink.set_shader_parameter("texel_size",Vector2.ONE/Vector2(texture.get_size()))
	var column=angle_slot if source_count==8 else mini(angle_slot,8-angle_slot)
	var speed=Vector2(actor.velocity.x,actor.velocity.z).length()
	var phase_delta=delta*speed/actor.stride_length()
	# Keep the planted pose visible even when a rendered frame takes longer
	# than one animation phase; never skip directly between the two strides.
	cycle+=minf(phase_delta,.219)
	var walking=speed>0.15
	var phase=fposmod(cycle,1.0)
	# Give both contact poses a little more screen time, including diagonals.
	var beat=0 if phase<.22 else (1 if phase<.50 else (2 if phase<.72 else 3))
	current_beat=beat
	var pose=0
	if armed:
		var reloading=is_instance_valid(director) and ((actor.is_player and director.reload_time>0) or (actor_id=="veteran_masked" and director.veteran_reload>0))
		if reloading:
			if pose_count>=7:pose=[5,2,6,2][beat] if walking else 2
			else:pose=[1,0,2,0][beat] if walking else 0
		elif walking:
			if pose_count>=5:pose=[3,0,4,0][beat]
			elif pose_count>=3:pose=[1,0,2,0][beat]
		elif reaction=="shot" and reaction_time>0:pose=1
	elif walking and pose_count>=3:
		pose=[1,0,2,0][beat]
	elif actor.animation_state=="talk" and pose_count>3:pose=3
	current_pose=pose
	current_column=column
	material.set_shader_parameter("puppet_stride",cos(TAU*phase) if walking and pose_count<3 else 0.0)
	material.set_shader_parameter("puppet_direction",Vector2(sin(angle),cos(angle)))
	material.set_shader_parameter("idle_time",idle_clock+float(posmod(String(actor.name).hash(),1000))/80.0)
	material.set_shader_parameter("idle_amount",0.0 if walking else 1.0)
	reaction_time=maxf(0.0,reaction_time-delta)
	material.set_shader_parameter("reaction",(1.0 if reaction=="success" else -1.0)*reaction_time if reaction_time>0 and reaction!="shot" else 0.0)
	material.set_shader_parameter("shot_recoil",reaction_time/.14 if reaction=="shot" else 0.0)
	material.set_shader_parameter("aim_screen",Vector2(sin(angle),cos(angle)))
	material.set_shader_parameter("frame_origin",Vector2(float(column)/source_count,float(pose)/pose_count))
	var mirrored_frames:Array=manifest[atlas_id].get("frame_mirror",[])
	var pose_mirrored=false if mirrored_frames.is_empty() else bool(mirrored_frames[pose][column])
	# New eight-view sheets store all actual directions, including both rear
	# diagonals. Older five-view residents retain their authored convention.
	var view_mirrored=(angle_slot>4) if source_count==5 else false
	material.set_shader_parameter("mirror",view_mirrored!=pose_mirrored)
	material.set_shader_parameter("puppet_direction",Vector2(sin(angle)*(-1.0 if view_mirrored!=pose_mirrored else 1.0),cos(angle)))
	material.set_shader_parameter("focus",1.0 if focused else 0.0)
	material.set_shader_parameter("down_amount",1.0 if is_instance_valid(director) and actor_id=="veteran_masked" and director.veteran_health<=0 else 0.0)
	light_clock+=delta
	if light_clock>=.16:
		light_clock=0
		light_target=PaintedLight.sample(world,actor.global_position,room_lamps)
		if not light_ready:sampled_light=light_target;light_ready=true
	sampled_light=sampled_light.lerp(light_target,1-exp(-delta*5.0))
	# Normalize small baked exposure differences between drawings in linear
	# light. Authored room lighting remains independent and smoothly blended.
	var exposures:Array=manifest[atlas_id].get("exposure",[])
	var exposure=1.0 if exposures.is_empty() else float(exposures[pose][column])
	material.set_shader_parameter("light_tint",sampled_light*exposure)
