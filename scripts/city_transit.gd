extends RefCounted
## The streetcar is built around the street rail gauge. The lower body, rounded
## cab glazing and roof share the same curved profile.
const City=preload("res://scripts/city_architecture.gd")
const Urban=preload("res://scripts/district_urban.gd")
const X=[-6.34,-6.23,-6.03,-5.74,5.74,6.03,6.23,6.34]
const WIDTH=[.76,.98,1.15,1.245,1.245,1.15,.98,.76]

static func build(k,c:Vector3):
	var root=Node3D.new()
	root.name="AbandonedCityTram"
	root.position=c
	k.root.add_child(root)
	City.hull(k,c+Vector3.UP*1.28,Vector3(12.66,2.24,2.45),"AbandonedTramHull")
	k.box("TramUnderframe",Vector3(0,.48,0),Vector3(12.15,.23,2.05),"old_iron",false,root)
	for bogie in [-3.53,3.53]:
		k.box("CastBogieFrame",Vector3(bogie,.46,0),Vector3(2.26,.31,1.70),"old_iron",false,root)
		for axle in [-.81,.81]:
			var x:float=bogie+axle
			k.pipe(c+Vector3(x,.342,-.83),c+Vector3(x,.342,.83),.084,"old_iron")
			for side in [-1,1]:
				var wheel=k.cyl("SteelRailWheel",Vector3(x,.342,side*.72),.312,.17,"dark",root)
				wheel.rotation.x=PI/2
				k.cyl("TramWheelFlange",Vector3(x,.342,side*.652),.325,.034,"old_iron",root).rotation.x=PI/2
				k.cyl("TramAxleBox",Vector3(x,.342,side*.83),.144,.064,"tram_bare_steel",root).rotation.x=PI/2
				k.box("LeafSpring",Vector3(x,.515,side*.89),Vector3(.41,.071,.13),"old_iron",false,root)
	belt(k,root,"PressedLowerApron",.57,.72,.951,.997,"tram_bare_steel")
	belt(k,root,"PressedEnamelBody",.716,1.30,.997,1.0,"tram_enamel")
	belt(k,root,"OriginalIvoryWaistband",1.298,1.447,1.0,1.0,"tram_ivory")
	belt(k,root,"TramSillRubber",1.444,1.47,1.0,1.0,"dark")
	belt(k,root,"CabRoofCornice",2.225,2.425,.985,.965,"tram_ivory")
	# Continuous turning bands at both ends, with the passenger window openings
	# built separately in the long middle bay.
	belt(k,root,"RoundedCabGlazing",1.465,2.23,.986,.967,"tram_glass",true)
	belt(k,root,"CurvedMetalRainGutter",2.414,2.46,.981,.961,"tram_bare_steel")
	roof(k,root)
	for side in [-1,1]:
		windows(k,root,side)
		end_details(k,root,side)
	for x in [-1.46,1.78]:
		k.box("PantographBearingShoe",Vector3(x,2.70,0),Vector3(.38,.12,.81),"tram_bare_steel",false,root)
		for z in [-.28,.28]:
			k.cyl("RoofPorcelainInsulator",Vector3(x,2.78,z),.085,.16,"tram_ivory",root)
	for z in [-.26,.26]:
		Urban.beam(k,"FoldedCollectorStrut",Vector3(-1.46,2.79,z),Vector3(.36,3.58,z*.66),.043,.043,"tram_bare_steel",root)
		Urban.beam(k,"FoldedCollectorStrut",Vector3(.36,3.58,z*.66),Vector3(1.78,2.80,z),.043,.043,"tram_bare_steel",root)
	Urban.beam(k,"CollectorContactShoe",Vector3(.36,3.60,-.45),Vector3(.36,3.60,.45),.063,.041,"old_iron",root)

static func belt(k,root:Node3D,id:String,low:float,high:float,lower:float,upper:float,finish:String,cab_only:bool=false):
	var st=SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for side in [-1,1]:
		for i in X.size()-1:
			if cab_only and i==3:continue
			var a=Vector3(X[i],low,side*WIDTH[i]*lower)
			var b=Vector3(X[i+1],low,side*WIDTH[i+1]*lower)
			var d=Vector3(X[i],high,side*WIDTH[i]*upper)
			var e=Vector3(X[i+1],high,side*WIDTH[i+1]*upper)
			quad(st,a,b,e,d,Vector3(0,0,side))
	for side in [-1,1]:
		var end_x:float=X[0] if side<0 else X[-1]
		quad(st,Vector3(end_x,low,-WIDTH[0]*lower),Vector3(end_x,low,WIDTH[0]*lower),Vector3(end_x,high,WIDTH[0]*upper),Vector3(end_x,high,-WIDTH[0]*upper),Vector3(side,0,0))
	surface(k,root,id,st,finish)

static func quad(st:SurfaceTool,a:Vector3,b:Vector3,c:Vector3,d:Vector3,outside:Vector3):
	var normal=(c-a).cross(b-a).normalized()
	var points=[a,b,c,a,c,d] if normal.dot(outside)>0 else [a,c,b,a,d,c]
	if normal.dot(outside)<0:normal=-normal
	for v in points:
		st.set_normal(normal)
		st.set_uv(Vector2(v.x*.42+v.z*.58,v.y*.73))
		st.add_vertex(v)

static func surface(k,root:Node3D,id:String,st:SurfaceTool,finish:String):
	var mesh=MeshInstance3D.new()
	mesh.name=id
	mesh.mesh=st.commit()
	mesh.material_override=k.new_veil_material(k.mats[finish]) if finish=="tram_roof" else k.mats[finish]
	root.add_child(mesh)

static func roof_point(index:int,cross:float)->Vector3:
	var crown=.255*cos(cross*PI/2)
	var end_drop=0.058*smoothstep(5.72,6.34,absf(X[index]))
	return Vector3(X[index],2.427+crown-end_drop,WIDTH[index]*cross*.971)

static func roof(k,root:Node3D):
	var metal=SurfaceTool.new()
	metal.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in X.size()-1:
		for j in 20:
			var a=-1.0+.1*j
			var b=a+.1
			quad(metal,roof_point(i,a),roof_point(i+1,a),roof_point(i+1,b),roof_point(i,b),Vector3.UP)
	surface(k,root,"ContinuousCamberedRoof",metal,"tram_roof")
	for x in [-4.57,-2.13,.48,3.38,5.1]:
		k.box("TramRoofHatchFrame",Vector3(x,2.637,-.32),Vector3(.59,.071,.33),"tram_bare_steel",false,root)
		k.box("TramRoofHatchPlate",Vector3(x,2.673,-.32),Vector3(.52,.043,.27),"tram_roof",false,root)
		for z in [-.45,-.19]:k.box("TramHatchEdgeBolt",Vector3(x+.17,2.702,z),Vector3(.042,.025,.042),"old_iron",false,root)

static func windows(k,root:Node3D,side:int):
	var z=side*1.245
	for j in 9:
		var x=(j-4)*1.27
		k.box("WindowPressedMullion",Vector3(x-.635,1.84,z),Vector3(.11,.82,.075),"tram_ivory",false,root)
		if side>0 and j in [1,5,8]:
			k.box("TramDarkDoorPocket",Vector3(x,1.34,z+.018),Vector3(1.15,1.75,.055),"dark",false,root)
			for leaf in [-1,1]:
				var lx=x+leaf*.284
				k.box("FoldingDoorLeaf",Vector3(lx,1.36,z+.061),Vector3(.547,1.69,.034),"tram_enamel",false,root)
				k.box("FoldingDoorGlass",Vector3(lx,1.82,z+.085),Vector3(.381,.60,.016),"tram_glass",false,root)
				k.box("DoorPull",Vector3(lx-leaf*.126,1.35,z+.101),Vector3(.045,.22,.035),"tram_bare_steel",false,root)
			k.box("PassengerStep",Vector3(x,.56,z+.036),Vector3(1.17,.085,.27),"tram_bare_steel",false,root)
		else:
			k.box("GlazingRubberSeal",Vector3(x,1.846,z-side*.029),Vector3(1.182,.743,.041),"dark",false,root)
			k.box("RecessedTramGlass",Vector3(x,1.844,z-side*.006),Vector3(1.096,.67,.018),"tram_glass",false,root)
			if posmod(j+side,3)!=0:
				k.box("HopperWindowTransom",Vector3(x,2.01,z+side*.018),Vector3(1.10,.036,.024),"tram_bare_steel",false,root)
	for x in [-5.69,5.69]:
		k.box("CabPillar",Vector3(x,1.833,z),Vector3(.11,.86,.08),"tram_ivory",false,root)
	for x in [-4.6,-.72,3.76]:
		k.box("BoltedInspectionCover",Vector3(x,.935,z+side*.018),Vector3(.75,.34,.024),"tram_enamel",false,root)
		for dx in [-.30,.30]:
			k.box("PressedInspectionBolt",Vector3(x+dx,.91,z+side*.036),Vector3(.043,.054,.021),"tram_bare_steel",false,root)

static func end_details(k,root:Node3D,side:int):
	var x=side*6.34
	for z in [-.69,0,.69]:
		k.box("RoundedWindshieldPost",Vector3(x+side*.012,1.842,z),Vector3(.034,.77,.067),"tram_ivory",false,root)
	k.box("FrontWindshieldRubberRail",Vector3(x+side*.021,1.52,0),Vector3(.041,.045,1.53),"dark",false,root)
	k.box("RouteNumberEnamel",Vector3(x+side*.026,2.325,0),Vector3(.038,.188,.39),"tram_enamel",false,root)
	var number=k.label("17",root.position+Vector3(x+side*.051,2.325,0),18,Color("d9d2b5"))
	number.rotation.y=side*PI/2
	for z in [-.42,.42]:
		k.cyl("PressedHeadlampRing",Vector3(x+side*.036,1.108,z),.131,.075,"tram_bare_steel",root).rotation.z=PI/2
		k.cyl("CloudedHeadlampLens",Vector3(x+side*.080,1.108,z),.093,.024,"tram_ivory",root).rotation.z=PI/2
	k.box("CabBumper",Vector3(x+side*.074,.652,0),Vector3(.182,.116,1.56),"old_iron",false,root)
	k.box("CouplerBar",Vector3(x+side*.17,.492,0),Vector3(.252,.102,.16),"old_iron",false,root)
