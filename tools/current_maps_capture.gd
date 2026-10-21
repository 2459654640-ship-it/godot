extends "res://tools/visual_capture_v9.gd"
func _initialize():
 folder="res://docs/maps";call_deferred("run")
func run():
 DirAccess.make_dir_recursive_absolute(folder)
 for id in (OS.get_cmdline_user_args() if not OS.get_cmdline_user_args().is_empty() else ["d6","labor","waterworks","commune","sech","coal","starcity","surface","railfront"]):
  await open_level(id)
  var bounds:Rect2=w.zones[0].rect
  for room in w.zones:bounds=bounds.merge(room.rect)
  var center=bounds.get_center();w.hud.visible=false;camera_at(Vector3(center.x,0,center.y),maxf(33,(bounds.size.x+bounds.size.y)*.55));await shot(id)
  await dispose()
 quit()
