extends RefCounted
## Original modular geometry. All measurements are metres.
var root: Node3D
var mats: Dictionary = {}
var solids: Array[Dictionary] = []
var occluders: Array[Dictionary] = []
var font = preload("res://assets/fonts/MetroSans.otf")

func _init(parent: Node3D):
	root = parent
	for id in ["plaster", "concrete", "metal", "rust", "wood", "cloth", "tile", "red"]:
		var m = StandardMaterial3D.new()
		m.albedo_texture = load("res://assets/textures/" + id + ".png")
		m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		m.roughness = 0.93
		m.uv1_triplanar = true
		m.uv1_world_triplanar = true
		m.uv1_scale = Vector3(0.75, 0.75, 0.75)
		mats[id] = m
	for pair in [["dark", "252e2d"], ["brass", "ad8e52"], ["paper", "c5bb96"], ["skin", "bba080"], ["boot", "292c28"], ["cream", "cfbb8a"], ["green", "657054"], ["blue", "556b70"], ["black", "111b1c"]]:
		var m = StandardMaterial3D.new()
		m.albedo_color = Color(pair[1])
		m.roughness = 0.85
		mats[pair[0]] = m
	for pair in [["warm_light", Color(1.0, 0.65, 0.27)], ["cold_light", Color(0.43, 0.78, 0.80)], ["red_light", Color(0.85, 0.24, 0.10)]]:
		var m = StandardMaterial3D.new()
		m.albedo_color = pair[1]
		m.emission_enabled = true
		m.emission = pair[1]
		m.emission_energy_multiplier = 1.8
		mats[pair[0]] = m

func box(id: String, p: Vector3, size: Vector3, material: String, solid: bool = false, parent: Node3D = null) -> MeshInstance3D:
	var mesh = MeshInstance3D.new()
	mesh.name = id
	var shape = BoxMesh.new()
	shape.size = size
	mesh.mesh = shape
	mesh.material_override = mats[material]
	(parent if parent else root).add_child(mesh)
	mesh.position = p
	if solid:
		var body = StaticBody3D.new()
		body.name = id + "_collision"
		body.collision_layer = 1
		mesh.add_child(body)
		var c = CollisionShape3D.new()
		var s = BoxShape3D.new()
		s.size = size
		c.shape = s
		body.add_child(c)
		# World fixtures have axis-aligned footprints; dynamic doors are tracked separately.
		if parent == null:
			solids.append({"name": id, "rect": Rect2(p.x-size.x/2, p.z-size.z/2, size.x, size.z), "bottom": p.y-size.y/2, "top": p.y+size.y/2})
	return mesh

func cyl(id: String, p: Vector3, radius: float, height: float, material: String, parent: Node3D = null, top: float = -1) -> MeshInstance3D:
	var m = MeshInstance3D.new()
	m.name = id
	var s = CylinderMesh.new()
	s.top_radius = radius if top < 0 else top
	s.bottom_radius = radius
	s.height = height
	s.radial_segments = 12
	m.mesh = s
	m.material_override = mats[material]
	(parent if parent else root).add_child(m)
	m.position = p
	return m

func ellipsoid(id: String, p: Vector3, radii: Vector3, material: String, parent: Node3D = null) -> MeshInstance3D:
	var m=MeshInstance3D.new()
	m.name=id
	var sphere=SphereMesh.new()
	sphere.radius=1.0
	sphere.height=2.0
	sphere.radial_segments=12
	sphere.rings=8
	m.mesh=sphere
	m.material_override=mats[material]
	(parent if parent else root).add_child(m)
	m.position=p
	m.scale=radii
	return m

func pipe(a: Vector3, b: Vector3, radius: float = 0.055, material: String = "rust"):
	var m = cyl("Pipe", (a+b)/2, radius, a.distance_to(b), material)
	m.quaternion = Quaternion(Vector3.UP, (b-a).normalized())
	for v in [a.lerp(b,0.12), a.lerp(b,0.55), a.lerp(b,0.9)]:
		var collar = cyl("PipeCollar", v, radius*1.35, 0.06, "dark")
		collar.quaternion = m.quaternion

func label(text: String, p: Vector3, size: int = 42, color: Color = Color("d1c5a4"), parent: Node3D = null) -> Label3D:
	var l = Label3D.new()
	l.text = text
	l.font = font
	l.font_size = size
	l.pixel_size = 0.008
	l.modulate = color
	l.outline_size = 0
	l.no_depth_test = false
	(parent if parent else root).add_child(l)
	l.position = p
	return l

func signboard(text: String, p: Vector3, width: float = 2.5):
	box("SignBacking", p, Vector3(width,0.52,0.07), "dark")
	box("SignRule", p+Vector3(0,-0.23,0.04), Vector3(width-0.08,0.025,0.018), "brass")
	label(text,p+Vector3(0,0,0.045),38)

func lamp(p: Vector3, warm: bool = true, power: float = 1.8, radius: float = 6.0):
	box("LampBracket",p,Vector3(0.7,0.16,0.16),"dark")
	box("LampGlass",p+Vector3(0,-0.04,0.08),Vector3(0.53,0.08,0.12),"warm_light" if warm else "cold_light")
	var l = OmniLight3D.new()
	root.add_child(l)
	l.position = p+Vector3(0,-0.25,0.4)
	l.light_color = Color("ffc276") if warm else Color("85cbd7")
	l.light_energy = power*0.46
	l.omni_range = radius
	l.omni_attenuation = 1.4
	l.shadow_enabled = false

func wall(id: String, a: Vector2, b: Vector2, cut: bool = false):
	var p = Vector3((a.x+b.x)/2,1.4,(a.y+b.y)/2)
	var size = Vector3(maxf(abs(a.x-b.x),0.20),2.8,maxf(abs(a.y-b.y),0.20))
	# Separate full-height physics from the cutaway visual.
	var body = StaticBody3D.new()
	body.name = id + "_wall"
	root.add_child(body)
	body.position = p
	var c = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = size
	c.shape = shape
	body.add_child(c)
	solids.append({"name": id, "rect": Rect2(p.x-size.x/2,p.z-size.z/2,size.x,size.z), "bottom":0.0,"top":2.8})
	var h = 0.55 if cut else 2.65
	box(id,Vector3(p.x,h/2,p.z),Vector3(size.x,h,size.z),"plaster")
	box(id+"Dado",Vector3(p.x,0.30,p.z),Vector3(size.x+0.025,0.6,size.z+0.025),"metal")
	box(id+"Coping",Vector3(p.x,h+0.025,p.z),Vector3(size.x+0.06,0.05,size.z+0.06),"dark")
	if not cut:
		box(id+"Trim",Vector3(p.x,0.85,p.z),Vector3(size.x+0.035,0.05,size.z+0.035),"dark")

func doorway(x: float, z: float, along_z: bool = false):
	var n = Node3D.new()
	root.add_child(n)
	n.position = Vector3(x,0,z)
	if along_z: n.rotation.y = PI/2
	for side in [-1,1]:
		box("DoorJamb",Vector3(side*0.79,1.06,0),Vector3(0.13,2.12,0.30),"dark",false,n)
		box("DoorEdge",Vector3(side*0.79,1.08,0.17),Vector3(0.025,2.0,0.02),"brass",false,n)
	box("DoorLintel",Vector3(0,2.15,0),Vector3(1.72,0.18,0.32),"metal",false,n)
	box("Threshold",Vector3(0,0.012,0),Vector3(1.5,0.024,0.35),"metal",false,n)
	# Opening height 2.06m, clear width 1.45m; no tiny threshold colliders.

func table(p: Vector3, length: float = 2.2):
	box("TableTop",p+Vector3(0,0.75,0),Vector3(length,0.09,0.9),"wood",true)
	for x in [-length/2+0.15,length/2-0.15]:
		for z in [-0.3,0.3]: box("TableLeg",p+Vector3(x,0.35,z),Vector3(0.065,0.7,0.065),"dark")
	# One consolidated footprint, rather than trapping the player between individual legs.
	box("TableFootprint",p+Vector3(0,0.32,0),Vector3(length-0.06,0.64,0.86),"dark").visible=false
	var footprint = StaticBody3D.new()
	root.add_child(footprint)
	footprint.position=p+Vector3(0,0.38,0)
	var c=CollisionShape3D.new()
	var s=BoxShape3D.new()
	s.size=Vector3(length,0.76,0.9)
	c.shape=s
	footprint.add_child(c)
	for x in [-0.6,0.3]:
		cyl("TinBowl",p+Vector3(x,0.83,-0.10),0.13,0.06,"cream")
		cyl("Cup",p+Vector3(x+0.22,0.88,0.18),0.07,0.16,"metal")
	box("Bread",p+Vector3(0.7,0.85,-0.1),Vector3(0.25,0.13,0.14),"wood")

func bench(p: Vector3, length: float = 2.1, back: bool = true):
	box("BenchSeat",p+Vector3(0,0.45,0),Vector3(length,0.12,0.40),"wood",true)
	# Consolidate seat+legs into a single collision box down to floor.
	box("BenchBase",p+Vector3(0,0.22,0),Vector3(length,0.44,0.4),"dark",true).visible=false
	for x in [-length/2+0.2,length/2-0.2]:box("BenchLeg",p+Vector3(x,0.22,0),Vector3(0.08,0.44,0.36),"dark")
	if back:box("BenchBack",p+Vector3(0,0.85,-0.17),Vector3(length,0.45,0.07),"wood")

func crate(p: Vector3, size: Vector3 = Vector3(0.65,0.55,0.6)):
	box("Crate",p+Vector3(0,size.y/2,0),size,"wood",true)
	for z in [-size.z/2-0.01,size.z/2+0.01]:
		for x in [-size.x*0.35,size.x*0.35]:box("CrateStrap",p+Vector3(x,size.y/2,z),Vector3(0.055,size.y,0.025),"metal")

func bed(p: Vector3):
	box("BedFrame",p+Vector3(0,0.35,0),Vector3(1.0,0.15,2.0),"dark",true)
	box("BedMattress",p+Vector3(0,0.48,0),Vector3(0.91,0.16,1.95),"cloth")
	box("BedFootprint",p+Vector3(0,0.2,0),Vector3(1.02,0.4,2.02),"dark",true).visible=false
	box("Pillow",p+Vector3(0,0.60,-0.70),Vector3(0.65,0.16,0.40),"paper")
	box("Blanket",p+Vector3(0,0.58,0.37),Vector3(0.92,0.08,1.0),"red")
	for z in [-0.96,0.96]:
		for x in [-0.48,0.48]:cyl("BedPost",p+Vector3(x,0.4,z),0.035,0.8,"metal")

func locker(p: Vector3, height: float = 1.85):
	box("Locker",p+Vector3(0,height/2,0),Vector3(0.75,height,0.55),"metal",true)
	box("LockerDoor",p+Vector3(0,height/2,0.285),Vector3(0.66,height-0.1,0.035),"green")
	box("LockerHandle",p+Vector3(0.22,height*0.50,0.32),Vector3(0.035,0.15,0.025),"brass")
	for y in [height-0.25,height-0.32,height-0.39]:box("LockerVent",p+Vector3(0,y,0.31),Vector3(0.4,0.018,0.02),"dark")

func poster(p: Vector3, text: String, red: bool = true):
	box("Poster",p,Vector3(0.88,1.2,0.018),"red" if red else "paper")
	label("★" if red else "06",p+Vector3(0,0.24,0.025),65,Color("c5ac77") if red else Color("3b4846"))
	label(text,p+Vector3(0,-0.28,0.025),22,Color("d6c6a1") if red else Color("3b4846"))

func batch_static():
	# Render repeated modules in material batches; their physics bodies remain independent.
	var groups:Dictionary={}
	for child in root.find_children("*","MeshInstance3D",true,false):
		if not child.visible or child.name in ["LockedMainGate","LockedSideDoor"]:continue
		var source=child.mesh
		var material=child.material_override
		if not material:continue
		var transform:Transform3D=child.global_transform
		var primitive:Mesh
		var key=str(material.get_instance_id())+"_cell_"+str(floori(child.global_position.x/7.0))+"_"+str(floori(child.global_position.z/7.0))
		if source is BoxMesh:
			key+="_box"
			primitive=BoxMesh.new()
			primitive.size=Vector3.ONE
			transform=transform.scaled_local(source.size)
		elif source is CylinderMesh:
			var ratio=source.top_radius/source.bottom_radius
			key+="_cyl_"+str(ratio)
			primitive=CylinderMesh.new()
			primitive.top_radius=ratio
			primitive.bottom_radius=1
			primitive.height=1
			primitive.radial_segments=12
			transform=transform.scaled_local(Vector3(source.bottom_radius,source.height,source.bottom_radius))
		else:continue
		if not groups.has(key):groups[key]={"mesh":primitive,"material":material,"transforms":[]}
		groups[key].transforms.append(transform)
		child.visible=false
	for key in groups:
		var group=groups[key]
		var instance=MultiMeshInstance3D.new()
		var mm=MultiMesh.new()
		mm.transform_format=MultiMesh.TRANSFORM_3D
		mm.mesh=group.mesh
		mm.instance_count=group.transforms.size()
		for i in group.transforms.size():mm.set_instance_transform(i,group.transforms[i])
		instance.multimesh=mm
		instance.material_override=group.material
		root.add_child(instance)
