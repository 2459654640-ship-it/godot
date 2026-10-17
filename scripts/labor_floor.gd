extends RefCounted
## Reused modular meshes and painted inhabitants; rooms remain physically built.
const ZONES=[
{"name":"作业层主道","code":"L0","rect":Rect2(-24,-1,50,5)},
{"name":"轮班工棚","code":"L1","rect":Rect2(-24,-13,10,12)},
{"name":"工具修配间","code":"L2","rect":Rect2(-14,-13,9,12)},
{"name":"医务间","code":"L3","rect":Rect2(-5,-13,10,12)},
{"name":"装备库","code":"L4","rect":Rect2(5,-13,10,12)},
{"name":"正门候车区","code":"L5","rect":Rect2(15,-13,11,12)},
{"name":"工人歇脚棚","code":"L6","rect":Rect2(-24,4,10,10)},
{"name":"征召集合区","code":"L7","rect":Rect2(-14,4,11,10)},
{"name":"煤运检票口","code":"L8","rect":Rect2(-3,4,12,10)},
{"name":"装卸与储运区","code":"L9","rect":Rect2(9,4,17,10)}]
const DOORS=[Vector2(-19,-1),Vector2(-9.5,-1),Vector2(0,-1),Vector2(10,-1),Vector2(20,-1),Vector2(-19,4),Vector2(-8.5,4),Vector2(3,4),Vector2(17,4)]
static func barrier(k,id:String,a:Vector2,b:Vector2,wood:bool=false):
	var length=a.distance_to(b)
	var size=Vector3(maxf(absf(a.x-b.x),.18),2.45,maxf(absf(a.y-b.y),.18))
	var center=Vector3((a.x+b.x)/2,1.225,(a.y+b.y)/2)
	var mesh=k.box(id,center,size,"wood" if wood else "rust",true)
	var material=ShaderMaterial.new()
	material.shader=load("res://assets/visual/masonry_veil.gdshader")
	material.set_shader_parameter("albedo_map",load("res://assets/visual/timber.png" if wood else "res://assets/visual/oxide.png"))
	material.set_shader_parameter("triplanar",true)
	material.set_shader_parameter("map_scale",Vector3.ONE*.65)
	material.set_shader_parameter("normal_strength",0.0)
	material.set_shader_parameter("base_color",Color("726b54") if wood else Color("82908a"))
	mesh.material_override=null
	mesh.mesh.material=material
	mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mesh.set_meta("foreground",id not in ["NorthSheet","GateRearLeft","GateRearRight","WestSheet"])
	k.scrap_meshes.append(mesh)
	k.veil_materials[mesh.get_instance_id()]=[]
	# Widely spaced ribs and posts are solids in the wall's own plane, never
	# little colliders sticking into the path. Their dressing fades with it.
	for i in range(ceili(length/.75)+1):
		var p=a.lerp(b,minf(1,float(i)*.75/maxf(length,.1)))
		var rib=k.box("SheetWallRib",Vector3(p.x,1.24,p.y),Vector3(.055,2.5,.23) if absf(a.x-b.x)>.1 else Vector3(.23,2.5,.055),"dark")
		var base=rib.material_override
		rib.material_override=k.veil_prop_material(base,mesh)

static func build(w):
	var k=w.kit
	k.box("Foundation",Vector3(1,-.30,.5),Vector3(51,.5,28),"concrete")
	k.box("FloorCollision",Vector3(1,-.1,.5),Vector3(50,.2,27),"tile",true).visible=false
	for zone in ZONES:
		var r:Rect2=zone.rect
		var material="concrete" if zone.code in ["L0","L3","L4","L5"] else "wood"
		k.box("Floor_"+zone.code,Vector3(r.get_center().x,.007,r.get_center().y),Vector3(r.size.x-.04,.014,r.size.y-.04),material)
	barrier(k,"NorthSheet",Vector2(-24,-13),Vector2(15,-13))
	# Actual sealed blast door: rails pass through a real aperture behind it.
	barrier(k,"GateRearLeft",Vector2(15,-13),Vector2(18,-13))
	barrier(k,"GateRearRight",Vector2(22,-13),Vector2(26,-13))
	k.box("D6BlastDoor",Vector3(20,1.75,-13),Vector3(4,3.5,.42),"metal",true)
	for x in [18.25,21.75]:k.box("BlastDoorTrack",Vector3(x,1.85,-12.73),Vector3(.18,3.7,.23),"dark")
	for y in [.5,1.6,2.7]:k.box("BlastDoorBrace",Vector3(20,y,-12.73),Vector3(3.5,.12,.15),"rust")
	k.cyl("BlastDoorWheel",Vector3(20,1.55,-12.56),.10,.12,"metal").rotation.x=PI/2
	k.label("Д–6 / ГЛАВНЫЙ ВХОД",Vector3(20,3.5,-12.5),34)
	barrier(k,"WestSheet",Vector2(-24,-13),Vector2(-24,14))
	barrier(k,"EastSheet",Vector2(26,-13),Vector2(26,14))
	barrier(k,"SouthSheet",Vector2(-24,14),Vector2(26,14),true)
	for x in [-14,-5,5,15]:
		if x in [-5,5,15]:k.wall("ConcreteServiceDivider",Vector2(x,-13),Vector2(x,-1),true)
		else:barrier(k,"WorkPartition",Vector2(x,-13),Vector2(x,-1))
	for x in [-14,-3,9]:barrier(k,"TimberPartition",Vector2(x,4),Vector2(x,14),true)
	for z in [-1,4]:
		var start=-24.0
		var doors=[-19,-9.5,0,10,20] if z==-1 else [-19,-8.5,3,17]
		for x in doors:
			barrier(k,"CorridorSheet",Vector2(start,z),Vector2(x-.86,z),z==4)
			k.doorway(x,z)
			start=x+.86
		barrier(k,"CorridorSheetEnd",Vector2(start,z),Vector2(26,z),z==4)
	k.finish_walls()
	# Work crews have bunks in shifts; repeated functional modules, varied uses.
	for x in [-22.4,-19.8,-17.2]:
		for z in [-10.9,-6.7]:w.Wing.bunk(k,Vector3(x,0,z))
	for x in [-22.4,-20.8,-19.2]:k.locker(Vector3(x,0,-2.7),1.65)
	k.table(Vector3(-9.7,0,-10.8),3.8)
	for p in [Vector3(-12,0,-6),Vector3(-7,0,-6)]:k.crate(p,Vector3(1.2,.75,.9))
	k.locker(Vector3(-12.6,0,-3),1.7)
	k.pipe(Vector3(-13.5,2.5,-11.5),Vector3(-5.5,2.5,-11.5),.1)
	for x in [-3,2.5]:k.bed(Vector3(x,0,-10.5),"paper")
	k.table(Vector3(0,0,-6.5),2.4)
	k.cyl("ClinicSteriliser",Vector3(.4,.95,-6.5),.24,.35,"metal")
	k.locker(Vector3(3.9,0,-8),1.8)
	k.box("MedicalCrossV",Vector3(.0,2,-12.8),Vector3(.11,.60,.05),"red")
	k.box("MedicalCrossH",Vector3(.0,2,-12.76),Vector3(.6,.11,.05),"red")
	for x in [6.3,7.3,8.3,9.3,10.3,11.3,12.3,13.3]:k.locker(Vector3(x,0,-11.8),1.9)
	k.table(Vector3(10,0,-6.5),3.4)
	k.box("ArmoryLedger",Vector3(10,.83,-6.5),Vector3(.45,.04,.32),"paper")
	for x in [6.7,13.3]:k.crate(Vector3(x,0,-8.6),Vector3(1.2,.9,1))
	# Embedded track and trolley: nothing at shoe height can snag a capsule.
	for x in [19.24,20.76]:k.box("MetroRail",Vector3(x,.03,-8),Vector3(.075,.06,10),"metal")
	for z in range(-12,-2):k.box("MetroSleeper",Vector3(20,.02,z),Vector3(2.5,.04,.17),"wood")
	k.box("RailTrolley",Vector3(20,.35,-7),Vector3(2.1,.55,3.0),"metal",true)
	k.bench(Vector3(20,.48,-7),1.6)
	for x in [19.15,20.85]:
		for z in [-8,-6]:k.cyl("TrolleyWheel",Vector3(x,.23,z),.23,.12,"dark").rotation.z=PI/2
	for z in [7,10.5]:k.table(Vector3(-19,0,z),3)
	for x in [-21,-17]:k.bench(Vector3(x,0,8.8),1.8)
	k.table(Vector3(-8.5,0,11.4),3.2)
	k.box("Roster",Vector3(-8.5,.83,11.4),Vector3(1.2,.025,.8),"paper")
	for x in [-12,-5]:k.bench(Vector3(x,0,8.0),2)
	# Mine gate is closed and reveals no future character identity.
	k.box("CoalGate",Vector3(3,1.2,13.75),Vector3(3,2.4,.25),"rust",true)
	k.label("УГОЛЬ / ПО ПРОПУСКАМ",Vector3(3,2.6,13.5),28).rotation.y=PI
	for x in [.5,5.5]:k.crate(Vector3(x,0,11),Vector3(1.2,1,1))
	for p in [Vector3(12,0,11.5),Vector3(15,0,11.5),Vector3(23,0,7),Vector3(23,0,11.5)]:k.crate(p,Vector3(1.5,1.2,1.3))
	for x in range(-21,26,6):
		k.pipe(Vector3(x,2.8,-.7),Vector3(x,2.8,3.7),.07)
		k.lamp(Vector3(x,2.4,-.82),x<0,1.9,6)
	for p in [Vector3(-19,2.3,-12.7),Vector3(-9.5,2.3,-12.7),Vector3(0,2.3,-12.7),Vector3(10,2.3,-12.7),Vector3(20,2.7,-12.5),Vector3(-19,2.3,4.2),Vector3(-8.5,2.3,4.2),Vector3(3,2.3,4.2),Vector3(17,2.3,4.2)]:k.lamp(p,p.x<0,2.3,8)
	k.signboard("МЕДПУНКТ",Vector3(0,2.3,-1.16),2.5)
	k.signboard("СНАРЯЖЕНИЕ",Vector3(10,2.3,-1.16),3)
	k.signboard("D–6 / ГЛАВНЫЙ ВХОД",Vector3(20,2.3,-1.16),3.8)
	k.signboard("ЖИЛОЙ ЯРУС / ↑",Vector3(-10,2.3,3.8),3.2)
	k.box("StairUpFrame",Vector3(-10,1.3,3.86),Vector3(2,2.6,.2),"dark")
	k.label("↑ 生活层",Vector3(-10,2.2,3.68),30).rotation.y=PI
	k.box("LaborNotice",Vector3(-7,1.5,3.8),Vector3(1.4,1,.1),"wood")

	preload("res://scripts/labor_dressing.gd").build(w)

static func people(w):
	w.person("commander",Vector3(-8.5,0,9.5),"green",true)
	w.person("armorer",Vector3(10,0,-8.0),"green",true,"queue")
	w.person("main_guard",Vector3(17.8,0,-10),"green",true,"commander")
	w.person("gate_soldier",Vector3(23.8,0,-10.2),"green",true,"igor")
	var crew=[Vector3(-20,0,-4),Vector3(-17,0,-4),Vector3(-10,0,-8),Vector3(-19,0,6),Vector3(-21,0,11),Vector3(1,0,9),Vector3(6.3,0,9),Vector3(12,0,7),Vector3(22,0,10),Vector3(16.8,0,-3.5)]
	for i in crew.size():w.person("worker_%02d"%i,crew[i],"wood",true,["resident","mikhail","queue","diner"][i%4])
static func routines(w):
	for id in w.npcs:
		var a=w.npcs[id];a.navigation=w.navigation
		var goal=a.anchor+Vector3(0,0,1.2)
		var route=w.navigation.path(a.anchor,goal)
		if not route.is_empty() and route[-1].distance_to(goal)<.6:a.patrol.assign([a.anchor,goal])
static func targets(w):
	w.target("commander",w.npcs.commander.position,"科瓦廖夫","talk")
	w.target("armory",Vector3(10,0,-5.4),"装备库值班台","talk")
	w.target("main_gate",Vector3(17.8,0,-9.4),"D-6 正门卫兵","talk")
	w.target("medical",Vector3(0,0,-5.3),"医务间")
	w.target("coal_door",Vector3(3,0,12),"煤运检票口")
	w.target("labor_notice",Vector3(-7,0,2.8),"作业层值班板")
	w.target("stairs_up",Vector3(-10,0,2.8),"楼梯 / 生活层")
