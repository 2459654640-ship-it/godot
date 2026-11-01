extends RefCounted
const Props=preload("res://scripts/production_props.gd")
const Shell=preload("res://scripts/facility_shell.gd")
static func build(w):
 Props.prepare(w.kit)
 match w.floor_id:
  "junction":junction(w)
  "star_interior":star(w)
  "relay":relay(w)
 w.kit.finish_walls()
static func base(w,star:bool=false):
 var k=w.kit;k.wall_surface="art28_plaster";k.wall_color=Color("b4bfb7" if star else "b5b6a4");k.wall_finish_theme="factory"
 k.wall_room_profiles=[{"rect":Rect2(-40,-40,80,80),"style":12}]
 k.mats.concrete=k.mats.institution_floor;k.mats.metal=k.mats.institution_enamel
 var plan:Dictionary=preload("res://scripts/late_layouts.gd").PLANS[w.floor_id]
 Shell.build(w,plan,w.zones)
 for zone in w.zones:
  var r:Rect2=zone.rect;var mat="institution_floor" if star else "junction_stone"
  if zone.code in ["01","03","05"]:mat="institution_tile"
  k.box("FinishFloor_"+zone.code,Vector3(r.get_center().x,.026,r.get_center().y),Vector3(r.size.x-.08,.018,r.size.y-.08),mat)
  var light=k.lamp(Vector3(r.position.x+.7,2.45,r.position.y+.25),zone.code in ["01","04","07"],1.6,8)
  light.shadow_enabled=true
static func junction(w):
 base(w);var k=w.kit
 for x in [-5.,5.]:
  for dx in [-.76,.76]:k.box("JunctionRunningRail",Vector3(x+dx,.032,0),Vector3(.075,.065,49),"dark_steel")
  for z in range(-24,25):k.box("JunctionSleeper",Vector3(x,.021,z),Vector3(2.5,.04,.17),"warm_wood")
 for x in [-2.25,2.25]:k.box("PlatformEdgeInlay",Vector3(x,.047,0),Vector3(.13,.012,48),"paper")
 for z in [-22,-14,-6,2,10,18]:
  Props.arch(k,Vector3(0,2.2,z),16.2,2.4)
  for x in [-7.9,7.9]:
   k.cyl("JunctionColumn",Vector3(x,1.1,z),.23,2.2,"junction_paint")
   k.cyl("JunctionColumnFoot",Vector3(x,.12,z),.30,.24,"dark_steel")
 Props.carriage(k,Vector3(5,0,10),0,true)
 Props.carriage(k,Vector3(-5,0,-16))
 # Comfortable waiting bays are clear of the two separate track envelopes.
 for p in [Vector3(12,0,-17.5),Vector3(22,0,-17.5),Vector3(-24,0,-19)]:k.bench(p,2.8,true)
 for x in [11.5,15,18.5]:k.bed(Vector3(x,0,-8),"cloth")
 k.table(Vector3(21,0,-16),2.5);Props.console(k,Vector3(20,0,10),0)
 k.table(Vector3(17,0,15),3.1)
 for x in [15.8,17.8]:Props.chair(k,Vector3(x,0,16.2))
 for x in [-24,-22.7,-21.4]:k.locker(Vector3(x,0,8.3))
 Props.rack(k,Vector3(-24,0,20),PI)
 k.table(Vector3(-22,0,-18),3.5);Props.chair(k,Vector3(-22,0,-16.8),PI)
 for x in [-23.2,-21.7]:k.box("WaitingMailPouch",Vector3(x,.86,-18),Vector3(.6,.15,.42),"cloth")
 for z in [-5,-1,3]:
  k.pipe(Vector3(-28.7,1.15,z),Vector3(-28.7,1.15,z+2),.09,"rust")
  k.lamp(Vector3(-28.65,2.1,z),true,.75,5)
 # Lever frame is beside, rather than on, the pedestrian crossing.
 Props.bevel(k,"PointsLeverBase",Vector3(-3.7,.3,18.8),Vector3(.7,.6,.6),"dark_steel",null,true)
 k.pipe(Vector3(-3.7,.5,18.8),Vector3(-3.7,1.3,18.5),.035,"red")
 for z in [-4,4]:
  for x in [-1.8,1.8]:k.crate(Vector3(x,0,z),Vector3(.9,.65,.9))
 Props.console(k,Vector3(14,0,8),0)
 k.label("ПЕРЕСАДКА / ЮЖНЫЙ ВЫХОД",Vector3(0,2.5,23.8),21)
 for p in [Vector3(-18,0,19),Vector3(22,0,-12)]:
  k.cyl("StationStove",p+Vector3.UP*.55,.3,1.1,"dark_steel");k.pipe(p+Vector3.UP*1.1,p+Vector3.UP*3.4,.08,"dark_steel")
static func star(w):
 base(w,true);var k=w.kit
 # A circular ring of instrumentation defines the main hall instead of a grid of desks.
 var ring=k.cyl("ControlHallTerrazzoDisc",Vector3(0,.047,-1),8.9,.018,"institution_tile");ring.mesh.radial_segments=64
 for i in 12:
  var angle=TAU*float(i)/12.;var p=Vector3(sin(angle)*6.4,0,-1+cos(angle)*6.4)
  if i in [0,3,6,9]:continue
  Props.console(k,p,angle,1.8);Props.chair(k,p+Vector3(sin(angle)*1.2,0,cos(angle)*1.2),angle)
 for z in [-8,0,7]:
  Props.arch(k,Vector3(0,2.75,z),22,2.0)
  for x in [-11.,11.]:
   Props.bevel(k,"HallStructuralColumn",Vector3(x,1.375,z),Vector3(.32,2.75,.38),"institution_enamel",null,true)
   k.box("HallColumnFoot",Vector3(x,.1,z),Vector3(.52,.20,.58),"dark_steel")
 for x in [-6.,6.]:
  for z in [-5.,4.]:
   k.box("HallWorkLightHousing",Vector3(x,3.1,z),Vector3(2.7,.16,.30),"dark_steel")
   k.box("HallWorkLightDiffuser",Vector3(x,3.01,z),Vector3(2.5,.035,.24),"cold_light")
   k.pipe(Vector3(x,3.2,z),Vector3(x,4.2,z),.018,"dark_steel")
   var task=OmniLight3D.new();w.add_child(task);task.position=Vector3(x,2.8,z);task.light_color=Color("cbd4c2");task.light_energy=1.5;task.omni_range=9;task.shadow_enabled=true
 for x in [-6.,6.]:
  k.box("HallChartFrame",Vector3(x,1.8,-10.77),Vector3(5.4,2.1,.12),"dark_steel")
  k.box("HallChartGlass",Vector3(x,1.8,-10.68),Vector3(5.15,1.85,.025),"blue")
  for n in range(6):k.box("HallChartVertical",Vector3(x-2+n*.8,1.8,-10.66),Vector3(.012,1.7,.01),"paper")
  for y in [1.1,1.5,1.9,2.3]:k.box("HallChartHorizontal",Vector3(x,y,-10.65),Vector3(5,.012,.01),"paper")
  for n in [0,1,2]:k.box("HallChartPoint",Vector3(x-1.5+n*1.3,1.3+n*.3,-10.63),Vector3(.05,.05,.02),"warm_light")
 # Separate reception, work, archive, communications and staff areas.
 k.table(Vector3(-7,0,12.5),3.0);Props.chair(k,Vector3(-7,0,11.3),PI)
 k.table(Vector3(3,0,15),4.0)
 for x in [1.5,3,4.5]:Props.chair(k,Vector3(x,0,16.2))
 for x in [-25.5,-24.3,-23.1]:k.locker(Vector3(x,0,19.5))
 for p in [Vector3(-25,0,11),Vector3(-21,0,11)]:k.bed(p,"cloth")
 k.table(Vector3(-8,0,-6),3.0);Props.chair(k,Vector3(-8,0,-7.2),PI)
 k.box("FatherFamilyPhotoFrame",Vector3(-8.8,1.05,-6),Vector3(.28,.40,.05),"warm_wood")
 k.box("FamilyPhotoPaper",Vector3(-8.8,1.05,-5.969),Vector3(.24,.35,.008),"paper")
 for p in [Vector3(-27,0,-6),Vector3(-25.8,0,-6),Vector3(-24.6,0,-6)]:Props.rack(k,p)
 for p in [Vector3(30,0,-6),Vector3(28.7,0,-6),Vector3(27.4,0,-6),Vector3(26.1,0,-6)]:Props.rack(k,p,0)
 for z in [-22,-19,-16]:w.CampaignMaps.bookcase(k,Vector3(-22.5,0,z),2.4)
 k.table(Vector3(-17.5,0,-21.2),3.0)
 for p in [Vector3(19,0,-18),Vector3(24,0,-18)]:
  k.table(p,3.0);Props.console(k,p+Vector3(0,.85,-.1),0,.9)
  k.lamp(p+Vector3(0,2.7,-1.1),false,1.1,6)
 Props.console(k,Vector3(22,0,1),0,2.2);Props.chair(k,Vector3(22,0,2.4),PI)
 Props.console(k,Vector3(0,0,-20),0,3.6)
 k.table(Vector3(-6,0,-20),2.6)
 for x in [-1.2,0,1.2]:Props.chair(k,Vector3(x,0,-18.5),0)
 # The north wall is a diagram, not a fantasy computer screen.
 k.box("ObservationChartFrame",Vector3(0,1.8,-22.8),Vector3(7,2.4,.12),"dark_steel")
 k.box("ObservationChartBoard",Vector3(0,1.8,-22.71),Vector3(6.7,2.15,.04),"blue")
 for i in 7:
  k.box("ChartVerticalGrid",Vector3(-3+i,1.8,-22.676),Vector3(.012,2,.008),"paper")
 for y in [1,1.5,2,2.5]:k.box("ChartHorizontalGrid",Vector3(0,y,-22.675),Vector3(6.5,.012,.008),"paper")
 k.label("ВРЕМЯ / НАПРАВЛЕНИЕ / ИСТОЧНИК",Vector3(0,3.15,-22.72),19)
 for p in [Vector3(-11.7,2.1,16),Vector3(11.7,2.1,-4),Vector3(13,2.1,-22.7)]:k.lamp(p,true,.9,5)
static func relay(w):
 var k=w.kit
 preload("res://scripts/surface_site.gd").ground(w,Rect2(-34,-29,68,58),false,false)
 preload("res://scripts/city_architecture.gd").materials(k)
 var house=Rect2(-30,-24,20,18)
 # The control house is a real four-sided building with a playable ground floor.
 k.box("RelayHouseFloor",Vector3(-20,.016,-15),Vector3(19.6,.032,17.6),"institution_tile")
 for span in [[-30.,-22.],[-18.,-10.]]:k.wall("RelayHouseFront",Vector2(span[0],-6),Vector2(span[1],-6),true)
 k.wall("RelayHouseBack",Vector2(-30,-24),Vector2(-10,-24),true)
 for x in [-30,-10]:k.wall("RelayHouseSide",Vector2(x,-24),Vector2(x,-6),true)
 for x in [-22.4,-17.6]:k.box("RelayHouseDoorFrame",Vector3(x,1.35,-6),Vector3(.16,2.7,.28),"dark_steel")
 for x in [-28,-24,-20,-16,-12]:
  k.box("RelayUpperSill",Vector3(x,3.05,-6),Vector3(4,.65,.25),"exterior_render")
  k.box("RelayUpperGlass",Vector3(x,3.85,-6),Vector3(2.6,.85,.05),"exterior_glass")
  for dx in [-1.5,1.5]:k.box("RelayWindowPier",Vector3(x+dx,3.85,-6),Vector3(.35,1.1,.25),"exterior_render")
  k.box("RelayUpperLintel",Vector3(x,4.5,-6),Vector3(4,.4,.25),"exterior_render")
 for x in [-30,-10]:k.box("RelayHouseUpperSide",Vector3(x,3.7,-15),Vector3(.25,2,18),"exterior_render").set_meta("interior_rect",house)
 k.box("RelayHouseUpperBack",Vector3(-20,3.7,-24),Vector3(20,2,.25),"exterior_render").set_meta("interior_rect",house)
 for node in w.find_children("RelayUpper*","MeshInstance3D",true,false):node.set_meta("interior_rect",house)
 for node in w.find_children("RelayWindowPier*","MeshInstance3D",true,false):node.set_meta("interior_rect",house)
 var roof=k.box("RelayHouseRoof",Vector3(-20,4.8,-15),Vector3(20.5,.16,18.5),"exterior_roof");roof.set_meta("interior_rect",house)
 var snow=k.box("RelayHouseRoofSnow",Vector3(-20,4.91,-15),Vector3(20.4,.06,18.4),"surface_snow");snow.set_meta("interior_rect",house)
 for x in [-26,-23.5,-21]:Props.rack(k,Vector3(x,0,-21.8))
 Props.console(k,Vector3(-23,0,-13.5),0,2.6);k.table(Vector3(-15,0,-20),2.8)
 k.lamp(Vector3(-27,2.4,-23.7),true,2.5,10)
 k.lamp(Vector3(-12,2.4,-6.2),false,1.0,8)
 # Road is bent by collapsed housing, with clear edges and several walkable approaches.
 for pair in [[Vector3(-23,0,28),Vector3(-18,0,10)],[Vector3(-18,0,10),Vector3(-16,0,-4)],[Vector3(-18,0,10),Vector3(15,0,10)]]:preload("res://scripts/surface_site.gd").road(k,pair[0],pair[1],4.2)
 # Four braced legs, dishes, feed cabinet and guy wires make the mast legible at play scale.
 for x in [16,20]:
  for z in [-21,-17]:
   k.box("MastConcreteFoot",Vector3(x,.18,z),Vector3(.9,.36,.9),"concrete",true)
   k.pipe(Vector3(x,.35,z),Vector3(18,10,-19),.10,"dark_steel")
 for y in [2.,4.,6.,8.]:
  for x in [16.,20.]:k.pipe(Vector3(x-(x-18)*y/12,y,-21+y/6),Vector3(18,y+1.5,-19),.045,"dark_steel")
  k.pipe(Vector3(16+y/6,y,-21+y/6),Vector3(20-y/6,y,-17-y/6),.045,"institution_enamel")
 k.pipe(Vector3(18,0,-19),Vector3(18,11,-19),.045,"dark_steel")
 for y in [6.,9.]:
  var dish=k.cyl("MicrowaveDish",Vector3(18.6,y,-18.8),.65,.12,"paper");dish.rotation.x=PI/2
  k.pipe(Vector3(18,y,-19),Vector3(18.8,y,-18.5),.04,"dark_steel")
 for anchor in [Vector3(8,0,-25),Vector3(29,0,-25),Vector3(27,0,-9)]:k.pipe(anchor,Vector3(18,8.5,-19),.016,"dark_steel")
 Props.console(k,Vector3(17,0,-16.4),0)
 Props.bevel(k,"RelayGeneratorHousing",Vector3(17,.7,12),Vector3(3,1.4,2),"dark_steel",null,true)
 for x in [16,16.5,17,17.5,18]:k.box("GeneratorVent",Vector3(x,.85,10.98),Vector3(.16,.60,.025),"black")
 k.pipe(Vector3(18,.9,12),Vector3(19,1.8,12),.08,"rust")
 k.cyl("GeneratorFuelTank",Vector3(23,.7,13),.65,1.4,"junction_paint")
 k.box("FuelTankHull",Vector3(23,.7,13),Vector3(1.2,1.4,1.2),"junction_paint",true).visible=false
 k.lamp(Vector3(12,2.3,12),true,.9,7)
 # Broken masonry is spatial cover, not scattered through the task furniture.
 for p in [Vector3(4,0,-3),Vector3(23,0,2),Vector3(6,0,18)]:
  preload("res://scripts/city_architecture.gd").mound(k,p,Vector3(3,.7,2),int(p.x+p.z+51))
 for spec in [[Vector3(-43,0,7),Vector2(12,20),3,63],[Vector3(43,0,-17),Vector2(12,15),4,65],[Vector3(-13,0,-39),Vector2(22,11),3,68]]:preload("res://scripts/outdoor_architecture.gd").block(k,spec[0],spec[1],spec[2],spec[3])
 # Physical edge obstructions look like the continuation of a ruined city, not a square wall.
 for p in [Vector3(-32,0,5),Vector3(32,0,23),Vector3(4,0,-27),Vector3(31,0,-13)]:preload("res://scripts/city_architecture.gd").mound(k,p,Vector3(4,1.5,4),int(p.x+p.z+89))
 k.bench(Vector3(-25,0,18),3.0,true)
 k.box("RelayExitMarker",Vector3(-28,1.2,23),Vector3(.10,2.4,.10),"dark_steel")
