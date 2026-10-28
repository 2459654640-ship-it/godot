extends RefCounted
## Distinct silhouettes and readable attack contracts; no companion commands.
const KINDS={
 "behemoth":{"name":"蓄水池巨兽","texture":"reservoir_beast","rows":7,"hp":460,"speed":1.25,"height":1.45,"radius":.55,"pixel":.0082,"center":1.1808},
 "mutant":{"name":"隧道食腐兽","texture":"tunnel_scavenger","rows":4,"hp":62,"speed":1.65,"height":.75,"radius":.27,"pixel":.004,"center":.47},
 "pouncer":{"name":"伏扑兽","texture":"tunnel_pouncer","rows":7,"hp":72,"speed":1.8,"height":.72,"radius":.27,"pixel":.004,"center":.56},
 "spitter":{"name":"囊喉兽","texture":"tunnel_spitter","rows":7,"hp":48,"speed":1.35,"height":.85,"radius":.27,"pixel":.0042,"center":.588}
}
static func get_kind(id:String)->Dictionary:return KINDS.get(id,KINDS.mutant)
static func wave(encounter:String,fallback:String,count:int)->Array:
 if fallback=="soldier":return []
 if encounter=="city_radio_nest":return ["spitter","pouncer","mutant"].slice(0,count)
 if encounter=="east_road":return ["mutant","pouncer"].slice(0,count)
 var compositions={"pump":["mutant","mutant","pouncer"],"workshop":["mutant","spitter","mutant"],"warehouse":["pouncer","mutant","spitter","mutant"],"surface_yard":["mutant","pouncer","mutant"],"surface_pool":["spitter","mutant","pouncer","mutant"]}
 if compositions.has(encounter):return compositions[encounter].slice(0,count)
 if encounter.ends_with("_west"):return ["mutant","pouncer","mutant"].slice(0,count)
 if encounter.ends_with("_north"):return ["spitter","mutant","pouncer"].slice(0,count)
 return []
static func budget(kind:String)->int:return 5 if kind=="pouncer" else 4
