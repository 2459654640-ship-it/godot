extends RefCounted
## Exterior sets sit on service frontage with explicit solid footprints.
const Ground=preload("res://scripts/city_ground.gd")
const City=preload("res://scripts/city_architecture.gd")
const Urban=preload("res://scripts/district_urban.gd")

static func materials(k):
	for spec in [
		["works_brick","waterplant_brick_v37","d5c2b4",.54],
		["frosted_steel","star_enamel","83918c",.49],
		["washed_concrete","city29_plaster","a8b0ab",.54],
		["rail_ballast","city30_rubble","9b9b90",.62]
	]:
		var texture="res://assets/visual/"+spec[1]+".png"
		if not ResourceLoader.exists(texture):texture="res://assets/visual/city29_brick.png"
		var m:StandardMaterial3D=k.mats.district_brick.duplicate()
		m.albedo_texture=load(texture)
		m.albedo_color=Color(spec[2])
		m.uv1_scale=Vector3.ONE*spec[3]
		m.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
		m.roughness=.93 if spec[0]!="frosted_steel" else .66
		m.metallic=.14 if spec[0]=="frosted_steel" else 0
		k.mats[spec[0]]=m

static func mainline(k,layout):
	var x:float=layout.railway.x
	var st=SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for n in range(-100,100):
		if n>=4 and n<12:continue
		var a=track_section(x,float(n))
		var b=track_section(x,float(n+1))
		for i in a.size()-1:
			for v in [a[i],a[i+1],b[i+1],a[i],b[i+1],b[i]]:
				st.set_uv(Vector2(v.x,v.z)*.5)
				st.add_vertex(v)
	st.generate_normals()
	var ballast=MeshInstance3D.new()
	ballast.name="DistrictRaisedBallast"
	ballast.mesh=st.commit()
	ballast.material_override=k.mats.rail_ballast
	k.root.add_child(ballast)
	ballast.create_trimesh_collision()
	for offset in [-.762,.762]:
		for z in range(-100,100,2):
			var a=Vector3(x+offset,rail_top(z),z)
			var b=Vector3(x+offset,rail_top(z+2),z+2)
			Urban.beam(k,"MainlineSteelRail",a,b,.064,.112,"old_iron",k.root)
	for z in range(-99,100):
		if absf(z-8)<4.6:continue
		var height=track_height(z)
		k.box("MainlineOiledSleeper",Vector3(x,height+.062,z),Vector3(2.55,.10,.25),"wood")
		if absf(z-8)>5 and z%3==0:
			for dx in [-.76,.76]:
				k.box("TrackFastener",Vector3(x+dx,height+.120,z),Vector3(.19,.037,.20),"dark")
	for z in [-88,-62,-32,28,56,86]:
		var x2=x-2.46
		k.box("RailKilometreMarker",Vector3(x2,.49,z),Vector3(.16,.98,.2),"washed_concrete",true)
		k.box("KilometreMarkerEnamel",Vector3(x2,.91,z+.108),Vector3(.26,.28,.036),"cream")

static func rail_top(z:float)->float:
	return track_height(z)+lerpf(.03,.16,smoothstep(4.0,5.6,absf(z-8.0)))

static func track_height(z:float)->float:
	return .48*smoothstep(4.6,13.0,absf(z-8.0))

static func track_section(x:float,z:float)->PackedVector3Array:
	var height=track_height(z)
	return PackedVector3Array([
		Vector3(x-2.30,.004,z),Vector3(x-1.38,height+.020,z),
		Vector3(x+1.38,height+.020,z),Vector3(x+2.30,.004,z)
	])

static func complete_factory(k):
	# A narrow valve tower joins the high pump hall and lower boiler house.
	# Access along the loading face stays at ground level, below the tower.
	var c=Vector3(-75.2,0,-47.8)
	var height=11.55
	var root=Node3D.new();root.name="WaterworksValveTower";root.position=c;k.root.add_child(root)
	k.box("ValveTowerCore",Vector3(0,5.78,0),Vector3(4.7,11.56,9.2),"works_brick",false,root)
	k.box("ValveTowerStonePlinth",Vector3(0,.55,0),Vector3(5.0,1.10,9.5),"washed_concrete",false,root)
	for y in [3.4,8.35,10.86]:
		k.box("ValveTowerStringCourse",Vector3(0,y,0),Vector3(4.86,.14,9.38),"washed_concrete",false,root)
	for z in [-4.66,4.66]:
		for x in [-1.05,1.05]:
			k.box("ValveTowerWindowSill",Vector3(x,8.73,z),Vector3(1.37,.16,.32),"washed_concrete",false,root)
			k.box("ValveTowerDarkRecess",Vector3(x,9.45,z),Vector3(1.17,1.35,.064),"dark",false,root)
			for dx in [-.60,.01,.60]:
				k.box("ValveTowerMullion",Vector3(x+dx,9.44,z+signf(z)*.052),Vector3(.05,1.43,.08),"frosted_steel",false,root)
	k.box("TowerStoneCopings",Vector3(0,height+.15,0),Vector3(5.1,.30,9.63),"washed_concrete",false,root)
	k.box("ValveTowerRoof",Vector3(0,height+.33,0),Vector3(4.91,.10,9.49),"frosted_steel",false,root)
	k.box("ValveTowerLeewardSnow",Vector3(.3,height+.40,.12),Vector3(3.9,.065,8.9),"district_roof_snow",false,root)
	City.hull(k,c+Vector3.UP*1.7,Vector3(4.8,3.4,9.3),"ValveTowerFootprint")
	# Ladder and high gantry join the actual pump hall wall. Steel remains
	# exposed at hand contact, with snow stored in corners of the grating.
	for dx in [-.31,.31]:
		k.pipe(c+Vector3(dx,.58,4.8),c+Vector3(dx,11.42,4.8),.027,"frosted_steel")
	for i in 29:
		k.pipe(c+Vector3(-.31,.63+i*.36,4.81),c+Vector3(.31,.63+i*.36,4.81),.02,"old_iron")
	k.box("TowerInspectionCatwalk",c+Vector3(2.31,9.70,2.64),Vector3(2.64,.17,3.12),"frosted_steel")
	for z in [1.16,4.11]:
		Urban.beam(k,"CatwalkDiagonalSupport",c+Vector3(2.29,9.02,z),c+Vector3(3.37,9.63,z),.13,.13,"old_iron",k.root)
		k.pipe(c+Vector3(1.0,10.65,z),c+Vector3(3.64,10.65,z),.035,"old_iron")
		for x in [1.13,2.35,3.52]:k.pipe(c+Vector3(x,9.79,z),c+Vector3(x,10.65,z),.026,"frosted_steel")
	for z in [-50.2,-47.4,-44.7]:
		k.box("BoilerConnectionSleeve",Vector3(-77.76,3.12,z),Vector3(1.2,.65,1.28),"works_brick")
		k.pipe(Vector3(-78.8,3.12,z),Vector3(-75.3,3.12,z),.27,"old_iron")
	# Recessed scale pan and boundary bollards. Pedestrians use the flush side.
	for x in [-65.8,-53.9]:
		k.box("DieselScaleKerb",Vector3(x,.105,-28.4),Vector3(.36,.21,6.62),"washed_concrete",true)
		for z in [-30.95,-25.75]:
			k.cyl("YardCastBollard",Vector3(x,.54,z),.115,1.08,"frosted_steel")
			k.cyl("BollardFrostedCap",Vector3(x,1.10,z),.121,.07,"district_roof_snow")
	for x in [-64.4,-55.2]:
		k.box("ScalePanPerimeter",Vector3(x,.034,-28.3),Vector3(1.18,.038,5.65),"frosted_steel")
		for z in range(8):
			k.box("ScalePanRaisedGrating",Vector3(x,.061,-30.57+z*.64),Vector3(1.12,.017,.034),"old_iron")
	k.box("GateIdentificationCastPlate",Vector3(-58.0,1.59,-22.657),Vector3(.42,.32,.043),"frosted_steel")
	k.label("В-2",Vector3(-58.0,1.61,-22.626),13,Color("e1d6b9"))

static func freight_yard(k):
	var c=Vector3(82.7,0,45.7)
	Ground.apron(k,Vector2(c.x,c.z),Vector2(14.4,9.5))
	for side in [-1,1]:
		var x=c.x+side*6.2
		k.box("FreightCraneConcreteFooting",Vector3(x,.19,c.z),Vector3(1.22,.38,1.6),"washed_concrete",true)
		for z in [-.50,.50]:
			var a=Vector3(x,.37,c.z+z)
			var b=Vector3(x-side*.56,4.85,c.z+z*.38)
			Urban.beam(k,"CraneAFrameLeg",a,b,.245,.33,"frosted_steel",k.root)
			k.cyl("CraneFoundationBolt",a+Vector3(0,.07,.37),.066,.13,"old_iron")
		City.hull(k,Vector3(x,.95,c.z),Vector3(1.1,1.9,1.37),"GantryGroundFoot")
		k.box("CraneGusset",Vector3(x-side*.32,2.75,c.z),Vector3(.22,.24,1.05),"old_iron")
	k.box("FreightGantryGirder",c+Vector3.UP*4.87,Vector3(13.2,.51,.41),"frosted_steel")
	for y in [4.57,5.17]:k.box("FreightGantryFlange",c+Vector3.UP*y,Vector3(13.24,.105,.64),"old_iron")
	for x in [-5,-2.5,0,2.5,5]:k.box("GantryStiffener",c+Vector3(x,4.87,.24),Vector3(.12,.46,.105),"old_iron")
	k.box("CraneHoistTrolley",c+Vector3(1.81,4.51,0),Vector3(.90,.24,.82),"rust")
	k.pipe(c+Vector3(1.81,4.42,0),c+Vector3(1.81,3.31,0),.025,"metal")
	k.box("HoistBlock",c+Vector3(1.81,3.27,0),Vector3(.25,.14,.22),"old_iron")
	for x in [-2.7,-.73,1.24]:
		k.crate(c+Vector3(x,0,1.90),Vector3(1.63,.96,1.12))
		k.box("ShippingLotStripe",c+Vector3(x,.64,2.478),Vector3(.78,.14,.033),"cream")
	# Cast axle stands and spill-stained pads line the rear edge of the bay.
	for x in [-4.3,4.3]:
		k.box("FreightOilStain",c+Vector3(x,.036,3.34),Vector3(1.5,.013,1.13),"rail_ballast")
		k.cyl("LoadingYardDrum",c+Vector3(x,.44,3.34),.31,.86,"frosted_steel")
		for y in [.16,.69]:k.cyl("DrumStampedRidge",c+Vector3(x,y,3.34),.321,.045,"old_iron")

static func housing_damage(k,p:Vector3,size:Vector2,room:Rect2):
	# One burst upper corner exposes joists, party walls and the underside of
	# a second floor. The inhabitable ground floor retains its front access.
	var up=Node3D.new();up.name="SplitWorkersHousingUpper";up.position=p;k.root.add_child(up)
	var half=size.x*.5;var depth=size.y*.5
	var outline=PackedVector2Array([
		Vector2(-half+.14,-depth+.17),Vector2(half-2.82,-depth+.17),
		Vector2(half-2.91,-3.44),Vector2(half-4.0,-.47),
		Vector2(half-3.07,.82),Vector2(half-3.55,3.12),
		Vector2(half-4.20,2.42),Vector2(half-5.85,4.94),
		Vector2(half-7.28,3.96),Vector2(half-8.65,5.78),
		Vector2(-half+.14,6.38)
	])
	cracked_concrete(k,up,outline,3.72,.25)
	k.box("ExposedHousePartyWall",Vector3(-half+.04,4.81,-1.14),Vector3(.31,2.15,size.y-2.28),"works_brick",false,up)
	k.box("RearMasonryBelowSash",Vector3(-1.55,3.96,-depth+.10),Vector3(size.x-3.10,.53,.27),"works_brick",false,up)
	for x in [-half+.71,-3.51,-1.65,.21,2.21]:
		var rise=1.35+.26*sin(x*4.0)
		k.box("HouseBrokenWindowJamb",Vector3(x,4.18+rise/2,-depth+.1),Vector3(.57,rise,.30),"works_brick",false,up)
	for i in range(3,outline.size()-1):
		var a=outline[i];var b=outline[i+1];var edge=(b-a).normalized()
		var outward=Vector2(edge.y,-edge.x)*-.45
		for t in [.26,.68]:
			var p2=a.lerp(b,t)
			var from=Vector3(p2.x,3.64,p2.y)
			var end=from+Vector3(outward.x,-.05,outward.y)*(1+.2*sin(i*2.4+t))
			Urban.beam(k,"ExposedSlabBar",from,end,.026,.022,"rust",up)
		var chipped=a.lerp(b,.62)
		var chip=k.box("SpalledRoofConcrete",Vector3(chipped.x,3.80,chipped.y-.19),Vector3(.22,.14,.41),"washed_concrete",false,up)
		chip.rotation=Vector3(.25*sin(i),i*.8,.21)
	for mesh in up.find_children("*","MeshInstance3D",true,false):mesh.set_meta("interior_rect",room)


static func cracked_concrete(k,root:Node3D,outline:PackedVector2Array,top:float,thickness:float):
	var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var triangles=Geometry2D.triangulate_polygon(outline)
	for index in range(0,triangles.size(),3):
		var a=outline[triangles[index]];var b=outline[triangles[index+1]];var c=outline[triangles[index+2]]
		if (b-a).cross(c-a)<0:
			var swap=b
			b=c
			c=swap
		st.set_normal(Vector3.UP)
		for p in [a,b,c]:
			st.set_uv(p*.65)
			st.add_vertex(Vector3(p.x,top,p.y))
	for i in outline.size():
		var a=outline[i];var b=outline[(i+1)%outline.size()]
		var edge=(b-a).normalized()
		st.set_normal(Vector3(edge.y,0,-edge.x))
		var left=Vector3(a.x,top,a.y);var right=Vector3(b.x,top,b.y)
		for v in [right,left,left-Vector3.UP*thickness,right,left-Vector3.UP*thickness,right-Vector3.UP*thickness]:
			st.set_uv(Vector2(v.x*.71+v.z*.48,v.y))
			st.add_vertex(v)
	var slab=MeshInstance3D.new();slab.name="FragmentedApartmentSlab"
	slab.mesh=st.commit();slab.material_override=k.mats.washed_concrete
	root.add_child(slab)
