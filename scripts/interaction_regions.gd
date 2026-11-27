extends RefCounted
## Activities belong to a bounded room; documents and people remain local targets.
## Bounds stop inside the walls/doorways, never across adjacent rooms.
const REGIONS={
	"commune_hall":{"floor":"commune","rect":Rect2(-10.3,-11.3,21.6,6.6),"action":"commune_assembly","label":"参加居民议事"},
	"sech_meeting":{"floor":"sech","rect":Rect2(-3.3,-13.3,11.6,7.6),"action":"sech_oath","label":"参加谢契入伙轮值"},
	"rescue35_lift":{"floor":"coal","rect":Rect2(-34.65,-3.38,3.65,3.42),"actions":["rescue35_call","rescue35_divert","rescue35_manual"],"label":"和提升值班员交谈"},
	"rescue35_handoff":{"floor":"coal","rect":Rect2(-25.2,-26.1,4.4,2.8),"action":"rescue35_handoff","label":"在备用转运口点名"}
}
static func active(s,id:String)->bool:
	if not REGIONS.has(id):return false
	var spec:Dictionary=REGIONS[id]
	if s.context.get("floor","")!=spec.floor:return false
	return spec.get("actions",[spec.get("action","")]).any(func(key):return s.Campaign.available(s,key))
static func contains(s,id:String,position:Vector3)->bool:
	return active(s,id) and REGIONS[id].rect.has_point(Vector2(position.x,position.z))
static func label(s,id:String)->String:
	return REGIONS[id].label if active(s,id) else ""
