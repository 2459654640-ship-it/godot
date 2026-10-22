extends RefCounted
## A repeatable optional sortie. Geometry, loot and trip state share save data.
const ENCOUNTERS={
 "surface_yard":{"rect":Rect2(-11,-2,25,11),"need":"surface_trip_active","skip":"unused_surface_skip","name":"电车道旁的兽群","spawns":[Vector3(-6,.04,2),Vector3(4,.04,4),Vector3(9,.04,0)]},
 "surface_pool":{"rect":Rect2(-10,-17,28,14),"need":"surface_drain_open","skip":"unused_surface_skip","name":"沉淀池里的巢穴","spawns":[Vector3(-5,.04,-9),Vector3(4,.04,-13),Vector3(10,.04,-8),Vector3(12,.04,-14)]}}
static func material(k,name:String,file:String,color:Color):
 var ink=k.mats.concrete.duplicate();ink.albedo_color=color;ink.normal_enabled=false;ink.roughness_texture=null;ink.roughness=.96
 if ResourceLoader.exists(file):ink.albedo_texture=load(file)
 ink.uv1_scale=Vector3(.28,.28,.28);k.mats[name]=ink
static func ground(w,bounds:Rect2):
 var k=w.kit
 material(k,"surface_snow","res://assets/visual/packed_snow.png",Color("aab5bd"))
 var snow_ink=ShaderMaterial.new();snow_ink.shader=load("res://assets/visual/surface_snow.gdshader");snow_ink.set_shader_parameter("snow_map",load("res://assets/visual/packed_snow.png"));k.mats.surface_snow=snow_ink
 k.mats.snowbank=snow_ink
 material(k,"surface_brick","res://assets/visual/ruined_brick.png",Color("c3b4aa"))
 k.mats.surface_brick.uv1_scale=Vector3(.32,.32,.32)
 var road_ink=ShaderMaterial.new();road_ink.shader=load("res://assets/visual/surface_asphalt.gdshader");road_ink.set_shader_parameter("asphalt_map",load("res://assets/visual/cracked_asphalt.png"));k.mats.surface_road=road_ink
 k.box("FloorOutdoor",Vector3(bounds.get_center().x,-.10,bounds.get_center().y),Vector3(bounds.size.x,.20,bounds.size.y),"surface_snow",true)
 var surrounding=k.box("DistantSnow",Vector3(0,-.28,0),Vector3(150,.12,130),"surface_snow")
 surrounding.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 preload("res://scripts/outdoor_architecture.gd").materials(k)
 preload("res://scripts/outdoor_architecture.gd").skyline(k)
 var snow=CPUParticles3D.new();snow.name="WindblownSnow";snow.position=Vector3(0,6,0);snow.amount=150;snow.lifetime=7;snow.preprocess=7;snow.emission_shape=CPUParticles3D.EMISSION_SHAPE_BOX;snow.emission_box_extents=Vector3(bounds.size.x/2,.1,bounds.size.y/2);snow.direction=Vector3(-.18,-1,.08);snow.gravity=Vector3(.1,-.12,.02);snow.initial_velocity_min=1.0;snow.initial_velocity_max=1.8
 var flake=QuadMesh.new();flake.size=Vector2(.035,.035);var ink=StandardMaterial3D.new();ink.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;ink.albedo_color=Color(.82,.88,.89,.45);ink.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;ink.billboard_mode=BaseMaterial3D.BILLBOARD_ENABLED;flake.material=ink;snow.mesh=flake;w.add_child(snow)
 for x in [bounds.position.x,bounds.end.x]:k.box("SiteBoundary",Vector3(x,.8,bounds.get_center().y),Vector3(.30,1.6,bounds.size.y),"concrete",true)
 for z in [bounds.position.y,bounds.end.y]:k.box("SiteBoundary",Vector3(bounds.get_center().x,.8,z),Vector3(bounds.size.x,1.6,.30),"concrete",true)
static func road(k,a:Vector3,b:Vector3,width:float):
 var d=b-a;var heading=atan2(d.x,d.z)
 var side=Vector3(d.z,0,-d.x).normalized()
 var strip=MeshInstance3D.new();strip.name="CrackedRoad";var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES);st.set_normal(Vector3.UP)
 for n in range(8):
  var p0=a.lerp(b,n/8.0)+Vector3.UP*.014;var p1=a.lerp(b,(n+1)/8.0)+Vector3.UP*.014
  var w0=width/2+.10*sin(n*3.1+a.x);var w1=width/2+.10*sin((n+1)*3.1+a.x)
  for point in [p0-side*w0,p0+side*w0,p1-side*w1,p0+side*w0,p1+side*w1,p1-side*w1]:st.add_vertex(point)
 strip.mesh=st.commit();strip.material_override=k.mats.surface_road.duplicate();k.root.add_child(strip)
 for point in [a,b]:k.cyl("WornRoadJoint",point+Vector3.UP*.006,width/2,.014,"surface_road")
 for edge in [-1,1]:
  for n in range(int(d.length()/1.2)):
   if n%5==3:continue
   var p=a.lerp(b,(n+.5)/(d.length()/1.2))+side*(width/2+.12)*edge
   var curb=k.box("BrokenRoadCurb",p+Vector3.UP*.065,Vector3(.20,.13,.96),"concrete",true);curb.rotation.y=heading
 for n in range(int(d.length()/2)):
  if n%3==1:continue
  var mark=k.box("FadedRoadPaint",a.lerp(b,(n+.5)/(d.length()/2))+Vector3.UP*.029,Vector3(.07,.004,.65),"paper");mark.rotation.y=heading
static func ruin(k,p:Vector3,size:Vector2,seed:int):
 # Window openings, missing wall sections and exposed joists give each ruin
 # a readable silhouette. A complete doorway stays clear at the south face.
 var sx=size.x;var sz=size.y
 k.box("RuinSlab",p+Vector3(0,.07,0),Vector3(sx,.14,sz),"concrete",true)
 for side in [-1,1]:
  k.box("RuinWindowSill",p+Vector3(side*sx/2,.48,0),Vector3(.30,.96,sz),"surface_brick",true)
  for z in [-sz/2,-sz/6,sz/6,sz/2]:
   var height=2.3+float(posmod(int(z*10)+seed,4))*.3
   k.box("BrokenMasonryPier",p+Vector3(side*sx/2,height/2,z),Vector3(.38,height,.50),"surface_brick",true)
   k.box("ExposedBrickEdge",p+Vector3(side*(sx/2+.18),1.25,z),Vector3(.05,.48,.46),"rust")
  for z in [-sz/3,0,sz/3]:
   k.box("FracturedWindowLintel",p+Vector3(side*sx/2,2.15,z),Vector3(.33,.22,sz/3-.25),"concrete")
   k.pipe(p+Vector3(side*sx/2,2.38,z-.3),p+Vector3(side*(sx/2-.25),2.9,z+.2),.018,"rust")
 k.box("RuinRearWall",p+Vector3(0,1.15,-sz/2),Vector3(sx,2.3,.32),"surface_brick",true)
 for x in [-sx*.33,sx*.33]:k.box("RuinDoorCheek",p+Vector3(x,.7,sz/2),Vector3(sx*.30,1.4,.30),"surface_brick",true)
 for z in [-sz*.3,0,sz*.3]:
  var beam=k.box("BareRuinJoist",p+Vector3(0,2.6,z),Vector3(sx,.13,.16),"old_iron");beam.rotation.z=.04*posmod(int(z*10)+seed,3)
 for n in range(7):
  var q=p+Vector3(-sx*.35+posmod(n*7+seed,9)*sx*.08,.10,-sz*.3+posmod(n*3,7)*sz*.09)
  var brick=k.box("LooseMasonry",q,Vector3(.28,.15,.16),"rust");brick.rotation.y=n*.73
static func fence(k,a:Vector3,b:Vector3):
 var d=b-a;var centre=(a+b)/2
 for n in range(ceili(d.length()/2)+1):
  var p=a.lerp(b,n/float(ceili(d.length()/2)))
  k.box("BentFencePost",p+Vector3.UP*.85,Vector3(.07,1.7,.07),"old_iron")
 for y in [.38,.85,1.4]:k.pipe(a+Vector3.UP*y,b+Vector3.UP*y,.024,"rust")
 var hull=k.box("FenceCollision",centre+Vector3.UP*.75,Vector3(d.length() if abs(d.x)>abs(d.z) else .12,1.5,d.length() if abs(d.z)>abs(d.x) else .12),"dark",true);hull.visible=false
static func build(w):
 var k=w.kit;ground(w,Rect2(-21,-18,43,36))
 road(k,Vector3(-18,0,13),Vector3(-5,0,5),3.6);road(k,Vector3(-5,0,5),Vector3(9,0,3),3.6);road(k,Vector3(9,0,3),Vector3(19,0,11),3.6)
 ruin(k,Vector3(-15,0,-10),Vector2(7,10),3);ruin(k,Vector3(18.5,0,-12),Vector2(4,6),7)
 # The abandoned tram really rests on rails; tracks never run through ruins.
 for x in [14.12,15.88]:k.box("TramRail",Vector3(x,.045,0),Vector3(.065,.09,32),"old_iron")
 for z in range(-16,17):k.box("RailSleeper",Vector3(15,.025,z),Vector3(2.8,.05,.16),"wood")
 k.box("TramChassis",Vector3(15,.58,3),Vector3(2.25,.5,8.9),"rust",true)
 for x in [14.0,16.0]:
  for z in [-.2,6.2]:k.cyl("TramWheel",Vector3(x,.28,z),.30,.18,"dark").rotation.z=PI/2
 for x in [13.84,16.16]:
  k.box("TramLowerBody",Vector3(x,1.12,3),Vector3(.12,.65,9.2),"rust")
  for z in [-.5,1.3,3.1,4.9,6.7]:
   k.box("TramWindowVoid",Vector3(x,1.93,z),Vector3(.025,.85,1.28),"dark")
   for dz in [-.7,.7]:k.box("TramWindowFrame",Vector3(x,1.93,z+dz),Vector3(.11,1.1,.065),"old_iron")
  k.box("TramFadedCreamStripe",Vector3(x,1.5,3),Vector3(.135,.10,9.0),"cream")
 k.box("TramRoof",Vector3(15,2.56,3),Vector3(2.5,.20,9.5),"old_iron")
 k.box("TramSnowCap",Vector3(15,2.68,3),Vector3(2.1,.08,8.8),"surface_snow")
 for z in [-1.55,7.55]:k.box("TramEnd",Vector3(15,1.6,z),Vector3(2.3,1.8,.15),"rust")
 for x in [-8,6]:
  k.cyl("OldCablePole",Vector3(x,2.4,7),.09,4.8,"old_iron");k.pipe(Vector3(x,4.4,7),Vector3(x+1.5,4.4,7),.035,"rust")
 k.pipe(Vector3(-8,4.4,7),Vector3(6,4.4,7),.012,"dark")
 # Low pool perimeter and rusted intake. The open service aisle is in the west.
 for x in [1.5,10.5]:k.box("SettlingPoolKerb",Vector3(x,.12,-11.5),Vector3(.24,.24,9),"concrete",true)
 k.box("SettlingPoolFloor",Vector3(6,.007,-11.5),Vector3(8.8,.012,8.8),"concrete")
 k.box("SettlingPoolNorthEdge",Vector3(6,.12,-16),Vector3(9,.24,.24),"concrete",true)
 var water=k.box("SurfaceStandingWater",Vector3(6,.018,-11.5),Vector3(8.7,.025,8.7),"metal");water.set_meta("dynamic",true);water.material_override=water.material_override.duplicate();water.material_override.albedo_color=Color("4d6557")
 for x in [-6,-2,2,6,10]:k.box("PipeBridgeUpright",Vector3(x,1.4,-17),Vector3(.15,2.8,.18),"old_iron",true)
 k.pipe(Vector3(-9,2.65,-17),Vector3(12,2.65,-17),.19,"rust")
 fence(k,Vector3(-21,0,-3),Vector3(-1.1,0,-3));fence(k,Vector3(1.1,0,-3),Vector3(22,0,-3))
 w.campaign_gate_flag="surface_drain_open";w.campaign_gate=k.box("CampaignInnerGate",Vector3(0,.85,-3),Vector3(1.82,1.7,.15),"corrugated",true);w.campaign_gate.set_meta("dynamic",true);w.campaign_gate.set_meta("closed_position",w.campaign_gate.position)
 # Industrial equipment, partial shelter and old street furniture occupy
 # purposeful edges of the yard, leaving the road and western detour clear.
 for p in [Vector3(-7,0,-15),Vector3(-3,0,-15)]:
  k.box("OutdoorPumpBase",p+Vector3(0,.24,0),Vector3(2.1,.48,1.4),"concrete",true)
  k.cyl("OutdoorPumpMotor",p+Vector3(0,.87,0),.48,1.1,"old_iron").rotation.z=PI/2
  k.pipe(p+Vector3(.7,.6,0),p+Vector3(.7,.6,1.6),.16,"rust")
 for x in [-6,-3,0]:k.box("ShedSupport",Vector3(x,1.6,14.5),Vector3(.14,3.2,.14),"old_iron",true)
 for z in [13.5,15.5]:k.box("ShedBrokenRoofRib",Vector3(-3,3.1,z),Vector3(6.3,.10,.14),"old_iron")
 k.box("ShedRoofRemainder",Vector3(-4.5,3.2,14.5),Vector3(3.2,.10,2.6),"corrugated")
 for p in [Vector3(-5,0,14.5),Vector3(-2,0,15)]:
  k.crate(p,Vector3(1.3,.9,1.1));k.ellipsoid("SnowOnCargo",p+Vector3(0,.91,0),Vector3(.6,.06,.5),"snowbank")
 for p in [Vector3(-18,0,6),Vector3(-18,0,-16),Vector3(20,0,-6),Vector3(12,0,14)]:
  k.ellipsoid("WindDrift",p+Vector3(0,.04,0),Vector3(1.6,.18,2.3),"snowbank")
 for p in [Vector3(-9,0,14),Vector3(19,0,-6),Vector3(-9,0,-15)]:
  k.box("DeadTreeFootprint",p+Vector3(0,1,0),Vector3(.25,2,.25),"wood",true).visible=false
  k.cyl("DeadTreeTrunk",p+Vector3(0,1.45,0),.10,2.9,"wood")
  for branch in [Vector3(-.7,2.5,.3),Vector3(.6,3.2,-.2),Vector3(.2,2.7,.7)]:k.pipe(p+Vector3(0,1.8,0),p+branch,.033,"wood")
 for x in [-19,-17.8,-16.6]:
  k.cyl("ForgottenOilDrum",Vector3(x,.47,-15),.34,.94,"rust");k.box("OilDrumFootprint",Vector3(x,.45,-15),Vector3(.6,.9,.6),"dark",true).visible=false
 k.box("RustedYardSign",Vector3(-11,1.7,16.9),Vector3(2.5,.8,.06),"old_iron")
 k.label("НАСОСНАЯ · 1961",Vector3(-11,1.72,16.85),18,Color("c5c1ac"))
 # Controls and work tables support their associated interactable objects.
 k.box("SurfaceControlPost",Vector3(-15,.8,4),Vector3(1,1.6,.45),"old_iron",true)
 k.box("SurfaceDiagram",Vector3(-15,1.2,4.25),Vector3(.65,.45,.025),"paper")
 k.pipe(Vector3(-13,.3,-2.1),Vector3(-13,1,-2.1),.12,"rust");k.cyl("SurfaceValveWheel",Vector3(-13,1,-2.1),.32,.09,"red").rotation.x=PI/2
 k.box("PoolSamplingBlock",Vector3(8.6,.12,-13),Vector3(.65,.24,.55),"concrete")
 k.cyl("SamplingMarkerBottle",Vector3(8.6,.36,-13),.065,.22,"green")
 k.crate(Vector3(-17,0,11.8),Vector3(1.2,.65,.9));k.box("SurfaceSupplyBag",Vector3(-17,.83,11.8),Vector3(.7,.35,.5),"cloth")
 k.box("ReturnHatchFrame",Vector3(-18,.06,14),Vector3(1.5,.12,1.2),"old_iron")
 for dx in [-.55,.55]:k.box("InspectionLadderRail",Vector3(-18+dx,.6,14.3),Vector3(.06,1.2,.06),"metal")
 k.lamp(Vector3(-18,2.2,15.2),true,1.6,7)
 # Snow-covered rubbish, curb chips, cable reels and caution signs: not colliders.
 for n in range(26):
  var x=-19+posmod(n*11,39);var z=-16+posmod(n*7,31)
  if abs(x)<2 and abs(z+3)<2:continue
  if ResourceLoader.exists("res://assets/visual/surface_rubble.png"):
   var decal=k.box("RubbleDecal",Vector3(x,.021,z),Vector3(1.8,.008,1.8),"surface_snow");var ink=StandardMaterial3D.new();ink.albedo_texture=load("res://assets/visual/surface_rubble.png");ink.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR;ink.roughness=1;decal.material_override=ink;decal.rotation.y=n*.73;decal.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 for p in [Vector3(-9,0,12),Vector3(7,0,8),Vector3(-9,0,-13)]:
  k.crate(p,Vector3(1.5,.8,1.1));k.cyl("AbandonedCableReel",p+Vector3(1.2,.42,0),.42,.5,"wood").rotation.z=PI/2
static func drop(w,enemy):
 var key:String=enemy.get_meta("loot_key","")
 if key=="":return
 var records:Dictionary=w.story.flags.get("surface_loot",{}).duplicate(true)
 if records.has(key):return
 var p:Vector3=enemy.position
 var good="mutant_sample" if int(enemy.get_meta("loot_index",0))%3==2 else "mutant_bone"
 records[key]={"position":[p.x,.04,p.z],"good":good,"taken":false};w.story.flags.surface_loot=records;build_drop(w,key,records[key])
static func build_drop(w,key:String,entry:Dictionary):
 if entry.taken:return
 var p=Vector3(entry.position[0],.04,entry.position[2]);var id="surface_loot_"+key
 var root=Node3D.new();root.name=id;w.add_child(root);root.position=p
 if entry.good=="mutant_bone":
  var bone=w.kit.cyl("DroppedBone",Vector3(0,.09,0),.035,.35,"paper",root);bone.rotation.z=PI/2
  for x in [-.16,.16]:w.kit.ellipsoid("BoneEnd",Vector3(x,.09,0),Vector3(.06,.06,.07),"paper",root)
 else:
  w.kit.cyl("SampleContainer",Vector3(0,.14,0),.075,.25,"green",root);w.kit.cyl("SampleLid",Vector3(0,.28,0),.085,.035,"metal",root)
 w.target(id,p,"可收集的"+("骨片" if entry.good=="mutant_bone" else "变异样本"),"collect")
static func restore_drops(w):
 for key in w.story.flags.get("surface_loot",{}):build_drop(w,key,w.story.flags.surface_loot[key])
static func collect(w,id:String):
 var key=id.trim_prefix("surface_loot_");var records:Dictionary=w.story.flags.get("surface_loot",{})
 if not records.has(key) or records[key].taken or not w.targets.has(id):return
 if w.player.position.distance_to(w.targets[id].pos)>1.9:return
 var good:String=records[key].good;records[key].taken=true;w.story.flags.surface_loot=records
 w.story.economy.goods[good]=int(w.story.economy.goods.get(good,0))+1
 var node=w.get_node_or_null(id)
 if node:node.queue_free()
 for marker in [w.targets[id].ring,w.targets[id].marker]:
  if is_instance_valid(marker):marker.queue_free()
 w.targets.erase(id);w.story.changed.emit();w.hud.toast("获得："+w.story.Economy.GOODS[good].name+" ×1，可到聚落军需处出售。",5);w.autosave()
