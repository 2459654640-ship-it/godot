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
	# Repair marks make this inherited civic space feel maintained, not pristine.
	for x in [-5,6]:
		k.box("StageSkirtingRepair",Vector3(x,.12,-10.12),Vector3(1.3,.17,.025),"old_iron")

static func waterworks(w):
	var k=w.kit
	for x in [-16,-10]:
		# Existing motor fins stay in facility_detail; do not stack duplicate rings.
		# Bolted base and manifold gauges reuse the pump footprint.
		k.box("PumpBedplate",Vector3(x+.35,.12,-10),Vector3(2.42,.18,1.55),"old_iron")
		for dx in [-.7,1.2]:
			for z in [-10.6,-9.4]:k.cyl("PumpAnchorBolt",Vector3(x+dx,.24,z),.045,.1,"brass")
		k.pipe(Vector3(x,.9,-10),Vector3(x,1.9,-10),.055,"old_iron")
		gauge(k,Vector3(x,1.96,-9.94),.19)
		for z in [-12.8,-11.8]:
			var flange=k.cyl("ManifoldFlange",Vector3(x,1.2,z),.28,.09,"old_iron");flange.rotation.x=PI/2
			for angle in [0,PI/2,PI,PI*1.5]:
				k.cyl("FlangeBolt",Vector3(x+cos(angle)*.23,1.2+sin(angle)*.23,z+.055),.025,.05,"brass").rotation.x=PI/2
	# A clearly readable floor service zone at the pump bases, with no raised rails.
	for x in [-16,-10]:
		for dx in [-1.12,1.82]:k.box("PumpServiceLine",Vector3(x+dx,.028,-10),Vector3(.065,.006,2.3),"cream")

static func gauge(k,p:Vector3,radius:float):
	var bezel=k.cyl("AnalogueGaugeBezel",p,radius,.08,"old_iron");bezel.rotation.x=PI/2
	var dial=k.cyl("AnalogueGaugeFace",p+Vector3(0,0,.045),radius*.85,.012,"paper");dial.rotation.x=PI/2
	for i in 9:
		var a=PI*.15+i*PI*.7/8
		var mark=k.box("GaugeGraduation",p+Vector3(cos(a)*radius*.65,sin(a)*radius*.65,.057),Vector3(.012,.025,.006),"dark");mark.rotation.z=a-PI/2
	var needle=k.box("GaugeNeedle",p+Vector3(-radius*.22,radius*.10,.062),Vector3(radius*.65,.012,.007),"red");needle.rotation.z=-.35

static func district(w):
	var k=w.kit
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
