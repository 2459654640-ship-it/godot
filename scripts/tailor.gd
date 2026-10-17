extends RefCounted
## Sculpted cross-sections, not stacked cubes. Physics/animation live in actor.gd.
static func form(kit,parent:Node3D,name:String,profiles:Array,material:String,segments:int=16) -> MeshInstance3D:
	var st=SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for row in profiles.size()-1:
		for col in segments:
			var points:Array[Vector3]=[]
			var normals:Array[Vector3]=[]
			var uvs:Array[Vector2]=[]
			for corner in [[row,col],[row+1,col],[row+1,col+1],[row,col+1]]:
				var profile:Vector3=profiles[corner[0]]
				var angle=TAU*corner[1]/segments
				points.append(Vector3(sin(angle)*profile.y,profile.x,cos(angle)*profile.z))
				normals.append(Vector3(sin(angle),0.10,cos(angle)).normalized())
				uvs.append(Vector2(float(corner[1])/segments,float(corner[0])/(profiles.size()-1)))
			for index in [0,1,2,0,2,3]:
				st.set_normal(normals[index])
				st.set_uv(uvs[index])
				st.add_vertex(points[index])
	st.generate_tangents()
	var mesh=MeshInstance3D.new()
	mesh.name=name
	mesh.mesh=st.commit()
	mesh.material_override=kit.mats[material]
	parent.add_child(mesh)
	return mesh

static func dress(actor,kit,player:bool,coat:String,hat:bool):
	var v:Node3D=actor.visual
	var fabric_id="fabric_"+coat
	if not kit.mats.has(fabric_id):
		var fabric:StandardMaterial3D=kit.mats.cloth.duplicate()
		fabric.albedo_color=Color({"green":"87916b","wood":"96816b","blue":"849a9e","cream":"c5b796","cloth":"a09a7d"}.get(coat,"93937c"))
		fabric.uv1_triplanar=true
		fabric.uv1_world_triplanar=false
		fabric.uv1_scale=Vector3.ONE*1.7
		kit.mats[fabric_id]=fabric
	coat=fabric_id
	form(kit,v,"TailoredGreatcoat",[Vector3(.64,.24,.15),Vector3(.68,.245,.15),Vector3(.85,.22,.155),Vector3(1.0,.185,.13),Vector3(1.18,.22,.14),Vector3(1.33,.235,.13),Vector3(1.39,.17,.105)],coat)
	# A recessed double-breasted placket, collar and lapels give readable silhouette.
	kit.box("Placket",Vector3(0,1.12,-.145),Vector3(.045,.42,.022),"boot",false,v)
	for side in [-1,1]:
		var lapel=kit.ellipsoid("FoldedLapel",Vector3(side*.095,1.31,-.13),Vector3(.075,.16,.035),coat,v)
		lapel.rotation.z=side*.30
		kit.box("WaistPocket",Vector3(side*.15,.90,-.15),Vector3(.11,.10,.025),coat,false,v)
		kit.box("PocketStitch",Vector3(side*.15,.94,-.168),Vector3(.10,.012,.012),"cloth",false,v)
		for y in [1.05,1.16,1.26]:
			kit.ellipsoid("BrassButton",Vector3(side*.055,y,-.16),Vector3(.012,.012,.009),"brass",v)
	form(kit,v,"LeatherBelt",[Vector3(.98,.20,.144),Vector3(1.035,.20,.144)],"boot")
	kit.box("BeltBuckle",Vector3(.025,1.005,-.153),Vector3(.06,.05,.018),"brass",false,v)
	kit.ellipsoid("KnittedScarf",Vector3(0,1.40,0),Vector3(.14,.065,.145),"cloth" if not player else "cream",v)
	form(kit,v,"Neck",[Vector3(1.40,.068,.075),Vector3(1.53,.075,.078)],"skin")
	# Chin, cheekbones, temples and cranium are separate cross-sections of one head.
	form(kit,v,"Face",[Vector3(1.465,.045,.055),Vector3(1.50,.077,.084),Vector3(1.55,.102,.096),Vector3(1.61,.111,.104),Vector3(1.67,.108,.099),Vector3(1.72,.083,.077),Vector3(1.745,.022,.025)],"skin",20)
	kit.ellipsoid("HairCrown",Vector3(0,1.705,.018),Vector3(.117,.059,.105),"hair",v)
	kit.ellipsoid("HairNape",Vector3(0,1.635,.085),Vector3(.093,.075,.04),"hair",v)
	kit.ellipsoid("NoseBridge",Vector3(0,1.598,-.105),Vector3(.022,.045,.029),"skin",v)
	kit.ellipsoid("NoseTip",Vector3(0,1.575,-.125),Vector3(.025,.018,.025),"skin",v)
	for side in [-1,1]:
		kit.ellipsoid("Ear",Vector3(side*.11,1.59,.001),Vector3(.018,.037,.027),"skin",v)
		kit.ellipsoid("EyeSocket",Vector3(side*.047,1.62,-.095),Vector3(.030,.012,.012),"hair",v)
		kit.ellipsoid("EyeGlint",Vector3(side*.047,1.62,-.107),Vector3(.008,.006,.003),"paper",v)
		var brow=kit.ellipsoid("Brow",Vector3(side*.045,1.642,-.101),Vector3(.033,.008,.009),"hair",v)
		brow.rotation.z=side*.10
	kit.ellipsoid("Mouth",Vector3(0,1.53,-.088),Vector3(.030,.006,.009),"hair",v)
	if hat:
		kit.ellipsoid("UshankaCrown",Vector3(0,1.739,.015),Vector3(.139,.08,.128),"boot",v)
		for side in [-1,1]:kit.ellipsoid("FurFlap",Vector3(side*.115,1.658,.02),Vector3(.038,.075,.10),"boot",v)
		kit.ellipsoid("HatBadge",Vector3(0,1.747,-.12),Vector3(.018,.018,.009),"brass",v)
	for side in [-1,1]:
		var leg=Node3D.new()
		v.add_child(leg)
		leg.position=Vector3(side*.105,.77,0)
		form(kit,leg,"Trousers",[Vector3(-.50,.071,.08),Vector3(-.36,.080,.09),Vector3(-.21,.088,.09),Vector3(-.02,.105,.11),Vector3(.09,.105,.11)],"cloth")
		form(kit,leg,"BootShaft",[Vector3(-.68,.078,.087),Vector3(-.60,.073,.085),Vector3(-.39,.080,.09)],"boot")
		kit.ellipsoid("BootToe",Vector3(0,-.67,-.055),Vector3(.087,.080,.153),"boot",leg)
		kit.ellipsoid("LeatherSole",Vector3(0,-.738,-.045),Vector3(.092,.025,.16),"dark",leg)
		var arm=Node3D.new()
		v.add_child(arm)
		arm.position=Vector3(side*.244,1.30,0)
		kit.ellipsoid("Shoulder",Vector3(0,-.02,0),Vector3(.098,.105,.11),coat,arm)
		form(kit,arm,"Sleeve",[Vector3(-.43,.057,.068),Vector3(-.35,.065,.075),Vector3(-.22,.075,.08),Vector3(-.08,.085,.092),Vector3(.01,.08,.09)],coat)
		form(kit,arm,"Cuff",[Vector3(-.435,.060,.073),Vector3(-.395,.065,.075)],"boot")
		kit.ellipsoid("Glove",Vector3(0,-.49,-.018),Vector3(.058,.080,.065),"boot",arm)
		if side<0:
			actor.left_leg=leg
			actor.left_arm=arm
		else:
			actor.right_leg=leg
			actor.right_arm=arm
	if player:
		kit.ellipsoid("CanvasPack",Vector3(0,1.16,.205),Vector3(.185,.21,.11),"cloth",v)
		kit.cyl("Bedroll",Vector3(0,1.40,.225),.07,.36,"wood",v).rotation.z=PI/2
		for side in [-1,1]:
			var strap=kit.box("PackStrap",Vector3(side*.15,1.25,-.15),Vector3(.03,.31,.02),"boot",false,v)
			strap.rotation.z=side*.10
	# A restrained ink contour with real lit, woven surfaces gives a 3D/2D finish.
	var copies:Dictionary={}
	for part in v.find_children("*","MeshInstance3D",true,false):
		part.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if part.name.begins_with("Eye") or part.name.begins_with("Brass"):continue
		var material:Material=part.material_override
		if not material:continue
		var key=material.get_instance_id()
		if not copies.has(key):
			var copy=material.duplicate()
			var ink=ShaderMaterial.new()
			ink.shader=load("res://assets/visual/character_ink.gdshader")
			copy.next_pass=ink
			copies[key]=copy
		part.material_override=copies[key]
	# Four low-cost silhouette casters replace dozens of buttons/cloth triangles
	# in each point-light cubemap. These never add collision or visible geometry.
	shadow_caster(v,Vector3(0,1.04,0),.17,.80)
	shadow_caster(v,Vector3(0,1.61,0),.09,.23)
	shadow_caster(actor.left_leg,Vector3(0,-.36,-.01),.085,.72)
	shadow_caster(actor.right_leg,Vector3(0,-.36,-.01),.085,.72)

static func shadow_caster(parent:Node3D,p:Vector3,radius:float,height:float):
	var instance=MeshInstance3D.new()
	instance.name="SilhouetteShadow"
	var capsule=CapsuleMesh.new()
	capsule.radius=radius
	capsule.height=height
	capsule.radial_segments=8
	capsule.rings=3
	instance.mesh=capsule
	instance.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
	parent.add_child(instance)
	instance.position=p
