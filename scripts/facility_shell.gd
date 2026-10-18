extends RefCounted
## Build every shared wall once; authored openings use their actual axis.
static func build(w,plan:Dictionary,zones:Array):
	var k=w.kit
	var star=preload("res://scripts/starcity_v17.gd")
	if w.floor_id=="starcity":star.prepare(k,zones)
	if w.floor_id=="commune":preload("res://scripts/commune_finishes.gd").prepare(k,zones)
	if w.floor_id=="waterworks":preload("res://scripts/factory_finishes.gd").prepare(k,zones)
	var edges={}
	for index in zones.size():
		var r:Rect2=zones[index].rect
		var material="wood" if w.floor_id=="sech" else ("terrazzo" if w.floor_id=="commune" else ("factory_floor" if w.floor_id=="waterworks" else "concrete"))
		if w.floor_id=="sech" and zones[index].code=="00":material="concrete"
		if w.floor_id=="commune" and zones[index].code in ["01","05"]:material="tile"
		if w.floor_id=="waterworks" and zones[index].code in ["05","06"]:material="tile"
		if w.floor_id=="coal" and zones[index].code in ["02","03"]:material="tile"
		if w.floor_id=="starcity" and zones[index].code=="03":material="tile"
		if w.floor_id=="starcity":material=star.floor_finish(zones[index].code)
		var tint=Color.WHITE if w.floor_id=="starcity" else Color(plan.palette)
		if w.floor_id=="commune":
			var finish=preload("res://scripts/commune_finishes.gd").floor_spec(zones[index].code);material=finish[0];tint=finish[1]
		if w.floor_id=="waterworks":material=preload("res://scripts/factory_finishes.gd").FLOOR[zones[index].code];tint=Color.WHITE
		if w.floor_id!="sech" or zones[index].code=="00":
			var foundation=k.box("Foundation",Vector3(r.get_center().x,-.3,r.get_center().y),Vector3(r.size.x,.5,r.size.y),"concrete")
			if w.floor_id=="starcity" and star.POLYGONS.has(zones[index].code):star.clip_foundation(foundation,star.POLYGONS[zones[index].code])
		k.box("FloorCollision",Vector3(r.get_center().x,-.1,r.get_center().y),Vector3(r.size.x,.2,r.size.y),material,true).visible=false
		var floor=k.box("Floor_"+str(index),Vector3(r.get_center().x,.009,r.get_center().y),Vector3(r.size.x-.02,.018,r.size.y-.02),material)
		floor.material_override=floor.material_override.duplicate()
		if floor.material_override is ShaderMaterial:floor.material_override.set_shader_parameter("base_color",tint)
		else:floor.material_override.albedo_color=tint
		if w.floor_id=="starcity" and star.POLYGONS.has(zones[index].code):star.clip_floor(floor,star.POLYGONS[zones[index].code])
		floor.set_meta("room_code",zones[index].code);floor.set_meta("floor_finish",material)
		for z in [int(r.position.y),int(r.end.y)]:
			for x in range(int(r.position.x),int(r.end.x)):edge(edges,"z",z,x,index)
		for x in [int(r.position.x),int(r.end.x)]:
			for z in range(int(r.position.y),int(r.end.y)):edge(edges,"x",x,z,index)
	var lines={}
	for key in edges:
		var e:Dictionary=edges[key]
		if w.floor_id=="starcity" and e.owners.any(func(owner):return star.POLYGONS.has(zones[owner].code)):continue
		if e.owners.size()==2 and zones[e.owners[0]].code=="00" and zones[e.owners[1]].code=="00":continue
		var line=e.axis+":"+str(e.fixed)
		if not lines.has(line):lines[line]={"axis":e.axis,"fixed":e.fixed,"units":[]}
		lines[line].units.append(e.start)
	for line in lines.values():
		line.units.sort()
		var start:float=line.units[0];var end=start+1
		for unit in line.units.slice(1):
			if unit==end:end+=1
			else:wall_with_doors(k,plan,line,start,end);start=unit;end=unit+1
		wall_with_doors(k,plan,line,start,end)
	if w.floor_id=="starcity":star.polygon_walls(k,plan)
	for d in plan.doors:
		if d.size()<4:k.doorway(d[0],d[1],d[2]=="x")
static func edge(edges:Dictionary,axis:String,fixed:int,start:int,owner:int):
	var key=axis+":"+str(fixed)+":"+str(start)
	if not edges.has(key):edges[key]={"axis":axis,"fixed":fixed,"start":start,"owners":[]}
	edges[key].owners.append(owner)
static func wall_with_doors(k,plan:Dictionary,line:Dictionary,start:float,end:float):
	for opening in plan.get("open_edges",[]):
		if line.axis==opening[0] and line.fixed==opening[1] and start>=opening[2] and end<=opening[3]:return
	var spans=[Vector2(start,end)]
	for d in plan.doors:
		if d[2]!=line.axis:continue
		var fixed:float=d[0] if d[2]=="x" else d[1]
		if not is_equal_approx(fixed,line.fixed):continue
		var middle:float=d[1] if d[2]=="x" else d[0]
		var half:float=d[3] if d.size()>3 else 1.1
		var updated=[]
		for span in spans:
			if middle+half<=span.x or middle-half>=span.y:updated.append(span);continue
			if middle-half>span.x:updated.append(Vector2(span.x,middle-half))
			if middle+half<span.y:updated.append(Vector2(middle+half,span.y))
		spans=updated
	for span in spans:
		if span.y-span.x<.05:continue
		var a=Vector2(line.fixed,span.x) if line.axis=="x" else Vector2(span.x,line.fixed)
		var b=Vector2(line.fixed,span.y) if line.axis=="x" else Vector2(span.y,line.fixed)
		k.wall("FacilityWall",a,b,true)
