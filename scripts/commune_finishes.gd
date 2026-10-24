extends RefCounted
## Surfaces follow room use; shared walls can have a different finish on each face.
const PROFILES={"00":1,"01":2,"02":1,"03":3,"04":1,"05":4,"06":2,"07":5,"08":4,"09":4,"10":2,"11":2,"12":5,"13":2}
static func prepare(k,zones:Array):
 for spec in [["commune_terrazzo",.8],["commune_linoleum",.35],["commune_ivory_tile",.32],["commune_plaster",.45]]:
  var m=k.mats.concrete.duplicate();m.albedo_texture=load("res://assets/visual/"+spec[0]+".png")
  if spec[0]=="commune_terrazzo":m.albedo_texture=load("res://assets/visual/art28_terrazzo.png")
  if spec[0]=="commune_plaster":m.albedo_texture=load("res://assets/visual/art28_plaster.png")
  m.albedo_color=Color.WHITE;m.normal_enabled=false;m.roughness_texture=null;m.roughness=.92;m.uv1_scale=Vector3.ONE*spec[1]
  k.mats[spec[0]]=m
 k.wall_room_profiles.clear()
 for room in zones:k.wall_room_profiles.append({"rect":room.rect,"style":PROFILES[room.code]})
 k.wall_color=Color.WHITE
static func floor_spec(code:String)->Array:
 match code:
  "01":return ["concrete",Color("92988a")]
  "03":return ["commune_linoleum",Color("c0b9ab")]
  "05":return ["commune_ivory_tile",Color("c9d4cf")]
  "06","10","11","13":return ["factory_floor",Color("aaa99a")]
  "07","12":return ["commune_linoleum",Color("b9aa94")]
  "08":return ["commune_ivory_tile",Color("d5c7a9")]
  "09":return ["commune_ivory_tile",Color("d1d9cd")]
  "04":return ["commune_terrazzo",Color("ded8c8")]
  _:return ["commune_terrazzo",Color("b5bcb3")]
