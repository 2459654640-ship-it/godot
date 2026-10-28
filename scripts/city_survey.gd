extends Node
## Persistent discoveries. Unknown cells and actors never appear on the street map.
const CELL=12.0
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
static func known_zone(s,z:Dictionary)->bool:
 if z.code=="00":return false
 var r:Rect2=z.rect
 for x in range(floori(r.position.x/CELL),ceili(r.end.x/CELL)):
  for y in range(floori(r.position.y/CELL),ceili(r.end.y/CELL)):
   if s.flags.get("city_seen",{}).has("%d,%d"%[x,y]):return true
 return false
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
 var w=v.world;var s=w.story;var local=w.floor_id=="east_district";var center=Vector2(w.player.position.x,w.player.position.z) if local and not v.expanded else Vector2.ZERO
 var extent=Vector2(240,200) if v.expanded else Vector2(52,52)
 v.drawing_scale=minf((v.size.x-50)/extent.x,(v.size.y-80)/extent.y) if v.expanded else minf((v.size.x-28)/(extent.x*1.72),(v.size.y-45)/(extent.y*.90))
 v.origin=v.size*.5-Vector2((center.x-center.y)*.86,(center.x+center.y)*.45)*v.drawing_scale
 if v.expanded:v.drawing_scale*=v.map_zoom;v.origin+=v.map_pan
 v.clip_contents=true
 var records:Dictionary=s.flags.get("city_seen",{})
 if v.expanded:
  v.draw_colored_polygon(v.polygon(Rect2(-120,-100,240,200)),Color("1d2a28"))
  for x in range(-120,121,24):v.draw_line(v.project(Vector2(x,-100)),v.project(Vector2(x,100)),Color("34423c"),1,true)
  for z in range(-100,101,24):v.draw_line(v.project(Vector2(-120,z)),v.project(Vector2(120,z)),Color("34423c"),1,true)
 for k in records:
  var a=k.split(",");if a.size()!=2:continue
  var r=Rect2(float(a[0])*CELL,float(a[1])*CELL,CELL,CELL)
  if not v.expanded and r.get_center().distance_to(center)>38:continue
  v.draw_colored_polygon(v.polygon(r),Color("25312d"))
 var layout=s.Campaign.District.layout()
 for road in layout.roads:
  for i in road.points.size()-1:
   var a=Vector2(road.points[i][0],road.points[i][1]);var b=Vector2(road.points[i+1][0],road.points[i+1][1]);var count=ceili(a.distance_to(b)/3)
   for n in count:
    var p=a.lerp(b,float(n)/count);var q=a.lerp(b,float(n+1)/count)
    if v.expanded and not Rect2(-120,-100,240,200).has_point(p):continue
    if not v.expanded and p.distance_to(center)>32:continue
    var seen=known(s,p)
    if seen or v.expanded:v.draw_line(v.project(p),v.project(q),Color("c6bc97") if seen else Color("56625b"),maxf(1,road.width*v.drawing_scale*.6),true)
 for parcel in layout.parcels:
  var b=parcel.building;var p=Vector2(b[0],b[1]);var r=Rect2(p-Vector2(b[2],b[3])/2,Vector2(b[2],b[3]))
  if not v.expanded and (not known(s,p) or p.distance_to(center)>32):continue
  var polygon=v.polygon(r);v.draw_colored_polygon(polygon,Color("596859") if known(s,p) else Color("303d38"))
 var label_rects:Array[Rect2]=[]
 for e in layout.entrances+layout.sites:
  var p=Vector2(e.point[0],e.point[1])
  if not known(s,p) or (not v.expanded and p.distance_to(center)>30):continue
  v.draw_circle(v.project(p),2.8 if v.expanded else 1.8,Color("b49c69"))
  if v.expanded:
   var caption=String(e.get("name",e.id));var label_at=v.project(p)+Vector2(7,-6)
   var area=Rect2(label_at-Vector2(0,14),Vector2(mini(caption.length(),14)*13,18))
   if not label_rects.any(func(r):return r.intersects(area)):
    v.draw_string(w.kit.font,label_at,caption,HORIZONTAL_ALIGNMENT_LEFT,180,13,Color("e1d7ba"));label_rects.append(area)
 var quest=w.hud.Journal.active(s)
 if not quest.is_empty() and quest.place=="east_district":
  for e in layout.entrances+layout.sites:
   if e.id!=quest.target:continue
   var q=Vector2(e.point[0],e.point[1])
   if v.expanded or (known(s,q) and q.distance_to(center)<30):
    v.draw_arc(v.project(q),6,0,TAU,20,Color("e0c48b"),2,true)
    if v.expanded:v.draw_string(w.kit.font,v.project(q)+Vector2(9,19),"当前目标" if known(s,q) else "任务指向此处 · 尚未踏查",HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("f2d392"))
 var waypoint=s.flags.get("city_waypoint",[])
 if waypoint.size()==2:
  var q=Vector2(waypoint[0],waypoint[1])
  if v.expanded or q.distance_to(center)<30:
   var at=v.project(q);v.draw_line(at-Vector2(6,6),at+Vector2(6,6),Color("8dc9ce"),2,true);v.draw_line(at-Vector2(-6,6),at+Vector2(-6,6),Color("8dc9ce"),2,true)
   if v.expanded:v.draw_string(w.kit.font,at+Vector2(10,-7),"标记 · %d m"%roundi(q.distance_to(Vector2(w.player.position.x,w.player.position.z))) if local else "标记",HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("8dc9ce"))
 if local:
  var p=v.project(Vector2(w.player.position.x,w.player.position.z));v.draw_circle(p,3,Color("f2d392"));v.draw_arc(p,7,0,TAU,24,Color("b49c69"),1,true)
 if v.expanded:
  v.draw_string(w.kit.font,Vector2(12,24),"东郊街区 · 探索记录",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("c7aa70"))
  v.draw_string(w.kit.font,Vector2(v.size.x-100,24),"北 ↑",HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("d2c7a6"))
  v.draw_string(w.kit.font,Vector2(12,v.size.y-8),"浅色：已踏查  ·  暗色：待探索  ·  金点：发现的入口或设施",HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("bac4ab"))
