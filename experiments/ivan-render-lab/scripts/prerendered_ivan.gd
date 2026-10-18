extends Node3D
## Isolated pilot. Neither the cast atlas nor the shipping player is replaced.
var actor
var material:ShaderMaterial
var sprite:MeshInstance3D
var angle_slot=0
var direction_ready=false
var distance=0.0
var idle_time=0.0
var current_pose=0
var metadata:Dictionary
func setup(body):
 actor=body
 metadata=JSON.parse_string(FileAccess.get_file_as_string("res://assets/characters/ivan_pilot/manifest.json"))
 sprite=MeshInstance3D.new();sprite.name="PrerenderedIvan"
 var quad=QuadMesh.new()
 var screen_height:float=metadata.screen_height
 quad.size=Vector2(screen_height*192.0/288.0,screen_height)
 quad.center_offset=Vector3.ZERO
 sprite.position.y=metadata.pivot_height
 sprite.extra_cull_margin=2;sprite.ignore_occlusion_culling=true
 sprite.mesh=quad;sprite.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 material=ShaderMaterial.new();material.shader=load("res://assets/visual/prerendered_actor.gdshader")
 material.set_shader_parameter("color_atlas",load("res://assets/characters/ivan_pilot/color.png"))
 material.set_shader_parameter("normal_atlas",load("res://assets/characters/ivan_pilot/normal.png"))
 sprite.material_override=material;add_child(sprite)
func _process(delta):
 if not is_instance_valid(actor):return
 var camera=get_viewport().get_camera_3d()
 if not camera:return
 var forward=-actor.visual.global_basis.z
 var towards=camera.global_basis.z;towards.y=0
 var right=camera.global_basis.x;right.y=0
 var angle=atan2(forward.dot(right.normalized()),forward.dot(towards.normalized()))
 var proposed=posmod(roundi(angle/(PI/4)),8)
 if not direction_ready or absf(angle_difference(angle_slot*PI/4,angle))>PI/8+.055:
  angle_slot=proposed;direction_ready=true
 actor.visual.position.y=0 # The rendered skeleton already contains its own gait bob.
 var speed=Vector2(actor.velocity.x,actor.velocity.z).length()
 if speed>.15:
  distance+=speed*delta
  current_pose=4+posmod(floori(distance/float(metadata.stride_meters)*16),16)
  idle_time=0
 else:
  idle_time+=delta;current_pose=floori(idle_time*3)%4
 material.set_shader_parameter("frame_origin",Vector2(float(angle_slot)/8,float(current_pose)/24))
