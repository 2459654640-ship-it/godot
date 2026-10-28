extends Node3D
var director
var remaining=.5
var duration=.5
var mesh:MeshInstance3D
var ink:StandardMaterial3D
func setup(d,p:Vector3,seconds:float,target:Vector3=Vector3.INF,width:float=.6,kind:String="bite"):
 director=d;position=p;duration=seconds;remaining=seconds
 mesh=MeshInstance3D.new();mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;add_child(mesh)
 ink=StandardMaterial3D.new();ink.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;ink.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;ink.no_depth_test=false;ink.cull_mode=BaseMaterial3D.CULL_DISABLED;ink.albedo_color=Color(.83,.59,.28,.7);mesh.material_override=ink
 var geometry=ImmediateMesh.new();mesh.mesh=geometry;geometry.surface_begin(Mesh.PRIMITIVE_LINES)
 var offset=target-p if target.is_finite() else Vector3.ZERO;offset.y=0
 if kind in ["pounce","charge"] and offset.length()>.01:
  var end=offset.normalized()*minf(offset.length(),7.6 if kind=="charge" else 2.45);var side=Vector3(-end.z,0,end.x).normalized()*(.9 if kind=="charge" else width)
  for edge in [-1,1]:line(geometry,side*edge,end+side*edge)
  line(geometry,end-side,end+side);line(geometry,end,end*.75+side*.5);line(geometry,end,end*.75-side*.5)
 else:
  for i in 40:
   var a=i*TAU/40;var b=(i+1)*TAU/40
   line(geometry,Vector3(cos(a),0,sin(a))*width,Vector3(cos(b),0,sin(b))*width)
 geometry.surface_end()
func line(g:ImmediateMesh,a:Vector3,b:Vector3):
 g.surface_add_vertex(a+Vector3.UP*.045);g.surface_add_vertex(b+Vector3.UP*.045)
func _physics_process(delta):
 if not is_instance_valid(director):queue_free();return
 if director.paused():return
 remaining-=delta
 if remaining<=0:queue_free();return
 ink.albedo_color=Color(.93,.55,.24,.45+.35*(1.0-remaining/duration))
