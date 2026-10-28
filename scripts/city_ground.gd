extends RefCounted
const Site=preload("res://scripts/surface_site.gd")
static func build(w,plan):
 var k=w.kit
 Site.ground(w,Rect2(-120,-100,240,200),false,false)
 var ink=ShaderMaterial.new();ink.shader=load("res://assets/visual/city_ground.gdshader")
 for pair in [["snow_map","art28_snow"],["asphalt_map","city29_asphalt"],["paving_map","city29_paving"]]:ink.set_shader_parameter(pair[0],load("res://assets/visual/"+pair[1]+".png"))
 var lines=PackedVector4Array();var widths=PackedFloat32Array()
 for road in plan.roads:
  for i in road.points.size()-1:
   var a=road.points[i];var b=road.points[i+1];lines.append(Vector4(a[0],a[1],b[0],b[1]));widths.append(road.width)
 ink.set_shader_parameter("road_count",lines.size());lines.resize(32);widths.resize(32);ink.set_shader_parameter("segments",lines);ink.set_shader_parameter("widths",widths)
 w.get_node("FloorOutdoor").material_override=ink
 var distant=w.get_node("DistantSnow");distant.position.y=-.13;distant.mesh.size=Vector3(400,.20,360);distant.material_override=ink
 # Curbs are authored around the union, so no junction is crossed by a kerb.
 for road in plan.roads:
  if road.width<5:continue
  for i in road.points.size()-1:
   var a=Vector2(road.points[i][0],road.points[i][1]);var b=Vector2(road.points[i+1][0],road.points[i+1][1]);var along=(b-a).normalized();var side=Vector2(-along.y,along.x)
   for n in int(a.distance_to(b)/1.9):
    for sign in [-1,1]:
     var p=a+along*(n*1.9+.95)+side*sign*(road.width/2+.12)
     var near_other=false
     for other in plan.roads:
      if other.id==road.id:continue
      for j in other.points.size()-1:
       var c=Vector2(other.points[j][0],other.points[j][1]);var e=Vector2(other.points[j+1][0],other.points[j+1][1])
       if Geometry2D.get_closest_point_to_segment(p,c,e).distance_to(p)<other.width/2+2:near_other=true
     if near_other or n%13==5:continue
     var curb=k.box("CityRoadKerb",Vector3(p.x,.055,p.y),Vector3(.15,.11,1.82),"concrete")
     curb.rotation.y=atan2(along.x,along.y)
static func apron(k,p:Vector2,size:Vector2):
 return k.box("CityYardPaving",Vector3(p.x,.016,p.y),Vector3(size.x,.028,size.y),"city_paving")
