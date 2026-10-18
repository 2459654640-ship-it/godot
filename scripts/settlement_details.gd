extends RefCounted
## Settlements are places to live: rooms communicate through several routes,
## while trackwork, heating, cooking and water supply have visible destinations.
const Detail=preload("res://scripts/facility_detail.gd")
static func rug(k,p:Vector3,size:Vector2):
 var m=k.mats.cloth.duplicate();m.albedo_texture=load("res://assets/visual/rug.png");m.uv1_triplanar=false;m.uv1_world_triplanar=false;m.uv1_scale=Vector3.ONE;m.normal_enabled=false
 var floor=k.box("WovenRug",p+Vector3(0,.032,0),Vector3(size.x,.018,size.y),"cloth");floor.material_override=m;floor.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
static func radiator(k,p:Vector3,width:float=2.0):
 for n in range(int(width/.15)):k.box("RadiatorFin",p+Vector3(-width/2+n*.15,.53,0),Vector3(.10,.78,.22),"old_iron")
 for y in [.23,.82]:k.pipe(p+Vector3(-width/2-.1,y,0),p+Vector3(width/2+.1,y,0),.045,"metal")
 k.cyl("RadiatorBleed",p+Vector3(width/2,.94,0),.045,.05,"brass")
static func stove(k,p:Vector3):
 k.box("EnamelStove",p+Vector3(0,.5,0),Vector3(1.65,1,.8),"old_iron",true)
 for x in [-.42,.42]:
  k.cyl("CookingPlate",p+Vector3(x,1.02,0),.25,.03,"dark")
  k.cyl("SoupPot",p+Vector3(x,1.2,0),.21,.35,"metal")
  k.cyl("PotLid",p+Vector3(x,1.39,0),.23,.035,"metal")
 k.box("StoveDoor",p+Vector3(0,.45,.415),Vector3(1.25,.5,.045),"dark")
 k.box("StoveHandle",p+Vector3(0,.65,.47),Vector3(.55,.04,.04),"brass")
 k.pipe(p+Vector3(.65,.8,-.2),p+Vector3(.65,3.1,-.2),.12,"rust")
 k.box("FlueCleanout",p+Vector3(.65,1.35,-.05),Vector3(.22,.22,.06),"metal")
static func linen(k,p:Vector3):
 for n in range(3):k.box("FoldedLinen",p+Vector3(0,.06+n*.07,0),Vector3(.55,.06,.45),"paper" if n%2==0 else "cloth")
static func chair(k,p:Vector3,heading:float=0):
 # Same facing convention as benches: the back is behind local -Z.
 var basis=Basis(Vector3.UP,heading)
 k.box("AssemblySeat",p+Vector3(0,.47,0),Vector3(.52,.09,.5),"wood",true)
 var back=k.box("AssemblyChairBack",p+basis*Vector3(0,.86,-.22),Vector3(.54,.62,.07),"wood");back.rotation.y=heading
 for x in [-.21,.21]:
  for z in [-.2,.2]:k.box("ChairLeg",p+basis*Vector3(x,.23,z),Vector3(.05,.46,.05),"metal")
static func commune(w):
 var k=w.kit
 # Four columns support straight transverse beams over the PUBLIC hall.
 # No unattached decorative arches floating above rooms.
 for z in [-2,4]:
  for x in [-8.7,9.7]:
   k.cyl("StationColumn",Vector3(x,1.75,z),.29,3.5,"tile")
   k.box("ColumnCollision",Vector3(x,1.4,z),Vector3(.58,2.8,.58),"tile",true).visible=false
   k.box("ColumnPlinth",Vector3(x,.13,z),Vector3(.76,.26,.76),"terrazzo")
   k.cyl("ColumnCapital",Vector3(x,3.40,z),.42,.18,"cream")
  k.box("HallStructuralBeam",Vector3(.5,3.55,z),Vector3(19.4,.22,.38),"plaster")
 # Assembly room is a compact Soviet public hall with a low stage and aisles.
 k.box("AssemblyLowStage",Vector3(.5,.12,-17),Vector3(17,.24,2.6),"wood")
 k.box("LecternBase",Vector3(.5,.42,-15.9),Vector3(.9,.84,.62),"wood",true)
 k.box("LecternTop",Vector3(.5,.88,-15.9),Vector3(1.05,.08,.72),"wood").rotation.x=-.12
 k.box("AssemblyRedDrape",Vector3(.5,2.35,-18.77),Vector3(13.6,.7,.08),"red")
 for x in [-7,8]:
  Detail.art(k,"CommuneWorkersPoster",Vector3(x,1.9,-18.80),Vector2(1.45,2.1),"res://assets/visual/commune_poster_0.png")
 for z in [-12.6,-10.6,-8.6]:
  for x in [-7,-5,-3,4,6,8]:chair(k,Vector3(x,0,z),PI)
 rug(k,Vector3(.5,0,-10.5),Vector2(2.3,7))
 for x in [-10.6,11.6]:radiator(k,Vector3(x,0,-16),1.5)
 k.table(Vector3(-7,0,-17),2.8)
 # Public allocation counter, no well inside a station building.
 k.box("WaterAllocationCounter",Vector3(8,.5,.5),Vector3(3.4,1,.72),"old_iron",true)
 for x in [6.8,8,9.2]:
  k.cyl("ClosedWaterCan",Vector3(x,.48,-1.5),.34,.96,"old_iron")
  k.cyl("WaterCanLid",Vector3(x,.98,-1.5),.35,.035,"metal")
 k.pipe(Vector3(6.5,1.3,-3.7),Vector3(10.8,1.3,-3.7),.09,"metal")
 k.box("OpenAllocationBook",Vector3(8,1.02,.5),Vector3(.7,.035,.5),"paper")
 k.bench(Vector3(-5,0,3.7),3.4);rug(k,Vector3(-3,0,.5),Vector2(4,3))
 # Greenhouse layout and equipment retain the well received planting art.
 for x in [-20,-16]:
  for z in [-9,-3,4]:
   if x==-20 and z==-9:continue
   k.box("GreenhouseBed",Vector3(x,.4,z),Vector3(2.2,.8,3.7),"old_iron",true);Detail.vegetables(k,x,z)
 for x in [-21,-19]:
  for y in [.48,1.03]:
   k.box("FungusShelf",Vector3(x,y,-9.4),Vector3(.65,.08,2.3),"wood")
   for z in [-10,-9.4,-8.8]:
    k.box("MushroomGrowingBag",Vector3(x,y+.17,z),Vector3(.36,.22,.3),"cloth")
    for dx in [-.08,.07]:
     k.cyl("MushroomStem",Vector3(x+dx,y+.34,z),.024,.12,"paper")
     k.ellipsoid("MushroomCap",Vector3(x+dx,y+.4,z),Vector3(.09,.035,.075),"cream")
 k.box("FungusShade",Vector3(-20,2.25,-8),Vector3(2.3,.7,.035),"fungus_shade").set_meta("dynamic",true)
 k.box("GreenhouseReturnPump",Vector3(-12.6,.55,-3.4),Vector3(.75,1.1,.55),"old_iron",true)
 k.cyl("GreenhouseFilterBasket",Vector3(-12.6,.85,-3),.22,.45,"metal")
 k.pipe(Vector3(-22,.7,-3.4),Vector3(-12.6,.7,-3.4),.055,"metal")
 for z in [-10,-4,3,9]:
  k.box("GrowReflector",Vector3(-18,2.7,z),Vector3(6,.09,.4),"metal")
  k.box("GrowTube",Vector3(-18,2.64,z),Vector3(5.8,.035,.15),"warm_light")
  k.lamp(Vector3(-17,2.7,z),true,1.25,6)
 # Dining and kitchen are separate; table orientation and wide aisles remain readable.
 for x in [-7,-1]:
  for z in [9,13]:
   k.table(Vector3(x,0,z),3.7);k.bench(Vector3(x,0,z-1.05),3.4,true,PI);k.bench(Vector3(x,0,z+1.05),3.4)
 Detail.art(k,"CommuneBreadPoster",Vector3(-8,1.8,6.18),Vector2(1.2,1.7),"res://assets/visual/commune_poster_1.png")
 stove(k,Vector3(8,0,8));k.table(Vector3(7,0,14),4)
 for x in [3.2,10.8]:k.locker(Vector3(x,0,14.5))
 for x in [6,7,8]:linen(k,Vector3(x,.82,14))
 # Medical and domestic props, privacy curtains, cabinets, wash water, drying laundry.
 for x in [-8,-2]:
  k.bed(Vector3(x,0,21),"paper");k.table(Vector3(x,0,18),1.4)
  k.box("MedicalSplashback",Vector3(x,1.0,23.81),Vector3(3,1.7,.05),"plant_tile")
 for x in [4.5,9.5]:k.bed(Vector3(x,0,21),"red")
 for x in [15,20]:
  for z in [7,21]:k.bed(Vector3(x,0,z),"cloth")
 for z in [10,16]:
  k.box("PrivacyCurtain",Vector3(20,1.3,z),Vector3(4.7,2.5,.035),"cloth")
  k.pipe(Vector3(17.7,2.6,z),Vector3(22.3,2.6,z),.018,"metal")
 radiator(k,Vector3(17.5,0,19),2)
 k.box("ResidentLedgerStand",Vector3(16,.48,11),Vector3(.75,.96,.6),"wood",true)
 k.box("ResidentLedger",Vector3(16,.98,11),Vector3(.65,.03,.45),"paper")
 rug(k,Vector3(17,0,13),Vector2(3,3.5));rug(k,Vector3(6,0,18),Vector2(4,1.5))
 for x in [13,22]:k.locker(Vector3(x,0,13))
 for x in [16,19,22]:k.box("ArchiveCabinet",Vector3(x,1,-12.3),Vector3(1.6,2,.7),"wood",true)
 for z in [-10,-8]:k.table(Vector3(19,0,z),3)
 k.pipe(Vector3(13,2.4,-12),Vector3(22,2.4,-12),.016,"metal")
 for x in [14,16,18,20]:k.box("DryingPrint",Vector3(x,1.9,-12),Vector3(.65,.85,.025),"paper")
static func sech(w):
 var k=w.kit
 # Active rails are beside the platform, never underneath the settlement rooms.
 k.box("DepotBallast",Vector3(23,-.31,-2),Vector3(5,.35,49),"concrete")
 for z in range(-25,22):
  k.box("RailSleeper",Vector3(23,-.1,z),Vector3(2.5,.13,.22),"wood")
 for dx in [-.76,.76]:k.box("DepotRail",Vector3(23+dx,.02,-2),Vector3(.08,.16,49),"metal")
 k.box("PlatformSafetyRail",Vector3(19.94,.5,-2),Vector3(.12,1,44),"metal",true).visible=false
 k.pipe(Vector3(19.8,.8,-24),Vector3(19.8,.8,20),.03,"metal")
 for z in [-21,-15,-9,-3,3,9,15]:
  k.box("PlatformEdge",Vector3(19.8,.04,z),Vector3(.12,.08,5.5),"cream")
  k.lamp(Vector3(18,2.8,z),false,.8,6)
  k.pipe(Vector3(19.8,.2,z),Vector3(19.8,.8,z),.035,"metal")
 # A real service wagon remains on the active track; homes were jacked OFF it.
 k.box("ServiceWagonChassis",Vector3(23,.65,8),Vector3(2.9,.25,8),"metal")
 for z in [5,11]:
  for dx in [-.76,.76]:k.cyl("ServiceWagonWheel",Vector3(23+dx,.35,z),.31,.13,"dark").rotation.z=PI/2
 k.box("ServiceWagonBody",Vector3(23,1.5,8),Vector3(2.9,1.45,8),"old_iron")
 for z in [5,7,9,11]:k.box("ServiceWagonWindow",Vector3(21.53,1.85,z),Vector3(.025,.5,1.25),"dark")
 for x in [-14,-6]:
  # Habitation car body strips on concrete supports, clear of any rails.
  for z in [7.2,17.8]:
   k.box("HabitationSupport",Vector3(x,-.3,z),Vector3(3,.45,.7),"concrete")
  k.box("HabitationCarChassis",Vector3(x,-.10,12.5),Vector3(3.85,.18,14.5),"metal")
  for z in [7,10,13,16,19]:
   var exterior=x-1.94 if x< -10 else x+1.94
   k.box("CarriageExteriorWindow",Vector3(exterior,1.7,z),Vector3(.04,.75,1.5),"dark")
   for dz in [-.74,0,.74]:k.box("WindowMullion",Vector3(exterior,1.7,z+dz),Vector3(.07,.8,.035),"metal")
   k.box("HabitationRib",Vector3(x-1.9,1.4,z),Vector3(.08,2.8,.10),"old_iron")
  k.box("CarriagePaintBand",Vector3(x,1,19.86),Vector3(3.8,.16,.035),"red")
 for x in [-14,-6]:
  for z in [7.3,17.6]:k.bed(Vector3(x,0,z),"cloth")
 for z in [9.3,15.5]:
  k.pipe(Vector3(-15.8,2.5,z),Vector3(-4.2,2.5,z),.02,"metal")
  k.box("FamilyCurtain",Vector3(-13.7,1.4,z),Vector3(4.1,2.2,.035),"cloth")
 for x in [-15,-5]:k.locker(Vector3(x,0,12))
 k.box("BunkNoticeStool",Vector3(-11.4,.35,11.5),Vector3(.6,.7,.6),"wood",true)
 k.box("BunkNoticePaper",Vector3(-11.4,.72,11.5),Vector3(.55,.025,.45),"paper")
 rug(k,Vector3(-10,0,12),Vector2(3.6,5));rug(k,Vector3(2,0,-10),Vector2(8,3))
 # The central public hall has several exits, workshop, laundry and resting spots.
 k.table(Vector3(3,0,2),3.4);k.bench(Vector3(3,0,3.1),3.1);k.bench(Vector3(3,0,.9),3.1,true,PI)
 k.bench(Vector3(7.5,0,6),2.5,true,-PI/2);rug(k,Vector3(1,0,6),Vector2(3,3))
 for z in [-3,3,8]:
  k.lamp(Vector3(0,2.8,z),true,1.35,7)
  k.box("DepotTrussFoot",Vector3(-3.7,1.5,z),Vector3(.18,3,.18),"metal")
  k.box("DepotTrussFoot",Vector3(8.7,1.5,z),Vector3(.18,3,.18),"metal")
 # Kitchen, pantry, stove and actual common meals.
 stove(k,Vector3(-14,0,-3));k.table(Vector3(-8,0,-2.5),4)
 k.table(Vector3(-12,0,2.5),3.1);k.bench(Vector3(-12,0,3.6),2.8)
 for x in [-15,-5]:k.locker(Vector3(x,0,3.8))
 # Separate meeting room, with Cossack icons and a ceremonial sabre.
 k.table(Vector3(2,0,-11.5),6);k.bench(Vector3(2,0,-12.6),5.5,true,PI);k.bench(Vector3(2,0,-10.4),5.5)
 k.box("CossackIconFrame",Vector3(7,1.9,-13.8),Vector3(.6,.8,.06),"wood")
 k.box("CossackIconCenter",Vector3(7,1.9,-13.75),Vector3(.35,.55,.025),"brass")
 k.box("CossackSabre",Vector3(8,1.7,-13.75),Vector3(.05,1.25,.04),"metal").rotation.z=.25
 # Library shelving makes the room legible without signs.
 for z in [-21,-17]:w.CampaignMaps.bookcase(k,Vector3(.6,0,z),2.5)
 k.table(Vector3(5,0,-20),2.5)
 for n in 5:k.box("OpenDryingBook",Vector3(4.1+n*.4,.83,-20),Vector3(.3,.04,.45),"paper")
 k.pipe(Vector3(1,2.4,-23),Vector3(8,2.4,-23),.02,"metal")
 k.box("BlueStitchedBlanket",Vector3(5,1.7,-22.8),Vector3(1.2,1,.04),"cloth")
 k.box("BlanketBlueStitch",Vector3(5.55,1.7,-22.76),Vector3(.025,.95,.015),"blue")
 # Washroom plumbing and medical/craft work, away from food preparation.
 for x in [10,12.5]:k.cyl("WashWaterBarrel",Vector3(x,.5,1),.4,1,"old_iron")
 k.box("WashBasin",Vector3(12,.7,8.6),Vector3(2.7,.2,.7),"cream",true)
 k.pipe(Vector3(13.7,.9,1),Vector3(13.7,.9,9),.055,"metal")
 for x in [-1,7]:k.bed(Vector3(x,0,17.6),"paper")
 k.table(Vector3(2,0,18.5),3);linen(k,Vector3(1.5,.82,18.5))
 k.box("SewingMachine",Vector3(3,.95,18.5),Vector3(.6,.3,.35),"dark")
 k.table(Vector3(-8,0,-20),3);k.table(Vector3(-8,0,-12),3)
 for x in [-10,-6]:k.locker(Vector3(x,0,-5.6))
