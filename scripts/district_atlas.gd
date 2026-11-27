extends RefCounted
## The paper chart and the field scene share surveyed positions and road geometry.
const Survey=preload("res://scripts/city_survey.gd")
const Contacts=preload("res://scripts/faction_contacts.gd")
const Guide=preload("res://scripts/field_guide.gd")
const Raid=preload("res://scripts/raid_loot.gd")
const Ground=preload("res://scripts/city_ground.gd")
const Architecture=preload("res://scripts/city_architecture.gd")
const STOCK=Color("e4dac0")
const INK=Color("243b38")
const FAINT=Color("626a58")
const LINE=Color("b8af95")
const TRAVEL=Color("2c675a")
const TASK=Color("9b432f")
const PIN=Color("356776")
const BOUNDS=Ground.GROUND_BOUNDS
const SIGNS={
 "east_pump_entry":["旧泵站","检修梯通向排水阀和旧沉淀池。原路可回东郊。"],
 "east_waterworks_entry":["水处理厂","从装卸院进入。厂区入口与旧泵站是两条路。"],
 "east_transfer_entry":["旧联络线","沿路下到旧换乘站。需要有任务接应。"],
 "east_north_entry":["北线接送站","司机按已核实的外勤班次接送。"],
 "east_mine_entry":["矿区检修口","内部接应确认后可使用。公开返站请走南侧登记口。"],
 "late_junction_entry":["换乘线检修梯","当前任务的接应在地表下面，入口在货场西侧的梯道。"],
 "city_clinic":["旧诊所","西侧街区的一层诊所。可以从候诊室和治疗间搜寻物资。"],
 "city_radio_log":["民防通信站","从北段支路进站，可以查值班记录和通信机架。"],
 "city_basin_controls":["蓄水池","控制台在西侧检修口。进入下池前先检查排水。"],
 "grey_shelter_entry":["灰狗避难所","岗哨后方的棚屋通往地下。从西侧围栏缺口可以绕开主门。"],
 "east_relay":["变配电所","检修柜影响货场通道和外勤线路。"],
 "east_gate":["货场横穿门","断电会卡住横穿门。从东侧可操作应急释放柄。"]}

static func point(value:Array)->Vector2:return Vector2(value[0],value[1])

static func features(w,task:Dictionary)->Dictionary:
 var s=w.story
 var layout:Dictionary=s.Campaign.District.layout()
 var here:bool=w.floor_id=="east_district"
 var found={}
 for item in layout.entrances+layout.public_places+layout.sites:
  var id:String=item.id
  var p=point(item.point)
  var faction=Contacts.GATES.find_key(id)
  if faction!=null:
   if not Contacts.located(s,faction):continue
   var state=Contacts.status(s,faction)
   found[id]={"p":p,"name":Contacts.NAMES[faction],"kind":"contact" if Contacts.can_enter(s,faction) else "closed","status":state.state,"note":state.detail,"floor":item.destination}
   continue
  if not Survey.known(s,p) or (not SIGNS.has(id) and not layout.public_places.has(item)):continue
  var row: Array=SIGNS.get(id,[item.name,"已经踏查，可以在图上标记这个地点。"])
  found[id]={"p":p,"name":row[0],"kind":"place","status":"已踏查","note":row[1],"floor":item.get("destination","")}
 if found.has("east_north_entry") and s.f("star_known"):
  var ready=s.Campaign.Complete.allowed(s,"east_take_north")
  found.east_north_entry.note="北线通往星城外围。"+("可以按接送安排前往。" if ready and s.f("east_power_restored") else ("可以使用步行检修通路。" if ready else "先完成技术联络与担保。"))
 if found.has("east_gate"):
  found.east_gate.status="已开启" if s.f("east_crossing_open") else "当前关闭"
  found.east_gate.kind="place" if s.f("east_crossing_open") else "closed"
 for id in ["grey_shelter_entry","late_junction_entry"]:
  var p=Vector2(42,-11.8) if id=="grey_shelter_entry" else Vector2(53,25.5)
  if here and w.targets.has(id):p=Vector2(w.targets[id].pos.x,w.targets[id].pos.z)
  if Survey.known(s,p) and (id=="grey_shelter_entry" or (here and w.targets.has(id))):
   found[id]={"p":p,"name":SIGNS[id][0],"kind":"place","status":"已踏查","note":SIGNS[id][1]}
 if task.get("place","")=="east_district":
  var p3:Vector3=Guide.point(w,task) if here else Vector3.INF
  var target:String=task.target
  var entry:Dictionary=found.get(target,{})
  if entry.is_empty():
   for item in layout.entrances+layout.sites:
    if item.id==target:entry={"p":point(item.point)};break
  if p3.is_finite() or entry.has("p"):
   var p=Vector2(p3.x,p3.z) if p3.is_finite() else Vector2(entry.p)
   found["objective"]={"p":p,"name":task.name,"kind":"task","status":"当前这一步" if Survey.known(s,p) else "任务给出的位置","note":task.step}
 var exit_info=Raid.extraction(s)
 if not exit_info.is_empty():
  for item in layout.entrances:
   if item.id!=exit_info.id:continue
   found["extraction"]={"p":point(item.point),"name":"撤离 · "+exit_info.name,"kind":"exit","status":"本次撤离口","note":"从这里入站会结算出勤和携带的物资。"}
 if here:
  var pos=w.player.position
  found["player"]={"p":Vector2(pos.x,pos.z),"name":"伊万","kind":"player","status":"当前位置","note":"箭头表示你当前面向的方向。"}
 var waypoint:Array=s.flags.get("city_waypoint",[])
 if waypoint.size()==2:found["waypoint"]={"p":point(waypoint),"name":"自定标记","kind":"pin","status":"路线备忘","note":"回到地表后，小地图也会显示附近的自定标记。"}
 return found

static func paper(v,title:String,subtitle:String):
 var rect=Rect2(Vector2.ZERO,v.size)
 v.draw_rect(rect,STOCK)
 v.draw_rect(rect.grow(-2),Color("94866c"),false,1)
 v.draw_rect(rect.grow(-7),Color("c2b295"),false,1)
 for y in range(9,int(v.size.y)-8,5):
  v.draw_line(Vector2(9,y),Vector2(v.size.x-9,y),Color(.32,.27,.19,.022+.008*sin(y*1.47)),1)
 heading(v,title,subtitle)

static func heading(v,title:String,subtitle:String):
 var font=v.world.kit.font
 v.draw_string(font,Vector2(26,31),title,HORIZONTAL_ALIGNMENT_LEFT,-1,22,INK)
 v.draw_string(font,Vector2(27,50),subtitle,HORIZONTAL_ALIGNMENT_LEFT,-1,12,FAINT)
 v.draw_line(Vector2(24,62),Vector2(v.size.x-24,62),LINE,1)

static func frame(v)->Rect2:return Rect2(Vector2(35,78),v.size-Vector2(70,127))

static func trimmed(a:Vector2,b:Vector2)->PackedVector2Array:
 var low=0.0
 var high=1.0
 var delta=b-a
 for axis in [0,1]:
  if absf(delta[axis])<.001:
   if a[axis]<BOUNDS.position[axis] or a[axis]>BOUNDS.end[axis]:return []
   continue
  var start=(BOUNDS.position[axis]-a[axis])/delta[axis]
  var end=(BOUNDS.end[axis]-a[axis])/delta[axis]
  low=maxf(low,minf(start,end));high=minf(high,maxf(start,end))
 if low>high:return []
 return PackedVector2Array([a+delta*low,a+delta*high])

static func draw_roads(v,layout):
 for layer in [0,1]:
  for road in layout.roads:
   var primary:bool=road.get("class","")=="arterial"
   for i in road.points.size()-1:
    var span=trimmed(point(road.points[i]),point(road.points[i+1]))
    if span.is_empty():continue
    var color=Color("969989") if primary else Color("adab96")
    if layer==1:color=Color("f2e5c8") if primary else Color("e4dbc0")
    v.draw_line(v.project(span[0]),v.project(span[1]),color,maxf(1.35,v.drawing_scale*float(road.width)*.62+(1.25 if layer==0 else -.1)),true)

static func compass(v,pos:Vector2):
 v.draw_arc(pos,17,0,TAU,32,INK,1,true)
 v.draw_colored_polygon(PackedVector2Array([pos+Vector2(0,-20),pos+Vector2(-5,6),pos,pos+Vector2(5,6)]),INK)
 v.draw_line(pos,pos+Vector2(0,10),INK,1,true)
 v.draw_string(v.world.kit.font,pos+Vector2(-5,-25),"北",HORIZONTAL_ALIGNMENT_LEFT,-1,12,INK)

static func scale(v,pos:Vector2,metres:int):
 var span=float(metres)*v.drawing_scale
 v.draw_rect(Rect2(pos,Vector2(span,4)),INK,false,1)
 v.draw_rect(Rect2(pos,Vector2(span/2,4)),INK)
 v.draw_string(v.world.kit.font,pos+Vector2(0,-5),"%d m"%metres,HORIZONTAL_ALIGNMENT_LEFT,-1,12,INK)

static func marker(v,at:Vector2,kind:String,highlighted:bool):
 var color:Color={"task":TASK,"closed":FAINT,"exit":TRAVEL,"pin":PIN,"player":INK}.get(kind,TRAVEL if kind=="contact" else INK)
 var radius=9.0 if kind in ["task","exit","player"] else 6.5
 if highlighted:v.draw_circle(at,radius+6,Color(color,.23))
 v.draw_circle(at,radius+1,STOCK)
 if kind=="task":
  v.draw_arc(at,9,0,TAU,28,color,2.1,true);v.draw_circle(at,3,color);return
 if kind=="pin":
  v.draw_line(at-Vector2(5,5),at+Vector2(5,5),color,2,true)
  v.draw_line(at-Vector2(5,-5),at+Vector2(5,-5),color,2,true);return
 if kind=="player":
  var facing:Vector3=-v.world.player.visual.global_basis.z
  var dir=Vector2(facing.x,facing.z).normalized()
  if dir.is_zero_approx():dir=Vector2.UP
  var side=dir.orthogonal()
  v.draw_colored_polygon(PackedVector2Array([at+dir*8,at-dir*5+side*4,at-dir*2,at-dir*5-side*4]),color);return
 if kind in ["closed","contact"]:
  var box=Rect2(at-Vector2(5,5),Vector2(10,10))
  v.draw_rect(box,color,kind=="contact",1.7)
  if kind=="closed":v.draw_line(at+Vector2(-3,3),at+Vector2(3,-3),color,1.4,true)
  return
 v.draw_circle(at,radius,color)
 if kind=="exit":v.draw_colored_polygon(PackedVector2Array([at+Vector2(5,0),at+Vector2(-3,-4),at+Vector2(-3,4)]),STOCK)
 else:v.draw_circle(at,2,STOCK)

static func caption(v,at:Vector2,name:String,occupied:Array[Rect2],view:Rect2,kind:String):
 var font=v.world.kit.font
 var font_size=16 if kind in ["task","exit"] else 13
 var color=TASK if kind=="task" else (TRAVEL if kind=="exit" else INK)
 var width=font.get_string_size(name,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x
 for offset in [Vector2(11,-9),Vector2(11,16),Vector2(-width-12,-9),Vector2(-width-12,16)]:
  var pen=at+offset
  var area=Rect2(pen-Vector2(4,font_size),Vector2(width+8,font_size+6))
  if not view.encloses(area) or occupied.any(func(r):return r.intersects(area)):continue
  v.draw_rect(area,Color(STOCK,.94))
  v.draw_string(font,pen,name,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,color)
  occupied.append(area)
  return

static func draw(v):
 var w=v.world
 var s=w.story
 var layout:Dictionary=s.Campaign.District.layout()
 var plot=frame(v)
 v.drawing_scale=maxf(.1,minf(plot.size.x/BOUNDS.size.x,plot.size.y/BOUNDS.size.y))*v.map_zoom
 v.origin=plot.get_center()+v.map_pan
 v.clip_contents=true
 paper(v,"东郊工业片区","ВОСТОЧНЫЙ ПРОМЫШЛЕННЫЙ РАЙОН  /  北向街区图")
 var world_rect=Rect2(v.project(BOUNDS.position),BOUNDS.size*v.drawing_scale)
 v.draw_rect(world_rect,Color("d1c9ad"))
 for k in s.flags.get("city_seen",{}):
  var cell=String(k).split(",")
  if cell.size()!=2:continue
  var rect=Rect2(Vector2(float(cell[0]),float(cell[1]))*Survey.CELL,Vector2.ONE*Survey.CELL).intersection(BOUNDS)
  if rect.has_area():v.draw_rect(Rect2(v.project(rect.position),rect.size*v.drawing_scale),Color("efe2bf"))
 for x in range(-120,121,20):v.draw_line(v.project(Vector2(x,-100)),v.project(Vector2(x,100)),Color(LINE,.66),1,true)
 for z in range(-100,101,20):v.draw_line(v.project(Vector2(-120,z)),v.project(Vector2(120,z)),Color(LINE,.66),1,true)
 for parcel in layout.parcels:
  var b=parcel.building
  var p=Vector2(b[0],b[1])
  var extent=Vector2(b[2],b[3])
  var r=Rect2(v.project(p-extent/2),extent*v.drawing_scale)
  v.draw_rect(r,Color("939687") if Survey.known(s,p) else Color("b3b29f"))
  v.draw_rect(r,Color("7d8274") if Survey.known(s,p) else Color("a6a592"),false,1)
 for hull in [Architecture.PUMP_HALL,Architecture.BOILER_HOUSE]:
  var r=Rect2(v.project(hull.position),hull.size*v.drawing_scale)
  v.draw_rect(r,Color("a39b82"));v.draw_rect(r,Color("8c846f"),false,1)
 for basin in Architecture.CLARIFIERS:
  var p:Vector2=v.project(basin)
  var r=Architecture.CLARIFIER_RADIUS*v.drawing_scale
  v.draw_circle(p,r,Color("afb2a0"));v.draw_arc(p,r,0,TAU,24,Color("858f80"),1,true)
 draw_roads(v,layout)
 var rail:Dictionary=layout.railway
 var rx:float=rail.x
 for edge in [-.76,.76]:
  v.draw_line(v.project(Vector2(rx+edge,-100)),v.project(Vector2(rx+edge,100)),Color("685f4c"),1.2,true)
 for z in range(-100,101,3):v.draw_line(v.project(Vector2(rx-1.45,z)),v.project(Vector2(rx+1.45,z)),Color("685f4c"),1,true)
 var impact=Ground.IMPACT_CENTER
 if Survey.known(s,impact):
  var rim=PackedVector2Array()
  for i in 25:
   var angle=TAU*float(i)/24
   rim.append(v.project(impact+Vector2(cos(angle),sin(angle))*Ground.IMPACT_RADII))
  v.draw_colored_polygon(rim,Color("bb8f71"));v.draw_polyline(rim,Color("9b7057"),1.4,true)
 v.draw_rect(world_rect,FAINT,false,1.2)
 var view=plot.grow(8).intersection(world_rect.grow(23))
 var font=w.kit.font
 for entry in [["旧货运路",Vector2(-84,10)],["住宅南街",Vector2(-45,63)],["厂区支路",Vector2(-72,-78)],["北货运线",Vector2(27,-78)],["工人街",Vector2(-10,78)]]:
  var at:Vector2=v.project(entry[1])
  if view.has_point(at):v.draw_string(font,at,entry[0],HORIZONTAL_ALIGNMENT_LEFT,-1,12,FAINT)
 v.map_points=features(w,v.map_task())
 var occupied:Array[Rect2]=[]
 var ids=v.map_points.keys()
 ids.reverse()
 for id in ids:
  var item:Dictionary=v.map_points[id]
  var at:Vector2=v.project(item.p)
  if view.has_point(at):occupied.append(Rect2(at-Vector2(7,7),Vector2(14,14)))
 for id in ids:
  var item:Dictionary=v.map_points[id]
  var at:Vector2=v.project(item.p)
  if not view.has_point(at):continue
  if item.kind in ["player","pin"]:continue
  if item.kind not in ["task","exit"] and ["objective","extraction"].any(func(key):return v.map_points.has(key) and v.map_points[key].p.distance_to(item.p)<1.5):continue
  caption(v,at,item.name,occupied,view,item.kind)
 for id in v.map_points:
  var item:Dictionary=v.map_points[id]
  var at:Vector2=v.project(item.p)
  if view.has_point(at):marker(v,at,item.kind,v.map_selected==id or v.map_hover==id)
 # The locator and scale stay attached to the sheet when the drawing is moved.
 v.draw_rect(Rect2(9,9,v.size.x-18,55),STOCK)
 heading(v,"东郊工业片区","ВОСТОЧНЫЙ ПРОМЫШЛЕННЫЙ РАЙОН  /  北向街区图")
 v.draw_rect(Rect2(Vector2(9,v.size.y-41),Vector2(v.size.x-18,32)),STOCK)
 scale(v,Vector2(25,v.size.y-20),20)
 v.draw_string(font,Vector2(v.size.x-240,v.size.y-19),"浅色已踏查 · 暗色待探索",HORIZONTAL_ALIGNMENT_LEFT,-1,13,FAINT)
 compass(v,Vector2(v.size.x-42,40))
