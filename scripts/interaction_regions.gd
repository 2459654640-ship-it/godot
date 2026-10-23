extends RefCounted
## Activities belong to a bounded room; documents and people remain local targets.
## Bounds stop inside the walls/doorways, never across adjacent rooms.
const REGIONS={
	"commune_hall":{"floor":"commune","rect":Rect2(-10.3,-11.3,21.6,6.6),"action":"commune_assembly","label":"参加居民议事"},
	"sech_meeting":{"floor":"sech","rect":Rect2(-3.3,-13.3,11.6,7.6),"action":"sech_oath","label":"参加谢契入伙轮值"}
}
static func active(s,id:String)->bool:
	if not REGIONS.has(id):return false
	var spec:Dictionary=REGIONS[id]
	return s.context.get("floor","")==spec.floor and s.Campaign.available(s,spec.action)
static func contains(s,id:String,position:Vector3)->bool:
	return active(s,id) and REGIONS[id].rect.has_point(Vector2(position.x,position.z))
static func label(s,id:String)->String:
	return REGIONS[id].label if active(s,id) else ""
