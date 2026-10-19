extends RefCounted
## Settlements are places to live: rooms communicate through several routes,
## while trackwork, heating, cooking and water supply have visible destinations.
const Detail=preload("res://scripts/facility_detail.gd")
static func rug(k,p:Vector3,size:Vector2,variant:String="burgundy",heading:float=0):
 var source={"burgundy":"rug","indigo":"rug_indigo","olive":"rug_olive","runner":"rug"}.get(variant,"rug")
 var repeats=2 if variant=="runner" else 1
 var texture:Texture2D=load("res://assets/visual/"+source+".png")
 var native=Vector2(texture.get_width(),texture.get_height()*repeats)
 var requested=Vector2(size.y,size.x) if absf(sin(heading))>.7 else size
 var actual=native*minf(requested.x/native.x,requested.y/native.y)
 var m=k.mats.cloth.duplicate();m.albedo_texture=texture;m.uv1_triplanar=false;m.uv1_world_triplanar=false;m.uv1_scale=Vector3(1,repeats,1);m.normal_enabled=false
 var floor=k.box("WovenRug",p+Vector3(0,.032,0),Vector3(actual.x,.018,actual.y),"cloth")
 floor.rotation.y=heading;floor.material_override=m;floor.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 floor.set_meta("rug_variant",variant);floor.set_meta("rug_native_aspect",native.x/native.y);floor.set_meta("rug_repeat",repeats)
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
 k.box("AssemblySeat",p+Vector3(0,.47,0),Vector3(.52,.09,.5),"wood",true).set_meta("seat_forward",basis*Vector3.BACK)
 var back=k.box("AssemblyChairBack",p+basis*Vector3(0,.86,-.22),Vector3(.54,.62,.07),"wood");back.rotation.y=heading
 for x in [-.21,.21]:
  for z in [-.2,.2]:k.box("ChairLeg",p+basis*Vector3(x,.23,z),Vector3(.05,.46,.05),"metal")
static func double_bed(k,p:Vector3):
 k.box("DoubleBedFrame",p+Vector3(0,.36,0),Vector3(1.85,.16,2.18),"wood",true)
 k.box("DoubleBedFootprint",p+Vector3(0,.2,0),Vector3(1.85,.4,2.18),"wood",true).visible=false
 k.box("DoubleBedMattress",p+Vector3(0,.49,0),Vector3(1.72,.15,2.03),"cloth")
 k.box("DoubleBedHeadboard",p+Vector3(0,.72,-1.08),Vector3(1.9,.92,.10),"wood",true)
 k.box("DoubleBedQuilt",p+Vector3(0,.59,.24),Vector3(1.72,.08,1.45),"red")
 for x in [-.43,.43]:k.ellipsoid("DoubleBedPillow",p+Vector3(x,.63,-.70),Vector3(.36,.08,.23),"paper")
static func partition(k,x:float,start:float,end:float,door:float):
 k.wall("FamilyAlcoveWall",Vector2(x,start),Vector2(x,door-.95),true)
 k.wall("FamilyAlcoveWall",Vector2(x,door+.95),Vector2(x,end),true)
 k.doorway(x,door,true)
 # A short fixed privacy panel stands inside the room, clear of the opening.
static func commune(w):
 var k=w.kit
 for z in [-2.9,4.85]:
  for x in [-10.91,11.91]:
   k.cyl("HallWallPilaster",Vector3(x,1.34,z),.25,2.68,"commune_ivory_tile")
   k.box("PilasterCollision",Vector3(x,1.30,z),Vector3(.46,2.60,.46),"tile",true).visible=false
   k.box("PilasterPlinth",Vector3(x,.12,z),Vector3(.56,.24,.56),"commune_terrazzo")
   k.cyl("PilasterCapital",Vector3(x,2.59,z),.30,.18,"cream")
 preload("res://scripts/assembly_door.gd").new().setup(w)
 # Half-depth meeting hall; production circulation runs behind its north wall.
 k.box("AssemblyLowStage",Vector3(.5,.10,-10.9),Vector3(17,.20,1.5),"wood",true)
 k.box("LecternBase",Vector3(.5,.62,-10.65),Vector3(.9,.84,.62),"wood",true)
 k.box("LecternTop",Vector3(.5,1.08,-10.65),Vector3(1.05,.08,.72),"wood").rotation.x=-.12
 k.box("AssemblyRedDrape",Vector3(.5,2.3,-11.79),Vector3(12,.50,.08),"red")
 # Keep the entire west frame clear of the production-corridor doorway.
 for x in [-7.4,9]:Detail.art(k,"CommuneWorkersPoster",Vector3(x,1.6,-11.80),Vector2(1.15,1.7),"res://assets/visual/commune_poster_0.png")
 for z in [-8.2,-6.2]:
  for x in [-7,-5,-3,4,6,8]:
   if z==-8.2 and x<0:continue # The seated group includes its own wooden bench.
   chair(k,Vector3(x,0,z),PI)
 rug(k,Vector3(.5,0,-6.8),Vector2(2.3,3.4))
 k.table(Vector3(-7,.2,-10.8),2.8)
 radiator(k,Vector3(-8.5,0,-4.3),1.8)
 # Public allocation counter and waiting space.
 k.box("WaterAllocationCounter",Vector3(8,.5,.5),Vector3(3.4,1,.72),"old_iron",true)
 for x in [6.8,8,9.2]:
  k.cyl("ClosedWaterCan",Vector3(x,.48,-1.5),.34,.96,"old_iron")
  k.cyl("WaterCanLid",Vector3(x,.98,-1.5),.35,.035,"metal")
 k.pipe(Vector3(6.5,1.3,-3.7),Vector3(10.8,1.3,-3.7),.09,"metal")
 k.box("OpenAllocationBook",Vector3(8,1.02,.5),Vector3(.7,.035,.5),"paper")
 k.bench(Vector3(-7.2,0,5.45),4,true,PI);rug(k,Vector3(-3,0,.5),Vector2(4,3),"indigo",PI/2)
 commune_garden(w)
 # Dining room keeps clear routes between tables, kitchen and medical room.
 for x in [-7,-1]:
  for z in [9,13]:
   k.table(Vector3(x,0,z),3.7);k.bench(Vector3(x,0,z-1.05),3.4);k.bench(Vector3(x,0,z+1.05),3.4,true,PI)
 Detail.art(k,"CommuneBreadPoster",Vector3(-8,1.8,6.18),Vector2(1.2,1.7),"res://assets/visual/commune_poster_1.png")
 stove(k,Vector3(8,0,8));k.table(Vector3(7,0,14),4)
 for x in [3.2,10.8]:k.locker(Vector3(x,0,14.5))
 for x in [6,7,8]:linen(k,Vector3(x,.82,14))
 for x in [-8,-2]:
  k.bed(Vector3(x,0,21),"paper");k.table(Vector3(x,0,18),1.4)
  k.box("MedicalSplashback",Vector3(x,1.0,23.81),Vector3(3,1.7,.05),"plant_tile")
 var linen_mat=k.mats.cloth.duplicate();linen_mat.albedo_color=Color("89948b");k.mats.medical_linen=linen_mat
 k.box("MedicalPrivacyHull",Vector3(-5.3,1.0,21.5),Vector3(.12,2.0,2.4),"metal",true).visible=false
 for z in [20.3,22.7]:
  k.box("MedicalScreenPost",Vector3(-5.3,1.0,z),Vector3(.055,2,.055),"metal")
  k.box("MedicalScreenFoot",Vector3(-5.3,.07,z),Vector3(.65,.1,.14),"metal",true)
 for y in [.4,1.94]:k.pipe(Vector3(-5.3,y,20.3),Vector3(-5.3,y,22.7),.025,"metal")
 k.box("MedicalPrivacyLinen",Vector3(-5.3,1.16,21.5),Vector3(.035,1.5,2.32),"medical_linen")
 commune_homes(w);commune_production(w);commune_defence(w)
 for x in [16,19,22]:k.box("ArchiveCabinet",Vector3(x,1,-12.3),Vector3(1.6,2,.7),"wood",true)
 for z in [-10,-8]:k.table(Vector3(19,0,z),3)
 k.pipe(Vector3(13,2.4,-12),Vector3(22,2.4,-12),.016,"metal")
 for x in [14,16,18,20]:k.box("DryingPrint",Vector3(x,1.9,-12),Vector3(.65,.85,.025),"paper")
 # Waiting residents face the allocation area, readers stand by archive
 # tables, and the bench audience leaves a passage behind the low stage.
 for spec in [["workers",-5.5,1.0,3],["queue",8.0,3.2,4],["family",14.1,19.7,3],["readers",16.0,-8.4,2],["assembly",-5,-7.5,3],["militia",26.7,.8,2]]:
  preload("res://scripts/painted_resident_group.gd").new().setup(w,spec[0],Vector3(spec[1],0,spec[2]),spec[3],1.28 if spec[0]=="assembly" else 1.73)
static func commune_garden(w):
 var k=w.kit
 # Existing mushroom puzzle bay stays recognizable; the enlarged farm grows four crop types.
 for x in [-20,-16]:
  for z in [-9,-3,4]:
   if x==-20 and z==-9:continue
   k.box("GreenhouseBed",Vector3(x,.4,z),Vector3(2.2,.8,3.7),"old_iron",true);Detail.vegetables(k,x,z)
 for x in [-21,-19]:
  k.box("FungusRackHull",Vector3(x,.85,-9.4),Vector3(.72,1.7,2.35),"wood",true).visible=false
  for y in [.48,1.03]:
   k.box("FungusShelf",Vector3(x,y,-9.4),Vector3(.65,.08,2.3),"wood")
   for z in [-10,-9.4,-8.8]:
    k.box("MushroomGrowingBag",Vector3(x,y+.17,z),Vector3(.36,.22,.3),"cloth")
    for dx in [-.08,.07]:
     k.cyl("MushroomStem",Vector3(x+dx,y+.34,z),.024,.12,"paper")
     k.ellipsoid("MushroomCap",Vector3(x+dx,y+.4,z),Vector3(.09,.035,.075),"cream")
 for x in [-21.5,-18.5]:
  for z in [-10.6,-8.2]:k.box("MushroomCanopyPost",Vector3(x,1.2,z),Vector3(.055,2.4,.055),"metal",true)
 for z in [-10.6,-8.2]:k.pipe(Vector3(-21.5,2.42,z),Vector3(-18.5,2.42,z),.025,"metal")
 var canopy=k.box("FungusShade",Vector3(-20,2.38,-9.4),Vector3(2.95,.035,2.35),"fungus_shade",true)
 canopy.set_meta("dynamic",true);canopy.material_override=k.new_veil_material(k.mats.fungus_shade)
 k.roof_occluders.append({"mesh":canopy,"bounds":canopy.global_transform*canopy.get_aabb(),"material":canopy.material_override})
 for x in [-26,-21,-16]:
  for z in [-19,-16]:
   k.box("NorthMushroomRackHull",Vector3(x,.9,z),Vector3(2.5,1.8,.75),"wood",true).visible=false
   for y in [.4,1,1.6]:
    k.box("NorthMushroomShelf",Vector3(x,y,z),Vector3(2.5,.08,.75),"wood")
    for dx in [-.8,0,.8]:
     k.box("MushroomCompostTray",Vector3(x+dx,y+.14,z),Vector3(.65,.24,.58),"cloth")
     for dz in [-.12,.12]:k.ellipsoid("OysterMushroomCluster",Vector3(x+dx,y+.30,z+dz),Vector3(.22,.06,.18),"cream")
 for z in [-9,-5]:
  k.box("SproutRackHull",Vector3(-26,.8,z),Vector3(2.8,1.6,1.1),"wood",true).visible=false
  for y in [.45,1.1]:
   k.box("SproutTray",Vector3(-26,y,z),Vector3(2.8,.12,1.1),"soil")
   for i in 14:
    var x=-27.15+i*.18
    for dz in [-.3,0,.3]:Detail.leaf(k,Vector3(x,y+.08,z+dz),.16,float(i)*.8)
 for z in [1,7]:
  k.box("PotatoGrowingBed",Vector3(-26,.35,z),Vector3(2.6,.7,3.4),"old_iron",true)
  k.box("PotatoSoil",Vector3(-26,.72,z),Vector3(2.4,.06,3.2),"soil")
  for dz in [-1,0,1]:
   for dx in [-.65,.65]:
    for n in 4:Detail.leaf(k,Vector3(-26+dx,.75,z+dz),.33,n*PI/2)
  k.crate(Vector3(-28,0,z),Vector3(.8,.5,.8))
  for n in 6:k.ellipsoid("HarvestedPotato",Vector3(-28+(n%2)*.18-.1,.55,z+floor(n/2)*.16-.2),Vector3(.13,.085,.09),"cream")
 k.box("GreenhouseReturnPump",Vector3(-12.6,.55,-3.4),Vector3(.75,1.1,.55),"old_iron",true)
 k.cyl("GreenhouseFilterBasket",Vector3(-12.6,.85,-3),.22,.45,"metal")
 k.pipe(Vector3(-28,.7,-3.4),Vector3(-12.6,.7,-3.4),.055,"metal")
 for x in [-26,-18]:
  for z in [-19,-10,-4,3,9]:
   k.box("GrowReflector",Vector3(x,2.7,z),Vector3(4,.09,.4),"metal")
   k.box("GrowTube",Vector3(x,2.64,z),Vector3(3.8,.035,.15),"warm_light")
   k.lamp(Vector3(x,2.7,z),true,1.25,6)
static func commune_homes(w):
 var k=w.kit
 for x in [16.4,18.6]:
  partition(k,x,4,14,10.2);partition(k,x,14,24,20.5)
 for span in [[12,16.4],[18.6,23]]:k.wall("FamilyCrossWall",Vector2(span[0],14),Vector2(span[1],14),true)
 for x in [14.1,20.9]:
  for z in [5.5,15.5]:
   double_bed(k,Vector3(x,0,z))
   k.lamp(Vector3(x,2.3,z-1.25),true,1.25,6)
   k.box("BedsideCabinet",Vector3(x+1.12,.34,z+.4),Vector3(.38,.68,.55),"wood",true)
   k.box("FamilyPhotoFrame",Vector3(x+1.12,.77,z+.4),Vector3(.18,.20,.05),"brass")
   k.locker(Vector3(x-1.2 if x<17 else x+1.2,0,z+(6.5 if x<17 else 3.0)))
  for z in [13.70,23.70]:
   radiator(k,Vector3(x,0,z),1.8)
   k.pipe(Vector3(x-1,.23,z),Vector3(x-1,.23,z-1),.04,"metal")
 # Supply/return pipes follow the outer back wall and the room partitions.
 for y in [.22,.82]:
  k.pipe(Vector3(12.3,y,23.72),Vector3(22.75,y,23.72),.045,"metal")
  k.pipe(Vector3(22.75,y,13.7),Vector3(22.75,y,23.72),.045,"metal")
  k.pipe(Vector3(12.3,y,13.7),Vector3(22.75,y,13.7),.045,"metal")
 k.box("ResidentLedgerStand",Vector3(14.8,.48,11),Vector3(.75,.96,.6),"wood",true)
 k.box("ResidentLedger",Vector3(14.8,.98,11),Vector3(.65,.03,.45),"paper")
 for p in [Vector3(14,0,9),Vector3(21,0,9),Vector3(14,0,20),Vector3(21,0,21)]:rug(k,p,Vector2(2,1.8),"olive" if p.x<17 else "indigo")
 k.table(Vector3(21,0,21.5),2.0);linen(k,Vector3(21,.82,21.5))
 k.box("ChildDrawing",Vector3(22.82,1.1,18),Vector3(.025,.55,.65),"paper")
static func commune_production(w):
 var k=w.kit
 k.table(Vector3(-7,0,-20),4.4)
 k.box("WindingMotor",Vector3(-7,1.04,-20),Vector3(1.1,.5,.6),"old_iron")
 k.cyl("CopperWireSpool",Vector3(-8.2,1,-20),.28,.55,"brass").rotation.z=PI/2
 k.box("LatheBed",Vector3(-5.5,.96,-20),Vector3(1.1,.2,.55),"metal")
 for x in [-10.3,-3.7]:k.locker(Vector3(x,0,-21))
 k.table(Vector3(-8.8,0,-17.4),2.7)
 k.box("PumpRepairLog",Vector3(-9,.83,-17.4),Vector3(.7,.035,.5),"paper")
 k.box("SalvageSpeaker",Vector3(-6,.4,-18.3),Vector3(.8,.8,.5),"wood",true)
 k.cyl("SpeakerCone",Vector3(-6,.43,-18.02),.28,.04,"dark").rotation.x=PI/2
 k.table(Vector3(.5,0,-20),4.5)
 for x in [-.7,1.7]:
  k.box("SewingMachine",Vector3(x,1.03,-20),Vector3(.7,.4,.35),"dark")
  k.cyl("SewingHandwheel",Vector3(x+.35,1.12,-20),.18,.08,"metal").rotation.z=PI/2
 k.box("TailorFootprint",Vector3(2.8,.8,-17),Vector3(.8,1.6,2),"wood",true).visible=false
 for y in [.3,.9,1.5]:
  k.box("ClothShelf",Vector3(2.8,y,-17),Vector3(.8,.08,2),"wood")
  for z in [-17.5,-16.5]:k.box("FoldedWorkCloth",Vector3(2.8,y+.18,z),Vector3(.7,.28,.65),"cloth")
 k.box("ShoeMendingBench",Vector3(-1.8,.45,-16.3),Vector3(1.1,.9,.6),"wood",true)
 for x in [-2.1,-1.6]:k.box("ResoledBoot",Vector3(x,.98,-16.3),Vector3(.23,.15,.4),"dark")
 # Boiler, coal storage, expansion vessel and routed hot-water pipes.
 k.box("BoilerBody",Vector3(6.5,1,-20.4),Vector3(2.5,2,1.9),"old_iron",true)
 k.box("BoilerFireDoor",Vector3(6.5,.65,-19.42),Vector3(1.05,.65,.12),"dark")
 k.box("BoilerInspectionGlass",Vector3(6.5,.72,-19.34),Vector3(.6,.22,.025),"warm_light")
 k.pipe(Vector3(6.5,1.9,-20.5),Vector3(6.5,3.1,-20.5),.17,"rust")
 k.cyl("BoilerExpansionTank",Vector3(9.3,1.5,-21),.42,1.4,"old_iron")
 k.box("CoalBunker",Vector3(10.5,.4,-19.9),Vector3(1.6,.8,1.5),"wood",true)
 for n in 10:k.ellipsoid("CoalLump",Vector3(10.1+(n%3)*.35,.82,-20.3+floor(n/3)*.25),Vector3(.22,.13,.18),"dark")
 for y in [2.55,2.78]:
  k.pipe(Vector3(6.5,y,-20.2),Vector3(11.5,y,-20.2),.075,"metal")
  k.pipe(Vector3(11.5,y,-20.2),Vector3(11.5,y,23.5),.075,"metal")
 k.box("BoilerGaugePanel",Vector3(9.3,1.2,-19.2),Vector3(.55,.8,.2),"metal")
 k.cyl("BoilerPressureGauge",Vector3(9.3,1.37,-19.06),.16,.04,"paper").rotation.x=PI/2
 k.table(Vector3(10,0,-16.2),2)
 k.box("MoroSketchbook",Vector3(10,.83,-16.2),Vector3(.5,.035,.4),"paper")
 k.ellipsoid("GuitarBody",Vector3(10.7,.7,-17.2),Vector3(.3,.4,.1),"wood")
 k.box("GuitarNeck",Vector3(10.7,1.28,-17.2),Vector3(.09,.72,.07),"wood")
 k.cyl("GuitarSoundHole",Vector3(10.7,.8,-17.08),.10,.025,"dark").rotation.x=PI/2
 for n in 4:k.box("GuitarString",Vector3(10.675+n*.017,1,-17.05),Vector3(.003,1.05,.003),"brass")
static func commune_defence(w):
 var k=w.kit
 k.table(Vector3(7,0,21.7),4.8)
 for x in [5.5,7,8.5]:k.box("MilitiaWeaponCase",Vector3(x,.9,21.7),Vector3(1.1,.22,.5),"wood")
 for x in [4.3,5,5.7]:
  k.box("MilitiaRifleStock",Vector3(x,.75,23.4),Vector3(.16,.65,.18),"wood")
  k.box("MilitiaRifleBarrel",Vector3(x,1.4,23.4),Vector3(.055,.8,.055),"metal")
 k.box("RifleRackHull",Vector3(5,1,23.4),Vector3(2.2,2,.5),"wood",true).visible=false
 k.box("MilitiaLockbox",Vector3(10.7,.75,23),Vector3(1.2,1.5,1),"old_iron",true)
 k.box("DefenceRouteMap",Vector3(10,1.65,16.2),Vector3(1.8,1.1,.04),"paper")
 for x in [9.5,10,10.5]:k.box("MapRoute",Vector3(x,1.7,16.23),Vector3(.025,.7,.015),"red")
 k.box("MilitiaRedBand",Vector3(7,.85,21.7),Vector3(.7,.03,.35),"red")
 k.locker(Vector3(3.1,0,22.5))
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
 for x in [-14.7,-5.3]:
  for z in [6.4,10.8,13.4 if x< -10 else 16.7,18.5]:k.bed(Vector3(x,0,z),"cloth",PI/2 if x< -10 else -PI/2)
 for z in [9.3,15.5]:
  k.pipe(Vector3(-15.8,2.5,z),Vector3(-4.2,2.5,z),.02,"metal")
  for x in [-13.7,-6.3]:
   k.box("FamilyCurtain",Vector3(x,1.4,z),Vector3(4.1,2.2,.035),"cloth",true)
 for x in [-15,-5]:k.locker(Vector3(x,0,12))
 k.box("BunkNoticeStool",Vector3(-11.4,.35,11.5),Vector3(.6,.7,.6),"wood",true)
 k.box("BunkNoticePaper",Vector3(-11.4,.72,11.5),Vector3(.55,.025,.45),"paper")
 rug(k,Vector3(-10,0,12),Vector2(3,4.5),"indigo");rug(k,Vector3(2,0,-11.5),Vector2(8,3),"runner",PI/2)
 # The central public hall has several exits, workshop, laundry and resting spots.
 k.table(Vector3(3,0,2),3.4);k.bench(Vector3(3,0,3.1),3.1);k.bench(Vector3(3,0,.9),3.1,true,PI)
 k.bench(Vector3(7.5,0,6),2.5,true,-PI/2);rug(k,Vector3(1,0,6),Vector2(3,3),"olive")
 for z in [-3,3,8]:
  k.lamp(Vector3(0,2.8,z),true,1.35,7)
  k.box("DepotTrussFoot",Vector3(-3.7,1.5,z),Vector3(.18,3,.18),"metal")
  k.box("DepotTrussFoot",Vector3(8.7,1.5,z),Vector3(.18,3,.18),"metal")
 # Kitchen, pantry, stove and actual common meals.
 stove(k,Vector3(-14,0,-3));k.table(Vector3(-8,0,-2.5),4)
 k.table(Vector3(-12,0,2.5),3.1);k.bench(Vector3(-12,0,3.6),2.8)
 for x in [-15,-5]:k.locker(Vector3(x,0,3.8))
 # Separate meeting room, with Cossack icons and a ceremonial sabre.
 k.table(Vector3(2,0,-11.5),6);k.bench(Vector3(2,0,-12.6),5.5);k.bench(Vector3(2,0,-10.4),5.5,true,PI)
 chair(k,Vector3(7.8,0,-11.5),-PI/2)
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
