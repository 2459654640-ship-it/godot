extends "res://tools/visual_capture_v8.gd"
func _initialize():
 folder="res://docs/screenshots/visual-v9";call_deferred("run")
func freeze():
 super.freeze();w.hud.refresh_status()
 if is_instance_valid(w.hud.receipt_box):w.hud.receipt_box.queue_free()
 w.hud.receipt_timers.clear()
func run():
 DirAccess.make_dir_recursive_absolute(folder)
 await open_level("d6")
 for entry in [["history_war","prologue-war"],["history_family","prologue-family"],["history_years","prologue-years"]]:
  w.hud.comic_active=false;w.story.flags.comic={"active":false};w.hud.show_comic(entry[0]);await shot(entry[1])
 w.hud.comic_active=false;w.story.flags.comic={"active":false};w.hud.close()
 w.player.position=Vector3(15.6,.04,1.6);camera_at(Vector3(14,1,1),14);await shot("d6-closed-life-door")
 w.player.position=Vector3(-12,.04,6);camera_at(Vector3(-12.5,1,6.5),10);await shot("washroom")
 w.story.flags.side_pass=true;w.on_story_changed();w.side_mesh.get_meta("motion").pause();w.side_mesh.get_meta("motion").custom_step(.45)
 w.player.position=Vector3(7.6,.04,4.5);camera_at(Vector3(7.5,1,5),12);await shot("side-door-opening")
 w.story.flags.side_pass=false;w.story.flags.igor_suspicious=true;w.on_story_changed();w.side_mesh.get_meta("motion").custom_step(2);w.hud.show_dialogue("igor");await shot("igor-suspicion")
 w.hud.close();w.story.act("search_box");w.story.flags.nina_job=true;w.hud.refresh_status();await shot("quest-and-item-receipts")
 await dispose()
 for id in ["sech","commune","coal","starcity"]:
  await open_level(id)
  var bounds:Rect2=w.zones[0].rect
  for room in w.zones:bounds=bounds.merge(room.rect)
  w.hud.visible=false;var center=bounds.get_center();camera_at(Vector3(center.x,0,center.y),maxf(30,(bounds.size.x+bounds.size.y)*.52));await shot(id+"-overview");w.hud.visible=true
  if id=="sech":
   w.player.position=Vector3(6,.04,-9);camera_at(Vector3(6,1,-12),12);await shot("library-carriage")
   w.player.position=Vector3(0,.04,5);camera_at(Vector3(0,1,4),17);await shot("platform-residents")
   w.story.act("c_north_accept");w.story.act("c_north_record");w.player.position=Vector3(6,.04,14);camera_at(Vector3(6,1,15.5),12);await shot("train-handbrake")
  if id=="commune":
   w.story.act("c_workers_accept");w.story.act("c_press_accept");w.story.flags.tracked_quest="workers_network";w.hud.show_journal();await shot("main-and-side-quests");w.hud.close()
   for notice in w.hud.receipt_timers:
    if is_instance_valid(notice.node):notice.node.queue_free()
   w.hud.receipt_timers.clear();w.story.Progression.fail(w.story,["commune"],"旅程已结束，未能交付。");w.story.changed.emit();w.hud.show_journal("closed");await shot("failed-side-quest")
  await dispose()
 quit()
