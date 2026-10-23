extends RefCounted
## Roads and parcels are authored before furnishings. All positions are metres.
const Layout=preload("res://scripts/east_district.gd")
const Site=preload("res://scripts/surface_site.gd")
const Architecture=preload("res://scripts/outdoor_architecture.gd")
static func position(a:Array,y:float=0)->Vector3:return Vector3(a[0],y,a[1])
static func building(k,p:Vector3,size:Vector2,floors:int,seed:int,north_door:bool=false):
	# Full facade modules have an actual door opening at ground level.
	var root=Node3D.new();root.name="DistrictBuilding%d"%seed;root.position=p;k.root.add_child(root)
	if north_door:root.rotation.y=PI
	var height=floors*2.8;var finish="district_ochre" if seed%3==1 else ("district_brick" if seed%3==2 else "district_concrete")
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
	for n in 3:
		var z=-size.y/2+size.y/3*(n+.5);var span=size.x*(.62 if n==seed%3 else .91)
		k.box("PartialRoof",Vector3((size.x-span)/2,height+.05,z),Vector3(span,.14,size.y/3-.06),"corrugated",false,root)
		k.box("RoofSnow",Vector3((size.x-span)/2,height+.15,z),Vector3(span-.15,.06,size.y/3-.19),"surface_snow",false,root)
		k.box("RoofJoist",Vector3(0,height-.05,z),Vector3(size.x,.16,.12),"old_iron",false,root)
	for z in [-size.y/2,size.y/2]:k.box("RoofParapet",Vector3(0,height+.22,z),Vector3(size.x,.34,.25),finish,false,root)
	for x in [-size.x/2,size.x/2]:k.box("RoofParapet",Vector3(x,height+.22,0),Vector3(.25,.34,size.y),finish,false,root)
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
	var k=w.kit;var plan=Layout.layout();var a=plan.bounds
	Site.ground(w,Rect2(a[0],a[1],a[2],a[3]),false)
	w.get_node("DistantSnow").mesh.size=Vector3(340,.12,280)
	k.mats.surface_road.set_shader_parameter("asphalt_map",load("res://assets/visual/district_asphalt.png"))
	for entry in [["district_concrete","district_concrete"],["district_ochre","district_ochre"],["district_brick","district_brick"]]:
		Site.material(k,entry[0],"res://assets/visual/"+entry[1]+".png",Color.WHITE)
		k.mats[entry[0]].uv1_scale=Vector3.ONE*.38
		k.mats[entry[0]].texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	Site.material(k,"shelter_snow","res://assets/visual/packed_snow.png",Color("aab5bd"))
	# Roads come first. Intersections are flush; no collision kerb crosses a junction.
	for road in plan.roads:
		for i in road.points.size()-1:Site.road(k,position(road.points[i]),position(road.points[i+1]),road.width)
	# The original road helper has interrupted low kerbs, all below the player's step limit.
	for i in plan.parcels.size():
		var parcel:Dictionary=plan.parcels[i];var b=parcel.building
		if parcel.id=="greyhound_camp":continue
		building(k,Vector3(b[0],0,b[1]),Vector2(b[2],b[3]),int(b[4]),i+1,parcel.id=="depot")
	# Additional residential volume and workshop ruins give the street a different silhouette.
	building(k,Vector3(30,0,43),Vector2(7,13),2,14)
	Site.ruin(k,Vector3(-43,0,21),Vector2(9,7),21,.014)
	Site.ruin(k,Vector3(14,0,25),Vector2(8,7),23,.014)
	for x in [23.24,24.76]:k.box("FreightRail",Vector3(x,.045,0),Vector3(.07,.09,118),"old_iron")
	for z in range(-58,59):
		if absf(z-8)<4.6:continue
		k.box("FreightSleeper",Vector3(24,.025,z),Vector3(2.6,.05,.18),"wood")
	for span in [[-60,3.5],[12.5,60]]:Site.fence(k,Vector3(24,0,span[0]),Vector3(24,0,span[1]))
	w.campaign_gate_flag="east_crossing_open";w.campaign_gate=k.box("CampaignInnerGate",Vector3(24,1.15,8),Vector3(.20,2.3,9),"corrugated",true)
	w.campaign_gate.set_meta("dynamic",true);w.campaign_gate.set_meta("closed_position",w.campaign_gate.position);w.campaign_gate.set_meta("opening_offset",Vector3(0,0,10))
	for z in [3.2,12.8]:k.box("CrossingGatePost",Vector3(24,1.35,z),Vector3(.40,2.7,.40),"old_iron",true)
	for x in [21,27]:
		k.box("CrossingSignalPost",Vector3(x,1.1,3),Vector3(.14,2.2,.14),"old_iron",true)
		var signal_head=k.cyl("CrossingSignalHead",Vector3(x,2.05,3.12),.16,.10,"red");signal_head.rotation.x=PI/2
		signal_head.set_meta("dynamic",true);signal_head.add_to_group("east_power_signals")
	k.lamp(Vector3(24,3.4,8),true,1.8,8).name="EastCrossingLamp"
	k.lamp(Vector3(14,2.8,22),true,1.5,6).name="EastWorkshopLamp"
	# Entrances belong to structures/retaining walls; the arrival is in front of the door.
	portal(k,Vector3(-64,0,43),"ЛИНИЯ · ЗАПАД")
	portal(k,Vector3(-18,0,49),"Д–6 · ВХОД")
	portal(k,Vector3(-3,0,15),"ПЕРЕХОД")
	portal(k,Vector3(-49,0,-49),"РЕМОНТ",PI)
	portal(k,Vector3(65,0,-49),"СЕВЕР",PI)
	# Mapping table and supply chest sit beside the route, with clear approaches.
	k.box("RoadMapWall",Vector3(-59,1,36.2),Vector3(2.4,2,.25),"district_concrete",true)
	k.box("RoadMapPanel",Vector3(-59,1.35,36.36),Vector3(1.55,.85,.025),"paper")
	for x in [-59.5,-59,-58.5]:k.box("MapRouteInk",Vector3(x,1.36,36.38),Vector3(.04,.60,.01),"dark")
	k.crate(Vector3(-61,0,39.3),Vector3(1.1,.65,.70))
	k.table(Vector3(-43,0,22.8),2.3);k.box("SpareProtectionModule",Vector3(-43,.92,22.8),Vector3(.52,.22,.40),"metal")
	k.box("RelayServiceCabinet",Vector3(5,.8,-24.8),Vector3(1.1,1.6,.35),"old_iron",true)
	for y in [.7,1.15]:k.box("RelaySwitch",Vector3(5,y,-24.59),Vector3(.28,.15,.05),"cream")
	k.table(Vector3(14,0,24),2.4)
	k.box("WorkshopHotplate",Vector3(14.7,.82,24),Vector3(.42,.05,.42),"old_iron")
	k.cyl("WorkshopKettle",Vector3(14.7,1.02,24),.16,.35,"metal")
	k.box("WorkshopToolRoll",Vector3(13.3,.835,24.1),Vector3(.55,.08,.40),"cloth")
	k.box("WorkshopViceBase",Vector3(14,.825,24),Vector3(.45,.06,.30),"metal")
	for x in [13.85,14.15]:k.box("WorkshopViceJaw",Vector3(x,.96,24),Vector3(.07,.22,.30),"old_iron")
	k.pipe(Vector3(13.6,.92,24),Vector3(14.35,.92,24),.025,"metal")
	k.box("WorkshopToolRail",Vector3(14,1.6,21.72),Vector3(2,.07,.07),"wood")
	for x in [13.3,13.8,14.3,14.8]:k.box("HangingWorkshopTool",Vector3(x,1.38,21.79),Vector3(.05,.40,.06),"metal")
	k.crate(Vector3(42,0,-10.8),Vector3(1.2,.85,.8))
	# A decommissioned power yard reads as a power facility from several angles.
	for x in [13,17]:
		k.box("TransformerPlinth",Vector3(x,.24,-34),Vector3(2.8,.48,4),"district_concrete",true)
		k.box("TransformerBody",Vector3(x,1.15,-34),Vector3(1.8,1.3,2.6),"old_iron")
		for z in [-35,-34,-33]:k.cyl("TransformerInsulator",Vector3(x,2,z),.12,.60,"cream")
	for x in [-74,-41,-8,28,72]:
		k.cyl("RoadUtilityPole",Vector3(x,2.4,12.2),.10,4.8,"old_iron")
		k.pipe(Vector3(x,4.1,12.2),Vector3(x+1.5,4.1,12.2),.035,"rust")
	for pair in [[-74,-41],[-41,-8],[-8,28],[28,72]]:k.pipe(Vector3(pair[0],4.1,12.2),Vector3(pair[1],4.1,12.2),.012,"dark")
	# Service pipes follow the industrial wall, not diagonal shortcuts across streets.
	for x in [-72,-56,-40,-24]:k.box("PipeRackFoot",Vector3(x,1.5,-53),Vector3(.18,3,.18),"old_iron",true)
	k.pipe(Vector3(-75,2.9,-53),Vector3(-20,2.9,-53),.20,"rust")
	k.cyl("WaterworksChimney",Vector3(-73,6,-38),.65,12,"district_brick")
	for p in [Vector3(-72,0,26),Vector3(-53,0,-7),Vector3(-8,0,36),Vector3(48,0,47),Vector3(72,0,-31)]:
		k.cyl("BareBirchTrunk",p+Vector3.UP*1.7,.11,3.4,"wood")
		for v in [Vector3(-.7,2.6,.3),Vector3(.5,3.5,-.4)]:k.pipe(p+Vector3.UP*1.8,p+v,.035,"wood")
	# Snow and loose rubble stay against facades; no decoration occupies a doorway.
	for parcel in plan.parcels:
		var b=parcel.building;var base=Vector3(b[0],0,b[1])
		for side in [-1,1]:
			k.ellipsoid("FacadeSnowDrift",base+Vector3(side*(b[2]/2+.6),.06,0),Vector3(.6,.20,b[3]*.40),"snowbank")
			for n in 4:
				var at=base+Vector3(side*(b[2]/2+.35),.08,-b[3]*.30+n*.8)
				var brick=k.box("FacadeFootRubble",at,Vector3(.32,.16,.22),"district_brick");brick.rotation.y=n*.72
	for p in [Vector3(-70,0,-53),Vector3(15,0,-52),Vector3(51,0,-38),Vector3(45,0,54)]:
		Architecture.block(k,p,Vector2(7,8),2,31+int(abs(p.x)))
		var collision=k.box("SceneryFootprint",p+Vector3.UP*1.5,Vector3(7.2,3,8.2),"dark",true);collision.visible=false
	streetscape(k)
	bandit_shelter(k)
	# Accessible workshops fade their roofs and foreground masonry visually;
	# their physical cover and guard sight lines keep the original collisions.
	for mesh in w.find_children("*","MeshInstance3D",true,false):
		if mesh.get_meta("design_id","") in ["RuinWindowSill","BrokenMasonryPier","FracturedWindowLintel","RuinRearWall","RuinDoorCheek","BareRuinJoist","ShelterCeilingPanel","ShelterCeilingSnow"]:mesh.set_meta("view_occluder",true)
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
