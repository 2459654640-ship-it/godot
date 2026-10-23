extends "res://tools/visual_capture_v8.gd"
func _initialize():
 folder=OS.get_environment("METRO_REVIEW_DIR") if OS.has_environment("METRO_REVIEW_DIR") else "/tmp/metro1982-review/v25";call_deferred("run")
func run():
 DirAccess.make_dir_recursive_absolute(folder)
 var menu=load("res://scenes/main_menu.tscn").instantiate();root.add_child(menu);current_scene=menu;await settle();menu.show_settings();await shot("title-settings")
 var session=root.get_node("Session");var preview=session.video.duplicate();preview.width=1280;preview.height=720;preview.fill=false;session.preview_video(preview);await settle();await shot("settings-1280-keep-aspect");assert(root.size==Vector2i(1280,720),"Window and viewport must actually resize")
 preview.fill=true;session.preview_video(preview);await settle();await shot("settings-1280-fill");session.revert_video();menu.queue_free();await settle()
 await open_level("d6")
 w.combat.set_physics_process(false)
 for id in ["revolver","mask","filter","photo","wrench","frequency","order","knife","vitamins","map","water_core"]:w.story.give(id)
 w.story.economy.goods={"medkit":2,"bandage":4,"bread":3,"antirad":1,"portable_radio":1};w.story.economy.health=68;w.story.economy.food=48
 w.hud.show_inventory();await shot("inventory-grid")
 preload("res://scripts/ui_inventory.gd").render(w.hud,"supplies","medkit");await shot("inventory-supplies")
 w.hud.show_settings();await shot("pause-settings");w.hud.close()
 w.story.route="official";w.story.flags.departure_official=true;w.story.flags.d6_returned=true;w.story.flags.d6_cargo_returned=true;w.story.flags.d6_duty_accepted=true;w.story.flags.d6_home_seen=true
 w.hud.show_task_detail("d6_first_duty");await shot("task-current-objective")
 w.hud.show_journal();await shot("quest-journal")
 for node in ["d6_home_evening","d6_home_grief","mine_bedside","d6_patrol_report"]:
  w.hud.comic_active=false;w.story.flags.comic={"active":false};w.hud.show_comic(node);await shot(node)
 await dispose()
 await open_level("commune");w.combat.set_physics_process(false);w.hud.hide()
 var ids=[]
 for id in w.npcs:
  if w.npcs[id].art_id in ["ambient_worker","ambient_woman","ambient_child"]:ids.append(id)
 if ids.size()>=3:
  for i in 3:
   var a=w.npcs[ids[i]];a.position=Vector3(-2+i*2,0,3);a.velocity=Vector3(.72,0,0);a.visual.rotation.y=PI
   a.visual.get_node("Painter").set_process(false)
  w.player.position=Vector3(-4,0,4);camera_at(Vector3(0,.8,3),10)
  for phase in [0.0,.25,.5,.75]:
   for id in ids:
    var p=w.npcs[id].visual.get_node("Painter");p.cycle=phase;p._process(0)
   await shot("resident-step-"+str(roundi(phase*100)))
 await dispose();print("JOURNEY_CAPTURE_V25 complete");quit()
