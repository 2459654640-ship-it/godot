extends "res://tools/visual_capture_v9.gd"
func _initialize():
 folder="res://docs/screenshots/visual-v12";call_deferred("run")
func run():
 DirAccess.make_dir_recursive_absolute(folder);await open_level("waterworks");w.combat.set_physics_process(false);w.hud.hide()
 w.player.position=Vector3(-17,.04,2.2);camera_at(Vector3(-16,1,6),17);await shot("factory-archive-door")
 w.player.position=Vector3(-13,.04,-5);camera_at(Vector3(-12,1,-9),20);await shot("factory-pump-room")
 w.player.position=Vector3(-1,.04,-3);camera_at(Vector3(-1,1,-6),15);await shot("factory-repair-room")
 w.player.position=Vector3(12,.04,-3);w.story.flags.plant_power=true;w.on_story_changed();w.gate_tween.custom_step(2);camera_at(Vector3(12,1,-8),18);await shot("factory-filter-warehouse")
 w.player.position=Vector3(-13,.04,-2);w.story.flags.plant_diagram=true;w.story.flags.weapon_drawn=true;w.combat.begin("pump");w.combat.veteran.position=Vector3(-11,.04,-3)
 for enemy in w.combat.enemies:enemy.set_physics_process(false)
 w.hud.show();w.combat._physics_process(0);camera_at(Vector3(-12,1,-6),19);await shot("factory-combat")
 w.hud.close();w.hud.show_inventory();w.combat._physics_process(0);await shot("weapon-equipment-slot");w.hud.close()
 await dispose();quit()
