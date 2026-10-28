extends RefCounted
## Roads and parcels are authored before furnishings. All positions are metres.
const Layout=preload("res://scripts/east_district.gd")
const Site=preload("res://scripts/surface_site.gd")
const Architecture=preload("res://scripts/outdoor_architecture.gd")
const Urban=preload("res://scripts/district_urban.gd")
static func position(a:Array,y:float=0)->Vector3:return Vector3(a[0],y,a[1])
static func road_conflict(plan:Dictionary,p:Vector3,size:Vector2)->bool:
	for road in plan.roads:
		var half=float(road.width)*.5+.65
		for i in range(road.points.size()-1):
			var a=Vector2(road.points[i][0],road.points[i][1]);var b=Vector2(road.points[i+1][0],road.points[i+1][1])
			if is_equal_approx(a.x,b.x) and absf(p.x-a.x)<size.x*.5+half and p.z+size.y*.5>minf(a.y,b.y)-half and p.z-size.y*.5<maxf(a.y,b.y)+half:return true
			if is_equal_approx(a.y,b.y) and absf(p.z-a.y)<size.y*.5+half and p.x+size.x*.5>minf(a.x,b.x)-half and p.x-size.x*.5<maxf(a.x,b.x)+half:return true
	return false
static func building(k,p:Vector3,size:Vector2,floors:int,seed:int,north_door:bool=false,kind:String="residential"):
	# Full facade modules have an actual door opening at ground level.
	var root=Node3D.new();root.name="DistrictBuilding%d"%seed;root.position=p;k.root.add_child(root)
	if north_door:root.rotation.y=PI
	var height=floors*2.8;var finish="district_ochre" if seed%3==1 else ("district_brick" if seed%3==2 else "district_concrete")
	if kind in ["waterworks","depot","pump"]:finish="district_brick"
	root.set_meta("architecture_kind",kind)
	root.set_meta("footprint",Rect2(p.x-size.x/2,p.z-size.y/2,size.x,size.y));root.set_meta("storeys",floors)
	k.box("BuildingFoundation",Vector3(0,.04,0),Vector3(size.x+.25,.22,size.y+.25),"district_concrete",false,root)
	for level in floors:
		var y=level*2.8
		k.box("BuildingFloor",Vector3(0,y+.16,0),Vector3(size.x,.16,size.y),"district_concrete",false,root)
		for face in 4:
			var x_face=face>=2;var sign=-1 if face%2==0 else 1
			var width=size.y if x_face else size.x;var bays=maxi(2,floori(width/2.1));var pitch=width/bays
			for n in bays:
				var along=-width/2+pitch*(n+.5)
				var c=Vector3(sign*size.x/2,0,along) if x_face else Vector3(along,0,sign*size.y/2)
				var door=level==0 and face==1 and n==floori(bays/2.0)
				var window_width=minf(1.25,pitch-.50)
				if not door:k.box("FacadeLowerWall",c+Vector3.UP*(y+.46),Vector3(.30,.78,pitch) if x_face else Vector3(pitch,.78,.30),finish,false,root)
				k.box("FacadeLintel",c+Vector3.UP*(y+2.48),Vector3(.30,.58,pitch) if x_face else Vector3(pitch,.58,.30),finish,false,root)
				for edge in [-1,1]:
					var side=c+Vector3.UP*(y+1.51)
					if x_face:side.z+=edge*(window_width/2+(pitch-window_width)/4)
					else:side.x+=edge*(window_width/2+(pitch-window_width)/4)
					k.box("FacadePier",side,Vector3(.30,1.34,(pitch-window_width)/2) if x_face else Vector3((pitch-window_width)/2,1.34,.30),finish,false,root)
				if door:
					k.box("DistrictEntranceDoor",c+Vector3(0,1.03,.03),Vector3(window_width-.07,2.03,.18),"old_iron",false,root)
					for dx in [-.49,.49]:k.box("DoorJamb",c+Vector3(dx,1.08,.20),Vector3(.08,2.18,.12),"metal",false,root)
					k.box("DoorHeader",c+Vector3(0,2.19,.20),Vector3(1.16,.10,.12),"metal",false,root)
					k.box("DoorHandle",c+Vector3(.32,1.08,.17),Vector3(.045,.17,.06),"brass",false,root)
				else:
					var out=Vector3(sign,0,0) if x_face else Vector3(0,0,sign)
					if posmod(n+seed+level+face,3)!=0:k.box("RecessedWindow",c+Vector3.UP*(y+1.52)-out*.06,Vector3(.025,1.15,window_width) if x_face else Vector3(window_width,1.15,.025),"exterior_glass",false,root)
					for edge in [-1,1]:
						var jamb=c+Vector3.UP*(y+1.52)+out*.03
						if x_face:jamb.z+=edge*window_width/2
						else:jamb.x+=edge*window_width/2
						k.box("WindowFrame",jamb,Vector3(.08,1.25,.06) if x_face else Vector3(.06,1.25,.08),"wood",false,root)
					k.box("WindowSill",c+Vector3.UP*(y+.88)+out*.04,Vector3(.42,.10,window_width+.2) if x_face else Vector3(window_width+.2,.10,.42),"district_concrete",false,root)
		k.box("FloorCourse",Vector3(0,y+2.78,0),Vector3(size.x+.12,.13,size.y+.12),"district_concrete",false,root)
	Urban.roof(k,root,size,height,kind,seed)
	Urban.facade(k,root,size,floors,kind)
	# Shutters and exposed brick repairs break up the repeated window bays.
	for n in 3:
		var x=-size.x*.32+n*size.x*.28
		for y in [1.4,4.2]:
			if y>height:continue
			var board=k.box("BoardedWindow",Vector3(x,y,size.y/2+.17),Vector3(1.08,.17,.06),"wood",false,root);board.rotation.z=.08 if n%2 else -.12
	if finish!="district_brick":k.box("ExposedBrickRepair",Vector3(-size.x*.3,.4,size.y/2+.16),Vector3(2.2,.55,.025),"district_brick",false,root)
	k.box("BuildingChimney",Vector3(-size.x*.25,height+.45,-size.y*.25),Vector3(.65,.9,.65),"district_brick",false,root)
	k.box("ChimneyCap",Vector3(-size.x*.25,height+.95,-size.y*.25),Vector3(.82,.12,.82),"district_concrete",false,root)
	for x in [-size.x/2+.25,size.x/2-.25]:k.box("RainPipe",Vector3(x,height/2,size.y/2+.18),Vector3(.08,height,.08),"rust",false,root)
	# Foreground building fabric fades with actual body coverage, keeping the
	# usable rear alleys visible without changing physical cover.
	for mesh in root.find_children("*","MeshInstance3D",true,false):
		if mesh.material_override is StandardMaterial3D and (mesh.global_transform*mesh.get_aabb()).end.y>.35:
			mesh.set_meta("view_occluder",true)
	var hull=k.box("DistrictBuildingHull",p+Vector3.UP*1.4,Vector3(size.x+.30,2.8,size.y+.30),"dark",true);hull.visible=false
static func portal(k,p:Vector3,label:String,heading:float=0):
	# Portal footprint stops behind the interaction/arrival space.
	var root=Node3D.new();root.name="DistrictPortal";root.position=p;k.root.add_child(root);root.rotation.y=heading
	for x in [-1.1,1.1]:k.box("PortalCheek",Vector3(x,1,-.8),Vector3(.30,2,1.7),"district_concrete",false,root)
	k.box("PortalCanopy",Vector3(0,2.1,-.8),Vector3(2.6,.18,2.0),"old_iron",false,root)
	k.box("PortalRoofSnow",Vector3(0,2.23,-.8),Vector3(2.4,.07,1.8),"surface_snow",false,root)
	k.box("PortalClosedDoor",Vector3(0,.95,-1.30),Vector3(1.85,1.9,.16),"corrugated",false,root)
	k.box("DoorPushBar",Vector3(0,1.05,-1.17),Vector3(.9,.07,.06),"metal",false,root)
	# Small lettering is painted on an existing lintel, not a floating black plaque.
	var words=k.label(label,p+Vector3(0,2.03,-.05),15,Color("bfb998"));words.rotation.y=heading
	var body=k.box("PortalBackHull",p+Vector3(0,0,-1.5).rotated(Vector3.UP,heading)+Vector3.UP,Vector3(2.5,2,.30),"dark",true);body.visible=false
	k.lamp(p+Vector3(-.7,2,-.3),true,1.5,5)
static func build(w):
	var k=w.kit;var plan=Layout.layout()
	var City=preload("res://scripts/city_architecture.gd");var Ground=preload("res://scripts/city_ground.gd")
	Ground.build(w,plan);City.materials(k)
	for i in plan.parcels.size():
		var parcel:Dictionary=plan.parcels[i];var b=parcel.building;var p=Vector3(b[0],0,b[1]);var size=Vector2(b[2],b[3])
		if parcel.id in ["clinic","radio"]:City.room(k,p,size,parcel.id)
		elif parcel.get("open",false):
			Site.ruin(k,p,size,i+21,.028)
			City.mound(k,p+Vector3(-size.x*.3,0,-size.y*.3),Vector3(size.x*.4,1.4,size.y*.36),i+20)
			k.box("RuinRemainingUpperFloor",p+Vector3(-size.x*.25,3.1,0),Vector3(size.x*.48,.22,size.y),"district_concrete")
			k.box("RuinUpperWall",p+Vector3(-size.x/2,4.3,0),Vector3(.35,2.4,size.y),"district_brick")
		else:building(k,p,size,int(b[4]),i+1,parcel.id=="depot",parcel.id if parcel.id in ["depot","pump","relay"] else "residential")
	# Foreground windows, floor breaks and different heights continue beyond the slice.
	for n in 8:
		for sign in [-1,1]:
			var p=Vector3(-113+n*31,0,sign*(124+float(n%2)*7));var size=Vector2(21,17)
			if not road_conflict(plan,p,size):building(k,p,size,2+n%3,100+n+10*sign,false,"residential")
	for n in 5:
		for sign in [-1,1]:
			var p=Vector3(sign*143,0,-80+n*36);var size=Vector2(18,26)
			if not road_conflict(plan,p,size):building(k,p,size,3+n%2,140+n+sign,false,"residential")
	City.factory(k);City.basin(k);City.edge(k)
	# Freight rail is a raised dedicated reservation. Only the authored crossing is level.
	Ground.apron(k,Vector2(24,0),Vector2(4.2,200))
	for x in [23.24,24.76]:k.box("FreightRail",Vector3(x,.06,0),Vector3(.07,.12,200),"old_iron")
	for z in range(-99,100):
		if absf(z-8)<4.6:continue
		k.box("FreightSleeper",Vector3(24,.035,z),Vector3(2.6,.07,.18),"wood")
	for span in [[-100,3.5],[12.5,100]]:Site.fence(k,Vector3(24,0,span[0]),Vector3(24,0,span[1]))
	w.campaign_gate_flag="east_crossing_open";w.campaign_gate=k.box("CampaignInnerGate",Vector3(24,1.15,8),Vector3(.20,2.3,9),"corrugated",true)
	w.campaign_gate.set_meta("dynamic",true);w.campaign_gate.set_meta("closed_position",w.campaign_gate.position);w.campaign_gate.set_meta("opening_offset",Vector3(0,0,10))
	for z in [3.2,12.8]:k.box("CrossingGatePost",Vector3(24,1.35,z),Vector3(.40,2.7,.40),"old_iron",true)
	for x in [21,27]:
		k.box("CrossingSignalPost",Vector3(x,1.1,3),Vector3(.14,2.2,.14),"old_iron",true)
		var signal_head=k.cyl("CrossingSignalHead",Vector3(x,2.05,3.12),.16,.10,"red");signal_head.rotation.x=PI/2
		signal_head.set_meta("dynamic",true);signal_head.add_to_group("east_power_signals")
	k.lamp(Vector3(24,3.4,8),true,1.8,8).name="EastCrossingLamp"
	k.lamp(Vector3(14,2.8,22),true,1.5,6).name="EastWorkshopLamp"
	# Portals are setback access pavilions, with level approaches kept clear.
	portal(k,Vector3(-64,0,43),"ЛИНИЯ · ЗАПАД")
	portal(k,Vector3(-18,0,49),"Д–6 · ВХОД")
	portal(k,Vector3(-3,0,15),"ПЕРЕХОД")
	portal(k,Vector3(-49,0,-49),"РЕМОНТ",PI)
	portal(k,Vector3(70,0,-43),"СЕВЕР",PI)
	for x in [-67,-61]:k.box("WestAccessRetainingWall",Vector3(x,.65,44.5),Vector3(.32,1.3,5),"district_concrete",true)
	for x in [-20.5,-15.5]:k.box("D6AccessRetainingWall",Vector3(x,.7,50),Vector3(.30,1.4,4),"district_concrete",true)
	Ground.apron(k,Vector2(-60,38),Vector2(4,12))
	k.box("RoadMapWall",Vector3(-59,1,36.2),Vector3(2.4,2,.25),"district_concrete",true)
	k.box("RoadMapPanel",Vector3(-59,1.35,36.36),Vector3(1.55,.85,.025),"paper")
	for x in [-59.5,-59,-58.5]:k.box("MapRouteInk",Vector3(x,1.36,36.38),Vector3(.04,.60,.01),"dark")
	k.crate(Vector3(-61,0,39.3),Vector3(1.1,.65,.70))
	Site.ruin(k,Vector3(-43,0,21),Vector2(9,7),21,.028)
	Site.ruin(k,Vector3(14,0,25),Vector2(8,7),23,.028)
	k.table(Vector3(-43,0,22.8),2.3);k.box("SpareProtectionModule",Vector3(-43,.92,22.8),Vector3(.52,.22,.40),"metal")
	k.box("RelayServiceCabinet",Vector3(5,.8,-24.8),Vector3(1.1,1.6,.35),"old_iron",true)
	for y in [.7,1.15]:k.box("RelaySwitch",Vector3(5,y,-24.59),Vector3(.28,.15,.05),"cream")
	k.table(Vector3(14,0,24),2.4);k.box("WorkshopHotplate",Vector3(14.7,.82,24),Vector3(.42,.05,.42),"old_iron")
	k.cyl("WorkshopKettle",Vector3(14.7,1.02,24),.16,.35,"metal");k.box("WorkshopToolRoll",Vector3(13.3,.835,24.1),Vector3(.55,.08,.40),"cloth")
	for x in [13,17]:
		k.box("TransformerPlinth",Vector3(x,.24,-36),Vector3(2.8,.48,4),"district_concrete",true)
		k.box("TransformerBody",Vector3(x,1.15,-36),Vector3(1.8,1.3,2.6),"old_iron")
		for z in [-37,-36,-35]:k.cyl("TransformerInsulator",Vector3(x,2,z),.12,.60,"cream")
	for pair in [[Vector3(-5,0,-40),Vector3(20,0,-40)],[Vector3(20,0,-40),Vector3(20,0,-23)]]:Site.fence(k,pair[0],pair[1])
	bandit_shelter(k);k.crate(Vector3(42,0,-10.8),Vector3(1.2,.85,.8))
	# Street furniture and wrecks follow road edges. Clear 3m paths connect each yard.
	for p in [Vector3(-80,0,13.5),Vector3(-26,0,13.5),Vector3(49,0,13.5),Vector3(71,0,-35),Vector3(-104,0,-14)]:wreck(k,p,PI/2 if absf(p.z-13.5)<1 else 0)
	for x in [-110,-83,-55,-25,4,43,77,104]:
		k.cyl("StreetLampStem",Vector3(x,3.1,14),.075,6.2,"old_iron")
		k.pipe(Vector3(x,6.1,14),Vector3(x,6.1,12.3),.05,"old_iron")
		k.box("StreetLampHead",Vector3(x,6.05,12.3),Vector3(.4,.13,.65),"metal")
	for p in [Vector3(-56,0,27),Vector3(-25,0,25),Vector3(-88,0,54),Vector3(43,0,29),Vector3(83,0,51)]:
		k.bench(p,2.7,true,PI);k.cyl("StreetRefuseDrum",p+Vector3(1.8,.35,0),.3,.7,"rust")
	# Collapsed corners and snow-filled courtyards vary the local terrain without
	# hiding ankle-high collision across a door or a marked route.
	for spec in [[-56,25,5,1.6,4],[-37,-47,7,2.3,6],[12,-56,11,2.8,15],[85,0,7,1.4,4],[102,51,8,2.1,8],[-86,53,9,1.2,4],[-5,94,14,2.4,5]]:
		City.mound(k,Vector3(spec[0],0,spec[1]),Vector3(spec[2],spec[3],spec[4]),int(spec[0]))
	for p in [Vector3(-57,0,54),Vector3(-23,0,55),Vector3(11,0,30),Vector3(52,0,55),Vector3(-92,0,20)]:
		k.cyl("BareBirchTrunk",p+Vector3.UP*2.1,.12,4.2,"wood")
		for v in [Vector3(-.9,3.2,.3),Vector3(.7,4.6,-.5),Vector3(.2,3.6,.8)]:k.pipe(p+Vector3.UP*2,p+v,.04,"wood")
	# Fade actual architecture over the player, including the newly enterable ruins.
	for mesh in w.find_children("*","MeshInstance3D",true,false):
		if mesh.material_override is StandardMaterial3D and (mesh.global_transform*mesh.get_aabb()).end.y>2.1 and mesh.get_meta("design_id","")!="CityEdgeBackstop":mesh.set_meta("view_occluder",true)
	k.finish_walls()

static func wreck(k,p:Vector3,heading:float=0):
	var root=Node3D.new();root.name="AbandonedUtilityCar";root.position=p;root.rotation.y=heading;k.root.add_child(root)
	k.box("CarChassis",Vector3(0,.44,0),Vector3(1.6,.5,3.7),"old_iron",false,root)
	k.box("CarBonnet",Vector3(0,.78,1.1),Vector3(1.52,.24,1.2),"rust",false,root)
	k.box("CarCabin",Vector3(0,1.05,-.25),Vector3(1.42,.8,1.85),"exterior_glass",false,root)
	k.box("CarRoof",Vector3(0,1.5,-.25),Vector3(1.56,.10,2),"rust",false,root)
	k.box("CarRoofSnow",Vector3(0,1.57,-.25),Vector3(1.42,.04,1.75),"surface_snow",false,root)
	for x in [-.74,.74]:
		for z in [-1.2,1.2]:
			k.box("CarWindowPillar",Vector3(x,1.05,z*.65),Vector3(.07,.85,.08),"rust",false,root)
			var wheel=k.cyl("FlatCarTyre",Vector3(x,.30,z),.30,.16,"dark",root);wheel.rotation.z=PI/2
	for x in [-.55,.55]:k.box("BrokenCarLamp",Vector3(x,.70,1.87),Vector3(.3,.15,.05),"cream",false,root)
	var across=absf(sin(heading))>.7
	var hull=k.box("CarCollision",p+Vector3.UP*.65,Vector3(3.7,1.3,1.6) if across else Vector3(1.6,1.3,3.7),"dark",true);hull.visible=false

static func streetscape(k):
	# Pavements stop before junctions and never cross a doorway or the railway.
	for spec in [[-18,-3,2.1,30],[-5,38,2.1,20],[-35,13,19,1.8],[6,13,23,1.8],[58,13,25,1.8]]:
		k.box("WornPavement",Vector3(spec[0],.035,spec[1]),Vector3(spec[2],.07,spec[3]),"district_concrete")
	for p in [Vector3(-29,0,15),Vector3(10,0,51),Vector3(68,0,23),Vector3(-66,0,-15)]:wreck(k,p,PI/2 if p.x<0 else 0)
	for x in [-67,-53,-31,3,39,65]:
		k.cyl("StreetLampStem",Vector3(x,2.6,15),.065,5.2,"old_iron")
		k.pipe(Vector3(x,5.1,15),Vector3(x,5.1,13.8),.045,"old_iron")
		k.box("BrokenStreetLampHead",Vector3(x,5.05,13.8),Vector3(.4,.13,.65),"metal")
	# Distinct yards: pipe stock at the waterworks, loading apron at the depot.
	Site.fence(k,Vector3(-69,0,-22),Vector3(-69,0,-43));Site.fence(k,Vector3(-68,0,-43),Vector3(-51,0,-43))
	for z in [-27,-29,-31]:
		for row in 2:k.pipe(Vector3(-68,.28+row*.36,z),Vector3(-64,.28+row*.36,z),.17,"rust")
	for p in [Vector3(56,0,34),Vector3(73,0,38),Vector3(-65,0,-25)]:
		k.crate(p,Vector3(1.1,.8,.8));k.crate(p+Vector3(1.5,0,0),Vector3(.9,.7,1.1))
	for x in [-72,-68,-58,-54,-33,-28,4,8,44,48,61,69]:
		var z=18.0+float(posmod(int(x)*7,5))
		for n in 3:
			var q=Vector3(x+.35*n,.04,z+.20*n)
			k.pipe(q,q+Vector3(.12,.35+.1*n,.07),.012,"wood")
	for p in [Vector3(-67,0,32),Vector3(-36,0,-12),Vector3(3,0,29),Vector3(57,0,20)]:
		for n in 8:
			var piece=k.box("StreetRubble",p+Vector3((n%4)*.35,.07,floori(n/4.0)*.4),Vector3(.3,.13,.21),"district_brick");piece.rotation.y=n*.82
	k.bench(Vector3(7,0,31),2.4,true,PI)
	k.cyl("StreetRefuseDrum",Vector3(8.8,.35,31),.3,.7,"rust")
	# Two low retaining walls explain the descending underground approaches.
	for x in [-67,-61]:k.box("WestAccessRetainingWall",Vector3(x,.65,44.5),Vector3(.32,1.3,5),"district_concrete",true)
	for x in [-20.5,-15.5]:k.box("D6AccessRetainingWall",Vector3(x,.7,50),Vector3(.30,1.4,4),"district_concrete",true)

static func bandit_shelter(k):
	# Human bandits live here: a repaired workshop, kitchen, beds, weapons and stores.
	Site.ruin(k,Vector3(42,0,-17),Vector2(10.5,10),42,.014)
	for x in [38.5,41,43.5,46]:
		k.box("ShelterCeilingPanel",Vector3(x,2.8,-20),Vector3(2.45,.12,4.2),"corrugated")
		k.box("ShelterCeilingSnow",Vector3(x,2.9,-20),Vector3(2.30,.04,4),"shelter_snow")
	for x in [43.5,45.3]:k.bed(Vector3(x,.014,-20),"cloth")
	k.table(Vector3(39,.014,-16.5),2.1)
	k.box("BanditStove",Vector3(38.2,.65,-20.5),Vector3(.65,1,.65),"old_iron",true)
	k.pipe(Vector3(38.2,1.1,-20.5),Vector3(38.2,3.7,-20.5),.09,"rust")
	k.box("StoveDoor",Vector3(38.2,.6,-20.12),Vector3(.40,.28,.06),"metal")
	for p in [Vector3(39.7,0,-20.7),Vector3(41,0,-20.7)]:k.crate(p+Vector3.UP*.014,Vector3(.8,.7,.8))
	k.box("ShelterBlanketScreen",Vector3(42,1.3,-19),Vector3(.05,2.2,3.4),"cloth",true)
	# Perimeter has a guarded main gate and a narrower service gap on the west.
	for segment in [[Vector3(30,0,-29),Vector3(30,0,-23)],[Vector3(30,0,-20),Vector3(30,0,-2)],[Vector3(57,0,-29),Vector3(57,0,-2)],[Vector3(30,0,-29),Vector3(57,0,-29)],[Vector3(30,0,-2),Vector3(35,0,-2)],[Vector3(40,0,-2),Vector3(57,0,-2)]]:Site.fence(k,segment[0],segment[1])
	for spec in [[30,-26,.10,5.5],[30,-11,.10,17.5],[57,-15.5,.10,26.5],[43.5,-29,26.5,.10],[32.5,-2,4.5,.10],[48.5,-2,16.5,.10]]:
		k.box("CampRepairedSheetFence",Vector3(spec[0],.75,spec[1]),Vector3(spec[2],1.5,spec[3]),"corrugated")
	for p in [Vector3(33,0,-13),Vector3(47,0,-6)]:
		k.crate(p,Vector3(2,1.5,1.2));k.crate(p+Vector3(-.3,1.5,0),Vector3(1,.5,.8))
	for p in [Vector3(54,0,-16),Vector3(54,0,-18),Vector3(55.5,0,-16)]:
		k.cyl("BanditWaterDrum",p+Vector3.UP*.5,.37,1,"old_iron")
		k.box("DrumFootprint",p+Vector3.UP*.5,Vector3(.74,1,.74),"dark",true).visible=false
	# Outside cooking station faces the open yard, away from walking routes.
	k.box("CampHearth",Vector3(50,.12,-4),Vector3(1.2,.24,1.1),"district_brick",true)
	k.cyl("CampCookingPot",Vector3(50,.65,-4),.30,.45,"old_iron")
	k.ellipsoid("CampGlowingCoals",Vector3(50,.28,-4),Vector3(.32,.07,.28),"warm_light")
	for x in [49.4,50.6]:k.box("PotSupport",Vector3(x,.55,-4),Vector3(.06,.90,.06),"metal")
	k.pipe(Vector3(49.4,1,-4),Vector3(50.6,1,-4),.035,"metal")
	k.lamp(Vector3(50,.45,-4),true,.65,4)
	k.table(Vector3(54,0,-5),1.7);k.bench(Vector3(54,0,-3.8),1.7,true,PI)
	for z in [-10,-8]:k.crate(Vector3(55,0,z),Vector3(1,.65,1))
	for x in [32,35]:k.box("CampClothesPole",Vector3(x,1.3,-26),Vector3(.06,2.6,.06),"wood")
	k.pipe(Vector3(32,2.5,-26),Vector3(35,2.5,-26),.015,"dark")
	for x in [32.6,33.6,34.6]:k.box("DryingCampCloth",Vector3(x,2.05,-26),Vector3(.6,.8,.03),"cloth")
	# Rough grey paint on the existing gatepost, with no floating room-name sign.
	k.box("GreyDogGateMark",Vector3(34.8,1.2,-1.95),Vector3(.28,.50,.035),"cream")
