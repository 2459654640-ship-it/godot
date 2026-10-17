extends RefCounted
## A dogleg off the existing circulation spine; the original seven story NPCs
## and all old routes remain in the same part of D-6.
const ZONES=[
{"name":"西翼入口","code":"09","rect":Rect2(-20,.1,5,3)},
{"name":"居民连廊","code":"10","rect":Rect2(-23,-8.9,3,12)},
{"name":"轮班宿舍","code":"11","rect":Rect2(-29,-8.9,6,5.4)},
{"name":"家属房","code":"12","rect":Rect2(-29,-3.5,6,6.6)},
{"name":"洗衣 / 晾晒间","code":"13","rect":Rect2(-23,-13.9,5.5,5)}]
const DOORS=[Vector2(-15,1.6),Vector2(-23,-6.2),Vector2(-23,-.5),Vector2(-21.5,-8.9)]

static func structure(w):
	var k=w.kit
	for zone in ZONES:
		var r:Rect2=zone.rect
		var c=r.get_center()
		k.box("WingFoundation",Vector3(c.x,-.30,c.y),Vector3(r.size.x,.5,r.size.y),"concrete")
		k.box("WingFloorCollision",Vector3(c.x,-.10,c.y),Vector3(r.size.x,.2,r.size.y),"tile",true).visible=false
	k.wall("WingEntryNorth",Vector2(-20,.1),Vector2(-15,.1))
	k.wall("WingSouth",Vector2(-29,3.1),Vector2(-15,3.1),true)
	k.wall("WingWest",Vector2(-29,-8.9),Vector2(-29,3.1))
	k.wall("WingDormNorth",Vector2(-29,-8.9),Vector2(-23,-8.9))
	k.wall("WingFamilyDivider",Vector2(-29,-3.5),Vector2(-23,-3.5),true)
	k.wall("WingHallEast",Vector2(-20,-8.9),Vector2(-20,.1),true)
	for span in [[-8.9,-7.06],[-5.34,-1.36],[.36,3.1]]:k.wall("WingRoomWall",Vector2(-23,span[0]),Vector2(-23,span[1]),true)
	for z in [-6.2,-.5]:k.doorway(-23,z,true)
	k.doorway(-15,1.6,true)
	k.wall("WingLaundryWest",Vector2(-23,-13.9),Vector2(-23,-8.9))
	k.wall("WingLaundryNorth",Vector2(-23,-13.9),Vector2(-17.5,-13.9))
	k.wall("WingLaundryEast",Vector2(-17.5,-13.9),Vector2(-17.5,-8.9),true)
	for span in [[-23,-22.36],[-20.64,-17.5]]:k.wall("WingLaundryDoorWall",Vector2(span[0],-8.9),Vector2(span[1],-8.9),true)
	k.doorway(-21.5,-8.9)

static func bunk(k,p:Vector3):
	k.bed(p,"blue")
	k.box("UpperBunkFrame",p+Vector3(0,1.35,0),Vector3(1.0,.08,2.0),"dark")
	k.box("UpperBunkBlanket",p+Vector3(0,1.43,.10),Vector3(.92,.10,1.78),"cloth")
	k.ellipsoid("UpperBunkPillow",p+Vector3(0,1.53,-.7),Vector3(.30,.07,.20),"paper")
	for x in [-.48,.48]:
		for z in [-.94,.94]:k.box("BunkPost",p+Vector3(x,.90,z),Vector3(.045,1.80,.045),"dark")
	k.box("BunkRail",p+Vector3(.48,1.63,0),Vector3(.035,.06,1.9),"dark")

static func furnish(w):
	var k=w.kit
	bunk(k,Vector3(-27.8,0,-7.2))
	bunk(k,Vector3(-25.5,0,-7.2))
	for x in [-28.1,-27.2,-26.3]:k.locker(Vector3(x,0,-4.25),1.70)
	k.bench(Vector3(-24.2,0,-4.3),1.2)
	k.signboard("11 / СМЕННАЯ КОМНАТА",Vector3(-26.0,2.3,-8.74),3.4)
	k.lamp(Vector3(-26.5,2.25,-8.65),true,2.1,6)
	# The family room has two occupied beds, a shared table, books and drying
	# clothes; it is a home rather than an empty room added to square a map.
	k.bed(Vector3(-27.8,0,-1.8),"cloth")
	k.bed(Vector3(-27.8,0,.9),"blue")
	k.table(Vector3(-25.3,0,1.8),1.3)
	k.box("FamilyBooks",Vector3(-25.5,.85,1.85),Vector3(.25,.12,.36),"red")
	k.box("FamilyRadiator",Vector3(-28.7,.60,-.2),Vector3(.30,1.05,.65),"metal",true)
	k.cyl("HeatingBleedValve",Vector3(-28.45,1.0,-.2),.07,.06,"brass").rotation.z=PI/2
	k.pipe(Vector3(-28.6,.3,-3.1),Vector3(-28.6,.3,2.8),.04)
	k.signboard("12 / СЕМЬЯ",Vector3(-26.3,2.3,-3.33),2.3)
	k.lamp(Vector3(-26.2,2.25,-3.28),true,1.8,6)
	k.table(Vector3(-21.0,0,-12.8),2.3)
	k.cyl("LaundryBasin",Vector3(-21.2,.88,-12.8),.28,.16,"metal")
	for x in [-22.2,-21.3,-20.4]:k.locker(Vector3(x,0,-11.0),1.65)
	k.box("LinenShelf",Vector3(-18.3,.9,-12.2),Vector3(1.2,1.8,.6),"wood",true)
	for y in [.45,.9,1.35]:k.box("FoldedLinen",Vector3(-18.3,y,-11.84),Vector3(.9,.17,.34),"cream")
	k.box("ResidentsBoard",Vector3(-19.0,1.65,-13.72),Vector3(1.4,.9,.08),"wood")
	k.label("ЖИЛЬЦЫ / 1982\nБЛОК Б · 12 КОЕК",Vector3(-19.0,1.68,-13.66),22)
	k.pipe(Vector3(-22.5,2.3,-12),Vector3(-18.1,2.3,-12),.025,"dark")
	for x in [-21.9,-20.9,-19.9]:k.box("DryingTowel",Vector3(x,1.98,-12),Vector3(.44,.52,.035),"cloth")
	k.lamp(Vector3(-20.8,2.3,-13.65),false,2.0,7)
	for z in [-7.8,-2.5]:k.lamp(Vector3(-22.8,2.3,z),true,1.3,5)
	k.lamp(Vector3(-17.5,2.3,.28),false,1.4,5)
	k.signboard("ЖИЛОЙ БЛОК / ←",Vector3(-16.8,2.25,.26),2.3)
	# A real opaque locked door implies the occupied block beyond this slice.
	k.box("DoorSleepingBlock",Vector3(-18.2,1.02,.29),Vector3(1.25,2.04,.10),"metal")
	k.label("Б / 3\nНОЧНАЯ СМЕНА",Vector3(-18.2,1.5,.36),25)
	k.box("DoorSleepingHandle",Vector3(-17.75,.95,.38),Vector3(.12,.035,.045),"brass")
	k.label("请轻声 · 夜班休息",Vector3(-18.2,2.35,.34),23)

static func targets(w):
	w.target("resident",w.npcs.resident.position,"帕维尔","talk")
	w.target("diner",w.npcs.diner.position,"维拉","talk")
	w.target("heating",Vector3(-27.6,0,-.2),"暖气排气阀")
	w.target("laundry",Vector3(-20.8,0,-11.65),"晾晒架与干布")
	w.target("residents_board",Vector3(-19.0,0,-12.75),"住户登记板")
	w.target("closed_rooms",Vector3(-18.2,0,1.1),"夜班宿舍门")
