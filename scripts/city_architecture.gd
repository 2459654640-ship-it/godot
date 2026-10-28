extends RefCounted
const Site=preload("res://scripts/surface_site.gd")
const Ground=preload("res://scripts/city_ground.gd")
const Urban=preload("res://scripts/district_urban.gd")
static func materials(k):
 for pair in [["district_brick","city29_brick","c5b6a8",.32],["district_concrete","city29_plaster","b7b8b2",.27],["district_ochre","city29_plaster","c2b08a",.28],["city_paving","city29_paving","c2c5c1",.30],["district_roof_snow","art28_snow","aab5bd",.28],["shelter_snow","art28_snow","aab5bd",.28]]:
  Site.material(k,pair[0],"res://assets/visual/"+pair[1]+".png",Color(pair[2]));k.mats[pair[0]].uv1_scale=Vector3.ONE*pair[3]
 k.mats.district_roof_snow.set_meta("roof_snow",true)
 k.mats.surface_brick=k.mats.district_brick
 var dirt=k.mats.concrete.duplicate();dirt.albedo_texture=load("res://assets/visual/city29_brick.png");dirt.albedo_color=Color("a7a196");dirt.cull_mode=BaseMaterial3D.CULL_DISABLED;dirt.normal_enabled=false;k.mats.city_rubble=dirt
static func hull(k,p:Vector3,size:Vector3,id:String="CitySolid"):
 var h=k.box(id,p,size,"dark",true);h.visible=false;return h
static func mound(k,p:Vector3,size:Vector3,seed:int,solid:bool=true):
 # Irregular triangular rubble, not a stretched sphere or a flat snow decal.
 var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
 var rim=[]
 for n in 10:
  var a=TAU*n/10;rim.append(p+Vector3(cos(a)*size.x*(.44+.05*sin(n*7+seed)),.03,sin(a)*size.z*(.44+.05*cos(n*3+seed))))
 var peak=p+Vector3(size.x*.09,size.y,-size.z*.08)
 for n in 10:
  var normal=(peak-rim[n]).cross(rim[(n+1)%10]-rim[n]).normalized()
  if normal.y<0:normal=-normal
  st.set_normal(normal)
  for v in [rim[n],rim[(n+1)%10],peak]:st.add_vertex(v)
 var mesh=MeshInstance3D.new();mesh.name="CollapsedMasonrySlope";mesh.mesh=st.commit();mesh.material_override=k.mats.city_rubble;k.root.add_child(mesh)
 if solid:hull(k,p+Vector3.UP*size.y*.4,Vector3(size.x*.72,maxf(.5,size.y*.8),size.z*.72),"RubbleFootprint")
 for n in 14:
  var angle=n*2.399+seed;var radius=.12+.30*float(n%5)/4;var at=p+Vector3(cos(angle)*size.x*radius,size.y*(.70-radius),sin(angle)*size.z*radius)
  var chunk=k.box("CollapsedMasonryBlock",at,Vector3(.7+.2*(n%3),.35,.55),"district_brick" if n%3 else "district_concrete");chunk.rotation=Vector3(.2*sin(n),angle,.15*cos(n))
  if n%3==0:k.pipe(at+Vector3.UP*.3,at+Vector3(.4,.7,.2),.016,"rust")
 for sign in [-1,1]:k.ellipsoid("RubbleWindDrift",p+Vector3(sign*size.x*.3,.05,size.z*.32),Vector3(size.x*.23,.16,size.z*.15),"snowbank")
static func room(k,p:Vector3,size:Vector2,id:String):
 Ground.apron(k,Vector2(p.x,p.z),size)
 var mat="district_concrete" if id=="clinic" else "district_brick"
 k.box("CityInteriorBack",p+Vector3(0,1.75,-size.y/2),Vector3(size.x,3.5,.36),mat,true)
 for sign in [-1,1]:
  k.box("CityInteriorSide",p+Vector3(sign*size.x/2,1.75,0),Vector3(.36,3.5,size.y),mat,true)
  # Front wings frame a generous central entrance; nothing crosses the threshold.
  k.box("CityInteriorFrontWing",p+Vector3(sign*(size.x/4+.65),1.3,size.y/2),Vector3(size.x/2-1.3,2.6,.36),mat,true)
 k.box("CityInteriorDoorLintel",p+Vector3(0,2.95,size.y/2),Vector3(size.x,.65,.4),mat)
 for x in [-1.3,1.3]:k.box("CityDoorFrame",p+Vector3(x,1.35,size.y/2+.2),Vector3(.12,2.7,.12),"old_iron")
 for z in [-size.y*.3,0,size.y*.3]:
  k.box("CityRoofBeam",p+Vector3(0,3.5,z),Vector3(size.x,.20,.18),"old_iron")
 # Partially collapsed roof: the room still reads from the street, and fades on entry.
 var interior=Rect2(p.x-size.x*.5,p.z-size.y*.5,size.x,size.y)
 var roof=k.box("CityInteriorRoof",p+Vector3(0,3.65,0),Vector3(size.x,.18,size.y),"corrugated")
 roof.set_meta("interior_rect",interior)
 var snow=k.box("CityInteriorRoofSnow",p+Vector3(0,3.79,0),Vector3(size.x-.2,.06,size.y-.2),"district_roof_snow")
 snow.set_meta("interior_rect",interior)
 if id=="clinic":
  # Waiting room and treatment room; a 2.2m opening connects the two.
  for z in [-5.3,4.8]:k.box("ClinicPartition",p+Vector3(1.2,1.3,z),Vector3(.16,2.6,5.8 if z<0 else 6.8),"plaster",true)
  k.table(p+Vector3(-3,0,2),2.2)
  k.box("ClinicEvacuationLedger",p+Vector3(-3,.825,2),Vector3(.55,.035,.4),"paper")
  for z in [-3,1,5]:k.bench(p+Vector3(-7,0,z),2.2,true,PI/2)
  k.bed(p+Vector3(5,0,-5),"cloth");k.bed(p+Vector3(5,0,4),"cloth")
  k.locker(p+Vector3(6,0,-5.8))
  k.box("ClinicMedicineCross",p+Vector3(6,1.6,-5.35),Vector3(.5,.12,.02),"red")
  k.box("ClinicMedicineCrossVertical",p+Vector3(6,1.6,-5.33),Vector3(.12,.5,.02),"red")
  var label=k.label("МЕДПУНКТ",p+Vector3(0,3.03,size.y/2+.25),27,Color("bcb7a4"));label.rotation.y=0
 else:
  k.table(p+Vector3(-5,0,1),2.6);k.box("CivilDefenceLog",p+Vector3(-5,.83,1),Vector3(.6,.035,.45),"paper")
  for x in [3,5,7]:
   k.box("RadioRack",p+Vector3(x,1.1,-1),Vector3(1.4,2.2,.7),"old_iron",true)
   for y in [.5,1,1.6]:
    k.box("RackMeter",p+Vector3(x-.25,y,-.63),Vector3(.5,.24,.02),"cream")
    k.cyl("RackDial",p+Vector3(x+.3,y,-.57),.06,.05,"black").rotation.x=PI/2
   for z in [-.8,-.5]:k.pipe(p+Vector3(x,2.2,z),p+Vector3(x,3,z),.025,"rust")
  for x in [-1.2,1.2]:k.box("RoofAntennaMast",p+Vector3(x,5.5,-5),Vector3(.09,4,.09),"old_iron")
  for y in [4,5.5,7]:k.pipe(p+Vector3(-2,y,-5),p+Vector3(2,y,-5),.035,"old_iron")
  k.label("ГРАЖДАНСКАЯ ОБОРОНА",p+Vector3(0,3.03,size.y/2+.25),20,Color("bcb7a4"))
static func factory(k):
 Ground.apron(k,Vector2(-67,-28),Vector2(48,16))
 # High pump hall with buttressed, arched industrial window bays; no residential facade.
 var c=Vector3(-62,0,-44);var sx=22.0;var sz=25.0;var h=8.1
 for side in [-1,1]:
  var x=c.x+side*sx/2
  k.box("PumpHallSidePlinth",Vector3(x,.75,c.z),Vector3(.55,1.5,sz),"district_brick")
  k.box("PumpHallSideCornice",Vector3(x,7.3,c.z),Vector3(.65,1.6,sz),"district_brick")
  for n in 6:
   var z=c.z-sz/2+(n+.5)*sz/6
   k.box("FactoryButtress",Vector3(x,3.85,z-sz/12),Vector3(.95,7.7,.62),"district_brick")
   k.box("FactoryDeepWindow",Vector3(x,4,z),Vector3(.045,4.7,3.25),"exterior_glass")
   for dz in [-1.6,0,1.6]:k.box("FactoryWindowVertical",Vector3(x+side*.07,3.9,z+dz),Vector3(.12,4.9,.06),"old_iron")
   for y in [1.65,2.8,4,5.2,6.3]:k.box("FactoryWindowHorizontal",Vector3(x+side*.08,y,z),Vector3(.13,.06,3.25),"old_iron")
 # Whole back wall. Front central opening is a real service door under an arch.
 k.box("FactoryRearWall",c+Vector3(0,h/2,-sz/2),Vector3(sx,h,.55),"district_brick")
 for dx in [-8,-3,2,7]:
  var z=c.z+sz/2
  if dx==2:
   k.box("FactoryServiceDoor",Vector3(c.x+dx,1.65,z),Vector3(3.7,3.3,.16),"corrugated")
   k.box("FactoryDoorCrossbar",Vector3(c.x+dx,1.6,z+.13),Vector3(3.4,.10,.06),"metal")
   k.box("FactoryEntryLintel",Vector3(c.x+dx,4.9,z),Vector3(4.7,3,.55),"district_brick")
  else:
   k.box("FactoryFrontPlinth",Vector3(c.x+dx,.7,z),Vector3(4.8,1.4,.55),"district_brick")
   k.box("FactoryFrontWindow",Vector3(c.x+dx,3.7,z),Vector3(3.4,4.5,.06),"exterior_glass")
   for ix in [-1.65,-.55,.55,1.65]:k.box("FactoryFrontMullion",Vector3(c.x+dx+ix,3.7,z+.07),Vector3(.06,4.5,.12),"old_iron")
   for y in [1.5,2.6,3.7,4.8,5.9]:k.box("FactoryFrontTransom",Vector3(c.x+dx,y,z+.07),Vector3(3.4,.06,.12),"old_iron")
  for edge in [-2.4,2.4]:k.box("FactoryFrontPier",Vector3(c.x+dx+edge,3.8,z),Vector3(.65,7.6,.85),"district_brick")
  # Voussoirs form a true arch silhouette over each bay.
  for n in 12:
   var a=PI*(n+.5)/12;var arch=k.box("FactoryWindowArch",Vector3(c.x+dx+cos(a)*1.86,5.95+sin(a)*1.05,z+.15),Vector3(.50,.36,.56),"district_concrete");arch.rotation.z=a-PI/2
 k.box("FactoryFrontCornice",c+Vector3(0,7.65,sz/2),Vector3(sx+.6,.75,.85),"district_brick")
 var root=Node3D.new();root.position=c;k.root.add_child(root);Urban.roof(k,root,Vector2(sx,sz),h,"waterworks",14)
 hull(k,c+Vector3.UP*3,Vector3(sx+.8,6,sz+.8),"FactoryHallHull")
 # Attached boiler house, coal bunker, chimney and service pipes are one readable compound.
 var annex=Vector3(-84,0,-43)
 k.box("BoilerHouseShell",annex+Vector3.UP*2.5,Vector3(13,5,21),"district_brick",true)
 for z in [-50,-45,-40]:
  k.box("BoilerHouseWindow",Vector3(-77.46,3,z),Vector3(.04,1.5,2.2),"exterior_glass")
  for y in [2.3,3,3.7]:k.box("BoilerWindowMullion",Vector3(-77.4,y,z),Vector3(.06,.06,2.2),"old_iron")
 k.box("BoilerFlatRoof",Vector3(-84,5.1,-43),Vector3(13.5,.25,21.5),"old_iron")
 k.box("BoilerRoofSnow",Vector3(-84,5.27,-43),Vector3(13.2,.08,21.2),"district_roof_snow")
 k.cyl("FactoryChimneyBase",Vector3(-88,1,-58),1.8,2,"district_brick")
 k.cyl("FactoryChimneyStack",Vector3(-88,9,-58),1.2,16,"district_brick",null,.65)
 for y in [3,6,9,12,15]:k.cyl("ChimneyIronBand",Vector3(-88,y,-58),1.25-(y-1)*.035,.12,"old_iron")
 hull(k,Vector3(-88,2,-58),Vector3(3,4,3))
 for pair in [[Vector3(-77,2.5,-49),Vector3(-74,2.5,-49)],[Vector3(-84,2,-54),Vector3(-84,2,-62)],[Vector3(-84,2,-62),Vector3(-60,2,-62)]]:k.pipe(pair[0],pair[1],.24,"rust")
 for x in [-80,-60]:tank(k,Vector3(x,0,-67),5.2)
 for x in [-62,-58]:
  k.box("FactoryGateBrickPier",Vector3(x,1.6,-23),Vector3(.65,3.2,.65),"district_brick",true)
  k.box("FactoryGateStoneCap",Vector3(x,3.25,-23),Vector3(.85,.16,.85),"district_concrete")
 k.box("FactoryGateHeader",Vector3(-60,3.22,-23),Vector3(4.6,.32,.48),"old_iron")
 k.label("ВОДОКАНАЛ · 1936",Vector3(-60,3.24,-22.72),20,Color("d1c6ab"))
 for segment in [[Vector3(-94,0,-76),Vector3(-48,0,-76)],[Vector3(-44,0,-76),Vector3(-42,0,-76)],[Vector3(-94,0,-76),Vector3(-94,0,-23)],[Vector3(-94,0,-23),Vector3(-63,0,-23)],[Vector3(-57,0,-23),Vector3(-42,0,-23)],[Vector3(-42,0,-23),Vector3(-42,0,-48)]]:Site.fence(k,segment[0],segment[1])
 for z in [-26,-28,-30]:
  for row in 2:k.pipe(Vector3(-86,.28+row*.36,z),Vector3(-80,.28+row*.36,z),.17,"rust")
static func tank(k,p:Vector3,r:float):
 k.cyl("ClarifierSludge",p+Vector3.UP*.10,r-.25,.15,"dark")
 for n in 36:
  var a=TAU*n/36;var b=TAU*(n+1)/36;var q=p+Vector3(sin(a)*r,0,cos(a)*r);var e=p+Vector3(sin(b)*r,0,cos(b)*r)
  var wall=k.box("ClarifierRing",(q+e)/2+Vector3.UP*.7,Vector3(.28,1.4,q.distance_to(e)+.04),"district_concrete");wall.rotation.y=atan2(e.x-q.x,e.z-q.z)
 k.box("ClarifierBridge",p+Vector3.UP*1.5,Vector3(r*2,.12,.9),"old_iron")
 for z in [-.46,.46]:k.pipe(p+Vector3(-r,2.35,z),p+Vector3(r,2.35,z),.025,"metal")
 for x in [-r,-r*.5,0,r*.5,r]:
  for z in [-.46,.46]:k.pipe(p+Vector3(x,1.5,z),p+Vector3(x,2.35,z),.025,"metal")
 k.cyl("ClarifierDrive",p+Vector3.UP*1.8,.4,.6,"rust")
 hull(k,p+Vector3.UP*.6,Vector3(r*1.65,1.2,r*1.65),"ClarifierFootprint")
static func basin(k):
 k.box("BasinConcreteBed",Vector3(91,.014,-61),Vector3(34,.028,30),"district_concrete")
 for x in [74,108]:
  if x==74:
   for z in [-67.5,-50.5]:k.box("BasinRetainingWall",Vector3(x,.9,z),Vector3(.6,1.8,17 if z< -60 else 9),"district_concrete",true)
  else:k.box("BasinRetainingWall",Vector3(x,.9,-61),Vector3(.6,1.8,30),"district_concrete",true)
 for z in [-76,-46]:k.box("BasinRetainingWall",Vector3(91,.9,z),Vector3(34,1.8,.6),"district_concrete",true)
 var gate=k.box("BasinInspectionGate",Vector3(74,1,-57),Vector3(.22,2,3.6),"corrugated",true);gate.set_meta("dynamic",true)
 for z in [-59,-55]:k.box("BasinGatePost",Vector3(74,1.2,z),Vector3(.35,2.4,.35),"old_iron",true)
 for p in [Vector3(80,0,-70),Vector3(100,0,-50)]:
  k.box("BasinBaffle",p+Vector3.UP*.8,Vector3(3.4,1.6,1.2),"district_concrete",true)
  k.pipe(p+Vector3(-1,1.8,0),p+Vector3(1,1.8,0),.08,"rust")
 for x in [83,98]:
  k.box("IntakeHousing",Vector3(x,1,-75),Vector3(3.5,2,1.8),"old_iron",true)
  for dx in [-1.3,-.65,0,.65,1.3]:k.box("IntakeGrille",Vector3(x+dx,1,-74.03),Vector3(.08,1.6,.1),"metal")
 k.box("BasinControlPedestal",Vector3(72,.7,-54.6),Vector3(1.1,1.4,.5),"old_iron",true)
 for x in [71.7,72.3]:k.cyl("BasinValveWheel",Vector3(x,1.1,-54.25),.18,.06,"red").rotation.x=PI/2
 k.pipe(Vector3(72,.4,-54.6),Vector3(78,.4,-54.6),.18,"rust")
 k.crate(Vector3(69,0,-51.8),Vector3(1,.7,.7));k.lamp(Vector3(71,2.8,-53),true,.5,5)
static func edge(k):
 # The playable slice is framed by destroyed urban fabric, not a municipal perimeter wall.
 # Jagged demolition piles have explicit collision; buildings continue behind them.
 # West: the rear walls of residential blocks have collapsed into a continuous
 # irregular apron. North/south: broken roads disappear under demolition debris.
 for n in 9:
  var z=-91+n*24;var x=-119+sin(n*2.3)*2
  mound(k,Vector3(x,0,z),Vector3(15,3.2+float(n%3)*1.2,32),70+n)
  if n%2==0:
   var wall=k.box("CollapsedQuarterWall",Vector3(x-1,2.7,z),Vector3(.5,5.4,14),"district_brick");wall.rotation.z=.12
 for side in [-1,1]:
  for n in 9:
   var x=-116+n*29;var z=side*(100+cos(n*1.8)*2)
   mound(k,Vector3(x,0,z),Vector3(38,2.9+float(n%4)*.7,16),90+n+side*13)
   if n%3==1:
    var slab=k.box("DroppedConcreteFloor",Vector3(x+3,2,z),Vector3(13,.45,6),"district_concrete");slab.rotation=Vector3(.12,0,.24)
 # East: a raised freight embankment, with an actual track above the slope.
 for n in 9:mound(k,Vector3(122,0,-96+n*25),Vector3(15,3.4,36),131+n)
 for x in [124.24,125.76]:k.box("BackgroundEmbankmentRail",Vector3(x,3.48,0),Vector3(.07,.12,220),"old_iron")
 for z in range(-109,110):k.box("BackgroundEmbankmentSleeper",Vector3(125,3.4,z),Vector3(2.6,.10,.18),"wood")
 # Damaged viaduct recedes behind the north streets.
 for x in range(-100,121,22):
  k.box("ViaductPier",Vector3(x,3.8,-113),Vector3(1.4,7.6,4),"district_concrete")
  var deck=k.box("BrokenViaductDeck",Vector3(x+7,7.6,-113),Vector3(18,.8,8),"district_concrete");deck.rotation.z=.025*sin(x)
  for z in [-116.7,-109.3]:k.box("ViaductParapet",Vector3(x+7,8.3,z),Vector3(18,.7,.25),"district_concrete")
 # Invisible backstop sits inside the rubble mass and prevents walking off the finite mesh.
 for x in [-120,120]:hull(k,Vector3(x,2,0),Vector3(.4,4,200),"CityEdgeBackstop")
 for z in [-100,100]:hull(k,Vector3(0,2,z),Vector3(240,4,.4),"CityEdgeBackstop")
