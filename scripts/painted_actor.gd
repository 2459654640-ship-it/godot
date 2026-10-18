extends Node3D
## Eight-direction painterly figures in the existing 3D physics world.
## Five authored angles are mirrored; aligned 2D leg layers drive the gait.
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
var legs:Array[MeshInstance3D]=[]
var leg_materials:Array[ShaderMaterial]=[]
var gait_phase=0.0
var room_lamps:Array=[]
var atlas_id=""
var light_clock=.2
var sampled_light=Vector3(.75,.72,.66)
var manifest:Dictionary={}
const HEIGHTS={"commune_cook":1.65,"sech_cook":1.64,"commune_child":1.19,"ambient_worker":1.76,"ambient_woman":1.65,"ambient_child":1.19,"ambient_elder":1.61,"commune_printer":1.69,"commune_grower":1.64,"sech_quartermaster":1.78,"star_technician":1.76,"commune_leader":1.65,"sech_elder":1.70,"sergey":1.79,"coal_clerk":1.71,"coal_medic":1.64,"coal_brother":1.72,"star_guard":1.74,"veteran_masked":1.77,"commander_masked":1.78,"ivan_masked":1.75,"anna":1.68,"father":1.73,"ivan":1.75,"semyon":1.70,"nina":1.68,"mikhail":1.72,"cook":1.66,"supply":1.70,"commander":1.78,"igor":1.84,"resident":1.72,"diner":1.68,"queue":1.78}

func setup(body):
	actor=body
	actor_id=body.art_id if body.art_id!="" else ("ivan" if body.is_player else String(body.name))
	manifest=JSON.parse_string(FileAccess.get_file_as_string("res://assets/characters/atlas.json"))
	pose_count=int(manifest[actor_id].poses)
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
	material.set_shader_parameter("painted_map",texture)
	material.set_shader_parameter("frame_size",Vector2(0.2,1.0/pose_count))
	material.set_shader_parameter("texel_size",Vector2.ONE/Vector2(texture.get_size()))
	sprite.material_override=material
	add_child(sprite)
	# Articulated 2D cutouts use ONE body drawing. Head, torso and clothing
	# cannot change size between independently generated stride drawings.
	for side in [-1,1]:
		var leg=MeshInstance3D.new();leg.name="FarLeg" if side<0 else "NearLeg"
		leg.mesh=quad;leg.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var ink:ShaderMaterial=material.duplicate();ink.set_shader_parameter("part",side)
		leg.material_override=ink;add_child(leg);legs.append(leg);leg_materials.append(ink)
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
	var director=world.get("combat")
	var armed=is_instance_valid(director) and director.enabled and (director.active or actor_id=="veteran_masked")
	var chosen=(actor_id+"_combat") if armed and manifest.has(actor_id+"_combat") else actor_id
	if chosen!=atlas_id:
		atlas_id=chosen;pose_count=int(manifest[chosen].poses)
		var texture:Texture2D=load("res://assets/characters/"+chosen+".png")
		var height:float=HEIGHTS.get(actor_id,1.75)
		sprite.mesh.size=Vector2(height*.762*float(manifest[chosen].cell[0])/324.0,height*352.0/324.0)
		sprite.mesh.subdivide_width=48 if armed else 20
		for ink in [material]+leg_materials:
			ink.set_shader_parameter("painted_map",texture);ink.set_shader_parameter("frame_size",Vector2(.2,1.0/pose_count));ink.set_shader_parameter("texel_size",Vector2.ONE/Vector2(texture.get_size()))
	var column=mini(angle_slot,8-angle_slot)
	var speed=Vector2(actor.velocity.x,actor.velocity.z).length()
	cycle+=delta*speed/(1.7 if actor.is_player else (.85 if actor_id in ["ambient_child","commune_child"] else 1.15))
	var walking=speed>0.15
	gait_phase=cycle*TAU
	var pose=0
	if armed:
		if reaction=="shot" and reaction_time>0:pose=1
		elif (actor.is_player and director.reload_time>0) or (actor_id=="veteran_masked" and director.veteran_reload>0):pose=2
	current_pose=(1 if sin(gait_phase)>=0 else 2) if walking else 0
	reaction_time=maxf(0.0,reaction_time-delta)
	material.set_shader_parameter("reaction",(1.0 if reaction=="success" else -1.0)*reaction_time if reaction_time>0 and reaction!="shot" else 0.0)
	material.set_shader_parameter("frame_origin",Vector2(column*.2,float(pose)/pose_count))
	material.set_shader_parameter("mirror",angle_slot>4)
	material.set_shader_parameter("focus",1.0 if focused else 0.0)
	material.set_shader_parameter("gait",cycle*PI*2)
	var hem=.60
	if actor_id in ["ambient_woman","ambient_elder","commune_cook"]:hem=.81
	elif actor_id=="sech_cook":hem=.74
	elif actor_id in ["semyon","commune_leader","sech_elder","coal_medic"]:hem=.70
	var rig_direction=float(column)*PI/4
	for ink in [material]+leg_materials:
		ink.set_shader_parameter("frame_origin",Vector2(column*.2,float(pose)/pose_count))
		ink.set_shader_parameter("mirror",angle_slot>4)
		ink.set_shader_parameter("gait",gait_phase)
		ink.set_shader_parameter("motion",1.0 if walking else 0.0)
		ink.set_shader_parameter("hem",hem)
		ink.set_shader_parameter("frame_pixels",float(manifest[atlas_id].cell[0]))
		ink.set_shader_parameter("step_length",.14 if actor.is_player else (.085 if actor_id in ["ambient_child","commune_child"] else .12))
		ink.set_shader_parameter("down_amount",1.0 if is_instance_valid(director) and actor_id=="veteran_masked" and director.veteran_health<=0 else 0.0)
		ink.set_shader_parameter("side_view",column==2)
		ink.set_shader_parameter("stride_axis",Vector2(sin(rig_direction),cos(rig_direction)))
		ink.set_shader_parameter("focus",1.0 if focused else 0.0)
		ink.set_shader_parameter("reaction",material.get_shader_parameter("reaction"))
	for leg in legs:leg.visible=walking
	# Painted key/fill remains readable, with a restrained room-color tint.
	var warm=clampf((1.8-actor.global_position.z)*0.04,-.04,.05)
	var floor=actor.get_parent().get("floor_id")
	if floor=="waterworks":warm=-.05
	elif floor=="commune":warm=.07
	elif floor in ["starcity","coal"]:warm=-.04
	var tint=Vector3(.94+warm,.91,.84-warm)
	# Sample authored room lamps, keeping their painted shading but allowing
	# a figure to become darker/cooler as it leaves the light pool.
	light_clock+=delta
	if light_clock>=.16:
		light_clock=0
		var energy=.34;var color=Vector3(.30,.34,.34)*energy
		for lamp in room_lamps:
			if not is_instance_valid(lamp):continue
			var distance=actor.global_position.distance_to(lamp.global_position-Vector3(0,.8,0))
			if distance>lamp.omni_range:continue
			var strength=pow(maxf(0,1-distance/lamp.omni_range),2)*lamp.light_energy*.48
			var query=PhysicsRayQueryParameters3D.create(actor.global_position+Vector3.UP*.95,lamp.global_position,1)
			if not actor.get_world_3d().direct_space_state.intersect_ray(query).is_empty():strength*=.15
			energy+=strength;color+=Vector3(lamp.light_color.r,lamp.light_color.g,lamp.light_color.b)*strength
		var illumination=clampf(.46+energy*.25,.49,1.02)
		var lamp_tint=color/maxf(energy,.01)
		sampled_light=tint*Vector3(illumination,illumination,illumination).lerp(lamp_tint,.12)
	var lit=sampled_light
	for ink in [material]+leg_materials:ink.set_shader_parameter("light_tint",lit)
