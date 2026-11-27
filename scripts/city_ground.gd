extends RefCounted
const Site=preload("res://scripts/surface_site.gd")
const GROUND_BOUNDS=Rect2(-120,-100,240,200)
const IMPACT_BOUNDS=Rect2(-1,-70,16,14)
const IMPACT_CENTER=Vector2(7,-63)
const IMPACT_RADII=Vector2(7.8,6.7)
const MAX_SEGMENTS=48
const SURFACES={"walk":0.0,"service":.30,"street":.68,"arterial":1.0}

static func build(w,plan):
 var k=w.kit
 Site.ground(w,GROUND_BOUNDS,false,false)
 var ink=ShaderMaterial.new();ink.shader=load("res://assets/visual/city_ground.gdshader")
 var road_finish="res://assets/visual/winter_road_v37.png"
 if not ResourceLoader.exists(road_finish):road_finish="res://assets/visual/city29_asphalt.png"
 ink.set_shader_parameter("asphalt_map",load(road_finish))
 ink.set_shader_parameter("snow_map",preload("res://assets/visual/art28_snow.png"))
 ink.set_shader_parameter("paving_map",preload("res://assets/visual/city29_paving.png"))
 var lines=PackedVector4Array();var widths=PackedFloat32Array();var surfaces=PackedFloat32Array()
 for road in plan.roads:
  for i in road.points.size()-1:
   var a=road.points[i];var b=road.points[i+1];lines.append(Vector4(a[0],a[1],b[0],b[1]));widths.append(road.width);surfaces.append(SURFACES[road.get("class","service")])
 assert(lines.size()<=MAX_SEGMENTS,"District ground segment limit exceeded")
 ink.set_shader_parameter("road_count",lines.size());lines.resize(MAX_SEGMENTS);widths.resize(MAX_SEGMENTS);surfaces.resize(MAX_SEGMENTS)
 ink.set_shader_parameter("segments",lines);ink.set_shader_parameter("widths",widths);ink.set_shader_parameter("road_surfaces",surfaces)
 ink.set_shader_parameter("impact_center",IMPACT_CENTER)
 ink.set_shader_parameter("impact_radii",IMPACT_RADII)
 terrain(w.get_node("FloorOutdoor"),ink)
 var distant=w.get_node("DistantSnow");distant.position.y=-.9;distant.mesh.size=Vector3(400,.20,360);distant.material_override=ink
 # Curbs are authored around the union, so no junction is crossed by a kerb.
 for road in plan.roads:
  if road.width<5:continue
  for i in road.points.size()-1:
   var a=Vector2(road.points[i][0],road.points[i][1]);var b=Vector2(road.points[i+1][0],road.points[i+1][1]);var along=(b-a).normalized();var side=Vector2(-along.y,along.x)
   for n in int(a.distance_to(b)/1.9):
    for sign in [-1,1]:
     var p=a+along*(n*1.9+.95)+side*sign*(road.width/2+.12)
     if not Rect2(-147,-123,294,246).has_point(p):continue
     var near_other=false
     for other in plan.roads:
      if other.id==road.id:continue
      for j in other.points.size()-1:
       var c=Vector2(other.points[j][0],other.points[j][1]);var e=Vector2(other.points[j+1][0],other.points[j+1][1])
       if Geometry2D.get_closest_point_to_segment(p,c,e).distance_to(p)<other.width/2+2:near_other=true
     if near_other or n%13==5:continue
     var curb=k.box("CityRoadKerb",Vector3(p.x,.055,p.y),Vector3(.15,.11,1.82),"concrete")
     curb.rotation.y=atan2(along.x,along.y)
static func impact_factor(p:Vector2)->float:
 return 1.0-smoothstep(.08,.98,((p-IMPACT_CENTER)/IMPACT_RADII).length())

static func height_at(p:Vector2)->float:
 return -.57*impact_factor(p)

static func terrain(floor:MeshInstance3D,material:ShaderMaterial):
 # The shallow depression and surrounding streets share one collision mesh.
 # Plane quads surround the densely sampled ground inside the impact bounds.
 var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
 var inner=IMPACT_BOUNDS;var bounds=GROUND_BOUNDS
 ground_quad(st,Rect2(bounds.position,Vector2(inner.position.x-bounds.position.x,bounds.size.y)))
 ground_quad(st,Rect2(Vector2(inner.end.x,bounds.position.y),Vector2(bounds.end.x-inner.end.x,bounds.size.y)))
 ground_quad(st,Rect2(Vector2(inner.position.x,bounds.position.y),Vector2(inner.size.x,inner.position.y-bounds.position.y)))
 ground_quad(st,Rect2(Vector2(inner.position.x,inner.end.y),Vector2(inner.size.x,bounds.end.y-inner.end.y)))
 for x in range(int(inner.position.x*2),int(inner.end.x*2)):
  for z in range(int(inner.position.y*2),int(inner.end.y*2)):
   ground_quad(st,Rect2(x*.5,z*.5,.5,.5))
 st.generate_normals()
 floor.position=Vector3.ZERO
 floor.mesh=st.commit()
 floor.material_override=material
 var shape:CollisionShape3D=floor.find_children("*","CollisionShape3D",true,false)[0]
 shape.shape=floor.mesh.create_trimesh_shape()

static func ground_quad(st:SurfaceTool,rect:Rect2):
 var a=rect.position;var c=rect.end;var b=Vector2(c.x,a.y);var d=Vector2(a.x,c.y)
 for p in [a,b,c,a,c,d]:st.add_vertex(Vector3(p.x,height_at(p),p.y))

static func apron(k,p:Vector2,size:Vector2):
 return k.box("CityYardPaving",Vector3(p.x,.016,p.y),Vector3(size.x,.028,size.y),"city_paving")
