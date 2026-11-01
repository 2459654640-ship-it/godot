extends RefCounted
## Authored focal points; decoration stays within existing fixture footprints.
const Detail=preload("res://scripts/facility_detail.gd")
static func build(w):
	match w.floor_id:
		"commune":commune(w)
		"waterworks":waterworks(w)
		"east_district":district(w)

static func commune(w):
	var k=w.kit
	# Mounted on the north wall above the existing stage, facing south into the hall.
	Detail.art(k,"WorkersEducationMosaic",Vector3(.5,1.81,-11.78),Vector2(5.55,1.85),"res://assets/visual/commune_mural_v28.png")
	# Two soft, shielded sconces explain the warm focal light without overexposure.
	for x in [-3.2,4.2]:
		k.box("HallSconceBack",Vector3(x,1.9,-11.75),Vector3(.15,.38,.08),"brass")
		k.box("HallSconceShade",Vector3(x,2.08,-11.62),Vector3(.34,.07,.28),"old_iron")
		var lamp=OmniLight3D.new();lamp.name="MosaicSconce";w.add_child(lamp)
		lamp.position=Vector3(x,1.98,-11.50);lamp.light_color=Color("edc190")
		lamp.light_energy=.7;lamp.omni_range=4.5;lamp.shadow_enabled=true
	# Inlaid borders lie below shoe level and stop before doorways.
	for x in [-10.5,11.5]:
		for span in [Vector2(-2.5,-.5),Vector2(2.8,4.3)]:
			k.box("HallStoneInlay",Vector3(x,.024,(span.x+span.y)/2),Vector3(.14,.007,span.y-span.x),"dark")
	# Practical communal notices sit on the existing north wall, east of the door.
	mounted_print(k,"CommuneDutyBoard",Vector3(8,1.6,-3.82),Vector2(2.8,1.4),"commune_rota_print")
	k.lamp(Vector3(8,2.48,-3.65),true,.9,5)
	# Repair marks make this inherited civic space feel maintained, not pristine.
	for x in [-5,6]:
		k.box("StageSkirtingRepair",Vector3(x,.12,-10.12),Vector3(1.3,.17,.025),"old_iron")

static func waterworks(w):
	var k=w.kit
	preload("res://scripts/production_props.gd").panel_face(k,k.root,Vector3(-.60,1.35,5.808),Vector2(1.22,.813),2)
	mounted_print(k,"FactoryOperationBoard",Vector3(1.9,1.85,4.16),Vector2(2.15,.967),"pump_operation_print")
	# Local inspection lights identify working areas; their brackets stay on walls.
	for p in [Vector3(-13,2.35,-13.72),Vector3(-1,2.35,-9.72),Vector3(16,2.35,4.28)]:
		k.box("InspectionLampBack",p,Vector3(.38,.30,.07),"old_iron")
		k.box("InspectionLampHood",p+Vector3(0,.18,.12),Vector3(.65,.09,.40),"factory_enamel_v13")
		var lamp=OmniLight3D.new();lamp.name="InspectionTaskLight";w.add_child(lamp);lamp.position=p+Vector3(0,-.02,.36);lamp.light_color=Color("e3c7a0");lamp.light_energy=1.4;lamp.omni_range=7;lamp.shadow_enabled=true
	for y in [1.8,2.0]:k.pipe(Vector3(-5.4,y,-9.62),Vector3(3.8,y,-9.62),.025,"old_iron")
	for x in [-4,0,3]:k.box("WorkshopConduitClip",Vector3(x,1.9,-9.59),Vector3(.055,.30,.055),"old_iron")

static func gauge(k,p:Vector3,radius:float):
	var bezel=k.cyl("AnalogueGaugeBezel",p,radius,.08,"old_iron");bezel.rotation.x=PI/2
	var dial=k.cyl("AnalogueGaugeFace",p+Vector3(0,0,.045),radius*.85,.012,"paper");dial.rotation.x=PI/2
	for i in 9:
		var a=PI*.15+i*PI*.7/8
		var mark=k.box("GaugeGraduation",p+Vector3(cos(a)*radius*.65,sin(a)*radius*.65,.057),Vector3(.012,.025,.006),"dark");mark.rotation.z=a-PI/2
	var needle=k.box("GaugeNeedle",p+Vector3(-radius*.22,radius*.10,.062),Vector3(radius*.65,.012,.007),"red");needle.rotation.z=-.35

static func district(w):
	var k=w.kit
	var panel=w.get_node_or_null("RoadMapPanel")
	if panel:
		var ink=StandardMaterial3D.new();ink.albedo_texture=load("res://assets/visual/district_route_print.svg");ink.roughness=.95;panel.material_override=ink
	# A complete bus shelter anchors the south-west street. Back and side are solid;
	# the open face looks toward the path, 3m clear of its centre and route board.
	var p=Vector3(-69,0,35)
	k.box("BusShelterFoundation",p+Vector3(0,.035,0),Vector3(3.1,.07,4.2),"district_concrete")
	for z in [-1.9,1.9]:
		k.box("BusShelterSide",p+Vector3(0,1.2,z),Vector3(2.9,2.4,.10),"old_iron",true)
		k.box("BusShelterSideInfill",p+Vector3(0,1.2,z+.06),Vector3(2.6,1.8,.02),"cream")
	k.box("BusShelterBack",p+Vector3(-1.45,1.2,0),Vector3(.12,2.4,3.8),"old_iron",true)
	var roof=k.box("BusShelterRoof",p+Vector3(0,2.45,0),Vector3(3.3,.14,4.4),"corrugated");roof.set_meta("view_occluder",true)
	var snow=k.box("BusShelterSnow",p+Vector3(0,2.55,0),Vector3(3.18,.06,4.25),"surface_snow");snow.set_meta("view_occluder",true)
	k.bench(p+Vector3(-.9,0,0),2.9,true,PI/2)
	# Tiled pedestrian approaches and broken edging provide a middle scale between
	# a whole road texture and loose debris. No collider crosses the street.
	for z in range(18,40,2):
		for x in [-67.5,-60.5]:
			k.box("AccessPavingSlab",Vector3(x,.024,z),Vector3(1.85,.04,1.92),"district_concrete")
	for z in [19,25,31,39]:
		k.ellipsoid("AccessSnowBank",Vector3(-72,.03,z),Vector3(1.1,.23,2.5),"surface_snow")
	# Street drain is flush with the ground; it doesn't obstruct movement.
	for z in [17,29]:
		k.box("StreetDrainRecess",Vector3(-62.4,.028,z),Vector3(.5,.008,.85),"dark")
		for n in 7:k.box("StreetDrainBar",Vector3(-62.4,.036,z-.35+n*.115),Vector3(.48,.012,.035),"old_iron")

static func mounted_print(k,id:String,p:Vector3,size:Vector2,asset:String):
	var frame=k.box(id+"Frame",p-Vector3(0,0,.025),Vector3(size.x+.10,size.y+.10,.065),"old_iron")
	frame.set_meta("view_occluder",true)
	var face=MeshInstance3D.new();face.name=id;var mesh=QuadMesh.new();mesh.size=size;face.mesh=mesh
	var mat=StandardMaterial3D.new();mat.albedo_texture=load("res://assets/visual/"+asset+".svg");mat.roughness=.94;face.material_override=mat;k.root.add_child(face);face.position=p+Vector3(0,0,.013);face.set_meta("view_occluder",true);face.set_meta("mount_surface","north_wall")
