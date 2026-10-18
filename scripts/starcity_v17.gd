extends RefCounted
## Research spaces with service access, coherent facing, and curved test equipment.
const POLYGONS={
 "03":[Vector2(-5.5,-15),Vector2(5,-15),Vector2(7,-13),Vector2(7,0),Vector2(5,2),Vector2(-5,2),Vector2(-7,0),Vector2(-7,-13.5)],
 "07":[Vector2(24,-17),Vector2(30,-17),Vector2(33,-14),Vector2(33,-6),Vector2(30,-3),Vector2(24,-3),Vector2(21,-6),Vector2(21,-14)]}
const FLOOR={"00":"star_terrazzo","01":"star_rubber","02":"star_linoleum","03":"star_linoleum","04":"star_terrazzo","05":"star_rubber","06":"star_linoleum","07":"star_lab_tile","08":"star_lab_tile"}
static func floor_finish(code:String)->String:return FLOOR[code]
static func prepare(k,zones:Array):
 for spec in [["star_linoleum",.38],["star_terrazzo",.6],["star_lab_tile",.42],["star_rubber",.9],["star_enamel",.7],["star_wall",.4],["star_alloy",.6]]:
  var m=k.mats.concrete.duplicate();m.albedo_texture=load("res://assets/visual/"+spec[0]+".png");m.albedo_color=Color.WHITE
  m.normal_enabled=false;m.roughness_texture=null;m.roughness=.85;m.uv1_scale=Vector3.ONE*spec[1];k.mats[spec[0]]=m
 k.wall_surface="star_wall";k.wall_color=Color.WHITE;k.wall_finish_theme="starcity";k.mats.blue=k.mats.star_enamel
 k.wall_room_profiles.clear()
 for room in zones:k.wall_room_profiles.append({"rect":room.rect,"style":21 if room.code in ["07","08"] else (22 if room.code=="01" else (23 if room.code in ["02","04"] else 20))})
static func clip_floor(floor:MeshInstance3D,points:Array):
 var vertices=PackedVector2Array(points);var tris=Geometry2D.triangulate_polygon(vertices)
 var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
 var center=floor.position
 for i in tris:
  var p:Vector2=vertices[i];st.set_normal(Vector3.UP);st.set_uv(p);st.add_vertex(Vector3(p.x-center.x,0,p.y-center.z))
 st.generate_tangents();floor.mesh=st.commit()
static func clip_foundation(node:MeshInstance3D,points:Array):
 var tool=SurfaceTool.new();tool.begin(Mesh.PRIMITIVE_TRIANGLES)
 var polygon=PackedVector2Array(points);var indices=Geometry2D.triangulate_polygon(polygon)
 for index in indices:
  var p:Vector2=polygon[index];tool.set_normal(Vector3.UP);tool.set_uv(p);tool.add_vertex(Vector3(p.x-node.position.x,.25,p.y-node.position.z))
 for i in polygon.size():
  var a:Vector2=polygon[i];var b:Vector2=polygon[(i+1)%polygon.size()];var d=b-a;var normal=Vector3(d.y,0,-d.x).normalized()
  for p in [Vector3(a.x,.25,a.y),Vector3(b.x,.25,b.y),Vector3(b.x,-.25,b.y),Vector3(a.x,.25,a.y),Vector3(b.x,-.25,b.y),Vector3(a.x,-.25,a.y)]:
   tool.set_normal(normal);tool.set_uv(Vector2(p.x+p.z,p.y));tool.add_vertex(p-Vector3(node.position.x,0,node.position.z))
 tool.generate_tangents();node.mesh=tool.commit()
static func polygon_walls(k,plan:Dictionary):
 for code in POLYGONS:
  var polygon:Array=POLYGONS[code]
  for i in polygon.size():
   var a:Vector2=polygon[i];var b:Vector2=polygon[(i+1)%polygon.size()]
   if is_equal_approx(a.x,b.x) or is_equal_approx(a.y,b.y):
    var axis="x" if is_equal_approx(a.x,b.x) else "z"
    var fixed=a.x if axis=="x" else a.y
    var first=minf(a.y,b.y) if axis=="x" else minf(a.x,b.x)
    var last=maxf(a.y,b.y) if axis=="x" else maxf(a.x,b.x)
    var spans=[Vector2(first,last)]
    for door in plan.doors:
     if door[2]!=axis or not is_equal_approx(door[0] if axis=="x" else door[1],fixed):continue
     var middle:float=door[1] if axis=="x" else door[0];var half:float=door[3] if door.size()>3 else 1.1
     var next=[]
     for span in spans:
      if middle+half<=span.x or middle-half>=span.y:next.append(span);continue
      if middle-half>span.x:next.append(Vector2(span.x,middle-half))
      if middle+half<span.y:next.append(Vector2(middle+half,span.y))
     spans=next
    for span in spans:
     k.wall("ResearchWall",Vector2(fixed,span.x) if axis=="x" else Vector2(span.x,fixed),Vector2(fixed,span.y) if axis=="x" else Vector2(span.y,fixed),true)
   else:diagonal_wall(k,a,b,21 if code=="07" else 20)
static func diagonal_wall(k,a:Vector2,b:Vector2,style:int):
 var mid=(a+b)*.5;var delta=b-a;var size=Vector3(delta.length(),2.7,.25)
 var node=k.box("ResearchChamferWall",Vector3(mid.x,1.35,mid.y),size,"star_wall",true)
 node.rotation.y=-atan2(delta.y,delta.x)
 # Physics uses the rotated shape; navigation uses a conservative corner footprint.
 k.solids[-1].rect=Rect2(Vector2(minf(a.x,b.x)-.125,minf(a.y,b.y)-.125),Vector2(absf(delta.x)+.25,absf(delta.y)+.25))
 var mat=k.new_veil_material(k.mats.star_wall)
 mat.set_shader_parameter("star_finish",true);mat.set_shader_parameter("star_enamel",k.mats.star_enamel.albedo_texture);mat.set_shader_parameter("star_tile",k.mats.star_lab_tile.albedo_texture)
 # Bake only the drawing into world coordinates, just like the shared wall
 # mesh. Its original rotated physics body remains intact beneath it.
 var arrays=node.mesh.surface_get_arrays(0);var tool=SurfaceTool.new();tool.begin(Mesh.PRIMITIVE_TRIANGLES)
 for index in arrays[Mesh.ARRAY_INDEX]:
  var p:Vector3=node.transform*arrays[Mesh.ARRAY_VERTEX][index];var normal:Vector3=node.basis*arrays[Mesh.ARRAY_NORMAL][index]
  tool.set_normal(normal);tool.set_uv2(Vector2(style,0));tool.set_uv(Vector2((p.x if absf(normal.z)>.5 else p.z)/3.0,1.0-p.y/2.7));tool.add_vertex(p)
 tool.generate_tangents();tool.set_material(mat)
 var drawing=MeshInstance3D.new();drawing.name="ResearchCornerMasonry";drawing.mesh=tool.commit();k.root.add_child(drawing);node.visible=false
 drawing.set_meta("foreground",true);k.wall_meshes.append(drawing);k.veil_materials[drawing.get_instance_id()]=[]
static func rotated_group(k,name:String,p:Vector3,heading:float,size:Vector3)->Node3D:
 var group=Node3D.new();group.name=name;k.root.add_child(group);group.position=p;group.rotation.y=heading
 var hull=k.box(name+"Hull",Vector3(0,size.y*.5,0),size,"star_enamel",true,group);hull.visible=false
 var extent=Vector2(absf(cos(heading))*size.x+absf(sin(heading))*size.z,absf(sin(heading))*size.x+absf(cos(heading))*size.z)
 k.solids.append({"name":name,"rect":Rect2(Vector2(p.x,p.z)-extent*.5,extent),"bottom":0.0,"top":size.y})
 return group
static func console(k,p:Vector3,heading:float,wide:float=1.65):
 var g=rotated_group(k,"TelemetryConsole",p,heading,Vector3(wide,1.35,.85))
 k.box("ConsolePedestal",Vector3(0,.39,0),Vector3(wide*.86,.78,.68),"star_enamel",false,g)
 var slope=k.box("ConsoleSlopingDeck",Vector3(0,.86,.08),Vector3(wide,.14,.85),"star_enamel",false,g);slope.rotation.x=-.16
 k.box("ConsoleCRTBezel",Vector3(0,1.18,-.20),Vector3(wide*.75,.62,.38),"dark",false,g)
 var screen=k.box("ConsolePhosphor",Vector3(0,1.18,.002),Vector3(wide*.61,.43,.025),"dark",false,g)
 var m=ShaderMaterial.new();m.shader=load("res://assets/visual/monitor.gdshader");screen.material_override=m
 for dx in [-.48,-.24,0,.24,.48]:
  k.cyl("ConsoleKnob",Vector3(dx,.99,.35),.037,.035,"cream",g)
  k.box("ConsoleKey",Vector3(dx,.96,.24),Vector3(.11,.025,.07),"dark",false,g)
 for dx in [-wide*.46,wide*.46]:k.box("ConsoleEndCheek",Vector3(dx,.87,.06),Vector3(.06,.24,.85),"star_alloy",false,g)
static func cabinet(k,p:Vector3,tape:bool=false):
 k.box("ResearchInstrumentCabinet",p+Vector3(0,1.05,0),Vector3(.95,2.1,.70),"star_enamel",true)
 for y in [.27,.65,1.03,1.41,1.79]:
  k.box("RemovableRackModule",p+Vector3(0,y,.37),Vector3(.82,.28,.045),"star_alloy")
  for dx in [-.28,.26]:k.cyl("RackToggle",p+Vector3(dx,y,.412),.025,.035,"black").rotation.x=PI/2
  k.box("RackVent",p+Vector3(0,y-.05,.404),Vector3(.30,.025,.012),"dark")
 if tape:
  for dx in [-.24,.24]:
   k.cyl("TapeMachineReel",p+Vector3(dx,1.42,.44),.19,.06,"paper").rotation.x=PI/2
   k.cyl("TapeReelHub",p+Vector3(dx,1.42,.483),.05,.025,"dark").rotation.x=PI/2
static func diagram(k,p:Vector3,size:Vector2):
 preload("res://scripts/facility_detail.gd").art(k,"OrbitalTelemetryDiagram",p,size,"res://assets/visual/star_telemetry.png")
static func build(w):
 var k=w.kit
 for door in [[7,-10.5,"x"],[21,-10.5,"x"],[14,-12,"z"]]:
  var p=Vector3(door[0],0,door[1]);var along_x=door[2]=="x"
  for side in [-1,1]:
   var offset=Vector3(0,1.18,side*.96) if along_x else Vector3(side*.96,1.18,0)
   k.box("LaboratorySealJamb",p+offset,Vector3(.32,2.36,.12) if along_x else Vector3(.12,2.36,.32),"star_alloy",true)
  k.box("LaboratorySealHeader",p+Vector3(0,2.40,0),Vector3(.32,.16,2.04) if along_x else Vector3(2.04,.16,.32),"star_enamel")
 # Control desks face the northern main display, leaving a 2m central approach.
 diagram(k,Vector3(.4,1.45,-14.84),Vector2(4.4,2.2))
 for x in [-4.3,-2.1,2.1,4.3]:
  var z=-7.0+absf(x)*.35
  var heading=PI+(-.20 if x<0 else .20)
  console(k,Vector3(x,0,z),heading)
  preload("res://scripts/settlement_details.gd").chair(k,Vector3(x,0,z+1.2),PI)
 # A second, offset observer's desk; no prop occupies the father/entry approach.
 console(k,Vector3(3.7,0,-12.6),PI,1.55)
 for x in [-5.9,5.9]:
  k.cyl("ControlColumnFoot",Vector3(x,.13,-3.0),.27,.26,"star_alloy")
  k.cyl("ControlColumn",Vector3(x,1.55,-3.0),.18,2.85,"star_enamel")
  k.box("ColumnHull",Vector3(x,1.4,-3),Vector3(.42,2.8,.42),"star_enamel",true).visible=false
 # Occupied research centre: no launch pad beneath a city. Test articles fit the lab.
 var c=Vector3(27,0,-10)
 k.box("VacuumChamberCollision",c+Vector3(0,1.1,0),Vector3(3.7,2.2,3.7),"star_alloy",true).visible=false
 k.cyl("VacuumChamberBase",c+Vector3(0,.2,0),2.0,.4,"star_enamel")
 k.cyl("VacuumVessel",c+Vector3(0,1.35,0),1.50,2.3,"star_alloy")
 k.ellipsoid("VacuumDishedLid",c+Vector3(0,2.48,0),Vector3(1.5,.45,1.5),"star_alloy")
 for angle in range(0,360,30):
  var a=deg_to_rad(angle);var q=c+Vector3(cos(a)*1.54,2.40,sin(a)*1.54)
  k.cyl("VesselFlangeBolt",q,.06,.16,"dark")
 for y in [.50,2.35]:k.cyl("VesselFlange",c+Vector3(0,y,0),1.59,.10,"star_enamel")
 k.cyl("VesselViewportRim",c+Vector3(0,1.5,1.52),.35,.15,"star_enamel").rotation.x=PI/2
 k.cyl("VesselViewport",c+Vector3(0,1.5,1.61),.26,.025,"dark").rotation.x=PI/2
 k.pipe(c+Vector3(1.48,.55,0),Vector3(31.8,.55,-10),.10,"star_alloy")
 k.box("VacuumPumpSkid",Vector3(31.5,.28,-10),Vector3(1.1,.56,2.0),"star_enamel",true)
 k.cyl("VacuumPumpMotor",Vector3(31.5,.74,-10),.30,.85,"dark").rotation.x=PI/2
 console(k,Vector3(24.5,0,-5.3),.15,1.6)
 # Gas supply secured against north wall; pipes remain outside the walking loop.
 for x in [24.8,25.5,26.2]:
  k.cyl("SecuredCalibrationGas",Vector3(x,.85,-16.3),.23,1.7,"star_enamel")
  k.ellipsoid("GasBottleShoulder",Vector3(x,1.72,-16.3),Vector3(.23,.13,.23),"star_enamel")
  k.cyl("BottleValve",Vector3(x,1.91,-16.3),.06,.18,"brass")
 k.box("GasBottleRack",Vector3(25.5,.9,-16.3),Vector3(2.1,1.8,.60),"star_enamel",true).visible=false
 # Optical/gyro preparation room: benches on the perimeter and a generous central aisle.
 for x in [10,14,18]:
  lab_table(k,Vector3(x,0,-18.7),2.4)
  k.cyl("InstrumentTurntable",Vector3(x,.89,-18.7),.40,.12,"star_alloy")
  k.cyl("GyroTestHousing",Vector3(x,1.13,-18.7),.24,.37,"star_enamel")
  k.pipe(Vector3(x,.99,-18.7),Vector3(x,1.64,-18.7),.035,"brass")
  k.box("BenchMeasurementCard",Vector3(x+.7,.838,-18.5),Vector3(.42,.025,.28),"paper")
 for x in [8.3,9.5]:cabinet(k,Vector3(x,0,-13.0))
 lab_table(k,Vector3(19,0,-13.1),2.0)
 var center=Vector3(19,1.38,-13.1)
 k.cyl("SatelliteModelStand",center-Vector3(0,.43,0),.27,.18,"dark")
 k.pipe(center-Vector3(0,.4,0),center,.035,"brass")
 k.ellipsoid("SatelliteCalibrationModel",center,Vector3(.24,.24,.24),"star_alloy")
 for offset in [Vector3(.55,.38,0),Vector3(-.55,.38,0),Vector3(0,.38,.55),Vector3(0,.38,-.55)]:k.pipe(center,center+offset,.018,"star_alloy")
 # Communications: recording racks along northern wall, repair and log desks behind them.
 for x in [9,10.2,11.4,15.8,17.0,18.2,19.4]:cabinet(k,Vector3(x,0,-4.45),x>15)
 console(k,Vector3(14,0,-1.0),0,1.7)
 lab_table(k,Vector3(10,0,-.4),2.4);k.cyl("CalibrationOscilloscope",Vector3(10,1.12,-.4),.25,.48,"star_enamel").rotation.z=PI/2
 lab_table(k,Vector3(12,0,2.7),2.4);k.box("HandoverLedger",Vector3(12,.84,2.7),Vector3(.8,.035,.6),"paper")
 k.box("ReceiverLog",Vector3(13.95,.99,-.55),Vector3(.4,.03,.25),"paper")
 # Power cabinets stay on west wall; a separate workbench supports the isolator interaction.
 for x in [-20.8,-19.6,-18.4]:cabinet(k,Vector3(x,0,-10.3))
 console(k,Vector3(-16,0,-7.1),0,1.8)
 for z in [-8.8,-6,-3.2]:
  k.pipe(Vector3(-21.5,2.4,z),Vector3(-11.6,2.4,z),.045,"star_alloy")
 # Original quest anchors keep their work surfaces, with no generic blue cubes.
 lab_table(k,Vector3(-6,0,-18.4),2.8);k.box("ArchiveRegister",Vector3(-5.8,.84,-18.3),Vector3(.7,.03,.5),"paper")
 for x in [-10,-8.6]:cabinet(k,Vector3(x,0,-18.4))
 lab_table(k,Vector3(-18,0,8.6),2.8);k.box("EntryManual",Vector3(-17.8,.84,8.7),Vector3(.7,.03,.5),"paper")
 console(k,Vector3(3,0,7),0,1.8)
 k.bench(Vector3(-21,0,9),2,true,PI/2)
 for z in [7.7,10.4]:k.bench(Vector3(-8,0,z),1.65,true,-PI/2)
 preload("res://scripts/settlement_details.gd").rug(k,Vector3(-16,0,12.3),Vector2(2.0,2.8),"indigo")
 for x in [-18,-14,-10,-6,-2,2,10,18]:
  k.box("CeilingCableTray",Vector3(x,2.72,3.0),Vector3(3.2,.10,.35),"star_alloy")
 # Threshold-free service passage and independent task lighting.
 for p in [Vector3(12,2.55,-10.5),Vector3(18,2.55,-10.5),Vector3(27,2.7,-6),Vector3(14,2.6,-16)]:
  k.box("LaboratoryStripFixture",p,Vector3(1.9,.08,.22),"star_alloy")
  k.box("LaboratoryStripDiffuser",p-Vector3(0,.06,0),Vector3(1.7,.025,.13),"cold_light")
  var lamp=fill_light(w,p,1.45,7);lamp.light_color=Color("c3d2c6")
  for dx in [-.75,.75]:k.pipe(p+Vector3(dx,.05,0),p+Vector3(dx,.60,0),.012,"star_alloy")
 for entry in [[Vector3(-2,2.6,-8),1.25,9],[Vector3(4,2.5,-12),1.0,6],[Vector3(17,2.5,-1),1.0,6]]:
  var lamp=fill_light(w,entry[0],entry[1],entry[2]);lamp.light_color=Color("b6c5b8")

static func fill_light(w,p:Vector3,power:float,radius:float)->OmniLight3D:
 var lamp=OmniLight3D.new();lamp.name="ResearchCeilingFill";w.add_child(lamp);lamp.position=p;lamp.light_energy=power;lamp.omni_range=radius;lamp.shadow_enabled=true;lamp.shadow_normal_bias=.35
 return lamp
static func lab_table(k,p:Vector3,width:float):
 k.box("LaboratoryWorktop",p+Vector3(0,.80,0),Vector3(width,.08,1.0),"star_alloy",true)
 for dx in [-width*.42,width*.42]:
  k.box("LaboratoryBenchLeg",p+Vector3(dx,.39,0),Vector3(.075,.78,.70),"star_enamel",true)
 k.box("LaboratoryBenchBrace",p+Vector3(0,.24,-.32),Vector3(width-.20,.08,.06),"star_enamel")
