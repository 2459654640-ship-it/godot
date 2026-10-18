extends Node3D
## Fixed background residents share the existing painterly billboard treatment.
## Full-body group artwork: no fake walking, dialogue target or roaming route.
var world
var material:ShaderMaterial
var light_clock=0.0
var lamps:Array=[]
var light_excludes:Array[RID]=[]
const PaintedLight=preload("res://scripts/painted_light.gd")
var light_target=Vector3(.66,.63,.55)
var light_current=Vector3(.66,.63,.55)
var light_ready=false
func setup(w,id:String,p:Vector3,count:int,height:float=1.73):
 world=w;position=p;name="ResidentGroup_"+id;w.add_child(self)
 set_meta("resident_count",count);set_meta("stationary",true)
 var texture:Texture2D=load("res://assets/characters/group_"+id+".png")
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
 if light_clock>=.25 or not light_ready:
  light_clock=0
  if lamps.is_empty():lamps=world.find_children("*","OmniLight3D",false,false)
  light_target=PaintedLight.sample(world,global_position,lamps,light_excludes)
  if not light_ready:light_current=light_target;light_ready=true
 light_current=light_current.lerp(light_target,1-exp(-delta*5.0))
 material.set_shader_parameter("light_tint",light_current)
