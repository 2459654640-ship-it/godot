extends RefCounted
## The platform, wet service gallery and medical office have distinct materials and use.
static func prepare(k):
 for entry in [["rail_floor","star_terrazzo","a5a99c",.48],["rail_platform","art28_terrazzo","c4bfaa",.60],["rail_service","factory_floor_tile_v13","9ea9a4",.55],["rail_tile","plant_ivory_tile","c2c5b3",.55],["rail_paint","factory_green_wall_v13","819089",.50]]:
  var m=k.mats.concrete.duplicate();m.albedo_texture=load("res://assets/visual/"+entry[1]+".png");m.albedo_color=Color(entry[2]);m.uv1_scale=Vector3.ONE*entry[3];m.normal_enabled=false;m.roughness_texture=null;m.roughness=.9;k.mats[entry[0]]=m
 k.wall_surface="art28_plaster";k.wall_color=Color("bbc0b3");k.wall_finish_theme="factory"
 k.wall_room_profiles=[{"rect":Rect2(-24,-24,15,48),"style":13},{"rect":Rect2(10,8,12,14),"style":12}]
 var enamel=k.mats.concrete.duplicate();enamel.albedo_texture=load("res://assets/visual/star_enamel.png");enamel.albedo_color=Color("77877b");enamel.uv1_scale=Vector3.ONE*.7;enamel.normal_enabled=false;enamel.roughness_texture=null;enamel.roughness=.78
 k.mats.old_iron=enamel;k.mats.metal=enamel
static func medical_case(k,name:String,p:Vector3):
 var box=k.box(name,p+Vector3(0,.18,0),Vector3(.78,.36,.50),"wood");box.set_meta("dynamic",true);box.visible=false
 for dx in [-.31,.31]:
  var band=k.box(name+"Band",p+Vector3(dx,.19,.257),Vector3(.035,.32,.018),"old_iron");band.set_meta("dynamic",true);band.visible=false
 for size in [Vector3(.26,.015,.06),Vector3(.06,.015,.26)]:
  var cross=k.box(name+"Seal",p+Vector3(0,.367,0),size,"red");cross.set_meta("dynamic",true);cross.visible=false
 return box
static func build(w):
 var k=w.kit
 k.box("TransferOfficeTileFloor",Vector3(-16.8,.014,-15.45),Vector3(11.1,.028,10.5),"rail_tile")
 for x in [-17.10,-13.9]:
  k.box("TransferDoorJamb",Vector3(x,1.22,-9.85),Vector3(.14,2.44,.16),"old_iron")
  k.box("OpenTransferDoor",Vector3(x,1.10,-9.27),Vector3(.10,2.20,1.15),"rail_paint",true)
  for y in [.3,1.1,1.9]:k.cyl("DoorHinge",Vector3(x,y,-9.81),.045,.12,"metal")
 k.box("TransferDoorLintel",Vector3(-15.5,2.52,-9.85),Vector3(3.35,.18,.16),"old_iron")
 for z in [-19,-8,3,17]:k.pipe(Vector3(0,3.07,z),Vector3(0,3.57,z),.022,"metal")
 for x in [-8.7,8.7]:
  for z in [-20,-12,-4,4,12,20]:
   k.cyl("PlatformColumnSkirting",Vector3(x,.17,z),.36,.34,"rail_paint")
   k.cyl("PlatformColumnBand",Vector3(x,1.25,z),.315,.10,"cream")
 # Glazed stone banding stays on the ground plane, below every walking threshold.
 for x in [-3.35,3.35]:k.box("PlatformInlay",Vector3(x,.023,0),Vector3(.16,.015,45),"rail_paint")
 for z in range(-21,23,3):
  for x in [-2.7,2.7]:k.box("PlatformTileJoint",Vector3(x,.021,z),Vector3(.5,.008,.035),"dark")
 # A shaded desk lamp, records and equipment establish the transfer office.
 for p in [Vector3(-18.5,0,-13),Vector3(15,0,11.6)]:
  k.cyl("DeskLampFoot",p+Vector3(0,.87,0),.16,.055,"old_iron")
  k.pipe(p+Vector3(0,.9,0),p+Vector3(.16,1.35,0),.022,"metal")
  var shade=k.cyl("DeskLampShade",p+Vector3(.16,1.34,0),.22,.18,"rail_paint");shade.rotation.z=-.16
  var light=OmniLight3D.new();light.name="TransferDeskLight";w.add_child(light);light.position=p+Vector3(.16,1.20,0);light.light_color=Color("efc58a");light.light_energy=1.2;light.omni_range=4.8;light.shadow_enabled=true
 for z in [-14.2,-11.4]:
  k.cyl("StretcherRestPost",Vector3(-21.5,.42,z),.025,.84,"old_iron")
 k.box("FoldedMedicalStretcher",Vector3(-21.5,.46,-12.8),Vector3(.52,.10,2.8),"cloth")
 for x in [-21.8,-21.2]:k.pipe(Vector3(x,.50,-14.35),Vector3(x,.50,-11.25),.025,"metal")
 # Backup desk faces the clear west side of the control room.
 k.box("BackupCallPedestal",Vector3(18,.42,17.3),Vector3(1.35,.84,.62),"rail_paint",true)
 k.box("BackupCallConsole",Vector3(18,.98,17.3),Vector3(1.45,.30,.68),"old_iron")
 for x in [17.55,18.05]:
  k.box("BackupCallMeter",Vector3(x,1.03,16.94),Vector3(.30,.18,.025),"cream")
  k.box("BackupMeterNeedle",Vector3(x,1.03,16.92),Vector3(.012,.10,.012),"black")
 k.cyl("BackupCallDial",Vector3(18.48,1.03,16.91),.08,.04,"black").rotation.x=PI/2
 k.box("BackupCallHandset",Vector3(18,.80,16.89),Vector3(.55,.09,.08),"black")
 var lamp=k.box("BackupCallIndicator",Vector3(18.57,1.07,16.92),Vector3(.07,.08,.025),"warm_light");lamp.set_meta("dynamic",true)
 for i in 6:k.box("WiredSetCord",Vector3(18.3,.75-i*.07,16.94),Vector3(.025,.04,.025),"black")
 # A sealed spare box on an existing wall cabinet; nothing projects across the corridor.
 k.box("ReplacementPartsCase",Vector3(-22.5,1.60,1.0),Vector3(.40,.28,.6),"wood")
 k.label("СВЯЗЬ / РЕЗЕРВ",Vector3(17,1.9,8.18),20,Color("aaa993"))
 # Wet patches are small reflective films near seepage, with no collision.
 var wet=StandardMaterial3D.new();wet.albedo_color=Color(.14,.21,.20,.32);wet.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;wet.roughness=.18
 for p in [Vector3(-22,.028,-5),Vector3(-21,.028,7),Vector3(1,.027,-15)]:
  var puddle=MeshInstance3D.new();puddle.name="SeepageFilm";var plane=PlaneMesh.new();plane.size=Vector2(1.4,2.3);puddle.mesh=plane;puddle.material_override=wet;puddle.position=p;puddle.rotation.y=.25;w.add_child(puddle)
 # Small maintenance details are attached to walls or existing furniture.
 for z in [-16,-7,6]:
  k.box("GalleryServiceMark",Vector3(-23.83,1.3,z),Vector3(.025,.65,.42),"cream")
  for y in [1.13,1.28,1.43]:k.box("GalleryMarkInk",Vector3(-23.81,y,z),Vector3(.014,.022,.27),"dark")
 for p in [Vector3(-19.8,.84,-13),Vector3(14,.84,11.6)]:
  k.box("TransferReceiptBook",p,Vector3(.35,.025,.46),"paper")
  k.cyl("EnamelCup",p+Vector3(.55,.11,0),.075,.17,"cream")
 k.box("TransferOrderBoard",Vector3(-20.1,1.75,-20.80),Vector3(1.65,1.15,.05),"wood")
 for x in [-20.5,-19.8]:
  k.box("PinnedTransferOrder",Vector3(x,1.77,-20.758),Vector3(.57,.84,.018),"paper")
  for y in [1.52,1.65,1.78,1.91]:k.box("OrderInk",Vector3(x,y,-20.745),Vector3(.42,.018,.005),"dark")
 k.box("WaitingLinenShelf",Vector3(-23,.85,19.2),Vector3(.6,.12,1.3),"wood")
 for z in [18.9,19.25,19.55]:k.box("WaitingLinenPack",Vector3(-23,.99,z),Vector3(.40,.16,.28),"paper")
 for x in [-19,-17.8]:medical_case(k,"ReturnedMedicalCase",Vector3(x,.48,17))
static func commune(w):
 var k=w.kit
 for dx in [-.4,.4]:medical_case(k,"CommuneMedicalArrival",Vector3(-1.9+dx,.84,18))
