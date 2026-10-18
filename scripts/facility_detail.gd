extends RefCounted
## Material and prop pass; task positions and circulation remain authored in Plans.
static func materials(k):
 for spec in [["terrazzo","terrazzo",.30],["plant_tile","plant_tile",.50],["factory_floor","factory_floor",.55],["soil","garden_soil",1.8],["leaf","vegetable_leaf",1.0],["old_iron","painted_iron",.8]]:
  var m:StandardMaterial3D=k.mats.concrete.duplicate()
  m.albedo_texture=load("res://assets/visual/"+spec[1]+".png");m.normal_texture=load("res://assets/visual/"+spec[1]+"_normal.png");m.roughness_texture=load("res://assets/visual/"+spec[1]+"_rough.png")
  m.albedo_color=Color.WHITE;m.uv1_scale=Vector3.ONE*spec[2];m.normal_enabled=true;m.normal_scale=.22
  k.mats[spec[0]]=m
 k.mats.leaf.cull_mode=BaseMaterial3D.CULL_DISABLED
 k.mats.leaf.normal_enabled=false;k.mats.leaf.uv1_triplanar=false;k.mats.leaf.uv1_world_triplanar=false;k.mats.leaf.uv1_scale=Vector3.ONE
 var shade=k.mats.cloth.duplicate();shade.albedo_color=Color("737d66");k.mats.fungus_shade=shade
static func art(k,name:String,p:Vector3,size:Vector2,texture:String):
 var frame=k.box("PosterFrame",p-Vector3(0,0,.026),Vector3(size.x+.07,size.y+.07,.045),"wood")
 var quad=MeshInstance3D.new();quad.name=name;quad.set_meta("poster_art",name);var q=QuadMesh.new();q.size=size;quad.mesh=q
 var m=StandardMaterial3D.new();m.albedo_texture=load(texture);m.roughness=1;m.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS;quad.material_override=m;k.root.add_child(quad);quad.position=p
 return frame
static func leaf(k,p:Vector3,radius:float,angle:float):
 var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
 var points=[]
 for i in range(7):
  var t=float(i)/6;var width=sin(t*PI)*radius*.53
  for side in [-1,1]:
   var local=Vector3(side*width,sin(t*PI)*radius*.38+t*radius*.3,t*radius)
   points.append(p+Basis(Vector3.UP,angle)*local)
 for i in range(6):
  for index in [i*2,i*2+1,i*2+3,i*2,i*2+3,i*2+2]:
   st.set_uv(Vector2(float(index%2),float(index/2)/6));st.add_vertex(points[index])
 st.generate_normals();st.generate_tangents();var m=MeshInstance3D.new();m.name="TexturedVegetableLeaf";m.set_meta("vegetable_leaf",true);m.mesh=st.commit();m.material_override=k.mats.leaf;k.root.add_child(m)
static func vegetables(k,x:float,z:float):
 k.box("GardenSoil",Vector3(x,.82,z),Vector3(2,.04,3.5),"soil")
 for dx in [-1.05,1.05]:k.box("BedEnamelRim",Vector3(x+dx,.83,z),Vector3(.10,.12,3.7),"old_iron")
 for dz in [-1.8,1.8]:k.box("BedEnamelRim",Vector3(x,.83,z+dz),Vector3(2.2,.12,.10),"old_iron")
 for dz in [-1.2,-.4,.4,1.2]:
  for dx in [-.52,.52]:
   for i in range(6):leaf(k,Vector3(x+dx,.86,z+dz),.24+float(posmod(i*7+int(x),4))*.02,float(i)*TAU/6)
 k.pipe(Vector3(x-.9,.90,z-1.6),Vector3(x-.9,.90,z+1.6),.018,"metal")
static func arch(k,p:Vector3,width:float):
 var points=[];var count=16
 for i in range(count+1):
  var t=PI*float(i)/count
  points.append(p+Vector3(cos(t)*width/2,sin(t)*2.4,0))
 for i in count:
  var a:Vector3=points[i];var b:Vector3=points[i+1]
  var rib=k.box("StationArchStone",(a+b)/2,Vector3(a.distance_to(b)+.035,.28,.50),"plaster")
  rib.rotation.z=atan2(b.y-a.y,b.x-a.x)
static func commune(w):
 var k=w.kit
 for z in [-1,9]:arch(k,Vector3(.5,3.35,z),19)
 for x in [-9,10]:
  for z in [-1,5,9]:
   k.box("ColumnPlinth",Vector3(x,.16,z),Vector3(.82,.32,.82),"terrazzo")
   k.cyl("ColumnLowerBand",Vector3(x,.6,z),.35,.14,"old_iron")
 # Public marble/terrazzo circulation and tiled service rooms replace the timber station floor.
 for x in [-9,10]:k.box("HallInlay",Vector3(x,.024,3.5),Vector3(.16,.016,13),"dark")
 for x in [-7,5]:
  art(k,"CommuneWorkersPoster",Vector3(x,1.75,-7.84),Vector2(1.25,1.85),"res://assets/visual/commune_poster_0.png")
  k.label("权力归劳动者",Vector3(x,.69,-7.78),17)
 art(k,"CommuneBreadPoster",Vector3(17,1.75,-12.83),Vector2(1.2,1.8),"res://assets/visual/commune_poster_1.png")
 k.label("面包与水，人人有份",Vector3(17,.70,-12.77),16)
 # Salvaged metro balustrades, repaired communal crockery and a wall radiator.
 for x in [-7,7]:
  k.box("CommitteeDrapedCloth",Vector3(x,2.53,-7.72),Vector3(2.5,.22,.035),"red")
 for x in range(-9,10,2):
  k.box("MetroWallWainscot",Vector3(x,.75,-3.83),Vector3(1.9,1.35,.045),"plant_tile")
 for x in [-21,-19]:
  for z in [-10,-9.4,-8.8]:
   for y in [.65,1.2]:
    k.box("MushroomGrowingBag",Vector3(x,y,z),Vector3(.36,.22,.3),"cloth")
    for dx in [-.08,.07]:
     k.cyl("MushroomStem",Vector3(x+dx,y+.14,z),.024,.12,"paper")
     k.ellipsoid("MushroomCap",Vector3(x+dx,y+.20,z),Vector3(.09,.035,.075),"cream")
 for x in [-21,-19]:
  k.box("FungusShelf",Vector3(x,.48,-9.4),Vector3(.65,.08,2.3),"wood")
  k.box("FungusShelf",Vector3(x,1.03,-9.4),Vector3(.65,.08,2.3),"wood")
 k.box("FungusShade",Vector3(-20,2.25,-8),Vector3(2.3,.7,.035),"fungus_shade").set_meta("dynamic",true)
 k.pipe(Vector3(-21.3,2.65,-8),Vector3(-18.7,2.65,-8),.025,"metal")
 k.box("GreenhouseReturnPump",Vector3(-12.6,.55,-3.4),Vector3(.75,1.1,.55),"old_iron",true)
 k.cyl("GreenhouseFilterBasket",Vector3(-12.6,.85,-3.0),.22,.45,"metal")
 k.pipe(Vector3(-15,.65,-3.4),Vector3(-12.6,.65,-3.4),.055,"metal")
 k.cyl("GardenPumpWheel",Vector3(-12.6,1,-2.82),.18,.05,"red").rotation.x=PI/2
 k.label("回水泵",Vector3(-12.6,.65,-3.10),17)
 for x in [-22.3,-12.1]:
  k.pipe(Vector3(x,.7,-11.5),Vector3(x,.7,9),.045,"metal")
 for x in [-22.4,-12]:
  k.cyl("RainBarrel",Vector3(x,.45,6),.35,.9,"old_iron")
  k.cyl("RainBarrelRim",Vector3(x,.91,6),.37,.06,"metal")
 k.box("SeedTray",Vector3(-12.2,.85,9.6),Vector3(.7,.08,.45),"soil")
 for i in range(4):leaf(k,Vector3(-12.45+i*.15,.9,9.6),.16,float(i))
 for x in [-21,-17]:
  k.box("PlantBedNumber",Vector3(x,.54,6),Vector3(.33,.24,.035),"paper")
  k.label("Б" if x==-21 else "А",Vector3(x,.56,6.025),17)
 # Wire-guarded grow fixtures above the beds; the warm hall remains distinct.
 for z in [-9,-3,4]:
  k.box("GrowReflector",Vector3(-18,2.55,z),Vector3(6,.09,.4),"metal")
  k.box("GrowTube",Vector3(-18,2.48,z),Vector3(5.8,.035,.15),"warm_light")
  for dx in [-2.8,2.8]:k.pipe(Vector3(-18+dx,2.55,z),Vector3(-18+dx,3,z),.012,"metal")
 for x in [-8,-1]:
  k.box("MedicalTileSplashback",Vector3(x,1.0,19.84),Vector3(3,1.8,.05),"plant_tile")
  for dx in [-.24,.24]:k.box("FoldedMedicalLinen",Vector3(x+dx,.72,17.75),Vector3(.30,.12,.28),"paper")
static func waterworks(w):
 var k=w.kit
 for x in [-16,-10]:
  k.box("PumpConcretePlinth",Vector3(x+.3,.16,-10),Vector3(2.8,.32,2),"concrete")
  # Bolted motor end and cooling rings are aligned with its real horizontal shaft.
  for dx in [.60,.77,.94,1.11,1.28]:k.cyl("MotorCoolingFin",Vector3(x+dx,1,-10),.48,.045,"old_iron").rotation.z=PI/2
  for i in range(8):
   var t=float(i)*TAU/8
   k.cyl("MotorFlangeBolt",Vector3(x+1.58,1+sin(t)*.31,-10+cos(t)*.31),.035,.08,"metal").rotation.z=PI/2
  k.pipe(Vector3(x-.35,1.3,-10),Vector3(x-.35,1.3,-12.4),.16,"old_iron")
  k.cyl("PipeBoltedFlange",Vector3(x-.35,1.3,-11.6),.25,.07,"old_iron").rotation.x=PI/2
  for i in range(6):
   var t=TAU*float(i)/6;k.cyl("FlangeBolt",Vector3(x-.35+sin(t)*.2,1.3+cos(t)*.2,-11.56),.022,.08,"metal").rotation.x=PI/2
  k.cyl("PumpGaugeBody",Vector3(x,1.65,-9.35),.19,.08,"metal").rotation.x=PI/2
  k.cyl("PumpGaugeFace",Vector3(x,1.65,-9.30),.16,.012,"paper").rotation.x=PI/2
  k.box("PressureNeedle",Vector3(x+.035,1.69,-9.28),Vector3(.015,.13,.012),"red").rotation.z=-.55
  k.label("НАСОС",Vector3(x,.50,-8.96),18)
  for dx in [-1.45,1.75]:k.box("PumpSafetyBoundary",Vector3(x+dx,.028,-10),Vector3(.07,.015,2.5),"brass")
 # Mark contaminated sludge physically before the player reaches it.
 for x in [-17,-15]:
  k.box("SludgeSediment",Vector3(x,.036,-12),Vector3(1.5,.03,1.8),"dark")
 k.box("RadiationWarningPlate",Vector3(-17,1.2,-13.7),Vector3(.65,.7,.04),"brass")
 k.label("☢",Vector3(-17,1.2,-13.65),40,Color("283329"))
 # Ceramic splashback, chipped painted steel, drains and old maintenance equipment.
 for span in [[-12.5,-13.84,12.5],[12,-13.84,13],[-16.5,4.17,10]]:
  k.box("FactoryTileSplashback",Vector3(span[0],.85,span[1]),Vector3(span[2],1.65,.045),"plant_tile")
 for x in [-17,-9,6,17]:
  k.box("DrainChannel",Vector3(x,.025,1.8),Vector3(1.5,.026,.22),"dark")
  for dx in range(10):k.box("DrainGrateBar",Vector3(x-.65+dx*.14,.043,1.8),Vector3(.025,.017,.24),"metal")
 for z in [-12,-6]:
  k.box("CableTray",Vector3(0,2.65,z),Vector3(8,.08,.36),"metal")
  for x in [-3,-1,1,3]:k.box("CableTrayCrossbar",Vector3(x,2.72,z),Vector3(.05,.04,.4),"rust")
 for x in [-20,-15]:
  var drum_z=10.8
  k.box("DrumCollision",Vector3(x,.48,drum_z),Vector3(.65,.96,.65),"metal",true).visible=false
  k.cyl("ChemicalDrum",Vector3(x,.48,drum_z),.32,.96,"old_iron")
  for y in [.12,.82]:k.cyl("DrumBand",Vector3(x,y,drum_z),.334,.035,"metal")
  k.box("DrumLabel",Vector3(x,.55,drum_z+.325),Vector3(.3,.32,.012),"paper")
 for x in [7,17]:
  for z in [-11,-4]:
   k.box("FloorSpall",Vector3(x,.029,z),Vector3(1.2,.022,.45),"concrete")
 k.signboard("ВОДООЧИСТКА  /  1962",Vector3(-12,2.25,-13.73),4.7)
 k.signboard("先卸压 · 后送电",Vector3(0,2.05,4.22),3.0)
 k.box("ControlWarningPlate",Vector3(0,1.0,5.77),Vector3(.45,.3,.025),"paper")
 k.label("380 В",Vector3(0,1.0,5.80),15)
 # Actual hinged factory exit in an authored opening, with moving collision.
 for x in [13.40,16.60]:k.box("FactoryExitJamb",Vector3(x,1.28,11.85),Vector3(.16,2.56,.28),"metal",true)
 k.box("FactoryExitLintel",Vector3(15,2.55,11.85),Vector3(3.36,.18,.28),"metal")
 for side in [-1,1]:
  var pivot=Node3D.new();pivot.name="FactoryExitLeaf";k.root.add_child(pivot);pivot.position=Vector3(15+side*1.5,0,11.85)
  pivot.set_meta("opening_angle",side*PI*.48);w.factory_exit_leaves.append(pivot)
  var leaf=k.box("FactorySteelLeaf",Vector3(-side*.75,1.25,0),Vector3(1.48,2.48,.10),"old_iron",true,pivot);leaf.set_meta("dynamic",true)
  for y in [.25,1.25,2.25]:k.box("FactoryGateRib",Vector3(-side*.75,y,-.065),Vector3(1.39,.065,.06),"metal",false,pivot).set_meta("dynamic",true)
  k.box("FactoryDoorHandle",Vector3(-side*1.30,1.22,-.12),Vector3(.045,.28,.065),"metal",false,pivot).set_meta("dynamic",true)
  if side==-1:k.box("FactoryLatch",Vector3(1.31,1.05,-.12),Vector3(.30,.065,.065),"metal",false,pivot).set_meta("dynamic",true)
  for y in [.35,2.13]:k.cyl("FactoryDoorHinge",Vector3(0,y,-.03),.055,.25,"rust",pivot).set_meta("dynamic",true)
 k.signboard("ВЫХОД  /  厂区道路",Vector3(15,2.88,11.66),3.1)
