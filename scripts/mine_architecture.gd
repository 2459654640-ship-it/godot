extends RefCounted
## The service gallery reaches a separate shaft landing and a backup transfer chamber.
const Props=preload("res://scripts/production_props.gd")

static func build(w):
 var k=w.kit
 Props.prepare(k)
 Props.material(k,"mine_cast_iron","painted_iron","777768",.7)
 k.mats.old_iron=k.mats.mine_cast_iron
 landing(w)
 reserve(w)
 # Metal lintels span the new openings. No collider or raised sill crosses either route.
 for opening in [[Vector3(-28,0,0),true,3.6],[Vector3(-23,0,-22),false,3.1]]:
  var p:Vector3=opening[0];var width:float=opening[2]
  var along:Vector3=Vector3.BACK if opening[1] else Vector3.RIGHT
  var size=Vector3(.34,2.4,.17) if opening[1] else Vector3(.17,2.4,.34)
  for side in [-1,1]:k.box("MinePortalJamb",p+Vector3.UP*1.2+along*side*(width*.5+.07),size,"dark_steel")
  k.box("MinePortalHeader",p+Vector3.UP*2.51,Vector3(.40,.21,width+.24) if opening[1] else Vector3(width+.24,.21,.40),"dark_steel").set_meta("view_occluder",true)
 # Wet timber travelway turns toward the hoist; the trolley rail stays in its own bay.
 for z in [-14.4,-10.4,-6.4,-2.4,1.6,5.6]:
  k.box("GalleryCableMarker",Vector3(-18.17,1.88,z),Vector3(.022,.23,.48),"paper")
 for z in [-15,-11,-7,-3,1,5]:
  k.pipe(Vector3(-18.26,2.24,z-1.75),Vector3(-18.26,2.24,z+1.75),.045,"rust")

static func landing(w):
 var k=w.kit
 var steel=k.mats.dark_steel
 steel.roughness=.82
 k.box("HoistLandingConcrete",Vector3(-32.5,.021,-1),Vector3(8.72,.02,11.72),"institution_floor")
 # Enclosed shaft sits behind its own sill. The playable waiting floor is level.
 k.box("ShaftConcreteBrow",Vector3(-32.7,.24,-6.15),Vector3(5.85,.48,1.33),"concrete",true)
 k.box("ShaftRecess",Vector3(-32.7,.63,-6.70),Vector3(4.5,.80,.30),"dark")
 for x in [-35.18,-30.22]:
  Props.bevel(k,"ShaftSteelPost",Vector3(x,1.66,-5.75),Vector3(.30,3.32,.36),"dark_steel",null,true)
  for y in [.25,.90,2.40]:k.box("ShaftPostPlate",Vector3(x,y,-5.54),Vector3(.46,.18,.065),"metal")
 k.box("ShaftCageHeader",Vector3(-32.7,2.89,-5.74),Vector3(5.18,.40,.28),"dark_steel").set_meta("view_occluder",true)
 var pulley=k.cyl("HoistHeadSheave",Vector3(-35.37,2.88,-5.88),.54,.27,"old_iron")
 pulley.rotation.z=PI/2;pulley.mesh.radial_segments=32;pulley.set_meta("view_occluder",true)
 for y in [1.18,2.43]:k.pipe(Vector3(-36.2,y,-6.48),Vector3(-29.05,y,-6.48),.04,"dark_steel")
 k.box("ShaftGrilleBacking",Vector3(-32.7,1.54,-6.57),Vector3(4.65,2.23,.22),"dark")
 k.box("LiftInterlock",Vector3(-32.7,1.31,-5.75),Vector3(4.65,2.64,.11),"dark_steel",true).visible=false
 for x in range(19):
  k.box("LiftCageBar",Vector3(-34.95+x*.25,1.61,-5.74),Vector3(.041,2.13,.07),"old_iron")
 for y in [.60,1.50,2.65]:k.box("LiftCageCrossRail",Vector3(-32.7,y,-5.70),Vector3(4.66,.07,.10),"dark_steel")
 k.box("HoistWinchPlinth",Vector3(-35.68,.30,-3.65),Vector3(1.83,.60,2.1),"concrete",true)
 var winch=k.cyl("HoistCableDrum",Vector3(-35.68,1.02,-3.65),.45,1.36,"old_iron");winch.rotation.z=PI/2;winch.mesh.radial_segments=32
 for x in [-36.37,-34.99]:
  var flange=k.cyl("HoistDrumFlange",Vector3(x,1.02,-3.65),.56,.10,"rust");flange.rotation.z=PI/2;flange.mesh.radial_segments=32
 for i in 10:
  var turn=k.cyl("HoistSpoolWinding",Vector3(-36.21+i*.116,1.02,-3.65),.472,.040,"dark_steel");turn.rotation.z=PI/2
 k.pipe(Vector3(-35.65,1.40,-3.79),Vector3(-35.65,2.63,-5.48),.034,"dark_steel")
 k.box("LiftOperatorDesk",Vector3(-32.8,.53,-3.77),Vector3(1.10,1.06,.64),"dark_steel",true)
 Props.panel_face(k,k.root,Vector3(-32.8,1.02,-3.43),Vector2(.82,.55),1)
 indicator(k,"MainHoistReady",Vector3(-30.13,1.97,-5.51),"warm_light")
 indicator(k,"MainHoistFault",Vector3(-30.13,1.79,-5.51),"warning_light")
 k.label("ПОДЪЁМ",Vector3(-32.7,2.36,-5.64),23,Color("c4b899"))
 k.bench(Vector3(-35.52,0,3.85),2.25,true,PI)
 # Shift papers and spare safety lamps sit on a narrow wall-side counter.
 k.box("ShiftCounterLeg",Vector3(-36.43,.45,-.48),Vector3(.30,.90,2.05),"dark_steel",true)
 Props.bevel(k,"ShiftCounter",Vector3(-36.40,.92,-.48),Vector3(.72,.16,2.33),"warm_wood")
 for z in [-1.26,-.81]:
  k.box("FoldedShiftDocket",Vector3(-36.32,1.013,z),Vector3(.39,.029,.30),"paper").rotation.y=.12
 for z in [-.25,.19]:
  k.cyl("MinersLampBase",Vector3(-36.3,1.057,z),.11,.095,"dark_steel")
  k.cyl("MinersLampGlass",Vector3(-36.3,1.16,z),.065,.15,"cream")
  k.cyl("MinersLampCrown",Vector3(-36.3,1.25,z),.10,.05,"old_iron")
 for z in [1.20,2.13,3.05]:k.box("LandingDrainCover",Vector3(-35.02,.035,z),Vector3(.24,.009,.90),"dark_steel")
 for z in [1.2,2.13,3.05]:
  for i in 6:k.box("LandingDrainSlot",Vector3(-35.02,.041,z-.35+i*.14),Vector3(.15,.004,.027),"dark")
 for x in [-34.5,-33.5,-32.5,-31.5,-30.5]:k.box("LoadingStandbackStripe",Vector3(x,.034,-4.83),Vector3(.64,.004,.11),"brass")
 for p in [Vector3(-36.66,2.36,-4.0),Vector3(-30,2.39,-5.4),Vector3(-34,2.45,4.72)]:
  k.lamp(p,true,1.7,7).shadow_enabled=true
 for x in [-35.8,-29.4]:
  k.box("ShaftPortalColumn",Vector3(x,1.45,-5.30),Vector3(.26,2.90,.39),"dark_steel",true)

static func reserve(w):
 var k=w.kit
 k.box("ReserveTransferApron",Vector3(-23,.024,-25.50),Vector3(9.7,.026,6.74),"junction_stone")
 # A raised cable bay is behind the rail. The east and west staging lanes are uninterrupted.
 k.box("TransferLoadingDeck",Vector3(-23,.12,-27.30),Vector3(5.8,.24,2.25),"dark_steel",true)
 for x in [-25.65,-20.35]:
  k.box("TransferDoorJamb",Vector3(x,1.25,-28.59),Vector3(.27,2.50,.50),"dark_steel")
 k.box("TransferDoorHeader",Vector3(-23,2.53,-28.58),Vector3(5.56,.26,.51),"dark_steel")
 k.box("TransferClosedShutter",Vector3(-23,1.31,-28.66),Vector3(4.95,2.48,.10),"corrugated")
 for x in [-24.84,-23,-21.16]:k.box("TransferShutterStiffener",Vector3(x,1.32,-28.57),Vector3(.07,2.45,.09),"dark_steel")
 k.label("РЕЗЕРВНЫЙ ПОДЪЁМ",Vector3(-23,2.54,-28.29),19,Color("c9c6ad"))
 indicator(k,"ReserveHoistReady",Vector3(-20.29,1.84,-28.30),"cold_light")
 for x in [-26.60,-19.40]:
  k.box("TransferWallRail",Vector3(x,1.06,-26.22),Vector3(.075,.075,3.56),"dark_steel")
  for z in [-27.8,-24.6]:k.box("TransferRailPost",Vector3(x,.55,z),Vector3(.075,1.10,.075),"dark_steel",true)
 k.bench(Vector3(-26.88,0,-26.24),2.65,true,PI/2)
 k.crate(Vector3(-19.38,0,-27.10),Vector3(.95,.72,1.1))
 for x in [-27.62,-18.38]:
  var lamp=k.lamp(Vector3(x,2.35,-26.10),false,1.52,7);lamp.shadow_enabled=true;lamp.light_color=Color("a9c8bf")

static func indicator(k,id:String,p:Vector3,material:String):
 if not k.mats.has("warning_light"):
  var red:StandardMaterial3D=k.mats.warm_light.duplicate()
  red.albedo_color=Color("af3628");red.emission=Color("fc5132");k.mats.warning_light=red
 k.box(id+"Socket",p-Vector3(0,0,.035),Vector3(.18,.15,.06),"dark_steel")
 k.box(id,p,Vector3(.12,.09,.025),material).set_meta("dynamic",true)
