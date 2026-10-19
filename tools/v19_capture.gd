extends "res://tools/visual_capture_v9.gd"
func _initialize():folder="/tmp/metro1982-review/v19";call_deferred("run")
func run():
 DirAccess.make_dir_recursive_absolute(folder)
 if "--surface-only" in OS.get_cmdline_user_args():
  await exterior();quit();return
 await open_level("commune")
 w.hud.visible=false;camera_at(Vector3(-8,0,-8),12);await shot("assembly-west-wall")
 for n in range(12):
  for group in w.get_children():
   if String(group.name).begins_with("ResidentGroup_"):group._process(.25)
  await shot("assembly-idle-%02d"%n)
 camera_at(Vector3(-5,0,1),11);await shot("public-crowds")
 await dispose()
 await exterior()
 quit()
func exterior():
 await open_level("surface")
 w.hud.visible=false;camera_at(Vector3(0,0,0),45);await shot("surface-overview")
 for p in [["road",Vector3(-1,0,5),19],["ruins",Vector3(-13,0,-8),19],["tram",Vector3(15,0,3),18],["pool",Vector3(5,0,-11),19]]:
  camera_at(p[1],p[2]);await shot("surface-"+p[0])
 w.story.flags.surface_job=true;w.story.flags.surface_trip_active=true;w.story.give("revolver");w.story.give("mask");w.story.give("filter");w.story.equip_weapon("revolver");w.story.economy.handmade=36
 w.player.position=Vector3(-7,.04,5);w.combat.set_physics_process(false);w.story.flags.weapon_drawn=true;w.combat.begin("surface_yard")
 for enemy in w.combat.enemies:enemy.set_physics_process(false)
 w.hud.visible=true;w.hud.refresh_status();camera_at(Vector3(-2,0,3),17);w.combat._physics_process(0)
 for receipt in w.hud.receipt_timers:
  if is_instance_valid(receipt.node):receipt.node.queue_free()
 w.hud.receipt_timers.clear();await shot("surface-first-encounter")
 await dispose()
 await open_level("starcity")
 w.hud.visible=false;camera_at(Vector3(0,0,5),32);await shot("star-perimeter")
 await dispose()
