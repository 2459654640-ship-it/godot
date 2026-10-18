extends RefCounted
## Original modular geometry. All measurements are metres.
var root: Node3D
var mats: Dictionary = {}
var solids: Array[Dictionary] = []
var occluders: Array[Dictionary] = []
var wall_sections: Array[Dictionary] = []
var scrap_meshes:Array[MeshInstance3D]=[]
var wall_meshes: Array[MeshInstance3D] = []
var veil_materials:Dictionary={}
var roof_occluders:Array=[]
var roof_material_cache:Dictionary={}
var highlight_material: ShaderMaterial
var highlight_proxies:Dictionary={}
var previous_highlight=""
var wall_surface="wall"
var wall_normal="wall_normal"
var wall_color=Color.WHITE
var wall_room_profiles:Array=[]
var wall_finish_theme="commune"
var font:Font

func _init(parent: Node3D):
	root = parent
	font=load("res://assets/fonts/MetroSans.otf")
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
	# Original layered maps: a single painted surface, not stacked coplanar boxes.
	for pair in [["plaster","wall"],["concrete","cement"],["tile","floor"],["metal","steel"],["rust","oxide"],["wood","timber"],["cloth","weave"],["red","weave"],["green","weave"],["blue","weave"]]:
		var m:StandardMaterial3D=mats[pair[0]]
		m.albedo_texture=load("res://assets/visual/"+pair[1]+".png")
		m.normal_enabled=true
		m.normal_texture=load("res://assets/visual/"+pair[1]+"_normal.png")
		m.normal_scale=0.55
		m.roughness_texture=load("res://assets/visual/"+pair[1]+"_rough.png")
		m.roughness=0.94
		m.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		m.uv1_scale=Vector3.ONE/2.4
		if pair[0]=="red":m.albedo_color=Color("794232")
		elif pair[0] in ["green","blue"]:m.albedo_color=m.albedo_color.lightened(0.15)
	var corrugated:StandardMaterial3D=mats.metal.duplicate()
	corrugated.albedo_texture=load("res://assets/visual/corrugated.png")
	corrugated.normal_enabled=false
	corrugated.roughness_texture=null
	mats["corrugated"]=corrugated
	mats.plaster.uv1_triplanar=false
	mats.plaster.uv1_world_triplanar=false
	mats.plaster.uv1_scale=Vector3.ONE
	var hair=StandardMaterial3D.new()
	hair.albedo_color=Color("403a2f")
	hair.roughness=1.0
	mats.hair=hair
	highlight_material=ShaderMaterial.new()
	highlight_material.shader=load("res://assets/visual/edge_highlight.gdshader")
	for pair in [["warm_light", Color(1.0, 0.65, 0.27)], ["cold_light", Color(0.43, 0.78, 0.80)], ["red_light", Color(0.85, 0.24, 0.10)]]:
		var m = StandardMaterial3D.new()
		m.albedo_color = pair[1]
		m.emission_enabled = true
		m.emission = pair[1]
		m.emission_energy_multiplier = 1.5
		mats[pair[0]] = m

func box(id: String, p: Vector3, size: Vector3, material: String, solid: bool = false, parent: Node3D = null) -> MeshInstance3D:
	var mesh = MeshInstance3D.new()
	mesh.name = id
	var shape = BoxMesh.new()
	shape.size = size
	mesh.mesh = shape
	mesh.set_meta("design_id",id)
	mesh.material_override = mats[material]
	(parent if parent else root).add_child(mesh)
	mesh.position = p
	if id.begins_with("Floor") or id in ["Foundation","UndergroundVoid"]:
		mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
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
	m.set_meta("design_id",id)
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
	var count=maxi(1,ceili(a.distance_to(b)/2.0))
	for i in count:
		var start=a.lerp(b,float(i)/count)
		var end=a.lerp(b,float(i+1)/count)
		var m=cyl("Pipe",(start+end)/2,radius,start.distance_to(end),material)
		m.quaternion=Quaternion(Vector3.UP,(b-a).normalized())
	for v in [a.lerp(b,0.12), a.lerp(b,0.55), a.lerp(b,0.9)]:
		var collar = cyl("PipeCollar", v, radius*1.35, 0.06, "dark")
		collar.quaternion = Quaternion(Vector3.UP,(b-a).normalized())

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

func signboard(_text:String,_p:Vector3,_width:float=2.5):
	# Room uses are recorded on the map; no floating black placards in the world.
	pass

func lamp(p: Vector3, warm: bool = true, power: float = 1.8, radius: float = 6.0):
	box("LampBracket",p,Vector3(0.7,0.16,0.16),"dark")
	box("LampGlass",p+Vector3(0,-0.04,0.08),Vector3(0.53,0.08,0.12),"warm_light" if warm else "cold_light")
	var l = OmniLight3D.new()
	root.add_child(l)
	l.position = p+Vector3(0,-0.25,0.4)
	l.light_color = Color("ffbb71") if warm else Color("83b7bb")
	l.light_energy = power*0.85
	l.omni_range = radius*0.86
	l.omni_attenuation = 1.8
	l.shadow_enabled = warm and power>=2.2
	l.shadow_bias=0.055
	l.shadow_normal_bias=0.8
	# Battered diffuser cover and protective cage, kept clear of the light face.
	for x in [-0.26,0.0,0.26]:box("LampCage",p+Vector3(x,-0.03,0.17),Vector3(0.018,0.18,0.025),"dark")

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
	# Preserve existing collision envelopes and door clearances. Visible masonry is
	# 25cm thick; neighbouring modules are union-meshed in finish_walls().
	wall_sections.append({"id":id,"rect":Rect2(p.x-maxf(abs(a.x-b.x),0.25)/2,p.z-maxf(abs(a.y-b.y),0.25)/2,maxf(abs(a.x-b.x),0.25),maxf(abs(a.y-b.y),0.25)),"height":2.70,"foreground":cut})

func finish_walls():
	# Union a rectilinear footprint before extrusion. Adjacent cells share edges,
	# never top faces. At T-junctions/corners the taller solid owns the volume.
	var xs:Array[float]=[]
	var zs:Array[float]=[]
	for section in wall_sections:
		var r:Rect2=section.rect
		for x in [r.position.x,r.end.x]:
			if x not in xs:xs.append(x)
		for z in [r.position.y,r.end.y]:
			if z not in zs:zs.append(z)
	# Short connected runs permit local fading, without overlapping wall boxes.
	for x in range(-30,16,2):
		if float(x) not in xs:xs.append(float(x))
	for z in range(-14,11,2):
		if float(z) not in zs:zs.append(float(z))
	xs.sort()
	zs.sort()
	var heights:Dictionary={}
	var foreground:Dictionary={}
	for ix in xs.size()-1:
		for iz in zs.size()-1:
			var center=Vector2((xs[ix]+xs[ix+1])*0.5,(zs[iz]+zs[iz+1])*0.5)
			for section in wall_sections:
				if section.rect.has_point(center):
					heights[Vector2i(ix,iz)]=maxf(heights.get(Vector2i(ix,iz),0),section.height)
					if section.foreground:foreground[Vector2i(ix,iz)]=true
	var groups:Dictionary={}
	var group_foreground:Dictionary={}
	for cell in heights:
		var x0=xs[cell.x]
		var x1=xs[cell.x+1]
		var z0=zs[cell.y]
		var z1=zs[cell.y+1]
		var h:float=heights[cell]
		var group_key=Vector2i(floori((x0+x1)/4),floori((z0+z1)/4))
		if foreground.has(cell):group_foreground[group_key]=true
		if not groups.has(group_key):
			groups[group_key]=[SurfaceTool.new(),SurfaceTool.new()]
			for tool in groups[group_key]:tool.begin(Mesh.PRIMITIVE_TRIANGLES)
		var tools=groups[group_key]
		wall_quad(tools[1],[Vector3(x0,h,z0),Vector3(x1,h,z0),Vector3(x1,h,z1),Vector3(x0,h,z1)],Vector3.UP,true)
		var neighbour:float=heights.get(cell+Vector2i(0,-1),0.0)
		if neighbour<h:wall_quad(tools[0],[Vector3(x0,neighbour,z0),Vector3(x1,neighbour,z0),Vector3(x1,h,z0),Vector3(x0,h,z0)],Vector3.FORWARD)
		neighbour=heights.get(cell+Vector2i(0,1),0.0)
		if neighbour<h:wall_quad(tools[0],[Vector3(x1,neighbour,z1),Vector3(x0,neighbour,z1),Vector3(x0,h,z1),Vector3(x1,h,z1)],Vector3.BACK)
		neighbour=heights.get(cell+Vector2i(-1,0),0.0)
		if neighbour<h:wall_quad(tools[0],[Vector3(x0,neighbour,z1),Vector3(x0,neighbour,z0),Vector3(x0,h,z0),Vector3(x0,h,z1)],Vector3.LEFT)
		neighbour=heights.get(cell+Vector2i(1,0),0.0)
		if neighbour<h:wall_quad(tools[0],[Vector3(x1,neighbour,z0),Vector3(x1,neighbour,z1),Vector3(x1,h,z1),Vector3(x1,h,z0)],Vector3.RIGHT)
	for group_key in groups:
		var mesh=ArrayMesh.new()
		for i in range(2):
			var tool:SurfaceTool=groups[group_key][i]
			if not tool.get_meta("has_vertices",false):continue
			tool.generate_tangents()
			var material=ShaderMaterial.new()
			material.shader=load("res://assets/visual/masonry_veil.gdshader")
			material.set_shader_parameter("albedo_map",load("res://assets/visual/"+wall_surface+".png" if i==0 else "res://assets/visual/cement.png"))
			material.set_shader_parameter("normal_map",load("res://assets/visual/"+wall_normal+".png" if i==0 else "res://assets/visual/cement_normal.png"))
			material.set_shader_parameter("base_color",wall_color)
			material.set_shader_parameter("normal_strength",0.45 if i==0 else 0.30)
			if not wall_room_profiles.is_empty() and i==0 and wall_finish_theme=="factory":
				material.set_shader_parameter("factory_finish",true)
				material.set_shader_parameter("factory_blue",load("res://assets/visual/plant_blue_wall.png"))
				material.set_shader_parameter("factory_tile",load("res://assets/visual/plant_ivory_tile.png"))
				material.set_shader_parameter("factory_archive",load("res://assets/visual/plant_archive_wall.png"))
				material.set_shader_parameter("normal_strength",0.0)
			elif not wall_room_profiles.is_empty() and i==0:
				material.set_shader_parameter("commune_finish",true)
				material.set_shader_parameter("finish_plaster",load("res://assets/visual/commune_plaster.png"))
				material.set_shader_parameter("finish_tile",load("res://assets/visual/commune_ivory_tile.png"))
				material.set_shader_parameter("finish_cement",load("res://assets/visual/cement.png"))
				material.set_shader_parameter("normal_strength",.16)
			tool.set_material(material)
			tool.commit(mesh)
		var instance=MeshInstance3D.new()
		instance.name="SolidMasonry_"+str(group_key)
		instance.mesh=mesh
		instance.set_meta("complete_masonry",true)
		instance.set_meta("foreground",group_foreground.has(group_key))
		instance.set_meta("veil_opacity",1.0)
		root.add_child(instance)
		wall_meshes.append(instance)
		veil_materials[instance.get_instance_id()]=[]
		var shadow=MeshInstance3D.new()
		shadow.name="MasonryShadow"
		shadow.mesh=mesh
		shadow.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
		shadow.material_override=mats.concrete
		root.add_child(shadow)
		instance.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func wall_quad(tool:SurfaceTool,points:Array,normal:Vector3,cap:bool=false):
	tool.set_meta("has_vertices",true)
	var style=0
	if not cap and not wall_room_profiles.is_empty():
		var center:Vector3=(points[0]+points[1]+points[2]+points[3])*.25+normal*.18
		for profile in wall_room_profiles:
			if profile.rect.has_point(Vector2(center.x,center.z)):style=profile.style;break
	# Godot front faces use clockwise vertex order. Normals are explicit and
	# unrelated to material transparency or the camera's moving position.
	for index in [0,1,2,0,2,3]:
		var p:Vector3=points[index]
		tool.set_normal(normal)
		tool.set_uv2(Vector2(style,0))
		tool.set_uv(Vector2(p.x,p.z)*0.55 if cap else Vector2((p.x if absf(normal.z)>0.5 else p.z)/3.0,1.0-p.y/2.7))
		tool.add_vertex(p)

func doorway(x: float, z: float, along_z: bool = false):
	var n = Node3D.new()
	root.add_child(n)
	n.position = Vector3(x,0,z)
	if along_z: n.rotation.y = PI/2
	for side in [-1,1]:
		box("DoorJamb",Vector3(side*0.79,1.06,0),Vector3(0.13,2.12,0.30),"dark",true,n)
		var centre=Vector3(x,0,z)+n.basis*Vector3(side*.79,0,0)
		var footprint=Vector2(.30,.13) if along_z else Vector2(.13,.30)
		solids.append({"name":"DoorJamb","rect":Rect2(Vector2(centre.x,centre.z)-footprint/2,footprint),"bottom":0.0,"top":2.12})
		box("DoorEdge",Vector3(side*0.79,1.08,0.17),Vector3(0.025,2.0,0.02),"brass",false,n)
	box("DoorLintel",Vector3(0,2.15,0),Vector3(1.72,0.18,0.32),"metal",false,n)
	box("ConcreteDoorBeam",Vector3(0,2.49,0),Vector3(2.12,0.42,0.35),"concrete",false,n)
	for side in [-1,1]:
		box("DoorPier",Vector3(side*0.96,1.14,0),Vector3(0.16,2.28,0.28),"concrete",false,n)
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

func bench(p:Vector3,length:float=2.1,back:bool=true,heading:float=0.0):
	var basis=Basis(Vector3.UP,heading)
	var across=absf(sin(heading))>.7
	var specs=[
		["BenchSeat",Vector3(0,.45,0),Vector3(length,.12,.4),"wood",true],
		["BenchBase",Vector3(0,.22,0),Vector3(length,.44,.4),"dark",true]]
	for x in [-length/2+.2,length/2-.2]:specs.append(["BenchLeg",Vector3(x,.22,0),Vector3(.08,.44,.36),"dark",false])
	if back:specs.append(["BenchBack",Vector3(0,.85,-.17),Vector3(length,.45,.07),"wood",false])
	for spec in specs:
		var extent:Vector3=spec[2]
		if across:extent=Vector3(extent.z,extent.y,extent.x)
		var m=box(spec[0],p+basis*spec[1],extent,spec[3],spec[4])
		if spec[0]=="BenchBase":m.visible=false
		m.set_meta("seat_forward",basis*Vector3.BACK)

func crate(p: Vector3, size: Vector3 = Vector3(0.65,0.55,0.6)):
	box("Crate",p+Vector3(0,size.y/2,0),size,"wood",true)
	for z in [-size.z/2-0.01,size.z/2+0.01]:
		for x in [-size.x*0.35,size.x*0.35]:box("CrateStrap",p+Vector3(x,size.y/2,z),Vector3(0.055,size.y,0.025),"metal")

func bed(p: Vector3,blanket:String="red"):
	box("BedFrame",p+Vector3(0,0.35,0),Vector3(1.0,0.15,2.0),"dark",true)
	ellipsoid("BedMattress",p+Vector3(0,0.48,0),Vector3(0.455,0.09,0.975),"cloth")
	box("BedFootprint",p+Vector3(0,0.2,0),Vector3(1.02,0.4,2.02),"dark",true).visible=false
	ellipsoid("Pillow",p+Vector3(0,0.60,-0.70),Vector3(0.325,0.08,0.20),"paper")
	box("Blanket",p+Vector3(0,0.58,0.37),Vector3(0.92,0.08,1.0),blanket)
	for x in [-0.30,-0.10,0.10,0.30]:
		box("QuiltStitch",p+Vector3(x,0.625,0.37),Vector3(0.006,0.006,0.94),"cloth")
	for z in [-0.96,0.96]:
		for x in [-0.48,0.48]:cyl("BedPost",p+Vector3(x,0.4,z),0.035,0.8,"metal")

func locker(p: Vector3, height: float = 1.85):
	box("Locker",p+Vector3(0,height/2,0),Vector3(0.75,height,0.55),"metal",true)
	box("LockerDoor",p+Vector3(0,height/2,0.285),Vector3(0.66,height-0.1,0.035),"green")
	box("LockerHandle",p+Vector3(0.22,height*0.50,0.32),Vector3(0.035,0.15,0.025),"brass")
	for y in [height-0.25,height-0.32,height-0.39]:box("LockerVent",p+Vector3(0,y,0.31),Vector3(0.4,0.018,0.02),"dark")

func poster(p: Vector3, text: String, red: bool = true):
	var m=MeshInstance3D.new()
	var q=QuadMesh.new()
	q.size=Vector2(0.88,1.2)
	m.mesh=q
	var mat=StandardMaterial3D.new()
	mat.albedo_texture=load("res://assets/visual/poster_"+str(posmod(text.hash(),3))+".png")
	mat.roughness=1.0
	mat.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	m.material_override=mat
	root.add_child(m)
	m.position=p+Vector3(0,0,0.012)
	# Opaque poster face is in front of masonry, never a transparent overlay.
	label(text,p+Vector3(0,-0.71,0.025),18,Color("bfb494"))

func batch_static():
	# Render repeated modules in material batches; their physics bodies remain independent.
	var groups:Dictionary={}
	for child in root.find_children("*","MeshInstance3D",true,false):
		if not child.visible or child.name in ["LockedMainGate","LockedSideDoor","CampaignInnerGate"] or child.has_meta("dynamic"):continue
		var source=child.mesh
		var material=child.material_override
		if not material:continue
		var overhead=false
		var design_id=String(child.get_meta("design_id",String(child.name)))
		var high_bounds: AABB=child.global_transform*child.get_aabb()
		if high_bounds.position.y>1.85:
			for word in ["Pipe","Cable","Lamp","Beam","Rib","Truss","Cross","Reflector","GrowTube","Rebar","Ceiling"]:
				if design_id.contains(word):overhead=true
		var veil=-1
		var architectural=false
		for prefix in ["Door","ConcreteDoor","Pipe","Cable","Lamp","Sign"]:
			if design_id.begins_with(prefix):architectural=true
		if architectural:
			var distance=2.5
			for index in wall_meshes.size():
				var bounds=wall_meshes[index].get_aabb().grow(0.62)
				var p=child.global_position
				if bounds.has_point(Vector3(p.x,1,p.z)):
					var d=Vector2(bounds.get_center().x-p.x,bounds.get_center().z-p.z).length()
					if d<distance:distance=d;veil=index
		if overhead and material is StandardMaterial3D:
			var cell=Vector2i(floori(child.global_position.x/2.5),floori(child.global_position.z/2.5))
			var roof_key=str(material.get_instance_id())+str(cell)
			if not roof_material_cache.has(roof_key):roof_material_cache[roof_key]=new_veil_material(material)
			material=roof_material_cache[roof_key]
		elif veil>=0:material=veil_prop_material(material,wall_meshes[veil])
		var transform:Transform3D=child.global_transform
		var primitive:Mesh
		var key=str(material.get_instance_id())+"_shadow_"+str(child.cast_shadow)+"_cell_"+str(floori(child.global_position.x/7.0))+"_"+str(floori(child.global_position.z/7.0))
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
		if not groups.has(key):groups[key]={"mesh":primitive,"material":material,"transforms":[],"shadow":child.cast_shadow,"overhead":overhead,"bounds":high_bounds}
		else:groups[key].bounds=groups[key].bounds.merge(high_bounds)
		groups[key].transforms.append(transform)
		child.set_meta("batched_visual",true)
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
		# A material can span different primitive/cell batches. Their coverage
		# differs, so each overhead batch needs its own visibility parameter.
		var render_material=group.material.duplicate() if group.overhead else group.material
		instance.material_override=render_material
		instance.cast_shadow=group.shadow
		root.add_child(instance)
		if group.overhead:
			instance.name="OverheadVeil"
			roof_occluders.append({"mesh":instance,"bounds":group.bounds,"material":render_material})

func veil_prop_material(base:StandardMaterial3D,wall_mesh:MeshInstance3D) -> ShaderMaterial:
	var list:Array=veil_materials[wall_mesh.get_instance_id()]
	for entry in list:
		if entry.base==base:return entry.material
	var material=new_veil_material(base)
	list.append({"base":base,"material":material})
	return material

func new_veil_material(base:StandardMaterial3D)->ShaderMaterial:
	var material=ShaderMaterial.new()
	material.shader=load("res://assets/visual/masonry_veil.gdshader")
	material.set_shader_parameter("normal_strength",0.0)
	material.set_shader_parameter("base_color",base.albedo_color)
	material.set_shader_parameter("has_texture",base.albedo_texture!=null)
	if base.albedo_texture:material.set_shader_parameter("albedo_map",base.albedo_texture)
	material.set_shader_parameter("triplanar",base.uv1_triplanar)
	material.set_shader_parameter("map_scale",base.uv1_scale)
	if base.emission_enabled:material.set_shader_parameter("emission_color",base.emission*base.emission_energy_multiplier)
	return material

func prepare_highlights():
	var specs={
		"box":[Vector3(-12.2,0,-4.8),["Crate"],0.7],
		"radio":[Vector3(-11.2,1,-7.65),["Radio"],0.8],
		"notice":[Vector3(11,1.5,-0.2),["NoticeBoard","CallUpNotice"],1.0],
		"valve":[Vector3(8.8,1.25,-6.5),["ValveWheel","CatchBucket"],0.8],
		"cabinet":[Vector3(-9,1.1,8.9),["FuseCabinet","FuseHazard"],1.0],
		"relay":[Vector3(7.7,1,3.8),["Relay"],1.0],
		"hatch":[Vector3(7.8,0,8.9),["Hatch"],1.0],
		"lift":[Vector3(-3.3,1,9.4),["Airlock"],1.5],
		"gate":[Vector3(9,1,6.7),["LockedMainGate"],1.0],
		"side":[Vector3(9,1,4.5),["LockedSideDoor"],1.0]}
	var originals=root.find_children("*","MeshInstance3D",true,false)
	for id in specs:
		highlight_proxies[id]=[]
		for original in originals:
			if not original.get_meta("batched_visual",false) and not original.visible:continue
			var match_name=false
			for prefix in specs[id][1]:
				if original.name.begins_with(prefix):match_name=true
			if not match_name or original.global_position.distance_to(specs[id][0])>specs[id][2]:continue
			var proxy=MeshInstance3D.new()
			proxy.name="InteractionContour_"+id
			proxy.mesh=original.mesh
			proxy.material_override=highlight_material
			proxy.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			root.add_child(proxy)
			proxy.global_transform=original.global_transform
			proxy.visible=false
			highlight_proxies[id].append(proxy)

func highlight(id:String,npcs:Dictionary):
	if id==previous_highlight:return
	for key in highlight_proxies:
		for proxy in highlight_proxies[key]:
			proxy.visible=key==id
	for key in npcs:
		var painter=npcs[key].visual.get_node_or_null("Painter")
		if painter:painter.focused=key==id
		for mesh in npcs[key].visual.find_children("*","MeshInstance3D",true,false):
			if mesh.name not in ["PaintedFigure","NearLeg","FarLeg"]:mesh.material_overlay=highlight_material if key==id else null
	previous_highlight=id
