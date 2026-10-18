extends RefCounted
## Material on shell faces, never a second rectangle across a doorway.
const FLOOR={"01":"factory_damp_v13","02":"factory_dry_v13","03":"factory_damp_v13","04":"factory_dry_v13","05":"factory_floor_tile_v13","06":"factory_floor_tile_v13","00":"factory_damp_v13"}
static func prepare(k,zones:Array):
 for spec in [["plant_damp_floor",.38],["plant_blue_wall",.40],["plant_ivory_tile",.55],["plant_rust_steel",.8],["plant_rubber",1.0],["plant_archive_wall",.40],["factory_damp_v13",.24],["factory_dry_v13",.24],["factory_floor_tile_v13",.45],["factory_enamel_v13",.35],["factory_oxide_v13",.40]]:
  var m=k.mats.concrete.duplicate();m.albedo_texture=load("res://assets/visual/"+spec[0]+".png")
  m.albedo_color=Color.WHITE;m.normal_enabled=false;m.roughness_texture=null;m.roughness=.94;m.uv1_scale=Vector3.ONE*spec[1]
  k.mats[spec[0]]=m
 for name in ["factory_damp_v13","factory_dry_v13"]:
  var floor=ShaderMaterial.new();floor.shader=load("res://assets/visual/factory_floor.gdshader")
  floor.set_shader_parameter("albedo_map",k.mats[name].albedo_texture)
  k.mats[name]=floor
 # Reuse one family of painted iron on both old and newly added machinery.
 for name in ["blue","metal","old_iron"]:k.mats[name]=k.mats.factory_enamel_v13
 k.mats.rust=k.mats.factory_oxide_v13
 k.wall_room_profiles.clear()
 for room in zones:k.wall_room_profiles.append({"rect":room.rect,"style":12 if room.code=="04" else (13 if room.code in ["05","06"] else 11)})
 k.wall_surface="factory_plaster_v13";k.wall_color=Color.WHITE;k.wall_finish_theme="factory"
