extends RefCounted
## Reused detail modules, with consolidated collision around piles.
static func build(w):
	var k=w.kit
	for mesh in w.find_children("Floor_L*","MeshInstance3D",true,false):
		mesh.material_override=mesh.material_override.duplicate()
		mesh.material_override.albedo_color=Color("8b8270") if mesh.name=="Floor_L0" else Color("a2977d")
		if mesh.name in ["Floor_L1","Floor_L2","Floor_L6","Floor_L7","Floor_L8","Floor_L9"]:mesh.material_override.albedo_color=Color("716b56")
	# Standard railway continues behind the closed blast door, never walkable.
	k.box("OutsideTrackBed",Vector3(20,-.13,-17.5),Vector3(4.6,.18,9),"concrete")
	for x in [19.24,20.76]:k.box("OutsideMetroRail",Vector3(x,.03,-17.5),Vector3(.075,.06,9),"metal")
	for z in range(-21,-13):k.box("OutsideSleeper",Vector3(20,.01,z),Vector3(2.5,.04,.17),"wood")
	for x in [17.55,22.45]:k.box("GateConcretePier",Vector3(x,2,-13.04),Vector3(.7,4,.8),"concrete")
	k.box("GateConcreteBeam",Vector3(20,3.95,-13.04),Vector3(5.6,.7,.8),"concrete")
	for x in [18.5,19,21,21.5]:
		for y in [.35,1.05,2.1,3.1]:k.cyl("BlastRivet",Vector3(x,y,-12.7),.055,.07,"dark").rotation.x=PI/2
	# Real wheel rim and spokes, rather than a bright solid disc.
	var rim=MeshInstance3D.new();var torus=TorusMesh.new();torus.inner_radius=.29;torus.outer_radius=.35;torus.rings=16;torus.ring_segments=8
	rim.mesh=torus;rim.material_override=k.mats.rust;w.add_child(rim);rim.position=Vector3(20,1.55,-12.43);rim.rotation.x=PI/2
	for i in 6:k.box("GateWheelSpoke",Vector3(20,1.55,-12.43),Vector3(.035,.61,.035),"metal").rotation.z=i*PI/3
	k.box("GateControlBox",Vector3(23.1,1.1,-12.6),Vector3(.6,.9,.25),"rust",true)
	k.cyl("GateRedLamp",Vector3(23.1,1.32,-12.43),.075,.04,"red_light").rotation.x=PI/2
	k.pipe(Vector3(23.1,1.6,-12.7),Vector3(23.1,3.1,-12.7),.04)
	# Worn waiting area and fuel/refrigerant drums.
	for p in [Vector3(16.5,0,-11.6),Vector3(24.5,0,-6.3),Vector3(-6,0,-11.4),Vector3(24.5,0,5.4)]:
		k.cyl("OldDrum",p+Vector3(0,.48,0),.33,.96,"rust")
		k.box("DrumHull",p+Vector3(0,.48,0),Vector3(.65,.96,.65),"dark",true).visible=false
		for y in [.16,.75]:k.cyl("DrumRim",p+Vector3(0,y,0),.35,.035,"dark")
	# Coal dump enclosed in one hull; individual chunks never trap feet.
	for center in [Vector3(1,0,12),Vector3(7,0,12)]:
		k.box("CoalHeapHull",center+Vector3(0,.4,0),Vector3(1.7,.8,1.4),"dark",true).visible=false
		for i in 27:
			var angle=float(i)*2.399;var rad=.13+float(i%5)*.15
			k.ellipsoid("CoalChunk",center+Vector3(cos(angle)*rad,.15+float(i%4)*.14,sin(angle)*rad*.8),Vector3(.22+float(i%3)*.04,.18,.17),"black")
	k.box("CoalCart",Vector3(3,.5,10.8),Vector3(1.5,.7,1.2),"rust",true)
	for x in [2.4,3.6]:
		for z in [10.4,11.2]:k.cyl("CoalCartWheel",Vector3(x,.2,z),.20,.1,"dark").rotation.z=PI/2
	for x in [.5,5.5]:
		k.box("ShovelHandle",Vector3(x,1.1,13.45),Vector3(.05,1.5,.05),"wood")
		k.box("ShovelBlade",Vector3(x,.38,13.45),Vector3(.24,.37,.045),"metal")
	# Irregular stacks, pallets, repair components and cloth bales.
	for p in [Vector3(12,0,12),Vector3(18,0,12),Vector3(-11.7,0,-11.3)]:
		for i in 5:k.box("StackedPlank",p+Vector3(0,.15+i*.075,0),Vector3(2.1,.06,.7),"wood").rotation.y=.02*i
	for p in [Vector3(11,0,5.5),Vector3(21,0,12)]:
		k.box("PalletHull",p+Vector3(0,.15,0),Vector3(1.4,.3,.8),"wood",true)
		for x in [-.55,0,.55]:k.box("PalletSlat",p+Vector3(x,.32,0),Vector3(.26,.04,.9),"wood")
		k.ellipsoid("CanvasBale",p+Vector3(0,.56,0),Vector3(.6,.26,.32),"cloth")
	for p in [Vector3(-9.9,.84,-10.8),Vector3(-8.7,.84,-10.8),Vector3(-8.3,.84,11.4)]:
		k.box("ToolCase",p,Vector3(.6,.18,.34),"metal")
		k.box("ToolCaseHandle",p+Vector3(0,.12,0),Vector3(.18,.06,.04),"dark")
	for x in [-13.7,-5.3]:
		for y in [.6,1.1,1.6]:k.box("WorkshopShelf",Vector3(x,y,-9),Vector3(.35,.05,3),"wood")
	for x in [-10.5,-9.7,-8.9]:k.cyl("RepairSpare",Vector3(x,.87,-10.9),.12,.18,"rust")
	for x in [-21,-18]:
		k.box("HangingCoat",Vector3(x,1.65,-12.72),Vector3(.4,.8,.1),"cloth")
		k.box("BunkShoes",Vector3(x,.11,-9.6),Vector3(.35,.2,.28),"boot")
	for p in [Vector3(-19,.84,7),Vector3(-18,.84,10.5)]:k.cyl("WorkersCup",p,.085,.16,"cream")
	# Wall placards and services reinforce room purpose at game camera scale.
	for pair in [[Vector3(-19,2.15,-12.78),"СМЕНА / 12 МЕСТ"],[Vector3(-9.5,2.15,-12.78),"РЕМОНТ / ИНСТРУМЕНТ"],[Vector3(3,2.15,13.55),"УГОЛЬ / СМЕННЫЙ УЧЁТ"]]:
		var l=k.label(pair[1],pair[0],25)
		if pair[0].z>0:l.rotation.y=PI
	k.poster(Vector3(-6,1.5,4.16),"БЕРЕГИ ВОДУ")
