extends RefCounted
## Build every shared wall once; authored openings use their actual axis.
static func build(w,plan:Dictionary,zones:Array):
	var k=w.kit
	var edges={}
	for index in zones.size():
		var r:Rect2=zones[index].rect
		var material="wood" if w.floor_id in ["commune","sech"] else "concrete"
		k.box("Foundation",Vector3(r.get_center().x,-.3,r.get_center().y),Vector3(r.size.x,.5,r.size.y),"concrete")
		k.box("FloorCollision",Vector3(r.get_center().x,-.1,r.get_center().y),Vector3(r.size.x,.2,r.size.y),material,true).visible=false
		var floor=k.box("Floor_"+str(index),Vector3(r.get_center().x,.009,r.get_center().y),Vector3(r.size.x-.02,.018,r.size.y-.02),material)
		floor.material_override=floor.material_override.duplicate();floor.material_override.albedo_color=Color(plan.palette)
		for z in [int(r.position.y),int(r.end.y)]:
			for x in range(int(r.position.x),int(r.end.x)):edge(edges,"z",z,x,index)
		for x in [int(r.position.x),int(r.end.x)]:
			for z in range(int(r.position.y),int(r.end.y)):edge(edges,"x",x,z,index)
	var lines={}
	for key in edges:
		var e:Dictionary=edges[key]
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
	for d in plan.doors:
		k.doorway(d[0],d[1],d[2]=="x")
	k.finish_walls()
static func edge(edges:Dictionary,axis:String,fixed:int,start:int,owner:int):
	var key=axis+":"+str(fixed)+":"+str(start)
	if not edges.has(key):edges[key]={"axis":axis,"fixed":fixed,"start":start,"owners":[]}
	edges[key].owners.append(owner)
static func wall_with_doors(k,plan:Dictionary,line:Dictionary,start:float,end:float):
	var spans=[Vector2(start,end)]
	for d in plan.doors:
		if d[2]!=line.axis:continue
		var fixed:float=d[0] if d[2]=="x" else d[1]
		if not is_equal_approx(fixed,line.fixed):continue
		var middle:float=d[1] if d[2]=="x" else d[0]
		var updated=[]
		for span in spans:
			if middle+1.1<=span.x or middle-1.1>=span.y:updated.append(span);continue
			if middle-1.1>span.x:updated.append(Vector2(span.x,middle-1.1))
			if middle+1.1<span.y:updated.append(Vector2(middle+1.1,span.y))
		spans=updated
	for span in spans:
		if span.y-span.x<.05:continue
		var a=Vector2(line.fixed,span.x) if line.axis=="x" else Vector2(span.x,line.fixed)
		var b=Vector2(line.fixed,span.y) if line.axis=="x" else Vector2(span.y,line.fixed)
		k.wall("FacilityWall",a,b,true)
