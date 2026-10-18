extends RefCounted
## Material on shell faces, never a second rectangle across a doorway.
const FLOOR={"01":"plant_damp_floor","02":"factory_floor","03":"plant_damp_floor","04":"factory_floor","05":"plant_ivory_tile","06":"plant_damp_floor","00":"plant_damp_floor"}
static func prepare(k,zones:Array):
 for spec in [["plant_damp_floor",.38],["plant_blue_wall",.40],["plant_ivory_tile",.55],["plant_rust_steel",.8],["plant_rubber",1.0],["plant_archive_wall",.40]]:
  var m=k.mats.concrete.duplicate();m.albedo_texture=load("res://assets/visual/"+spec[0]+".png")
  m.albedo_color=Color.WHITE;m.normal_enabled=false;m.roughness_texture=null;m.roughness=.94;m.uv1_scale=Vector3.ONE*spec[1]
  k.mats[spec[0]]=m
 k.wall_room_profiles.clear()
 for room in zones:k.wall_room_profiles.append({"rect":room.rect,"style":12 if room.code=="04" else (13 if room.code in ["05","06"] else 11)})
 k.wall_color=Color.WHITE;k.wall_finish_theme="factory"
