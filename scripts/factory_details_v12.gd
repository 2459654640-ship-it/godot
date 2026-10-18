extends RefCounted
const Detail=preload("res://scripts/facility_detail.gd")
static func label_face(k,id:String,p:Vector3,size:Vector2,asset:String):
 var quad=MeshInstance3D.new();quad.name=id;quad.set_meta("factory_decal",true)
 var q=QuadMesh.new();q.size=size;quad.mesh=q
 var m=StandardMaterial3D.new();m.albedo_texture=load("res://assets/visual/"+asset+".png");m.roughness=1;quad.material_override=m
 k.root.add_child(quad);quad.position=p;quad.set_meta("mount_surface","wall_or_crate_front")
static func build(w):
 var k=w.kit
 # Every sheet faces +Z, mounted centimetres in front of a real north-facing
 # wall/box face, away from door cuts. None has a room-sized backing rectangle.
 for spec in [["PumpServiceChart",Vector3(-13,1.55,-13.845),Vector2(1.25,1.25),"plant_pump_chart"],["ArchiveShiftRoster",Vector3(-20.4,1.50,4.15),Vector2(.85,1.05),"plant_roster_chart"],["ArchiveSafetySheet",Vector3(-12.1,1.45,4.15),Vector2(.85,1.05),"plant_safety_chart"],["RepairToolBoard",Vector3(-.8,1.60,-9.845),Vector2(2.1,1.25),"plant_tool_board"],["AirlockSafetySheet",Vector3(6.5,1.45,4.15),Vector2(.85,1.10),"plant_safety_chart"]]:label_face(k,spec[0],spec[1],spec[2],spec[3])
 # Controller's physical front is z=5.77. Keep warning on that housing.
 label_face(k,"ControllerHighVoltage",Vector3(.65,1.35,5.80),Vector2(.42,.50),"plant_electric_warning")
 for x in [-16,-10]:
  var pad=k.box("PumpMaintenanceMat",Vector3(x,.028,-8.35),Vector3(2.0,.014,1.0),"plant_rubber")
  pad.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 # Repair-room cabinet has a consolidated footprint; the central work route
 # and both encounter entrances remain clear.
 k.box("RepairDrawerCabinet",Vector3(-4.8,.5,-8.9),Vector3(.8,1,.65),"plant_rust_steel",true)
 for y in [.25,.52,.79]:
  k.box("RepairDrawer",Vector3(-4.8,y,-8.56),Vector3(.70,.19,.025),"old_iron")
  k.box("RepairDrawerPull",Vector3(-4.8,y,-8.53),Vector3(.20,.035,.035),"metal")
 for x in [-5.02,-4.75,-4.48]:k.cyl("RepairOilBottle",Vector3(x,1.13,-8.9),.07,.25,"old_iron")
 # Existing crates are on a two-row storage grid. Label their fronts, never
 # free-float a sign in front of the aisle or the animated gate.
 for x in [8,12,16]:
  label_face(k,"FilterShippingLabel",Vector3(x,.55,-9.485),Vector2(.55,.48),"plant_filter_label")
  for dx in [-.48,0,.48]:k.box("StoragePalletSlat",Vector3(x+dx,.035,-11),Vector3(.22,.035,1.08),"wood")
 # Replacement filters on the two actual shelf units, not across walk space.
 for x in [6.5,17]:
  for y in [.48,1.02,1.56]:
   for dx in [-.50,0,.50]:
    k.cyl("WrappedFilter",Vector3(x+dx,y+.19,-8),.13,.35,"paper")
    for h in [-.10,.10]:k.cyl("FilterBinding",Vector3(x+dx,y+.19+h,-8),.135,.025,"metal")
 # Hangers mounted beside, not in front of, the archive doorway.
 for x in [-22,-21.5]:
  k.box("ArchiveWallHook",Vector3(x,1.6,4.25),Vector3(.035,.12,.2),"rust")
 k.box("ArchiveMapCabinet",Vector3(-11,.8,10.8),Vector3(.7,1.6,.6),"plant_rust_steel",true)
 for y in [.45,.85,1.25]:k.box("ArchiveDrawerPull",Vector3(-11,y,11.125),Vector3(.22,.04,.04),"metal")
