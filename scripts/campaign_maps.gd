extends RefCounted
const Campaign=preload("res://scripts/campaign.gd")
const Plans=preload("res://scripts/facility_layouts.gd")
const Detail=preload("res://scripts/facility_detail.gd")
const Settlement=preload("res://scripts/settlement_details.gd")
const Shell=preload("res://scripts/facility_shell.gd")
const LAYOUTS=Plans.PLANS
static func rooms(id:String)->Array:return Plans.rooms(id)
static func door_specs(id:String)->Array:return Plans.door_specs(id)
static func doors(id:String)->Array:
	var out=[]
	for entry in LAYOUTS[id].doors:out.append(Vector2(entry[0],entry[1]))
	return out
static func build(w):
	var k=w.kit;var id:String=w.floor_id;var plan:Dictionary=LAYOUTS[id]
	if id in ["commune","waterworks","sech","starcity","surface","railfront"]:Detail.materials(k)
	if id=="railfront":
		preload("res://scripts/frontline.gd").build(w);return
	if id in ["surface","starcity"]:
		preload("res://scripts/surface_site.gd").build(w) if id=="surface" else preload("res://scripts/star_perimeter.gd").build(w)
		k.finish_walls();return
	var surfaces={"waterworks":["cement","cement_normal","a3b6bb"],"commune":["wall","wall_normal","d8c39b"],"sech":["corrugated","steel_normal","8a9990"],"coal":["oxide","oxide_normal","a19883"],"starcity":["steel","steel_normal","a2c0cb"]}
	k.wall_surface=surfaces[id][0];k.wall_normal=surfaces[id][1];k.wall_color=Color(surfaces[id][2])
	k.mats.blue=k.mats.metal.duplicate();k.mats.blue.albedo_color=Color("66858c")
	k.mats.plaster.albedo_color=Color({"waterworks":"a3b4ad","commune":"c1b38f","sech":"8f9992","coal":"8a8c84","starcity":"a1b5bb"}[id])
	Shell.build(w,plan,rooms(id))
	for entry in plan.objects:
		if id!="starcity":furnish(k,entry,id)
	for room in rooms(id):
		if room.code=="00":continue
		var r:Rect2=room.rect
		var warm:bool=plan.warm or (id=="coal" and room.code in ["02","03"])
		var power=2.4 if (warm and room.code in ["01","02"]) else 2.1
		var lamp_position=Vector3(r.get_center().x,2.5,r.position.y+.65)
		if id=="starcity":lamp_position.z=r.position.y+.18
		if id in ["waterworks","commune"]:lamp_position.z=r.position.y+.22
		if id=="starcity" and room.code=="03":lamp_position=Vector3(4.2,2.5,-14.82)
		if id=="waterworks" and room.code=="01":lamp_position.x=-18.1
		if id=="waterworks" and room.code=="03":lamp_position.x=5.9
		if id=="commune" and room.code=="02":lamp_position=Vector3(-3,2.5,-3.80) # Mounted beside the double door, clear of its leaves.
		var lamp=k.lamp(lamp_position,warm,power,8)
		if id=="waterworks":
			lamp.light_color=Color("c9c8af") if room.code in ["02","04","05"] else Color("b7cac3")
			lamp.shadow_enabled=true;lamp.shadow_bias=.035;lamp.shadow_normal_bias=.35
	for entry in plan.doors:
		if entry[2]=="z":
			var label=""
			for room in rooms(id):
				if room.code!="00" and absf(room.rect.position.y-entry[1])<.01 and entry[0]>room.rect.position.x and entry[0]<room.rect.end.x:label=room.name;break
			if label!="" and id!="starcity":k.signboard(label,Vector3(entry[0],2.35,entry[1]+.16),3.5)
	if plan.has("gate"):
		w.campaign_gate_flag=plan.gate_flag
		w.campaign_gate=k.box("CampaignInnerGate",plan.gate,Vector3(1.82,2.2,.18),"corrugated" if id=="waterworks" else "blue",true)
		w.campaign_gate.set_meta("dynamic",true)
		w.campaign_gate.set_meta("closed_position",plan.gate)
		for x in [-.94,.94]:k.box("GateRail",plan.gate+Vector3(x,0,0),Vector3(.1,2.5,.27),"metal")
	match id:
		"waterworks":waterworks(w);Detail.waterworks(w);preload("res://scripts/factory_details_v12.gd").build(w)
		"commune":Settlement.commune(w)
		"sech":Settlement.sech(w)
		"coal":coal(w)
		"starcity":starcity(w)
	k.finish_walls()
static func waterworks(w):
	var k=w.kit
	# Unheated surface building; outside snow and ruins are scenery beyond solid walls.
	var snow=k.mats.concrete.duplicate();snow.albedo_color=Color("e1e2de");snow.roughness=1;snow.normal_enabled=false;snow.roughness_texture=null
	if ResourceLoader.exists("res://assets/visual/ash_snow.png"):snow.albedo_texture=load("res://assets/visual/ash_snow.png");snow.uv1_scale=Vector3(.15,.15,.15)
	var ground=k.box("ExteriorSnow",Vector3(0,-.35,0),Vector3(100,.12,85),"concrete");ground.material_override=snow
	# The factory exterior shares the same volumetric, textured city ruins as
	# the two outdoor maps; scenery stays outside the plant's collision shell.
	k.mats.surface_snow=snow; k.mats.snowbank=snow
	preload("res://scripts/outdoor_architecture.gd").materials(k)
	preload("res://scripts/outdoor_architecture.gd").skyline(k)
	for x in [-16,-10]:
		k.box("PumpCollision",Vector3(x+.35,.75,-10),Vector3(2.6,1.5,1.8),"metal",true).visible=false
		k.cyl("PumpHousing",Vector3(x,.75,-10),.9,1.5,"metal")
		k.cyl("PumpMotor",Vector3(x+1,1,-10),.45,1.1,"rust").rotation.z=PI/2
		k.pipe(Vector3(x,1.2,-10),Vector3(x,1.2,-13.7),.2,"rust")
		for z in [-11.5,-9.5]:k.cyl("PipeClamp",Vector3(x,.35,z),.24,.15,"metal")
	for x in [-18.6,4.8,18.6]:
		for z in [-12,-6]:k.box("FactoryRib",Vector3(x,1.6,z),Vector3(.28,3.2,.4),"metal")
	for x in [-16,-12,-8,8,12,16]:
		var window=k.box("FrostedFactoryWindow",Vector3(x,2,-13.9),Vector3(2.5,1.1,.04),"cold_light")
		for dx in [-.8,0,.8]:k.box("WindowMullion",Vector3(x+dx,2,-13.84),Vector3(.045,1.15,.06),"metal")
	# Broad cool window fill complements dimmer, warmer maintenance fixtures.
	# Actual shadowed lights are inside the masonry, with no bright indoor sun.
	for x in [-12,12]:
		var daylight=OmniLight3D.new();daylight.name="FactoryWindowFill";w.add_child(daylight)
		daylight.position=Vector3(x,2.05,-13.35);daylight.light_color=Color("acbfc4");daylight.light_energy=1.65;daylight.omni_range=11;daylight.omni_attenuation=2.0;daylight.shadow_enabled=true;daylight.shadow_normal_bias=.35
	k.lamp(Vector3(-7,2.65,.22),false,1.5,8)
	k.lamp(Vector3(11,2.65,.22),false,1.5,8)
	for x in [8,12,16]:
		for z in [-12,-10]:k.crate(Vector3(x,0,z),Vector3(1.35,1,1))
	for z in [-9,-5]:k.pipe(Vector3(-18,2.8,z),Vector3(18,2.8,z),.12,"rust")
	for x in [-21,-18]:k.locker(Vector3(x,0,10.8))
	k.table(Vector3(-7,0,11),3)
	for x in [-8,-7,-6]:k.box("PowerSpare",Vector3(x,.92,11),Vector3(.6,.2,.45),"metal")
	for z in [5.8,8.6]:rack(k,Vector3(-22.4,0,z),1.1,"metal")
	for x in [6.5,17]:rack(k,Vector3(x,0,-8),1.8,"wood")
	for x in [-3,0,3]:k.box("CableTrenchCover",Vector3(x,.025,2),Vector3(1.8,.05,.5),"metal")
	k.signboard("值班图 / 入口登记",Vector3(8,1.8,4.7),2.7)
	k.bench(Vector3(16,0,10.8),2.8,true,PI)
	# The archive extends farther west than the pump room. Snow follows the
	# exterior footprint instead of putting white slabs inside the archive.
	for p in [Vector2(-20.3,-11),Vector2(-20.3,-6),Vector2(-24.3,1),Vector2(-24.3,6),Vector2(-24.3,10),Vector2(20.3,-11),Vector2(20.3,-6),Vector2(20.3,1),Vector2(20.3,6)]:
		var drift=k.ellipsoid("SnowDrift",Vector3(p.x,-.12,p.y),Vector3(.75,.28,1.6),"concrete");drift.material_override=snow
static func commune(w):
	var k=w.kit
	# Tall station columns define an open public hall instead of a corridor of identical cells.
	for x in [-9,10]:
		for z in [-1,5,9]:
			k.cyl("StationColumn",Vector3(x,1.8,z),.33,3.6,"tile")
			k.box("ColumnCollision",Vector3(x,1.5,z),Vector3(.65,3,.65),"tile",true).visible=false
			k.cyl("ColumnCapital",Vector3(x,3.4,z),.49,.18,"cream")
	k.table(Vector3(-3,0,6),5);k.bench(Vector3(-3,0,4.9),4.2,true,PI);k.bench(Vector3(-3,0,7.1),4.2)
	for x in [-20,-16]:
		for z in [-9,-3,4]:
			if x==-20 and z==-9:continue # Mushroom racks occupy this bay.
			k.box("GreenhouseBed",Vector3(x,.4,z),Vector3(2.2,.8,3.7),"old_iron",true)
			Detail.vegetables(k,x,z)
	for z in [-11,-5,1,8]:
		k.pipe(Vector3(-22,2.8,z),Vector3(-12,2.8,z),.045,"metal")
		k.lamp(Vector3(-17,2.5,z),true,1.2,6)
	for x in [-8,-1]:k.bed(Vector3(x,0,17),"paper")
	for x in [15,19]:w.Wing.bunk(k,Vector3(x,0,10))
	k.table(Vector3(18,0,-10),4)
	for x in [16.5,17.2,17.9,18.6,19.3]:k.box("ArchiveFile",Vector3(x,.86,-10),Vector3(.5,.08,.65),"paper")
	k.poster(Vector3(-5,1.8,-7.8),"ВМЕСТЕ",true)
	k.signboard("工人委员会 / 反对特权配给",Vector3(3,1.7,-7.8),6)
	for x in [-7,0,7]:
		k.box("MeetingBallot",Vector3(x,1,-7.3),Vector3(.7,.4,.5),"wood",true)
		k.box("BallotSlot",Vector3(x,1.21,-7.3),Vector3(.35,.015,.035),"dark")
	for x in [-5,1]:
		k.table(Vector3(x,0,-1.5),3.8)
		for dx in [-1,0,1]:k.cyl("SoupBowl",Vector3(x+dx,.86,-1.5),.15,.1,"cream")
	for x in [14,21]:k.locker(Vector3(x,0,15.8))
	for x in [-8,0]:rack(k,Vector3(x,0,19.3),2,"wood")
	for x in [-22,-12]:rack(k,Vector3(x,0,9.5),1.3,"wood")
	for x in [14,16,18,20]:
		k.box("DryingPrint",Vector3(x,1.9,-12),Vector3(.65,.85,.025),"paper")
		k.box("PrintLine",Vector3(x,1.93,-11.98),Vector3(.5,.035,.01),"red")
	k.pipe(Vector3(13,2.4,-12),Vector3(22,2.4,-12),.016,"metal")
	k.table(Vector3(7,0,8),2.7);k.bench(Vector3(7,0,6.9),2.2,true,PI)
	for dx in [-.7,0,.7]:k.box("MendedLunchTin",Vector3(7+dx,.9,8),Vector3(.4,.15,.35),"metal")
	k.signboard("公用水井 / 食堂",Vector3(5,2.1,-3.8),3.5)
static func sech(w):
	var k=w.kit
	k.box("DepotTrackBed",Vector3(0,-.9,-1),Vector3(24,.15,52),"concrete")
	# Each pair of rails supports the matching car bodies; no rail cuts across a room.
	for center in [-6,6]:
		for dx in [-.76,.76]:k.box("DepotRail",Vector3(center+dx,-.70,-1),Vector3(.08,.13,49),"metal")
		for z in range(-24,24):k.box("TrackSleeper",Vector3(center,-.80,z),Vector3(2.45,.1,.2),"wood")
	for spec in [[-6,-19,11],[-6,-6,11],[-6,7,11],[6,-19,18],[6,2,16]]:
		var x:float=spec[0];var start:float=spec[1];var length:float=spec[2]
		k.box("CarriageChassis",Vector3(x,-.19,start+length/2),Vector3(3.95,.28,length),"metal")
		for end in [start,start+length]:
			k.box("Coupler",Vector3(x,-.22,end+(-.55 if end==start else .55)),Vector3(.22,.22,1.1),"metal")
			for dx in [-1.25,1.25]:k.cyl("Buffer",Vector3(x+dx,-.12,end),.14,.35,"dark").rotation.x=PI/2
		for z in [start+1.6,start+length-1.6]:
			for dz in [-.35,.35]:
				k.pipe(Vector3(x-.9,-.335,z+dz),Vector3(x+.9,-.335,z+dz),.08,"metal")
				for dx in [-.76,.76]:k.cyl("BogieWheel",Vector3(x+dx,-.335,z+dz),.3,.12,"dark").rotation.z=PI/2
		for z in range(int(start+2),int(start+length-1),3):
			# Exterior window assemblies and repeated ribs make the narrow volumes legible as cars.
			var outer=x+(-2.08 if x<0 else 2.08)
			k.box("CarriageWindowFrame",Vector3(outer,1.7,z),Vector3(.12,.9,1.5),"metal")
			k.box("CarriageWindowGlass",Vector3(outer+(-.07 if x<0 else .07),1.7,z),Vector3(.03,.68,1.25),"dark")
			for edge in [-1.9,1.9]:k.box("CarriageBodyRib",Vector3(x+edge,1.3,z+.95),Vector3(.06,2.6,.07),"metal")
			k.pipe(Vector3(x-1.9,2.7,z+.95),Vector3(x+1.9,2.7,z+.95),.045,"metal")
		k.box("WeatheredCarriageStripe",Vector3(x+(-2.09 if x<0 else 2.09),.65,start+length/2),Vector3(.03,.18,length-.3),"red")
	for z in [-20,-14,-8,-2,4,10,16]:
		k.lamp(Vector3(0,3.1,z),true,.65,5)
		k.pipe(Vector3(-4,3.25,z),Vector3(4,3.25,z),.045,"metal")
		k.pipe(Vector3(0,3.25,z),Vector3(0,3.1,z),.025,"metal")
		for x in [-3.65,3.65]:k.box("PlatformEdge",Vector3(x,.03,z),Vector3(.06,.05,2.8),"cream")
	for z in [-16,-12,-7]:bookcase(k,Vector3(4.35,0,z),2.5)
	k.lamp(Vector3(6,2.4,-11),true,1.1,7)
	k.table(Vector3(6,0,-14.5),2.1)
	for i in 5:k.box("DryingBook",Vector3(5.2+i*.35,.86,-14.5),Vector3(.25,.06,.45),"paper")
	k.bench(Vector3(6,0,-5.8),2.3,true,PI)
	k.table(Vector3(-6,0,17),2.3)
	k.cyl("DepotStove",Vector3(-7.3,.6,8.5),.32,1.2,"dark")
	k.box("StoveHull",Vector3(-7.3,.6,8.5),Vector3(.65,1.2,.65),"dark",true).visible=false
	k.pipe(Vector3(-7.3,1.2,8.5),Vector3(-7.3,3.2,8.5),.09,"metal")
	k.lamp(Vector3(-7,1.4,8.5),true,.8,4)
	for z in [4.5,7]:k.bench(Vector3(6,0,z),2.2,true,PI)
	for x in [-7.3,-4.7]:k.locker(Vector3(x,0,-18.1))
	k.signboard("КНИГИ / 书架车厢",Vector3(6,2.4,-18.8),3.5)
	k.signboard("КРУГ / 议事 · 轮值",Vector3(-6,2.4,17.8),3.2)
	k.box("CossackIconFrame",Vector3(-7.5,1.9,17.78),Vector3(.5,.65,.05),"wood")
	k.box("IconCenter",Vector3(-7.5,1.9,17.73),Vector3(.25,.4,.02),"brass")
	k.box("SabreBlade",Vector3(-4.4,1.6,17.75),Vector3(.05,1.25,.05),"metal").rotation.z=.22
	k.box("SabreGuard",Vector3(-4.48,1.95,17.75),Vector3(.3,.06,.08),"brass")
static func bookcase(k,p:Vector3,length:float):
	var front=1.0 if p.x<6 else -1.0
	k.box("BookcaseHull",p+Vector3(0,1,0),Vector3(.45,2,length),"wood",true).visible=false
	k.box("BookcaseBack",p+Vector3(-front*.18,1,0),Vector3(.08,2,length),"wood")
	for end in [-length/2,length/2]:k.box("BookcaseSide",p+Vector3(0,1,end),Vector3(.5,2,.09),"wood")
	for y in [.15,.7,1.25,1.8]:
		k.box("BookcaseShelf",p+Vector3(0,y,0),Vector3(.52,.08,length),"wood")
		for index in range(int(length/.13)-1):
			var mat=["red","blue","green","paper","wood"][posmod(index+int(y*10),5)]
			var height=.28+posmod(index,4)*.045
			k.box("BookSpine",p+Vector3(front*.05,y+height/2+.04,-length/2+.16+index*.13),Vector3(.36,height,.105),mat)
			k.box("BookSpineWear",p+Vector3(front*.238,y+height*.6,-length/2+.16+index*.13),Vector3(.008,.015,.075),"paper")
static func coal(w):
	var k=w.kit
	var frame=Vector3(-23,1.15,-18)
	for x in [-24.5,-21.5]:k.box("MineEscapeJamb",Vector3(x,1.2,-18),Vector3(.16,2.4,.2),"metal")
	var grate=k.box("MineEscapeGrille",frame,Vector3(2.8,2.3,.10),"rust",true);grate.set_meta("dynamic",true)
	if w.story.f("rescue_route_ready"):grate.position.x+=2.8
	k.lamp(Vector3(-23,2.25,-19),true,1.1,5)

	Settlement.rug(k,Vector3(-12,0,11.9),Vector2(2,2),"olive")
	for x in [-26.1,-24.9]:k.box("CoalHaulRail",Vector3(x,.025,-7.5),Vector3(.08,.05,27),"metal")
	for z in range(-21,8,2):
		for x in [-27.6,-18.4]:k.box("MineSupport",Vector3(x,1.3,z),Vector3(.22,2.6,.25),"wood",true)
		k.box("MineCrossTimber",Vector3(-23,2.65,z),Vector3(9.5,.25,.3),"wood")
	for z in [-17,-9,-3]:
		k.box("CoalMineCart",Vector3(-25.5,.6,z),Vector3(1.4,.9,2),"rust",true)
		for n in range(7):k.ellipsoid("CoalLoad",Vector3(-26+float(n%3)*.45,1.1,-.6+z+float(n/3)*.4),Vector3(.28,.22,.3),"dark")
	for z in [-20,-12,-4,4]:k.lamp(Vector3(-27.5,2.3,z),true,.85,6)
	k.box("MineWinchFrame",Vector3(-20,.65,5),Vector3(1.7,1.3,1.4),"metal",true)
	k.cyl("WinchCableDrum",Vector3(-20,1.2,5),.42,1.5,"rust").rotation.z=PI/2
	k.pipe(Vector3(-20,1.3,5),Vector3(-20,2.7,-6),.045,"dark")
	for x in [-16,-12,-8,-4]:
		for z in [2.25,6.75]:k.box("MineTimber",Vector3(x,1.2,z),Vector3(.22,2.4,.22),"wood",true)
		k.box("MineCrossbeam",Vector3(x,2.42,4.5),Vector3(.22,.2,4.8),"wood")
	for z in [-10,-5,0]:
		for x in [-1.75,1.75]:k.box("OldMineRib",Vector3(x,1.2,z),Vector3(.16,2.4,.22),"rust")
	for x in [-15,-12]:k.box("TransferRail",Vector3(x,.022,4.5),Vector3(.08,.04,13),"metal").rotation.y=PI/2
	for x in [6,12]:k.bed(Vector3(x,0,-8),"paper")
	for x in [5,11]:k.table(Vector3(x,0,-10),1.2)
	for z in [-10,-6]:k.box("PrivacyCurtain",Vector3(3,1.6,z),Vector3(.04,2.1,3),"cloth")
	k.table(Vector3(5,0,-17),4)
	k.box("WashBasin",Vector3(8,1,-15),Vector3(.7,.2,.6),"cream")
	k.box("TagBoard",Vector3(-11,1.5,13.8),Vector3(3,1.2,.1),"wood")
	for i in 7:k.box("WorkTag",Vector3(-12.2+i*.4,1.5,13.72),Vector3(.2,.3,.02),"paper")
	for x in [-14,-11,-8]:k.locker(Vector3(x,0,-10.3))
	for x in [-17.3,-8.7]:k.bench(Vector3(x,0,10),2,true,PI/2)
	for x in [4,6,8]:rack(k,Vector3(x,0,-17.4),1.1,"metal")
	for x in [5,11]:
		k.box("BedsideMug",Vector3(x,.9,-10),Vector3(.2,.18,.2),"cream")
		k.box("FamilyPhoto",Vector3(x+.3,1.05,-10.1),Vector3(.2,.3,.03),"wood")
	k.table(Vector3(-12,0,-8.5),3)
	for dx in [-1,0,1]:k.box("PaySlip",Vector3(-12+dx,.84,-8.5),Vector3(.6,.02,.5),"paper")
	k.pipe(Vector3(-1.7,1.8,-12),Vector3(-1.7,1.8,1),.08,"rust")
	k.signboard("中央苏维埃 · D-6 / 限区探访",Vector3(-13,2.1,13.8),4.3)
	k.signboard("休养间 / 请轻声",Vector3(10,2.1,-2.17),3.4)
static func starcity(w):
	preload("res://scripts/starcity_v17.gd").build(w)
static func furnish(k,e:Array,id:String):
	var p=Vector3(e[1],0,e[2]);var kind:String=e[3]
	if kind=="tank" and id=="sech":
		k.cyl("CarriageWaterTank",p+Vector3(-1,.8,.2),.6,1.6,"rust")
		k.box("TankCollision",p+Vector3(-1,.8,.2),Vector3(1.2,1.6,1.2),"metal",true).visible=false
		k.pipe(p+Vector3(-.4,1,.2),p+Vector3(0,1,0),.07,"metal")
		k.cyl("TankHandwheel",p+Vector3(0,1,0),.2,.04,"red").rotation.x=PI/2
		return
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
			for dx in [-.65,.65]:
				k.crate(p+Vector3(dx,0,-1.7),Vector3(1.1,.8,.8))
				k.box("FilterShippingLabel",p+Vector3(dx,.48,-1.285),Vector3(.65,.28,.018),"paper")
				k.label("1962 / ФИЛЬТР",p+Vector3(dx,.5,-1.27),13)
		"desk","bench","paper":
			k.table(p+Vector3(0,0,-1.4),2.8)
			k.box("OpenLedger",p+Vector3(.2,.83,-1.3),Vector3(.7,.035,.48),"paper")
			for dx in [-.3,0,.3]:k.box("LedgerMark",p+Vector3(dx,.853,-1.3),Vector3(.025,.005,.28),"dark")
		"factory_exit":pass
		"exit":
			k.box("AirlockMarker",p+Vector3(0,.02,1.4),Vector3(1.8,.025,.15),"brass")
			k.label("⇄",p+Vector3(0,1.8,1.5),45)
		"lockers":
			for dx in [-.55,.55]:k.locker(p+Vector3(dx,0,-1.5))
		"shelf":rack(k,p+Vector3(0,0,-1.4),2.2,"metal")
		"press":
			k.table(p+Vector3(0,0,-1.4),2.7)
			k.box("Duplicator",p+Vector3(0,1.08,-1.4),Vector3(.9,.48,.6),"metal")
			k.cyl("InkDrum",p+Vector3(0,1.45,-1.4),.23,.9,"dark").rotation.z=PI/2
			k.pipe(p+Vector3(.6,1.4,-1.4),p+Vector3(.6,1.65,-1.1),.04,"metal")
			k.box("ProofPaper",p+Vector3(-.8,.84,-1.3),Vector3(.6,.025,.6),"paper")
		"car_brake":
			k.box("HandbrakePost",p+Vector3(0,.8,1.1),Vector3(.18,1.6,.18),"metal",true)
			k.cyl("HandbrakeWheel",p+Vector3(0,1.25,.93),.28,.07,"red").rotation.x=PI/2
			k.box("InspectionHatch",p+Vector3(-.9,.04,1),Vector3(.8,.05,.65),"metal")
			k.box("ChockShelf",p+Vector3(1.25,.65,1.2),Vector3(.7,.12,.45),"wood",true)
			for dx in [-.15,.15]:k.box("PublicWheelChock",p+Vector3(1.25+dx,.77,1.2),Vector3(.23,.12,.3),"wood").rotation.z=.12
		"signal":
			k.box("SignalPost",p+Vector3(0,1,-1.2),Vector3(.16,2,.16),"metal",true)
			k.box("RouteArrow",p+Vector3(.2,1.8,-1.2),Vector3(1,.2,.08),"cream")
			k.box("StopMarker",p+Vector3(-.4,1.3,-1.2),Vector3(.4,.5,.08),"red")
		"wash":
			k.table(p+Vector3(0,0,-1.5),3.3)
			for dx in [-1,0,1]:k.box("SortingBasket",p+Vector3(dx,1,-1.5),Vector3(.75,.3,.6),"wood")
			k.pipe(p+Vector3(-1.5,2.1,-1.5),p+Vector3(1.5,2.1,-1.5),.025,"metal")
static func rack(k,p:Vector3,width:float,material:String):
	k.box("ShelfCollision",p+Vector3(0,1,0),Vector3(width,2,.55),material,true).visible=false
	for dx in [-width/2,width/2]:k.box("ShelfUpright",p+Vector3(dx,1,0),Vector3(.07,2,.55),material)
	for y in [.2,.85,1.5]:
		k.box("ShelfBoard",p+Vector3(0,y,0),Vector3(width,.08,.55),material)
		for x in [-.3,.3]:k.box("ShelfParcel",p+Vector3(x*width,y+.18,0),Vector3(width*.32,.28,.4),"paper" if y>1 else "wood")
static func people(w):
	if w.floor_id=="commune" and w.story.f("anna_outcome_done"):
		w.person("commune_aleksei",Vector3(-2.9,0,20),"cloth",true,"coal_brother");w.npcs.commune_aleksei.stationary=true
	if w.floor_id=="coal" and w.story.f("anna_rescue_started") and not w.story.f("anna_outcome_done"):
		w.person("mine_anna",Vector3(7,0,-5.3),"cloth",true,"anna");w.npcs.mine_anna.stationary=true
	if w.floor_id=="railfront":preload("res://scripts/frontline.gd").people(w);return
	var arts={"plant_guide":"commander_masked","commune_leader":"commune_leader","commune_anna":"anna","sech_elder":"sech_elder","sech_sergey":"sergey","coal_clerk":"coal_clerk","coal_medic":"coal_medic","coal_brother":"coal_brother","star_guard":"star_guard","star_father":"father"}
	for person_id in ["commune_printer","commune_grower","sech_quartermaster","star_technician"]:arts[person_id]=person_id
	arts.merge({"commune_cook":"commune_cook","commune_child":"commune_child","commune_moro":"commune_moro","commune_guard":"commune_guard","commune_baranova":"ambient_elder","sech_cook":"sech_cook"})
	for e in LAYOUTS[w.floor_id].objects:
		if e[0]=="commune_anna" and w.story.f("anna_dead"):continue
		if e[0]=="coal_brother" and w.story.f("anna_outcome_done"):continue
		if e[3]=="npc":w.person(e[0],Vector3(e[1],0,e[2]),"green",true,arts[e[0]])
	for id in ["commune_moro","commune_guard","commune_baranova"]:
		if w.npcs.has(id):w.npcs[id].stationary=true
	if w.floor_id=="surface" and w.story.f("sided_veteran"):
		w.person("plant_veteran",Vector3(-16.5,0,13),"green",true,"veteran_masked")
	if w.floor_id=="waterworks":
		w.person("plant_guide",Vector3(10,0,7.5),"green",true,"commander_masked")
		w.person("plant_veteran",Vector3(13,0,7),"green",true,"veteran_masked")
static func targets(w):
	for extra in ["commune_aleksei","mine_anna"]:
		if w.npcs.has(extra):w.target(extra,w.npcs[extra].position,Campaign.data().interactions[extra].name,"talk")
	for e in LAYOUTS[w.floor_id].objects:
		if (e[0]=="commune_anna" and w.story.f("anna_dead")) or (e[0]=="coal_brother" and w.story.f("anna_outcome_done")):continue
		var d:Dictionary=Campaign.data().interactions[e[0]]
		w.target(e[0],Vector3(e[1],0,e[2]),d.name,"talk" if e[3]=="npc" else "inspect")
	if w.floor_id=="surface":preload("res://scripts/surface_site.gd").restore_drops(w)
	if w.floor_id=="waterworks":
		w.target("plant_guide",w.npcs.plant_guide.position,"科瓦廖夫","talk")
		w.target("plant_veteran",w.npcs.plant_veteran.position,"老兵","talk")
static func residents(w):
	var layouts={"commune":[["ambient_worker",6,4],["ambient_woman",-4.1,11.1],["ambient_woman",-7,21],["ambient_worker",9,-5.2],["ambient_child",15,9]],"sech":[["ambient_worker",0,3],["ambient_child",-10,14],["ambient_elder",-7,17.6],["ambient_woman",-8,2],["ambient_worker",16,-10]],"coal":[["ambient_worker",-5,11],["ambient_woman",12,-4]],"starcity":[]}
	for index in layouts.get(w.floor_id,[]).size():
		var entry=layouts[w.floor_id][index]
		w.person("resident_%s_%d"%[entry[0],index],Vector3(entry[1],0,entry[2]),"cloth",false,entry[0])

static func routines(w):
	for id in w.npcs:w.npcs[id].navigation=w.navigation
