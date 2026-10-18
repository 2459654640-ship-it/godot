extends Node3D
## Fixed background residents share the existing painterly billboard treatment.
## Full-body group artwork: no fake walking, dialogue target or roaming route.
var world
var material:ShaderMaterial
var light_clock=0.0
var lamps:Array=[]
var light_excludes:Array[RID]=[]
func setup(w,id:String,p:Vector3,count:int):
 world=w;position=p;name="ResidentGroup_"+id;w.add_child(self)
 set_meta("resident_count",count);set_meta("stationary",true)
 var texture:Texture2D=load("res://assets/characters/group_"+id+".png")
 var height=1.73
 var width=height*.762*texture.get_width()/texture.get_height()
 set_meta("footprint_width",width)
 var mesh=MeshInstance3D.new();mesh.name="PaintedResidents"
 var quad=QuadMesh.new();quad.size=Vector2(width,height);quad.center_offset=Vector3(0,height/2,0);mesh.mesh=quad
 material=ShaderMaterial.new();material.shader=load("res://assets/visual/painted_actor.gdshader")
 material.set_shader_parameter("painted_map",texture);material.set_shader_parameter("frame_size",Vector2.ONE)
 material.set_shader_parameter("texel_size",Vector2.ONE/Vector2(texture.get_size()))
 material.set_shader_parameter("light_tint",Vector3(.66,.63,.55));mesh.material_override=material
 mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;add_child(mesh)
 # Matching physical footprint follows the diagonal group, not a thin sprite.
 var hull=w.kit.box("ResidentGroupHull",Vector3(0,.86,0),Vector3(width,1.72,.65),"dark",true,self)
 hull.visible=false;hull.rotation.y=atan2(23.0,27.0)
 light_excludes.append(hull.get_child(0).get_rid())
 var extent=Vector2(absf(cos(hull.rotation.y))*width+absf(sin(hull.rotation.y))*.65,absf(sin(hull.rotation.y))*width+absf(cos(hull.rotation.y))*.65)
 w.kit.solids.append({"name":name,"rect":Rect2(Vector2(p.x,p.z)-extent/2,extent),"bottom":0.0,"top":1.72})
 var shadow=MeshInstance3D.new();shadow.name="GroupContactShadow"
 var plane=PlaneMesh.new();plane.size=Vector2(width,.63);shadow.mesh=plane;shadow.position.y=.052;shadow.rotation.y=hull.rotation.y
 var ink=ShaderMaterial.new();ink.shader=load("res://assets/visual/contact_shadow.gdshader");shadow.material_override=ink
 shadow.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;add_child(shadow)
func _process(delta):
 light_clock+=delta
 if light_clock<.25:return
 light_clock=0
 if lamps.is_empty():lamps=world.find_children("*","OmniLight3D",false,false)
 var energy=.34;var color=Vector3(.30,.34,.34)*energy
 for lamp in lamps:
  if not is_instance_valid(lamp):continue
  var distance=global_position.distance_to(lamp.global_position-Vector3.UP*.8)
  if distance>lamp.omni_range:continue
  var strength=pow(maxf(0,1-distance/lamp.omni_range),2)*lamp.light_energy*.48
  var ray=PhysicsRayQueryParameters3D.create(global_position+Vector3.UP*.95,lamp.global_position,1)
  ray.exclude=light_excludes
  if not get_world_3d().direct_space_state.intersect_ray(ray).is_empty():strength*=.15
  energy+=strength;color+=Vector3(lamp.light_color.r,lamp.light_color.g,lamp.light_color.b)*strength
 var level=clampf(.46+energy*.25,.49,1.02)
 material.set_shader_parameter("light_tint",Vector3(1.01,.91,.77)*Vector3.ONE.lerp(color/maxf(.01,energy),.12)*level)
