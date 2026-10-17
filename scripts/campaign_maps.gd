extends RefCounted
## Interior-only facilities, measured in metres. Wide central circulation, authored rooms and reusable kit.
const Campaign=preload("res://scripts/campaign.gd")
const LAYOUTS={
"waterworks":{"half":18.0,"north":-12.0,"south":12.0,"cuts":[-6.0,5.0],"names":["西侧泵房","工具修配","封存仓库","交接档案室","送电控制室","入口气闸"],"spawn":Vector3(12,.04,6)},
"commune":{"half":20.0,"north":-12.0,"south":11.0,"cuts":[-5.0,7.0],"names":["地下温室","公用水井","联络档案室","公社议事处","医务与探访","联络气闸"],"spawn":Vector3(13,.04,6)},
"sech":{"half":17.0,"north":-10.0,"south":12.0,"cuts":[-5.0,5.0],"names":["旧军列调度","电台维修室","书籍与车厢","储水检修棚","营地议事桌","北线候车库"],"spawn":Vector3(11,.04,6)},
"coal":{"half":15.0,"north":-10.0,"south":10.0,"cuts":[-5.0,5.0],"names":["班组档案","医护值班","井下休养间","探访登记","接送准备间","探视出口"],"spawn":Vector3(-10,.04,6)},
"starcity":{"half":20.0,"north":-13.0,"south":11.0,"cuts":[-6.0,7.0],"names":["配电隔离室","旧转移档案","测控室","蓝门值班室","内门联锁台","远程通信室"],"spawn":Vector3(-13,.04,6)}}
# A target always sits in an open approach in front of its fixture, never inside its collider.
const OBJECTS={
"waterworks":[["plant_bypass",-12,-6,"valve"],["plant_bench",-1,-6,"bench"],["plant_store",11,-6,"store"],["plant_log",-12,6,"desk"],["plant_power",0,6,"panel"],["plant_diagram",8,6,"paper"],["plant_exit",15,6,"exit"]],
"commune":[["commune_greenhouse",-13,-6,"garden"],["commune_well",1,-6,"well"],["commune_records",13,-6,"desk"],["commune_leader",-13,6,"npc"],["commune_anna",1,6,"npc"],["commune_leave",14,6,"exit"]],
"sech":[["sech_manual",-11,-5,"desk"],["sech_radio",0,-5,"radio"],["sech_sergey",10,-5,"npc"],["sech_water",-11,6,"tank"],["sech_elder",0,6,"npc"],["sech_leave",11,6,"exit"]],
"coal":[["coal_archive",-10,-5,"desk"],["coal_medic",0,-5,"npc"],["coal_brother",10,-5,"npc"],["coal_clerk",-10,5,"npc"],["coal_exit",10,5,"exit"]],
"starcity":[["star_isolator",-13,-7,"panel"],["star_archive",0,-7,"desk"],["star_father",13,-7,"npc"],["star_manual",-16,6,"paper"],["star_guard",-11,6,"npc"],["star_bypass",0,6,"panel"],["star_radio",12,6,"radio"],["star_exit",17,6,"exit"]]}
static func rooms(id:String)->Array:
	var l:Dictionary=LAYOUTS[id];var edges=[-l.half,l.cuts[0],l.cuts[1],l.half];var out=[]
	for row in 2:
		for col in 3:
			out.append({"name":l.names[row*3+col],"code":"%02d"%(row*3+col+1),"rect":Rect2(edges[col],l.north if row==0 else 2,edges[col+1]-edges[col],-2-l.north if row==0 else l.south-2)})
	out.append({"name":"设施内联络通道","code":"00","rect":Rect2(-l.half,-2,l.half*2,4)})
	return out
static func doors(id:String)->Array:
	var out=[]
	for r in rooms(id):
		if r.code!="00":out.append(Vector2(r.rect.get_center().x,-2 if r.rect.position.y<0 else 2))
	return out
static func build(w):
	var k=w.kit;var id:String=w.floor_id;var l:Dictionary=LAYOUTS[id]
	var half:float=l.half
	k.box("Foundation",Vector3(0,-.3,(l.north+l.south)/2),Vector3(half*2+.5,.5,l.south-l.north+.5),"concrete")
	k.box("FloorCollision",Vector3(0,-.1,(l.north+l.south)/2),Vector3(half*2,.2,l.south-l.north),"concrete",true).visible=false
	for zone in rooms(id):
		var r:Rect2=zone.rect
		var material="wood" if id=="sech" or (id=="commune" and zone.code in ["04","05"]) else "concrete"
		if zone.code=="00":material="metal" if id=="starcity" else "concrete"
		var floor_mesh=k.box("Floor_"+zone.code,Vector3(r.get_center().x,.009,r.get_center().y),Vector3(r.size.x-.04,.018,r.size.y-.04),material)
		floor_mesh.material_override=floor_mesh.material_override.duplicate()
		floor_mesh.material_override.albedo_color=Color({"waterworks":"788880","commune":"b1aa8f","sech":"9e8f75","coal":"828579","starcity":"889b9b"}[id])
	k.wall("FacilityNorth",Vector2(-half,l.north),Vector2(half,l.north))
	k.wall("FacilityWest",Vector2(-half,l.north),Vector2(-half,l.south))
	k.wall("FacilityEast",Vector2(half,l.north),Vector2(half,l.south),true)
	k.wall("FacilitySouth",Vector2(-half,l.south),Vector2(half,l.south),true)
	for x in l.cuts:
		# Service loops connect related rooms; each facility has a different internal connection.
		var link_z:float={"waterworks":-7.5,"commune":-7.0,"sech":-5.0,"coal":-5.5,"starcity":-8.0}[id]
		var linked=(id in ["commune","sech"] or (id=="waterworks" and x==l.cuts[0]) or (id=="coal" and x==l.cuts[0]))
		if linked:
			k.wall("NorthServiceRear",Vector2(x,l.north),Vector2(x,link_z-1.1),true)
			k.doorway(x,link_z,true)
			k.wall("NorthServiceFront",Vector2(x,link_z+1.1),Vector2(x,-2),true)
		else:k.wall("NorthRoomDivider",Vector2(x,l.north),Vector2(x,-2),true)
		k.wall("SouthRoomDivider",Vector2(x,2),Vector2(x,l.south),true)
	for row in 2:
		var z=-2.0 if row==0 else 2.0;var edge=-half
		for col in 3:
			var r:Rect2=rooms(id)[row*3+col].rect;var x=r.get_center().x
			k.wall("CorridorPartition",Vector2(edge,z),Vector2(x-1.1,z),true)
			k.doorway(x,z)
			k.signboard(l.names[row*3+col],Vector3(x,2.35,z+(.16 if row==0 else -.16)),3.8)
			edge=x+1.1
		k.wall("CorridorEnd",Vector2(edge,z),Vector2(half,z),true)
	k.finish_walls()
	for x in range(-int(half)+2,int(half),6):
		k.lamp(Vector3(x,2.4,-1.8),id in ["commune","sech"],1.8,7)
		k.pipe(Vector3(x,2.7,l.north+.5),Vector3(x,2.7,l.south-.5),.065)
	for zone in rooms(id):
		if zone.code=="00":continue
		var r:Rect2=zone.rect;var p=Vector3(r.get_center().x,0,r.position.y+.8)
		k.lamp(p+Vector3(0,2.35,0),id in ["commune","sech"],2.2,9)
		k.crate(Vector3(r.position.x+1,0,r.position.y+1),Vector3(1.1,.75,.8))
		k.box("RoomNumber",p+Vector3(-1.2,1.7,0),Vector3(.35,.4,.035),"paper")
		k.label(zone.code,p+Vector3(-1.2,1.7,.035),22)
		# Per-room wear patches use a single material surface, no overlapping floor planes.
		k.locker(Vector3(r.end.x-1,0,r.position.y+1.2),1.7)
	for entry in OBJECTS[id]:furnish(k,entry,id)
	dress_facility(w)
	if id=="waterworks":
		w.campaign_gate_flag="plant_power"
		w.campaign_gate=k.box("CampaignInnerGate",Vector3(11.5,1.1,-2),Vector3(1.8,2.2,.18),"corrugated",true)
		for x in [-16,-9]:
			k.cyl("PumpHousing",Vector3(x,.65,-9),.7,1.3,"metal")
			k.pipe(Vector3(x,1.2,-9),Vector3(x,1.2,-11.5),.2,"rust")
		for x in [8,11,14,17]:k.crate(Vector3(x,0,-10),Vector3(1.4,1,1))
	if id=="commune":
		for x in [-17,-13,-9]:
			k.box("GreenhouseBed",Vector3(x,.35,-9),Vector3(2.4,.7,3.2),"wood",true)
			k.box("GardenSoil",Vector3(x,.72,-9),Vector3(2.2,.05,3),"dark")
			for z in [-10,-9,-8]:
				for dx in [-.6,.2]:k.ellipsoid("LeafCluster",Vector3(x+dx,.86,z),Vector3(.28,.17,.3),"green")
		for x in [-3.5,4.5]:k.bed(Vector3(x,0,8.5),"paper")
	if id=="sech":
		for x in [7.5,12.5]:
			w.Wing.bunk(k,Vector3(x,0,-8))
			k.bench(Vector3(x,0,9.5),2)
		for x in [9.8,11.2]:k.box("IndoorRail",Vector3(x,.025,9),Vector3(.08,.05,5),"metal")
	if id=="coal":
		for x in [7,12.5]:k.bed(Vector3(x,0,-7.7),"paper")
		k.table(Vector3(0,0,7),3)
	if id=="starcity":
		# Readable interlock: collision and visual door disappear together only after the puzzle.
		var gate=k.box("CampaignInnerGate",Vector3(13.5,1.1,-2),Vector3(1.8,2.2,.18),"blue",true)
		w.campaign_gate=gate
		for x in [10,13,16]:
			k.box("ControlConsole",Vector3(x,.7,-10.5),Vector3(2.2,1.4,.8),"blue",true)
			k.box("ControlScreenFrame",Vector3(x,1.7,-10.7),Vector3(1.8,.7,.12),"dark")
			k.box("ControlScreen",Vector3(x,1.7,-10.62),Vector3(1.45,.5,.02),"blue")
			for dx in [-.5,-.2,.2,.5]:
				k.cyl("ConsoleGauge",Vector3(x+dx,1.25,-10.06),.07,.03,"cream").rotation.x=PI/2
				k.box("ScreenTrace",Vector3(x+dx,1.65,-10.6),Vector3(.18,.02,.01),"cold_light")
		k.cyl("OrbitalMockup",Vector3(18,1.6,-8),.55,3.2,"metal")
		k.label("ВОСТОК–7",Vector3(13,2.5,-12.7),36)
static func furnish(k,e:Array,id:String):
	var p=Vector3(e[1],0,e[2]);var kind:String=e[3]
	match kind:
		"panel","radio":
			k.box("ServicePanel_"+e[0],p+Vector3(0,.8,-1),Vector3(1.4,1.6,.5),"blue" if id=="starcity" else "metal",true)
			for dx in [-.4,0,.4]:k.cyl("ControlDial",p+Vector3(dx,1,-.72),.09,.04,"cream").rotation.x=PI/2
			k.box("Indicator",p+Vector3(0,1.4,-.72),Vector3(.35,.1,.02),"warm_light")
		"valve","tank":
			k.cyl("Reservoir",p+Vector3(0,.9,-1.5),.8,1.8,"rust")
			k.box("ReservoirHull",p+Vector3(0,.8,-1.5),Vector3(1.5,1.6,1.5),"dark",true).visible=false
			k.pipe(p+Vector3(-2,.5,-1.5),p+Vector3(2,.5,-1.5),.1,"metal")
			k.cyl("Handwheel",p+Vector3(0,1,-.6),.28,.05,"red").rotation.x=PI/2
		"well":
			k.cyl("WellRim",p+Vector3(0,.35,-1.4),.9,.7,"concrete")
			k.cyl("WellWater",p+Vector3(0,.71,-1.4),.68,.02,"dark")
			k.box("WellHull",p+Vector3(0,.35,-1.4),Vector3(1.7,.7,1.7),"dark",true).visible=false
		"store":
			k.table(p+Vector3(0,0,-1.7),3)
			k.box("SealedParts",p+Vector3(0,1,-1.7),Vector3(1.5,.35,.65),"cream")
		"desk","bench","paper":
			k.table(p+Vector3(0,0,-1.4),2.8)
			k.box("OpenLedger",p+Vector3(.2,.83,-1.3),Vector3(.7,.035,.48),"paper")
			for dx in [-.3,0,.3]:k.box("LedgerMark",p+Vector3(dx,.853,-1.3),Vector3(.025,.005,.28),"dark")
		"exit":
			k.box("AirlockMarker",p+Vector3(0,.02,1.4),Vector3(1.8,.025,.15),"brass")
			k.label("⇄",p+Vector3(0,1.8,1.5),45)
static func people(w):
	var arts={"plant_guide":"commander","commune_leader":"cook","commune_anna":"nina","sech_elder":"semyon","sech_sergey":"igor","coal_clerk":"queue","coal_medic":"supply","coal_brother":"resident","star_guard":"commander","star_father":"semyon"}
	for e in OBJECTS[w.floor_id]:
		if e[3]=="npc":w.person(e[0],Vector3(e[1],0,e[2]),"green",true,arts[e[0]])
	if w.floor_id=="waterworks":w.person("plant_guide",Vector3(10,0,4),"green",true,"commander")
static func targets(w):
	for e in OBJECTS[w.floor_id]:
		var d:Dictionary=Campaign.data().interactions[e[0]]
		w.target(e[0],Vector3(e[1],0,e[2]),d.name,"talk" if e[3]=="npc" else "inspect")
	if w.floor_id=="waterworks":w.target("plant_guide",Vector3(10,0,4),"科瓦廖夫","talk")
static func routines(w):
	for id in w.npcs:w.npcs[id].navigation=w.navigation

static func dress_facility(w):
	var k=w.kit;var id:String=w.floor_id;var layout:Dictionary=LAYOUTS[id]
	for room in rooms(id):
		if room.code=="00":continue
		var r:Rect2=room.rect
		var back:float=r.position.y+1 if r.position.y<0 else r.end.y-1
		var center:float=r.get_center().x
		# Perimeter furnishings preserve a wide approach to every door and target.
		if id in ["commune","sech","coal"]:
			k.bench(Vector3(center,0,back),3.6)
			for dx in [-1.1,0,1.1]:
				k.box("FoldedBlanket",Vector3(center+dx,.6,back),Vector3(.65,.18,.5),"cloth")
		else:
			k.box("ServiceBackboard",Vector3(center,1.3,back),Vector3(3.8,1.5,.15),"corrugated" if id=="waterworks" else "blue")
			for dx in [-1.3,-.5,.5,1.3]:
				k.cyl("PanelGauge",Vector3(center+dx,1.5,back+.13),.12,.04,"cream").rotation.x=PI/2
				k.box("PanelSwitch",Vector3(center+dx,1,back+.13),Vector3(.1,.15,.08),"dark")
		for dx in [-1,0,1]:
			k.box("PinnedWorkOrder",Vector3(center+dx,2.1,back),Vector3(.3,.42,.02),"paper")
		for x in [r.position.x+.35,r.end.x-.35]:
			k.box("RoomRib",Vector3(x,1.4,back),Vector3(.16,2.8,.28),"concrete")
		# Wall-side water barrel and stacked supply boxes, with unified collision footprints.
		var corner=Vector3(r.position.x+1.2,0,back)
		if id in ["waterworks","coal"]:
			k.cyl("WaterDrum",corner+Vector3(0,.48,0),.38,.96,"metal")
			for y in [.1,.85]:k.cyl("BarrelHoop",corner+Vector3(0,y,0),.395,.04,"dark")
			k.box("BarrelHull",corner+Vector3(0,.48,0),Vector3(.75,.96,.75),"dark",true).visible=false
		else:
			k.crate(corner,Vector3(1.2,.75,.8))
			k.box("SupplyParcel",corner+Vector3(0,.9,0),Vector3(.7,.3,.55),"cloth")
	# Continuous guided circulation is marked in paint, not collision.
	for x in range(-int(layout.half)+1,int(layout.half)):
		k.box("WayfindingLine",Vector3(x,.027,0),Vector3(.45,.012,.035),"brass")
	for z in [layout.north+.6,layout.south-.6]:
		k.pipe(Vector3(-layout.half+.3,2.55,z),Vector3(layout.half-.3,2.55,z),.11,"metal")
	# Function-specific silhouettes keep these facilities distinct from the D-6 living rooms.
	match id:
		"waterworks":
			for x in [-16.5,-8.5]:
				for z in [-4]:
					k.cyl("FilterColumn",Vector3(x,1,z),.6,2,"metal")
					k.box("FilterColumnHull",Vector3(x,.9,z),Vector3(1.15,1.8,1.15),"dark",true).visible=false
					k.pipe(Vector3(x,2,z),Vector3(x,2,-11.3),.1,"rust")
			for z in [-10.5,-8.5]:
				for x in [7,16.5]:k.crate(Vector3(x,0,z),Vector3(1.3,.9,1.1))
		"commune":
			k.table(Vector3(-13,0,8.5),5)
			for x in [-14.5,-13,-11.5]:
				k.cyl("SoupBowl",Vector3(x,.84,8.5),.14,.1,"cream")
			k.bench(Vector3(-13,0,7.4),3.8)
			k.poster(Vector3(-14,1.7,10.7),"ВМЕСТЕ",true)
			for x in [-3,5]:
				k.box("ClinicScreenPost",Vector3(x,1.1,8.5),Vector3(.06,2.2,2.4),"metal")
				k.box("ClinicCurtain",Vector3(x,1.45,8.5),Vector3(.035,1.3,2.3),"cloth")
			k.table(Vector3(13,0,-10.5),4)
			for x in [11.7,12.4,13.1,13.8]:k.box("ArchiveFile",Vector3(x,.86,-10.5),Vector3(.5,.08,.65),"paper")
		"sech":
			k.box("RailCarSide",Vector3(15.6,1.1,-6.5),Vector3(.15,2.2,5),"corrugated")
			for z in [-8,-6,-4]:k.box("CarWindow",Vector3(15.5,1.45,z),Vector3(.04,.65,.8),"dark")
			k.table(Vector3(0,0,9),4)
			k.bench(Vector3(0,0,7.8),3)
			for x in [-2,2]:k.cyl("StoveChimney",Vector3(x,1.5,9),.11,3,"rust")
			for i in 8:k.box("DryingBook",Vector3(7+i*.65,.7,-8),Vector3(.45,.07,.6),"paper")
		"coal":
			for x in [7.7,12]:k.table(Vector3(x,0,-8.7),1.2)
			k.box("CoalTransferBoard",Vector3(-10,1.7,9.7),Vector3(2.7,1.3,.07),"wood")
			for x in [-11,-10.5,-10,-9.5,-9]:k.box("HangingWorkCard",Vector3(x,1.6,9.63),Vector3(.2,.3,.035),"paper")
		"starcity":
			for x in [-3,-1.5,0,1.5,3]:
				k.locker(Vector3(x,0,-11.5),2.0)
				k.box("ArchiveLabel",Vector3(x,1.4,-11.2),Vector3(.4,.22,.02),"paper")
			k.table(Vector3(12,0,9),4)
			for x in [10.5,11.5,12.5,13.5]:k.box("RadioRecorder",Vector3(x,1.1,9),Vector3(.7,.5,.5),"metal")
