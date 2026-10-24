extends RefCounted
## Street-scale architecture. Circulation is authored in metres, before dressing.
## Existing quest approaches and the freight-rail reservation stay unobstructed.
const BLOCKS=[
	{"id":"west_tenement","at":Vector3(-52,0,40),"size":Vector2(9,12),"floors":2,"seed":31},
	{"id":"tram_workers_house","at":Vector3(-74,0,27),"size":Vector2(7,13),"floors":2,"seed":32},
	{"id":"courtyard_laundry","at":Vector3(-38,0,44),"size":Vector2(17,7),"floors":1,"seed":33},
	{"id":"workers_corner","at":Vector3(-29,0,24),"size":Vector2(9,12),"floors":2,"seed":34},
	{"id":"industrial_annex","at":Vector3(-45,0,-34),"size":Vector2(5,12),"floors":1,"seed":35}
]

static func beam(k,id:String,a:Vector3,b:Vector3,width:float,depth:float,material:String,parent:Node3D):
	var mesh=k.box(id,(a+b)/2,Vector3(width,a.distance_to(b),depth),material,false,parent)
	mesh.quaternion=Quaternion(Vector3.UP,(b-a).normalized())
	return mesh

static func roof(k,root:Node3D,size:Vector2,height:float,kind:String,seed:int):
	if kind=="depot" or kind=="pump":
		# Riveted barrel roof: every segment has thickness, longitudinal seams and
		# a snow load above its sheet. The end gables close the building volume.
		var rise=1.25 if kind=="depot" else .85
		for n in 14:
			var x0=-size.x/2+size.x*n/14.0;var x1=-size.x/2+size.x*(n+1)/14.0
			var y0=height+rise*sin(PI*n/14.0);var y1=height+rise*sin(PI*(n+1)/14.0)
			var slope=atan2(y1-y0,x1-x0);var span=Vector2(x1-x0,y1-y0).length()
			var sheet=k.box("VaultedRoofSheet",Vector3((x0+x1)/2,(y0+y1)/2,0),Vector3(span+.025,.10,size.y+.30),"corrugated",false,root);sheet.rotation.z=slope
			var snow=k.box("VaultedRoofSnow",sheet.position+Vector3(0,.075,0),Vector3(span+.01,.045,size.y+.20),"district_roof_snow",false,root);snow.rotation.z=slope
			for z in [-size.y/2,size.y/2]:
				var fill=(y0+y1)/2-height
				if fill>.05:k.box("VaultEndGable",Vector3((x0+x1)/2,height+fill/2,z),Vector3(x1-x0+.01,fill,.20),"district_brick",false,root)
		for z in [-size.y*.48,0,size.y*.48]:
			for n in 14:
				var a=Vector3(-size.x/2+size.x*n/14.0,height+rise*sin(PI*n/14.0)+.11,z)
				var b=Vector3(-size.x/2+size.x*(n+1)/14.0,height+rise*sin(PI*(n+1)/14.0)+.11,z)
				beam(k,"RoofArchSeam",a,b,.055,.06,"old_iron",root)
	elif kind=="waterworks":
		# Three north-light sawtooth bays, a recognisable industrial silhouette.
		var pitch=size.y/3
		for n in 3:
			var z=-size.y/2+n*pitch
			var slope=atan2(1.15,pitch-.25)
			var sheet=k.box("SawtoothRoofSlope",Vector3(0,height+.60,z+pitch/2),Vector3(size.x+.35,.12,sqrt(pow(pitch-.25,2)+1.15*1.15)),"corrugated",false,root);sheet.rotation.x=-slope
			var snow=k.box("SawtoothRoofSnow",sheet.position+Vector3.UP*.09,Vector3(size.x+.2,.045,sheet.mesh.size.z-.04),"district_roof_snow",false,root);snow.rotation.x=-slope
			k.box("ClerestoryGlass",Vector3(0,height+.62,z+pitch-.12),Vector3(size.x,1.10,.06),"exterior_glass",false,root)
			for x in range(-int(size.x/2),int(size.x/2)+1,2):k.box("ClerestoryMullion",Vector3(x,height+.62,z+pitch-.07),Vector3(.065,1.15,.08),"old_iron",false,root)
			# Triangular end cheeks use narrow masonry slices, no open roof sides.
			for i in 12:
				var h=1.15*(i+.5)/12
				for x in [-size.x/2,size.x/2]:k.box("SawtoothGable",Vector3(x,height+h/2,z+pitch*(i+.5)/12),Vector3(.20,h,pitch/12+.01),"district_brick",false,root)
	else:
		# Residential roofs retain a damaged corner, with framed skylights and
		# parapet coping rather than identical flat lids on every facility.
		for n in 3:
			var z=-size.y/2+size.y/3*(n+.5);var span=size.x*(.72 if n==seed%3 else .98)
			k.box("PartialRoof",Vector3((size.x-span)/2,height+.05,z),Vector3(span,.14,size.y/3-.06),"corrugated",false,root)
			k.box("RoofSnow",Vector3((size.x-span)/2,height+.15,z),Vector3(span-.15,.06,size.y/3-.19),"district_roof_snow",false,root)
			k.box("RoofJoist",Vector3(0,height-.05,z),Vector3(size.x,.16,.12),"old_iron",false,root)
		for z in [-size.y/2,size.y/2]:
			k.box("RoofParapet",Vector3(0,height+.22,z),Vector3(size.x,.34,.25),"district_concrete",false,root)
			k.box("ParapetCoping",Vector3(0,height+.42,z),Vector3(size.x+.18,.09,.42),"district_concrete",false,root)
		for x in [-size.x/2,size.x/2]:k.box("RoofParapet",Vector3(x,height+.22,0),Vector3(.25,.34,size.y),"district_concrete",false,root)
		k.box("RoofAccessLantern",Vector3(size.x*.20,height+.44,-size.y*.2),Vector3(1.5,.6,1.2),"exterior_glass",false,root)
		k.box("RoofAccessCap",Vector3(size.x*.20,height+.78,-size.y*.2),Vector3(1.7,.12,1.4),"old_iron",false,root)

static func facade(k,root:Node3D,size:Vector2,floors:int,kind:String):
	var height=floors*2.8
	# The central door is approached on level ground. The canopy sits above it.
	var bays=maxi(2,floori(size.x/2.1));var door_x=-size.x/2+(size.x/bays)*(floori(bays/2.0)+.5)
	var z=size.y/2
	k.box("EntranceCanopy",Vector3(door_x,2.32,z+.65),Vector3(2.1,.12,1.4),"old_iron",false,root)
	k.box("EntranceCanopySnow",Vector3(door_x,2.41,z+.65),Vector3(1.95,.05,1.25),"district_roof_snow",false,root)
	for x in [door_x-.88,door_x+.88]:beam(k,"CanopyBracket",Vector3(x,1.98,z+.18),Vector3(x,2.25,z+1.15),.045,.045,"old_iron",root)
	if kind in ["waterworks","depot","pump","relay"]:
		for x in [-size.x/2+.25,size.x/2-.25]:
			k.box("IndustrialButtress",Vector3(x,height/2,z+.13),Vector3(.45,height,.45),"district_brick",false,root)
		for y in [height-.40,height-.15]:k.box("IndustrialCornice",Vector3(0,y,z+.12),Vector3(size.x+.25,.12,.46),"district_concrete",false,root)
		for x in [-size.x*.29,size.x*.29]:
			k.box("IndustrialVentRecess",Vector3(x,2.48,z+.18),Vector3(1.1,.36,.08),"dark",false,root)
			for y in [2.36,2.45,2.54,2.63]:k.box("IndustrialVentLouver",Vector3(x,y,z+.25),Vector3(1.08,.035,.08),"old_iron",false,root)
	else:
		for x in [-size.x/2+.22,size.x/2-.22]:
			for y in range(int(height/.35)):
				k.box("StoneCornerQuoin",Vector3(x,.20+y*.35,z+.13),Vector3(.55,.28,.32),"district_concrete",false,root)
		for level in range(1,floors):
			# Balconies are deliberately on the rear facade, away from entrances.
			for x in [-size.x*.25,size.x*.25]:
				var y=level*2.8+.18
				k.box("BalconySlab",Vector3(x,y,-size.y/2-.50),Vector3(1.75,.12,1.1),"district_concrete",false,root)
				k.box("BalconyRail",Vector3(x,y+1,-size.y/2-.98),Vector3(1.70,.045,.04),"old_iron",false,root)
				for dx in [-.8,-.4,0,.4,.8]:k.box("BalconyBaluster",Vector3(x+dx,y+.5,-size.y/2-.98),Vector3(.035,1,.035),"old_iron",false,root)
				for dx in [-.83,.83]:k.box("BalconySideRail",Vector3(x+dx,y+1,-size.y/2-.50),Vector3(.04,.045,1),"old_iron",false,root)
		# Leave a full-width opening at the real door; no plinth spans its threshold.
		for side in [-1,1]:
			var start=-size.x/2 if side<0 else door_x+.65
			var end=door_x-.65 if side<0 else size.x/2
			if end>start:k.box("HousePlinthSide",Vector3((start+end)/2,.30,z+.06),Vector3(end-start,.55,.12),"district_concrete",false,root)

static func street_block(k):
	# A continuous, level pedestrian court connects the station exit, map board
	# and repair workshop. Slab joints are at most 4cm, with no hidden barriers.
	for z in range(26,42,2):
		for x in [-62.3,-60.3,-58.3]:k.box("StationForecourtSlab",Vector3(x,.026,z),Vector3(1.94,.045,1.94),"district_concrete")
	for x in range(-58,-43,2):k.box("WorkshopApproachSlab",Vector3(x,.026,26),Vector3(1.94,.045,2.0),"district_concrete")
	# A courtyard lies behind the two street fronts. Its central through-route
	# remains over 3m wide, and the north-east service alley remains open.
	for x in range(-45,-33,2):
		for z in [33,35,37]:k.box("CourtyardPaving",Vector3(x,.025,z),Vector3(1.95,.04,1.95),"district_concrete")
	for p in [Vector3(-43,0,38.8),Vector3(-38,0,38.8)]:k.bench(p,2.8,true,PI)
	for x in [-46.5,-33.5]:
		k.box("CourtyardHeatingPlinth",Vector3(x,.18,35),Vector3(.65,.36,.65),"district_concrete",true)
		k.pipe(Vector3(x,.36,35),Vector3(x,1.7,35),.075,"rust")
	# A retired play frame belongs to the residential yard, away from battle
	# spawns. Missing seats and a broken chain tell its age without a popup.
	for x in [-44,-40]:
		beam(k,"AbandonedSwingLeg",Vector3(x,0,30),Vector3(x,2.3,31),.065,.065,"old_iron",k.root)
		beam(k,"AbandonedSwingLeg",Vector3(x,0,32),Vector3(x,2.3,31),.065,.065,"old_iron",k.root)
		k.box("SwingFootprint",Vector3(x,.5,31),Vector3(.15,1,2.2),"dark",true).visible=false
	k.pipe(Vector3(-44,2.3,31),Vector3(-40,2.3,31),.065,"old_iron")
	for x in [-43.2,-42.6]:k.pipe(Vector3(x,2.3,31),Vector3(x,.65,31),.012,"rust")
	k.box("SwingSeat",Vector3(-42.9,.63,31),Vector3(.75,.08,.32),"wood")
	k.pipe(Vector3(-41.4,2.3,31),Vector3(-41.15,1.25,31),.012,"rust")
	# Raised planting beds frame the yard, never the walking line.
	for x in [-46.5,-32.2]:
		k.box("EmptyCourtyardBed",Vector3(x,.12,29.5),Vector3(.65,.24,3),"district_brick",true)
		k.box("CourtyardBedSnow",Vector3(x,.26,29.5),Vector3(.53,.05,2.88),"surface_snow")
	# Coherent facade-foot rubble: a few larger fragments surrounded by gravel,
	# kept inside the verge instead of sprinkled uniformly over walkable roads.
	for spec in BLOCKS:
		var p:Vector3=spec.at;var size:Vector2=spec.size
		for side in [-1,1]:
			for n in 9:
				var at=p+Vector3(side*(size.x/2+.45),.10,-size.y*.40+n*size.y*.09)
				var stone=k.box("UrbanFacadeDebris",at,Vector3(.18+.08*(n%3),.15+.06*(n%2),.28),"district_brick");stone.rotation.y=n*1.03
			k.ellipsoid("UrbanFacadeDrift",p+Vector3(side*(size.x/2+.50),.06,0),Vector3(.42,.17,size.y*.43),"surface_snow")
	# Retaining ends and a ventilation head explain why the underground portal
	# stands here. The return spawn and the door approach stay entirely clear.
	k.box("StationVentBase",Vector3(-68.3,.20,46),Vector3(1.4,.40,2.6),"district_concrete",true)
	k.box("StationVentStack",Vector3(-68.3,1.3,46),Vector3(.9,2.2,1.7),"district_brick",true)
	for y in [1.5,1.7,1.9,2.1]:k.box("StationVentLouver",Vector3(-67.8,y,46),Vector3(.10,.10,1.45),"old_iron")
	k.box("StationVentSnowCap",Vector3(-68.3,2.48,46),Vector3(1.3,.16,2.1),"surface_snow")
	# Link surfaces give facilities actual yards instead of isolated building
	# models on a snow plane. Their height is below the walking step limit.
	for spec in [[-60,-24.2,10.8,3.8],[-31,-17.2,7.8,3.4],[5,-24,7.6,3],[65,34.5,10,3.4]]:
		k.box("IndustrialEntranceApron",Vector3(spec[0],.021,spec[1]),Vector3(spec[2],.035,spec[3]),"district_concrete")
	for x in [-62,-58]:
		k.box("WaterworksGatePier",Vector3(x,1.7,-21.5),Vector3(.6,3.4,.6),"district_brick",true)
		k.box("GatePierCoping",Vector3(x,3.45,-21.5),Vector3(.82,.15,.82),"district_concrete")
	k.box("WaterworksGateLintel",Vector3(-60,3.42,-21.5),Vector3(4.5,.38,.5),"old_iron")
