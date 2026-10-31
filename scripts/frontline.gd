extends RefCounted
## A revisited transfer line: six distinct sorties share coherent, persistent geography.
static func encounters(s)->Dictionary:
 var id=s.Campaign.Update.mission(s)
 if not s.Campaign.Update.data().missions.has(id):return {}
 var soldiers=id in ["c3","s3"]
 return {
 id+"_west":{"rect":Rect2(-22,-20,14,19),"need":"field_"+id+"_routes","skip":"unused_front_skip","name":"转移点的封锁" if soldiers else "侧廊里的兽群","spawns":[Vector3(-17,.04,-13),Vector3(-12,.04,-17),Vector3(-19,.04,-6)],"enemy_kind":"soldier" if soldiers else "mutant"},
 id+"_north":{"rect":Rect2(-8,-23,17,16),"need":"field_"+id+"_evidence","skip":"unused_front_skip","name":"北口接送线","spawns":[Vector3(-5,.04,-19),Vector3(3,.04,-21),Vector3(6,.04,-12)],"enemy_kind":"soldier" if soldiers else "mutant"}}
static func build(w):
 var k=w.kit
 preload("res://scripts/railway_detail.gd").prepare(k)
 k.box("FloorTransferStation",Vector3(0,-.13,0),Vector3(48,.26,48),"rail_floor",true)
 k.box("TransferPlatformTerrazzo",Vector3(0,.008,0),Vector3(7.6,.016,47),"rail_platform")
 k.box("ControlRoomServiceTile",Vector3(16,.009,15),Vector3(11.6,.018,13.6),"rail_service")
 for z in [-18,-10,-2,6,14,22]:k.box("GalleryRepairPlate",Vector3(-20.8,.012,z),Vector3(2.4,.024,2.6),"factory_floor")
 # Tracks occupy their own bays; no room, furniture or carriage crosses them.
 for x in [-6.3,6.3]:
  k.box("InsetBallast",Vector3(x,.008,0),Vector3(2.5,.016,45),"dark")
  for dx in [-.72,.72]:k.box("FlushRail",Vector3(x+dx,.035,0),Vector3(.075,.07,45),"old_iron")
  for z in range(-22,23):k.box("EmbeddedSleeper",Vector3(x,.012,z),Vector3(2.3,.024,.18),"wood")
 # Platforms, level crossings and the side gallery remain at the same walking height.
 for x in [-3.9,3.9]:k.box("PlatformEdgeStripe",Vector3(x,.023,0),Vector3(.12,.025,46),"cream")
 for z in [-2,12]:
  k.box("FlushCrossing",Vector3(0,.07,z),Vector3(16,.14,2.7),"old_iron",true)
 # An asymmetric service block and a broad main platform, rather than a room grid.
 k.wall("TransferWest",Vector2(-24,-24),Vector2(-24,24))
 k.wall("TransferEast",Vector2(24,-24),Vector2(24,24))
 k.wall("TransferNorth",Vector2(-24,-24),Vector2(24,-24))
 k.wall("TransferSouth",Vector2(-24,24),Vector2(24,24),true)
 for span in [[-24,-4],[1,8],[16,24]]:k.wall("WestPlatformArcade",Vector2(-9,span[0]),Vector2(-9,span[1]),true)
 k.wall("ControlRear",Vector2(10,8),Vector2(22,8))
 k.wall("ControlOuter",Vector2(22,8),Vector2(22,22))
 k.wall("ControlSouth",Vector2(10,22),Vector2(22,22),true)
 for span in [[8,11.7],[14.3,22]]:k.wall("ControlDoorWall",Vector2(10,span[0]),Vector2(10,span[1]),true)
 for z in [11.7,14.3]:k.box("ControlDoorJamb",Vector3(10,1.25,z),Vector3(.28,2.5,.18),"old_iron")
 k.box("ControlDoorLintel",Vector3(10,2.55,13),Vector3(.28,.22,2.8),"old_iron")
 for z in [-20,-12,-4,4,12,20]:
  for x in [-8.7,8.7]:
   k.cyl("TransferColumn",Vector3(x,1.7,z),.30,3.4,"tile")
   k.box("TransferColumnHull",Vector3(x,1.5,z),Vector3(.60,3,.60),"tile",true).visible=false
   k.cyl("TransferCapital",Vector3(x,3.25,z),.43,.18,"cream")
  # Thin vaulted ribs are roof props, not shoe-height obstacles.
  for x in [-6,-3,0,3,6]:k.pipe(Vector3(x-1.5,3.6-absf(x-1.5)*.045,z),Vector3(x+1.5,3.6-absf(x+1.5)*.045,z),.065,"metal")
 # Freight wagon rests exactly on the eastern rails, clear of crossing approaches.
 k.box("TransferCarChassis",Vector3(6.3,.42,4.5),Vector3(2.15,.5,8.5),"rust",true)
 for x in [5.25,7.35]:
  for z in [1.2,7.8]:k.cyl("TransferWagonWheel",Vector3(x,.24,z),.24,.12,"metal").rotation.z=PI/2
 for x in [5.16,7.44]:k.box("TransferCarSides",Vector3(x,1.12,4.5),Vector3(.14,.9,8.5),"old_iron")
 k.box("TransferCarRoof",Vector3(6.3,2.12,4.5),Vector3(2.4,.18,8.7),"corrugated")
 # Furnishing stays along walls and away from the crossing/circulation corridor.
 k.table(Vector3(15,0,11.6),3)
 k.box("TransferOriginalMap",Vector3(15,.83,11.6),Vector3(.95,.025,.65),"paper")
 for x in [19.8,21]:k.locker(Vector3(x,0,9.1))
 k.bench(Vector3(17,0,20.7),3,true,PI)
 k.table(Vector3(-17,0,-13),3)
 for x in [-17.8,-16.6]:k.box("SealedMissionParcel",Vector3(x,.99,-13),Vector3(.9,.30,.6),"wood").set_meta("dynamic",true)
 k.box("TransferSignalCabinet",Vector3(3,1,-18.2),Vector3(1.3,2,.5),"old_iron",true)
 for y in [.8,1.3]:k.cyl("TransferSignalDial",Vector3(3,y,-17.92),.12,.05,"cream").rotation.x=PI/2
 k.box("TransferSignalLamp",Vector3(3,1.7,-17.91),Vector3(.24,.12,.035),"warm_light")
 k.crate(Vector3(2.5,0,14),Vector3(.9,.6,.7))
 for entry in [[-19,17,0],[-14,17,0],[18,-15,PI/2]]:k.bench(Vector3(entry[0],0,entry[1]),2.7,true,entry[2])
 for z in [-19,-8,3,17]:
  k.lamp(Vector3(0,3.05,z),true,2.3,10)
  k.lamp(Vector3(-22.9,2.6,z),false,1.3,7)
 k.lamp(Vector3(15,2.6,8.25),true,2,8)
 for p in [Vector3(-23,.03,-17),Vector3(-23,.03,3),Vector3(22,.03,-20)]:
  for i in 8:
   var rubble=k.box("WallFootRubble",p+Vector3((i%3)*.20,.09,(i/3)*.24),Vector3(.26,.18,.18),"concrete");rubble.rotation.y=i*.67
 if w.story.Campaign.Update.mission(w.story) in ["c3","s3"]:
  for z in [-21,-18]:
   for x in [-1,0,1]:k.box("DefensiveSupplyBags",Vector3(x,.4,z),Vector3(.85,.8,.55),"cloth",true)
 details(w)
 preload("res://scripts/railway_detail.gd").build(w)
 k.finish_walls()
static func people(w):
 for entry in [["ambient_woman",-20,18],["ambient_elder",-16,18.4],["ambient_child",-18,18.7]]:
  w.person("front_resident_"+entry[0],Vector3(entry[1],0,entry[2]),"cloth",false,entry[0]);w.npcs["front_resident_"+entry[0]].stationary=true
 if w.story.f("sided_veteran"):w.person("plant_veteran",Vector3(-2,0,16.5),"green",true,"veteran_masked")

static func details(w):
 var k=w.kit
 # Eastern machinery bays are closed installations, not empty walkable rooms.
 for z in [-16,-1.5]:
  k.box("ServiceBayFoundation",Vector3(17,.18,z),Vector3(10,.36,10),"factory_floor",true)
  k.box("ServiceBayBack",Vector3(22,1.5,z),Vector3(.24,3,10),"old_iron",true)
  for dz in [-5,5]:k.box("ServiceBayReturn",Vector3(17,1.15,z+dz),Vector3(10,2.3,.22),"concrete",true)
  # A meshed lower barrier makes the bay's boundary readable in perspective.
  k.box("ServiceBayGuardHull",Vector3(12,.55,z),Vector3(.12,1.1,10),"metal",true).visible=false
  for dz in [-4,-2,0,2,4]:k.box("ServiceBayGuardPost",Vector3(12,.65,z+dz),Vector3(.07,1.3,.07),"old_iron")
  for y in [.3,.8,1.2]:k.pipe(Vector3(12,y,z-5),Vector3(12,y,z+5),.027,"metal")
  for dz in [-2,2]:
   k.box("CompressorPlinth",Vector3(17,.35,z+dz),Vector3(5,.3,2),"concrete")
   var housing=k.cyl("CompressorHousing",Vector3(17,1.1,z+dz),.65,3.7,"old_iron");housing.rotation.z=PI/2
   for x in [15.4,18.6]:k.box("CompressorFoot",Vector3(x,.65,z+dz),Vector3(.3,.65,1.2),"metal")
   k.pipe(Vector3(19,1.1,z+dz),Vector3(21.4,1.1,z+dz),.16,"rust")
  for x in [14,18,21]:k.pipe(Vector3(x,2.6,z-4.8),Vector3(x,2.6,z+4.8),.09,"metal")
  k.lamp(Vector3(21.7,2.6,z),false,1.7,10)
 # West transfer office: walls and a wide south opening leave room for stretchers.
 k.wall("TransferOfficeRear",Vector2(-22.5,-21),Vector2(-11,-21))
 k.wall("TransferOfficeSide",Vector2(-22.5,-21),Vector2(-22.5,-10))
 for x1 in [-22.5,-14]:
  k.wall("TransferOfficeSouth",Vector2(x1,-10),Vector2(x1+(5.5 if x1< -20 else 3),-10),true)
 for x in [-20.5,-18.5,-16.5]:k.locker(Vector3(x,0,-19.8))
 k.bench(Vector3(-21.1,0,-15.5),2.7,true,PI/2)
 for x in [-14,-12.5]:
  k.crate(Vector3(x,0,-19),Vector3(.95,.65,.8))
  k.box("MedicalParcelCloth",Vector3(x,.68,-19),Vector3(.92,.035,.78),"cloth")
  k.box("ParcelRedCrossA",Vector3(x,.705,-19),Vector3(.42,.012,.08),"red")
  k.box("ParcelRedCrossB",Vector3(x,.707,-19),Vector3(.08,.012,.42),"red")
 k.lamp(Vector3(-19,2.5,-20.7),true,2.1,9)
 # A protected waiting bay, salvage shelves and actual cable runs establish use.
 for x in [-22,-18]:
  k.box("WaitingBayStack",Vector3(x,.45,20.8),Vector3(2.3,.9,1.3),"wood",true)
  k.box("WaitingBayBlanket",Vector3(x,.93,20.8),Vector3(2,.07,1.1),"cloth")
 for z in [-6,2,9]:
  k.box("CableCabinet",Vector3(-23,1,z),Vector3(.7,2,1.7),"old_iron",true)
  for dz in [-.5,.1,.5]:k.box("CableCabinetLouvre",Vector3(-22.63,1.35,z+dz),Vector3(.025,.035,.30),"dark")
 for x in [-23.5,23.5]:
  for y in [2.1,2.4]:k.pipe(Vector3(x,y,-23),Vector3(x,y,23),.055,"rust")
 for z in [-16,-6,5,18]:
  for x in [-3,0,3]:k.box("RoofCableBracket",Vector3(x,3.3,z),Vector3(.05,.18,.5),"metal")
 for z in [-20,-10,0,10,20]:
  k.box("PlatformTileRepair",Vector3(-2.5,.027,z),Vector3(.6,.015,1.4),"factory_floor")
 # Control-room apparatus is wall-bound and never crowds its 2.6m doorway.
 for z in [12,15,18]:
  k.box("RelayCabinet",Vector3(21.25,1.05,z),Vector3(.85,2.1,1.6),"old_iron",true)
  for dy in [.65,1.15,1.65]:
   k.box("RelayWindow",Vector3(20.81,dy,z),Vector3(.025,.30,1.15),"dark")
   for dz in [-.35,0,.35]:k.box("RelayContact",Vector3(20.79,dy,z+dz),Vector3(.025,.16,.07),"brass")
 k.table(Vector3(12.7,0,20),2.3)
 k.box("SignalBenchRadio",Vector3(12.7,1.04,20),Vector3(1.15,.42,.48),"wood")
 k.box("BenchRadioSpeaker",Vector3(12.4,1.05,20.25),Vector3(.38,.30,.025),"cloth")
 k.box("BenchRadioScale",Vector3(12.95,1.12,20.25),Vector3(.45,.08,.025),"cream")
 for dx in [-.15,.15]:k.cyl("SignalBenchKnob",Vector3(12.95+dx,.97,20.28),.045,.04,"dark").rotation.x=PI/2
 for dx in [-.30,0,.30]:
  k.box("MapRailLine",Vector3(15+dx,.849,11.6),Vector3(.012,.006,.52),"dark")
 for dz in [-.15,.15]:k.box("MapCrossingLine",Vector3(15,.850,11.6+dz),Vector3(.80,.005,.012),"red")
 k.box("TransferRouteNotice",Vector3(15,1.7,8.16),Vector3(2,1.2,.035),"paper")
 k.label("ПЕРЕХОД / 02",Vector3(15,1.7,8.19),24)
 for z in [-21,-18,-15]:
  k.box("EvacuationDirectionMark",Vector3(-.6,.034,z),Vector3(.05,.012,.6),"cream")
 # Short sandbag cover has one well-defined collider, with visual bags resting on it.
 if w.story.Campaign.Update.mission(w.story) in ["c3","s3"]:
  for cover in [[-18,-4],[1,-12],[4,-17]]:
   var x:float=cover[0];var z:float=cover[1]
   k.box("CoverSandbagHull",Vector3(x,.45,z),Vector3(2.1,.9,.7),"cloth",true).visible=false
   for row in 2:
    for col in 3:k.ellipsoid("CoverSandbag",Vector3(x-.7+col*.7,.24+row*.4,z),Vector3(.39,.24,.36),"cloth")
