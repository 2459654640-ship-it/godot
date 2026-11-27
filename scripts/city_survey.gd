extends Node
## Foot surveys are saved independently of the pre-war street chart.
const CELL=12.0
const Ground=preload("res://scripts/city_ground.gd")
var world
var timer=0.0
func setup(w):world=w;survey()
func _process(delta):
 if not is_instance_valid(world) or not world.initialized:return
 timer+=delta
 if timer<.5:return
 timer=0;survey()
static func key(p:Vector2)->String:return "%d,%d"%[floori(p.x/CELL),floori(p.y/CELL)]
static func known(s,p:Vector2)->bool:return s.flags.get("city_seen",{}).has(key(p))
func survey():
 var p:Vector3=world.player.position;var records:Dictionary=world.story.flags.get("city_seen",{}).duplicate()
 for x in [-1,0,1]:
  for z in [-1,0,1]:
   var q=Vector2(p.x+x*CELL*.8,p.z+z*CELL*.8)
   if x!=0 or z!=0:
    var ray=PhysicsRayQueryParameters3D.create(p+Vector3.UP,Vector3(q.x,1,q.y),1)
    if not world.get_world_3d().direct_space_state.intersect_ray(ray).is_empty():continue
   records[key(q)]=true
 world.story.flags.city_seen=records
static func draw_map(v):
 var w=v.world
 var s=w.story
 var center=Vector2(w.player.position.x,w.player.position.z)
 v.drawing_scale=minf((v.size.x-28)/(52*1.72),(v.size.y-45)/(52*.90))
 v.origin=v.size*.5-Vector2((center.x-center.y)*.86,(center.x+center.y)*.45)*v.drawing_scale
 v.clip_contents=true
 for k in s.flags.get("city_seen",{}):
  var coords=k.split(",")
  if coords.size()!=2:continue
  var rect=Rect2(float(coords[0])*CELL,float(coords[1])*CELL,CELL,CELL)
  if rect.get_center().distance_to(center)<38:v.draw_colored_polygon(v.polygon(rect),Color("25312d"))
 var layout=s.Campaign.District.layout()
 for road in layout.roads:
  for i in road.points.size()-1:
   var a=Vector2(road.points[i][0],road.points[i][1])
   var b=Vector2(road.points[i+1][0],road.points[i+1][1])
   var count=ceili(a.distance_to(b)/3)
   for n in count:
    var p=a.lerp(b,float(n)/count)
    if p.distance_to(center)>32 or not known(s,p):continue
    var q=a.lerp(b,float(n+1)/count)
    v.draw_line(v.project(p),v.project(q),Color("bbb594"),maxf(.8,road.width*v.drawing_scale*.60),true)
 for parcel in layout.parcels:
  var b=parcel.building
  var p=Vector2(b[0],b[1])
  if p.distance_to(center)>32 or not known(s,p):continue
  var footprint=Rect2(p-Vector2(b[2],b[3])/2,Vector2(b[2],b[3]))
  v.draw_colored_polygon(v.polygon(footprint),Color("596859"))
 var rail_x:float=layout.railway.x
 for z in range(-100,100,4):
  var q=Vector2(rail_x,z)
  if q.distance_to(center)>34 or not known(s,q):continue
  for dx in [-.68,.68]:v.draw_line(v.project(q+Vector2(dx,0)),v.project(q+Vector2(dx,4)),Color("9c8c6e"),1.1,true)
  v.draw_line(v.project(q-Vector2(1.6,0)),v.project(q+Vector2(1.6,0)),Color("9c8c6e"),1,true)
 var scar=Ground.IMPACT_CENTER
 if known(s,scar) and scar.distance_to(center)<32:
  var fill=PackedVector2Array()
  for i in 20:
   var angle=TAU*i/20
   fill.append(v.project(scar+Vector2(cos(angle),sin(angle))*Ground.IMPACT_RADII))
  v.draw_colored_polygon(fill,Color("805946"))
 for item in layout.public_places+layout.entrances+layout.sites:
  var p=Vector2(item.point[0],item.point[1])
  if p.distance_to(center)>30 or not known(s,p):continue
  var contacts=s.Campaign.District.Contacts
  var id=contacts.GATES.find_key(item.id)
  if id==null or contacts.located(s,id):v.draw_circle(v.project(p),1.8,Color("b49c69"))
 var exit_info=load("res://scripts/raid_loot.gd").extraction(s)
 for entrance in layout.entrances:
  if entrance.id!=exit_info.get("id",""):continue
  var p=Vector2(entrance.point[0],entrance.point[1])
  if p.distance_to(center)>30:continue
  var at=v.project(p)
  var mark=Color("b8d8af")
  v.draw_arc(at,8,0,TAU,24,mark,2,true)
  v.draw_colored_polygon(PackedVector2Array([at+Vector2(-3,-4),at+Vector2(5,0),at+Vector2(-3,4)]),mark)
 var task=w.hud.Journal.active(s)
 var goal:Vector3=load("res://scripts/field_guide.gd").point(w,task)
 if goal.is_finite():
  var q=Vector2(goal.x,goal.z)
  if known(s,q) and q.distance_to(center)<30:
   v.draw_arc(v.project(q),7,0,TAU,24,Color("e0c48b"),2,true)
   v.draw_circle(v.project(q),2,Color("e0c48b"))
 var waypoint=s.flags.get("city_waypoint",[])
 if waypoint.size()==2:
  var p=Vector2(waypoint[0],waypoint[1])
  if p.distance_to(center)<30:
   var at=v.project(p)
   v.draw_line(at-Vector2(5,5),at+Vector2(5,5),Color("8dc9ce"),2,true)
   v.draw_line(at-Vector2(-5,5),at+Vector2(-5,5),Color("8dc9ce"),2,true)
 v.draw_circle(v.project(center),3,Color("f2d392"))
 v.draw_arc(v.project(center),6,0,TAU,24,Color("b49c69"),1,true)
