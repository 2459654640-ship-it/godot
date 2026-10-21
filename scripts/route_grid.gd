extends RefCounted
## Conservative 0.5m navigation for the existing CharacterBody3D controllers.
## Navigation never moves a body directly; every step still uses physics.
var graph=AStar2D.new()
var cells:Dictionary={}
var points:Dictionary={}
const STEP=0.5
const CLEARANCE=0.32

func setup(world):
	graph.clear();cells.clear();points.clear()
	var regions:Array=[]
	var bounds:Rect2=world.zones[0].rect
	for zone in world.zones:
		regions.append(zone.rect)
		bounds=bounds.merge(zone.rect)
	var obstacles:Array=[]
	for solid in world.kit.solids:
		if solid.name=="CampaignInnerGate" and world.story.f(world.campaign_gate_flag):continue
		if solid.top>0.24 and solid.bottom<1.75:
			var rect:Rect2=solid.rect
			if solid.name=="MineEscapeGrille" and world.story.f("rescue_route_ready"):rect.position.x+=2.8
			obstacles.append(rect.grow(CLEARANCE))
	var index=0
	for x in range(floori(bounds.position.x/STEP),ceili(bounds.end.x/STEP)+1):
		for z in range(floori(bounds.position.y/STEP),ceili(bounds.end.y/STEP)+1):
			var p=Vector2(x*STEP,z*STEP)
			var valid=true
			for offset in [Vector2(-CLEARANCE,0),Vector2(CLEARANCE,0),Vector2(0,-CLEARANCE),Vector2(0,CLEARANCE)]:
				var on_floor=false
				for region in regions:
					if region.has_point(p+offset):on_floor=true;break
				if not on_floor:valid=false;break
			if not valid:continue
			for rect in obstacles:
				if rect.has_point(p):valid=false;break
			if not valid:continue
			var key=Vector2i(x,z)
			cells[key]=index
			points[index]=p
			graph.add_point(index,p)
			index+=1
	for cell in cells:
		for offset in [Vector2i(1,0),Vector2i(0,1),Vector2i(1,1),Vector2i(1,-1)]:
			var neighbour=cell+offset
			if not cells.has(neighbour):continue
			if offset.x!=0 and offset.y!=0:
				if not cells.has(cell+Vector2i(offset.x,0)) or not cells.has(cell+Vector2i(0,offset.y)):continue
			graph.connect_points(cells[cell],cells[neighbour])

func path(start:Vector3,end:Vector3) -> PackedVector3Array:
	var out=PackedVector3Array()
	if graph.get_point_count()==0:return out
	var from=graph.get_closest_point(Vector2(start.x,start.z))
	var to=graph.get_closest_point(Vector2(end.x,end.z))
	for p in graph.get_point_path(from,to):out.append(Vector3(p.x,0,p.y))
	if not out.is_empty() and out[0].distance_to(Vector3(start.x,0,start.z))<0.25:out.remove_at(0)
	return out
