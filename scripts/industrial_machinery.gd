extends RefCounted
## Two horizontal centrifugal sets, sized to the existing 2.6 x 1.8m hulls.
## No decorative collider or raised strip is added to the servicing aisle.
static func shaft(k,id:String,p:Vector3,r:float,length:float,mat:String):
 var node=k.cyl(id,p,r,length,mat);node.rotation.z=PI/2;node.mesh.radial_segments=48;return node
static func bypass(k,p:Vector3):
 var c=p+Vector3(0,0,-1.5)
 k.box("BypassHull",c+Vector3(0,.8,0),Vector3(1.5,1.6,1.5),"metal",true).visible=false
 k.box("BypassConcretePad",c+Vector3(0,.10,0),Vector3(1.4,.20,1.3),"concrete")
 for dx in [-.55,.55]:
  k.pipe(c+Vector3(dx,.20,0),c+Vector3(dx,.9,0),.115,"old_iron")
  k.cyl("BypassFloorFlange",c+Vector3(dx,.24,0),.20,.07,"metal")
 k.pipe(c+Vector3(-.55,.9,0),c+Vector3(.55,.9,0),.13,"old_iron")
 for dx in [-.36,.36]:
  shaft(k,"BypassFlange",c+Vector3(dx,.9,0),.22,.07,"metal")
  for i in 6:
   var a=TAU*i/6.;shaft(k,"BypassFlangeBolt",c+Vector3(dx+.047,.9+sin(a)*.17,cos(a)*.17),.024,.06,"brass")
 k.ellipsoid("CastGateValveBody",c+Vector3(0,1.02,0),Vector3(.23,.35,.23),"old_iron")
 k.pipe(c+Vector3(0,1.17,0),c+Vector3(0,1.42,.44),.035,"metal")
 var at=c+Vector3(0,1.42,.46);var ring=MeshInstance3D.new();ring.name="BypassHandwheel";ring.set_meta("design_id","BypassHandwheel")
 var torus=TorusMesh.new();torus.inner_radius=.20;torus.outer_radius=.26;torus.rings=32;torus.ring_segments=12;ring.mesh=torus;ring.material_override=k.mats.red;k.root.add_child(ring);ring.position=at;ring.rotation.x=PI/2
 for i in 3:
  var a=TAU*i/3.;k.pipe(at,at+Vector3(cos(a)*.23,sin(a)*.23,0),.018,"red")
 k.box("BypassOperationPlate",c+Vector3(0,.62,.69),Vector3(.65,.23,.025),"brass")
 k.label("ОБВОД",c+Vector3(0,.62,.708),11,Color("292e2b"))
static func pumps(k):
 var bevel=preload("res://scripts/production_props.gd")
 for x in [-16.,-10.]:
  k.box("PumpCollision",Vector3(x+.35,.75,-10),Vector3(2.6,1.5,1.8),"metal",true).visible=false
  k.box("PumpConcretePlinth",Vector3(x+.35,.13,-10),Vector3(2.60,.26,1.8),"concrete")
  bevel.bevel(k,"PumpCommonBedplate",Vector3(x+.35,.32,-10),Vector3(2.45,.16,1.55),"old_iron")
  for dx in [-.66,1.30]:
   for z in [-10.60,-9.40]:
    k.cyl("PumpAnchorWasher",Vector3(x+dx,.417,z),.07,.026,"metal")
    k.cyl("PumpAnchorBolt",Vector3(x+dx,.446,z),.039,.045,"brass")
  for dx in [-.36,.80,1.20]:bevel.bevel(k,"MachineMountFoot",Vector3(x+dx,.48,-10),Vector3(.32,.18,.90),"old_iron")
  # A horizontal volute and cover, with a coaxial motor and protected coupling.
  k.ellipsoid("CentrifugalPumpVolute",Vector3(x-.35,1.01,-10),Vector3(.34,.62,.59),"old_iron")
  shaft(k,"PumpInspectionCover",Vector3(x-.69,1.01,-10),.47,.065,"metal")
  for i in 10:
   var angle=TAU*i/10.;shaft(k,"PumpCoverBolt",Vector3(x-.735,1.01+sin(angle)*.39,-10+cos(angle)*.39),.035,.055,"brass")
  shaft(k,"PumpCouplingShaft",Vector3(x+.19,.97,-10),.085,.43,"metal")
  bevel.bevel(k,"CouplingSafetyCover",Vector3(x+.20,1.00,-10),Vector3(.43,.40,.42),"old_iron")
  for z in [-10.16,-10.08,-10,-9.92,-9.84]:k.box("CouplingGuardVent",Vector3(x+.2,1.205,z),Vector3(.26,.007,.018),"dark")
  shaft(k,"HorizontalPumpMotor",Vector3(x+.95,.97,-10),.35,.98,"old_iron")
  for dx in [.57,.70,.83,.96,1.09,1.22,1.35]:shaft(k,"MotorCoolingFin",Vector3(x+dx,.97,-10),.40,.032,"old_iron")
  shaft(k,"MotorFanCowl",Vector3(x+1.48,.97,-10),.375,.20,"metal")
  for angle in range(0,360,45):
   var a=deg_to_rad(angle);shaft(k,"MotorFanGrilleHole",Vector3(x+1.587,.97+sin(a)*.24,-10+cos(a)*.24),.045,.006,"dark")
  bevel.bevel(k,"MotorTerminalBox",Vector3(x+.95,1.36,-10),Vector3(.38,.19,.30),"old_iron")
  k.pipe(Vector3(x+1.1,1.38,-10.16),Vector3(x+1.1,.49,-10.50),.025,"dark")
  # Discharge and inlet are mechanically connected, rather than floating props.
  k.pipe(Vector3(x-.35,1.42,-10),Vector3(x-.35,1.42,-13.60),.14,"rust")
  for z in [-10.9,-12.6]:
   var f=k.cyl("DischargeBoltedFlange",Vector3(x-.35,1.42,z),.23,.08,"old_iron");f.rotation.x=PI/2
   for i in 8:
    var a=TAU*i/8.;var bolt=k.cyl("FlangeBolt",Vector3(x-.35+cos(a)*.18,1.42+sin(a)*.18,z+.05),.022,.055,"brass");bolt.rotation.x=PI/2
  k.pipe(Vector3(x-.35,1.50,-11.7),Vector3(x-.35,1.95,-11.7),.045,"old_iron")
  var wheel=k.cyl("PumpIsolationHandwheel",Vector3(x-.35,1.98,-11.7),.23,.05,"red");wheel.mesh.radial_segments=32
  k.pipe(Vector3(x-.35,1.31,-9.95),Vector3(x-.35,1.80,-9.45),.025,"metal")
  preload("res://scripts/environment_details.gd").gauge(k,Vector3(x-.35,1.88,-9.40),.17)
  k.box("PumpNameplate",Vector3(x+.35,.47,-9.215),Vector3(.53,.15,.012),"brass")
  k.label("НАСОС",Vector3(x+.35,.47,-9.205),10,Color("282e2b"))
  for dx in [-1.12,1.82]:k.box("PumpServiceLine",Vector3(x+dx,.028,-10),Vector3(.065,.006,2.30),"cream")
