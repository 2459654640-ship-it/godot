extends RefCounted
## Structures retain the routes, utility connections and evidence of their former use.
const Ground=preload("res://scripts/city_ground.gd")
const Urban=preload("res://scripts/district_urban.gd")
const City=preload("res://scripts/city_architecture.gd")

static func shelter(k,p:Vector3,size:Vector2):
	var room=Rect2(Vector2(p.x,p.z)-size/2,size)
	var west=room.position.x;var east=room.end.x
	var north=room.position.y;var south=room.end.y
	Ground.apron(k,room.get_center(),size)
	k.box("ShelterWornTerrazzo",p+Vector3.UP*.039,Vector3(size.x-.36,.015,size.y-.36),"city_paving")
	for x in [west,east]:
		k.box("ShelterSideWall",Vector3(x,1.75,p.z),Vector3(.32,3.5,size.y),"district_brick",true)
		k.box("ShelterCableSkirt",Vector3(x+signf(p.x-x)*.21,.6,p.z),Vector3(.09,1.2,size.y-.35),"civic_tile")
	for z in [north,south]:
		var door_x=p.x+1 if z==north else p.x-2
		for span in [Vector2(west,door_x-1.28),Vector2(door_x+1.28,east)]:
			k.box("ShelterEndWing",Vector3((span.x+span.y)/2,1.45,z),Vector3(span.y-span.x,2.9,.34),"district_brick",true)
		k.box("ShelterDoorHead",Vector3(p.x,3.16,z),Vector3(size.x,.55,.36),"district_concrete").set_meta("interior_rect",room)
		for sign in [-1,1]:
			k.box("ShelterDoorJamb",Vector3(door_x+sign*1.29,1.16,z),Vector3(.15,2.32,.42),"old_iron")
	var roof_root=Node3D.new();roof_root.name="ShelterUpperStorey";roof_root.position=p;k.root.add_child(roof_root)
	# Dispatcher's upper floor is stepped back behind a canopy over the platforms.
	for side in [-1,1]:
		k.box("ShelterUpperPartyWall",Vector3(side*4.8,4.55,.5),Vector3(.23,2.1,12),"district_brick",false,roof_root)
		k.box("ShelterUpperCornice",Vector3(0,4.99,.5+side*6),Vector3(9.7,1.21,.24),"district_brick",false,roof_root)
		k.box("ShelterUpperSill",Vector3(0,3.68,.5+side*6),Vector3(9.7,.38,.24),"district_brick",false,roof_root)
		for x in [-3.5,-1.2,1.2,3.5]:
			k.box("ShelterUpperWindow",Vector3(x,4.18,.5+side*6),Vector3(1.72,.65,.20),"exterior_glass",false,roof_root)
			k.box("ShelterUpperPier",Vector3(x+1.04,4.18,.5+side*6),Vector3(.56,.66,.24),"district_brick",false,roof_root)
	k.box("ShelterLowerRoof",Vector3(0,3.50,0),Vector3(size.x+.5,.22,size.y+.5),"old_iron",false,roof_root)
	for x in [-6.13,6.13]:
		k.box("ShelterLowerRoofSnow",Vector3(x,3.64,0),Vector3(2.57,.05,size.y+.17),"district_roof_snow",false,roof_root)
	for z in [-7.5,8.1]:
		k.box("ShelterLowerRoofSnow",Vector3(0,3.64,z),Vector3(9.68,.05,2.85),"district_roof_snow",false,roof_root)
	Urban.roof(k,roof_root,Vector2(9.75,12.3),5.61,"depot",3)
	for mesh in roof_root.find_children("*","MeshInstance3D",true,false):mesh.set_meta("interior_rect",room)
	for z in [-4.5,1.2,6.5]:
		k.box("ShelterCastBeam",p+Vector3(0,3.22,z),Vector3(size.x,.15,.24),"old_iron").set_meta("interior_rect",room)
	# The west counter handled names and departures. The east stall took people
	# off the street, behind a washable privacy wall with two open ends.
	k.box("ShelterPrivacyWall",p+Vector3(1.8,1.15,1.6),Vector3(.2,2.3,6.7),"civic_tile",true)
	for z in [-4.7,3.3,6.2]:k.bench(p+Vector3(-6.2,0,z),2.3,true,PI/2)
	k.table(p+Vector3(-4,0,-3),2.6)
	k.box("PassengerRoll",p+Vector3(-4,.815,-3),Vector3(.51,.035,.37),"paper")
	k.box("PassengerRollCover",p+Vector3(-4.15,.84,-3),Vector3(.24,.02,.37),"cloth")
	k.box("ShelterWashableFloor",p+Vector3(4.58,.053,1.55),Vector3(5.42,.018,13.1),"tile")
	for z in [-2,4.6]:
		k.bed(p+Vector3(5.9,0,z),"cloth")
		k.box("StretcherFoldedCover",p+Vector3(5.9,.58,z+.36),Vector3(.75,.15,.68),"paper")
	for x in [-6.55,-4.65]:
		k.box("DispatchCubby",p+Vector3(x,1.02,-8.79),Vector3(1.36,2.04,.57),"wood",true)
		for y in [.62,1.23,1.80]:
			k.box("CabinetNameCard",p+Vector3(x,y,-8.49),Vector3(.55,.19,.025),"cream")
			k.box("CabinetCupPull",p+Vector3(x+.43,y,-8.43),Vector3(.18,.035,.09),"dark")
	k.box("CivilDefenseFirstAidCabinet",p+Vector3(7.19,1.37,-6.4),Vector3(.33,.96,1.02),"old_iron")
	k.box("FirstAidPaintSquare",p+Vector3(7.014,1.39,-6.4),Vector3(.021,.33,.34),"cream")
	for v in [Vector2(.247,.06),Vector2(.06,.247)]:k.box("FirstAidGreenCross",p+Vector3(6.997,1.39,-6.4),Vector3(.012,v.y,v.x),"civic_tile")
	for z in [4.1,4.7,5.3,5.9,6.5,7.1,7.7]:
		k.box("LuggageQueuePaint",p+Vector3(-3.35,.054,z),Vector3(.067,.008,.37),"cream")
	k.crate(p+Vector3(-4.6,0,8.3),Vector3(1.42,.65,.76))
	k.box("TransitBlanketBundle",p+Vector3(-4.6,.73,8.32),Vector3(1.16,.13,.47),"cloth")
	for y in [.25,.43]:k.pipe(p+Vector3(-7.23,y,-7.5),p+Vector3(-7.23,y,8.8),.042,"old_iron")
	for x in [4.0,5.2]:
		k.box("ShelterAirDuct",p+Vector3(x,2.92,.6),Vector3(.48,.27,15),"old_iron").set_meta("interior_rect",room)
		k.box("ShelterAirGrille",p+Vector3(x,2.65,8.96),Vector3(.66,.46,.12),"old_iron")
		for y in [2.53,2.62,2.71,2.8]:k.box("ShelterAirSlat",p+Vector3(x,y,8.88),Vector3(.58,.035,.025),"metal")
	var lamp=k.lamp(p+Vector3(-4.1,2.55,-9.28),true,1.4,7);lamp.light_color=Color("dfbc89")
	var cold=k.lamp(p+Vector3(5.1,2.60,-9.28),false,1.2,8);cold.light_color=Color("a3bac0")
	k.label("ПУНКТ СБОРА",Vector3(p.x-3.9,2.58,north-.20),16,Color("d2c8a7")).rotation.y=PI

static func public_spaces(k):
	tram_stop(k,Vector3(-65,0,16))
	heating_court(k)
	impact_square(k)

static func tram_stop(k,p:Vector3):
	# The passenger platform stands outside the vehicle lane. Asphalt tram rails
	# end in crushed ballast before the central freight junction.
	for z in [7.28,8.72]:
		k.box("AbandonedTramRail",Vector3(-73.5,.025,z),Vector3(55,.05,.052),"old_iron")
		k.box("TramRailFlangeway",Vector3(-73.5,.015,z+.075),Vector3(55,.03,.067),"dark")
	Ground.apron(k,Vector2(p.x,p.z),Vector2(25,3.3))
	k.box("TramShelterBack",p+Vector3(-1,1.12,1.32),Vector3(8.6,2.24,.24),"civic_tile",true)
	k.box("TramShelterSteelRoof",p+Vector3(-1,2.55,.3),Vector3(9.3,.13,2.45),"old_iron")
	k.box("TramCanopySnow",p+Vector3(-1,2.64,.3),Vector3(9.0,.05,2.26),"district_roof_snow")
	for x in [-5.38,3.37]:
		k.box("TramShelterPillar",p+Vector3(x,1.27,-.70),Vector3(.19,2.54,.19),"old_iron",true)
	k.bench(p+Vector3(-1,0,.72),5.2,true,PI)
	k.box("OriginalRouteEnamel",p+Vector3(-5.25,1.65,1.17),Vector3(.63,.8,.05),"cream")
	var route=k.label("17",p+Vector3(-5.25,1.74,1.13),28,Color("314342"));route.rotation.y=PI
	k.box("TramPlatformEdge",p+Vector3(0,.041,-1.29),Vector3(24.8,.013,.12),"cream")
	for dx in [-10.3,10.9]:
		k.box("PlatformClockPost",p+Vector3(dx,1.19,1.1),Vector3(.09,2.38,.09),"old_iron",true)
		k.box("OriginalSchedule",p+Vector3(dx,2.14,1.1),Vector3(.54,.55,.09),"civic_tile")
		for y in [1.99,2.09,2.19]:k.box("ScheduleLine",p+Vector3(dx,y,1.045),Vector3(.36,.018,.013),"cream")
	tram_car(k,Vector3(-88,0,8))

static func tram_car(k,c:Vector3):
	# A late-run single carriage, with the passenger side facing the platform.
	# Its real wheel gauge and dead catenary are aligned to the inset street rail.
	var root=Node3D.new();root.name="AbandonedCityTram";root.position=c;k.root.add_child(root)
	k.box("TramSteelUnderframe",Vector3(0,.48,0),Vector3(12.65,.32,2.40),"old_iron",false,root)
	City.hull(k,c+Vector3.UP*1.28,Vector3(12.66,2.24,2.45),"AbandonedTramHull")
	for x in [-4.3,-2.7,2.7,4.3]:
		k.box("TramAxle",Vector3(x,.35,0),Vector3(.21,.18,1.72),"old_iron",false,root)
		for side in [-1,1]:
			var wheel=k.cyl("TramRailWheel",Vector3(x,.34,side*.72),.31,.19,"dark",root)
			wheel.rotation.x=PI/2
			k.cyl("TramAxleBox",Vector3(x,.34,side*.855),.146,.066,"old_iron",root).rotation.x=PI/2
	for side in [-1,1]:
		var z=side*1.24
		k.box("TramPressedBelt",Vector3(0,.95,z),Vector3(12.6,.59,.13),"red",false,root)
		k.box("TramCreamPaintLine",Vector3(0,1.268,z+side*.069),Vector3(12.52,.12,.017),"cream",false,root)
		k.box("TramRoofHeader",Vector3(0,2.27,z),Vector3(12.6,.34,.15),"frosted_steel",false,root)
		for i in 10:
			var x=(i-4.5)*1.25
			k.box("CarriageWindowPier",Vector3(x-.624,1.77,z),Vector3(.12,.92,.15),"frosted_steel",false,root)
			if side>0 and i in [1,5,8]:
				k.box("TramDoorPocket",Vector3(x,1.42,z+.082),Vector3(1.13,1.59,.035),"dark",false,root)
				for dx in [-.278,.278]:
					k.box("FoldingTramDoor",Vector3(x+dx,1.42,z+.106),Vector3(.537,1.54,.043),"frosted_steel",false,root)
					k.box("TramDoorVisionGlass",Vector3(x+dx,1.72,z+.13),Vector3(.319,.62,.015),"exterior_glass",false,root)
					k.box("TramDoorHandle",Vector3(x+dx*.32,1.35,z+.158),Vector3(.033,.23,.032),"old_iron",false,root)
				k.box("ScoredTramStep",Vector3(x,.53,z+.09),Vector3(1.13,.063,.23),"old_iron",false,root)
			else:
				k.box("RecessedTramGlass",Vector3(x,1.75,z-side*.030),Vector3(1.10,.75,.063),"exterior_glass",false,root)
				k.box("SpringTramSash",Vector3(x,1.94,z+side*.06),Vector3(1.11,.042,.033),"old_iron",false,root)
		k.box("TramPressedGutter",Vector3(0,2.43,side*1.27),Vector3(12.7,.07,.09),"old_iron",false,root)
	for side in [-1,1]:
		var x=side*6.32
		k.box("TramNoseLower",Vector3(x,1.06,0),Vector3(.16,1.09,2.40),"red",false,root)
		k.box("TramNoseHeader",Vector3(x,2.245,0),Vector3(.16,.34,2.40),"frosted_steel",false,root)
		k.box("TramWindshield",Vector3(x+side*.045,1.78,0),Vector3(.08,.74,2.12),"exterior_glass",false,root)
		for z in [-1.14,0,1.14]:k.box("TramFrontWindowPost",Vector3(x+side*.087,1.80,z),Vector3(.11,.78,.108),"frosted_steel",false,root)
		for z in [-.72,.72]:k.box("TramDulledHeadlamp",Vector3(x+side*.101,.99,z),Vector3(.043,.14,.23),"cream" if side>0 else "red",false,root)
		k.box("BentTramBumper",Vector3(x+side*.15,.61,0),Vector3(.20,.16,2.43),"old_iron",false,root).rotation.z=.02*side
	for n in 12:
		var z0=(n/12.0-.5)*2.60;var z1=((n+1)/12.0-.5)*2.60
		var y0=2.39+.29*cos(z0/1.30*PI/2);var y1=2.39+.29*cos(z1/1.30*PI/2)
		var pitch=Vector2(z1-z0,y1-y0).length()
		var sheet=k.box("CamberedTramRoof",Vector3(0,(y0+y1)/2,(z0+z1)/2),Vector3(12.71,.12,pitch+.008),"frosted_steel",false,root)
		sheet.rotation.x=-atan2(y1-y0,z1-z0)
		if n in [0,1,10,11]:continue
		var snow=k.box("CamberedRoofWindLoad",sheet.position+Vector3(-.15,.088,0),Vector3(10.32+.35*sin(n),.055,pitch+.006),"district_roof_snow",false,root)
		snow.rotation.x=sheet.rotation.x
	for n in [-1.4,1.8]:
		k.box("PantographBase",Vector3(n,2.74,0),Vector3(.82,.12,.74),"old_iron",false,root)
	k.pipe(c+Vector3(-1.43,2.76,0),c+Vector3(.40,3.64,0),.036,"old_iron")
	k.pipe(c+Vector3(.40,3.64,0),c+Vector3(1.86,2.77,0),.032,"old_iron")
	k.pipe(c+Vector3(.4,3.64,-.34),c+Vector3(.4,3.64,.32),.023,"old_iron")
	for x in [-94,-57]:
		k.cyl("DeadTramCatenaryMast",Vector3(x,2.55,5.15),.091,5.10,"old_iron")
		k.pipe(Vector3(x,5.09,5.15),Vector3(x,5.09,8.0),.042,"frosted_steel")
	for span in [[-94.,5.06,-82.5,4.60],[-82.5,4.60,-75.,4.82],[-75.,4.82,-57.,5.06]]:
		k.pipe(Vector3(span[0],span[1],8),Vector3(span[2],span[3],8),.018,"old_iron")

static func heating_court(k):
	Ground.apron(k,Vector2(-48.5,55.15),Vector2(14.2,5.4))
	# Supply and return are paired and turn into the housing foundations.
	for z in [54.2,54.82]:
		k.pipe(Vector3(-55,1.06,z),Vector3(-47,1.06,z),.18,"rust")
		k.pipe(Vector3(-47,1.06,z),Vector3(-47,1.06,51.0),.18,"rust")
	for x in [-54.7,-51,-47.3]:
		k.box("HeatingPipeFoot",Vector3(x,.43,54.50),Vector3(.26,.86,1.12),"district_concrete",true)
		k.box("HeatingPipeSaddle",Vector3(x,.92,54.5),Vector3(.39,.14,1.09),"old_iron")
	City.hull(k,Vector3(-51,1.06,54.5),Vector3(8.35,.4,1.02),"HeatingPipeHull")
	City.hull(k,Vector3(-47,1.06,52.55),Vector3(.40,.4,3.48),"HeatingReturnHull")
	for x in [-54.9,-51.2,-47.4]:
		k.box("HeatingCourtRetaining",Vector3(x,.27,56.36),Vector3(3.45,.54,.26),"district_brick",true)
		k.box("HeatingCourtCoping",Vector3(x,.58,56.36),Vector3(3.49,.08,.43),"district_concrete")
	k.cyl("HeatingIsolationValve",Vector3(-51.4,1.42,54.2),.26,.08,"red")
	k.pipe(Vector3(-51.4,1.08,54.2),Vector3(-51.4,1.40,54.2),.063,"old_iron")

static func impact_square(k):
	var center=Vector3(7,0,-63)
	# Paving stops at the damaged depression. Debris follows the surface grade.
	# One usable pavement meets Workers' Street. Across the impact lie split
	# slabs from the utility island, with open snow around them.
	Ground.apron(k,Vector2(-4.38,-62),Vector2(4.4,17.8))
	Ground.apron(k,Vector2(4.04,-70.98),Vector2(12.3,2.6))
	for i in 9:
		var z=-71.7+i*2.17
		var x=16.5+sin(i*2.16)*1.10
		var slab=k.box("SplitUtilityPaving",Vector3(x,.025,z),Vector3(1.62+.15*cos(i),.05,1.93),"city_paving")
		slab.rotation.y=.12*sin(i*2.10)
	for x in [10.8,14.9,17.4]:
		k.box("BrokenIslandCoping",Vector3(x,.11,-55.28),Vector3(1.7,.22,.32),"district_concrete")
	for entry in [[-4.9,2.8,3.8,1.2,1.8],[1.9,-3.5,4.4,1.5,2.2],[4.5,2.7,3.9,1.8,2.8]]:
		var debris=center+Vector3(entry[0],0,entry[1])
		debris.y=Ground.height_at(Vector2(debris.x,debris.z))
		City.mound(k,debris,Vector3(entry[2],entry[3],entry[4]),roundi(entry[0]*3))
	for side in [-1,1]:
		var x=12+side*.32
		k.pipe(Vector3(x,.15,-64),Vector3(x,.6,-65.4),.055,"rust")
		k.pipe(Vector3(x,.6,-65.4),Vector3(x-side*.46,.89,-66.4),.055,"old_iron")
	for z in [-67.1,-59]:
		k.box("ScorchedUtilityMarker",Vector3(14,.58,z),Vector3(.14,1.16,.14),"old_iron",true)
		k.box("WarningEnamel",Vector3(14,1.02,z+.10),Vector3(.46,.35,.05),"cream")
