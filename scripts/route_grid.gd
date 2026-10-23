extends RefCounted
## Conservative 0.5m navigation for the existing CharacterBody3D controllers.
## Navigation never moves a body directly; every step still uses physics.
var graph=AStar2D.new()
var cells:Dictionary={}
var points:Dictionary={}
var revision=0
var STEP=0.5
const CLEARANCE=0.32

func setup(world,minimum_obstacle_height:float=0.24):
	revision+=1
	STEP=1.0 if world.floor_id=="east_district" else .5
	graph.clear();cells.clear();points.clear()
	var regions:Array=[]
	var bounds:Rect2=world.zones[0].rect
	for zone in world.zones:
		regions.append(zone.rect)
		bounds=bounds.merge(zone.rect)
	var obstacles:Array=[]
	for solid in world.kit.solids:
		if solid.name=="CampaignInnerGate" and world.story.f(world.campaign_gate_flag):continue
		if solid.top>minimum_obstacle_height and solid.bottom<1.75:
			var rect:Rect2=solid.rect
			if solid.name=="MineEscapeGrille" and world.story.f("rescue_route_ready"):rect.position.x+=2.8
			obstacles.append(rect.grow(CLEARANCE))
	# Spatial buckets keep the district's wider ground from multiplying every
	# grid point by every facade, kerb and piece of furniture.
	var buckets:Dictionary={}
	for rect in obstacles:
		for bx in range(floori(rect.position.x/4),floori(rect.end.x/4)+1):
			for bz in range(floori(rect.position.y/4),floori(rect.end.y/4)+1):
				var bucket=Vector2i(bx,bz)
				if not buckets.has(bucket):buckets[bucket]=[]
				buckets[bucket].append(rect)
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
			for rect in buckets.get(Vector2i(floori(p.x/4),floori(p.y/4)),[]):
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

func path_avoiding(start:Vector3,end:Vector3,bodies:Array,traveller)->PackedVector3Array:
	# Temporary occupancy is local to this query. Restore every graph node even
	# when there is no route, so one character never corrupts another's grid.
	var disabled:Dictionary={}
	for body in bodies:
		if not is_instance_valid(body) or body==traveller or body.collision_layer==0:continue
		var centre=Vector2(body.position.x,body.position.z)
		var cell=Vector2i(roundi(centre.x/STEP),roundi(centre.y/STEP))
		for dx in range(-2,3):
			for dz in range(-2,3):
				var key=cell+Vector2i(dx,dz)
				if cells.has(key) and points[cells[key]].distance_to(centre)<.70 and points[cells[key]].distance_to(Vector2(start.x,start.z))>.25:
					var id=cells[key]
					if not graph.is_point_disabled(id):graph.set_point_disabled(id,true);disabled[id]=true
	var route=path(start,end)
	for id in disabled:graph.set_point_disabled(id,false)
	return route
