extends RefCounted
## Utility spaces sit between public access and the operations they serve.

static func commune(k):
	# Produce comes through the west greenhouse door. This is a dry packing
	# line fed from a separate, washable bay on the eastern wall.
	k.table(Vector3(-24.4,0,15.4),4.2)
	for x in [-25.5,-24.15,-22.8]:
		k.box("HarvestSortingTray",Vector3(x,.82,15.4),Vector3(.79,.10,.61),"wood")
		for n in 5:
			k.ellipsoid("HarvestedRoot",Vector3(x+(n%3-.9)*.19,.92,15.23+floorf(n/3.0)*.23),Vector3(.13,.055,.072),"cream")
	for x in [-27.5,-26.4,-25.3]:
		k.crate(Vector3(x,0,16.82),Vector3(.88,.64,.83))
	k.box("ProduceWashBench",Vector3(-12.25,.45,14.25),Vector3(.95,.9,2.8),"metal",true)
	k.box("ProduceWashBackboard",Vector3(-11.73,1.11,14.25),Vector3(.11,.49,2.78),"tile")
	for z in [13.65,14.85]:
		k.box("ProduceWashBasin",Vector3(-12.25,.94,z),Vector3(.69,.09,.87),"dark")
		k.pipe(Vector3(-11.87,1.14,z),Vector3(-12.25,1.14,z),.027,"metal")
		k.pipe(Vector3(-12.25,1.14,z),Vector3(-12.25,1.06,z),.027,"metal")
	for y in [.27,.43]:k.pipe(Vector3(-11.36,y,11.5),Vector3(-11.36,y,17.7),.038,"rust")
	k.box("ProduceDrainGrille",Vector3(-12.96,.026,14.28),Vector3(.24,.019,2.63),"old_iron")
	for z in range(13,16):
		for i in 6:k.box("DrainBar",Vector3(-12.96,.039,z+i*.15),Vector3(.18,.009,.025),"metal")
	k.lamp(Vector3(-21.6,2.5,11.22),true,1.4,6)
	k.lamp(Vector3(-12.1,2.5,11.22),false,1.1,5)
	# The airlock side room keeps used filters and coats out of the family rooms.
	for x in [24.2,25.4,26.6,27.8]:k.locker(Vector3(x,0,8.3),1.72)
	k.bench(Vector3(28.7,0,6),1.85,true,PI/2)
	k.box("DeconFilterBin",Vector3(24.1,.38,5.44),Vector3(.75,.76,.65),"old_iron",true)
	k.box("DeconBinLid",Vector3(24.1,.78,5.44),Vector3(.82,.08,.73),"metal")
	k.box("DeconBinTape",Vector3(24.1,.60,5.09),Vector3(.41,.16,.025),"cream")
	k.pipe(Vector3(24,2.54,8.77),Vector3(29.65,2.54,8.77),.17,"old_iron")

static func sech(k):
	# Mending room is shared by the inhabitants of the two off-track carriages.
	k.table(Vector3(-10,0,24.75),3.4)
	k.box("TreadleSewingHead",Vector3(-10,1.03,24.85),Vector3(.42,.36,.18),"old_iron")
	k.box("TreadleSewingArm",Vector3(-9.75,1.17,24.85),Vector3(.58,.14,.16),"old_iron")
	k.cyl("TreadleSewingWheel",Vector3(-10.23,1.1,24.86),.146,.052,"metal").rotation.z=PI/2
	k.bench(Vector3(-10,0,23.7),2.3,true,PI)
	for x in [-14.8,-5.3]:
		k.box("MendingShelfPost",Vector3(x,1.0,25.2),Vector3(.52,2.0,.16),"wood",true)
		for y in [.43,1.06,1.69]:
			k.box("LinenShelf",Vector3(x,y,24.85),Vector3(1.18,.09,.7),"wood",true)
			k.box("SpareBlanket",Vector3(x,y+.14,24.85),Vector3(.96,.17,.51),"cloth")
	var lamp=k.lamp(Vector3(-7.5,2.5,20.22),true,1.75,6);lamp.light_color=Color("efbd83")
	# A rail-side jib and a hand-cart make the short end bay usable for work.
	k.box("RailJibPostFoot",Vector3(19.2,.13,-28.2),Vector3(.63,.26,.63),"concrete",true)
	k.box("RailJibPost",Vector3(19.2,1.55,-28.2),Vector3(.25,3.1,.26),"old_iron",true)
	k.box("RailJibArm",Vector3(21.3,3.15,-28.2),Vector3(4.4,.27,.27),"old_iron")
	k.pipe(Vector3(19.25,2.56,-28.2),Vector3(20.45,3.10,-28.2),.058,"old_iron")
	k.pipe(Vector3(22.95,3.01,-28.2),Vector3(22.95,1.95,-28.2),.026,"metal")
	k.box("JackToolRack",Vector3(14.65,1.05,-28.3),Vector3(.72,2.1,2.5),"old_iron",true)
	for z in [-29.05,-28.45,-27.8]:k.pipe(Vector3(15.04,.47,z),Vector3(15.04,1.78,z),.04,"metal")

static func d6(k):
	# Three bays are screened from the intake room. The aisle reaches the door
	# in one line, so a stretcher can pass without turning around furniture.
	for x in [-3.6,3.55]:
		k.bed(Vector3(x,0,-17.0),"paper")
		k.box("WardBedEndCard",Vector3(x,.75,-15.92),Vector3(.39,.24,.045),"cream")
		k.box("ObservationOxygenCase",Vector3(x,.35,-18.33),Vector3(.65,.70,.64),"metal",true)
	for x in [-2.12,2.12]:
		k.pipe(Vector3(x,2.62,-18.55),Vector3(x,2.62,-14.72),.024,"metal")
		k.box("WardCurtain",Vector3(x,1.53,-17.57),Vector3(.08,1.98,1.76),"cloth",true)
	k.table(Vector3(0,0,-18.35),2.02)
	k.box("ObservationChart",Vector3(0,.815,-18.35),Vector3(.47,.04,.35),"paper")
	k.cyl("WardCarafe",Vector3(.6,.97,-18.35),.14,.32,"cream")
	for x in [-3.45,3.45]:
		var lamp=k.lamp(Vector3(x,2.46,-18.78),false,1.55,5)
		lamp.light_color=Color("c4ccc1")
