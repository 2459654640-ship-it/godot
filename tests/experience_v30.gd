extends SceneTree
const Story=preload("res://scripts/story.gd")
const Books=preload("res://scripts/publications.gd")
var checks=0
var failures=0
var w
func _initialize():call_deferred("run")
func check(ok:bool,why:String):
 checks+=1
 if not ok:failures+=1;push_error(why)
func frames(n=4):
 for i in n:await process_frame
func act(s,key):s.act("c_"+key);check(s.last_action_valid,"available: "+key)
func radio_target(s)->String:
 for task in s.Campaign.side_tasks(s):
  if task.id=="city_radio":return task.target
 return ""
func run():
 var s=Story.new();s.context.floor="east_district"
 act(s,"city_radio_read");check(radio_target(s)=="city_radio_panel","radio task starts at isolation switch")
 act(s,"city_radio_isolate");check(radio_target(s)=="east_spares","unpowered station directs to obtainable component")
 act(s,"east_take_spares");check(radio_target(s)=="east_relay","carrying component directs to substation")
 act(s,"east_power_restore");check(radio_target(s)=="city_radio_panel","restored power directs back to radio")
 for key in ["city_radio_power","city_radio_test"]:act(s,key)
 check(s.f("city_radio_online"),"radio-first exploration can complete without starting the other power quest")
 var power_first=Story.new();power_first.context.floor="east_district";power_first.flags.east_power_restored=true
 act(power_first,"city_radio_read");act(power_first,"city_radio_isolate")
 check(radio_target(power_first)=="city_radio_panel","earlier power repair skips obsolete component errand")
 act(s,"city_family_read");check(Books.owned(s,"pub_city_family"),"residence letter is actually readable in the collection")
 var count=Books.count(s);s.act("c_city_family_read");check(not s.last_action_valid and Books.count(s)==count,"letter cannot duplicate")
 w=load("res://scenes/east_district.tscn").instantiate();root.add_child(w);current_scene=w;await frames()
 w.set_physics_process(false);w.player.set_physics_process(false);w.combat.set_physics_process(false);w.grey_camp.set_physics_process(false)
 for guard in w.grey_camp.guards:guard.set_physics_process(false)
 w.story.flags.intro_done=true;w.story.flags.comic={"active":false};w.hud.comic_active=false;w.hud.close()
 w.story.flags.east_crossing_open=true;w.navigation.setup(w)
 for id in ["city_family_letter","raid_container_apartment_pantry","raid_container_apartment_workbag","raid_container_south_entry","raid_container_south_supply","raid_container_east_corner_tools"]:
  var target=w.targets[id].pos;var path=w.navigation.path(w.player.position,target)
  check(not path.is_empty() and path[-1].distance_to(target)<1.7,"walkable search location: "+id)
 for roof in w.wall_veil.interior_roofs:check(not roof.get_meta("batched_visual",false),"roof remains the actual rendered mesh, without a stale batched copy")
 w.player.position=Vector3(-82.5,.04,32);w.wall_veil._process(.5)
 check(w.wall_veil.interior_active and w.wall_veil.focus_overlay.visible,"entering clinic engages interior focus")
 for roof in w.wall_veil.interior_roofs:
  if roof.get_meta("interior_rect").has_point(Vector2(-82.5,32)):check(not roof.visible,"occupied room roof and snow both disappear")
 w.set_camera(0,true);check(w.camera.size<=15,"indoor camera closes in without overwriting user zoom")
 w.player.position=Vector3(-64,.04,46);w.wall_veil._process(1)
 check(not w.wall_veil.interior_active and not w.wall_veil.focus_overlay.visible,"outside appearance restores on exit")
 for roof in w.wall_veil.interior_roofs:check(roof.visible,"all room roofs restore outside")
 w.hud.start_modal("测试页面甲","",true,"scroll_test_a")
 for i in 50:w.hud.body("一条足以占据高度的记录",20)
 await frames();w.hud.modal_box.get_parent().scroll_vertical=240
 w.hud.start_modal("测试页面乙","",true,"scroll_test_b")
 for i in 50:w.hud.body("另一页记录",20)
 await frames();check(w.hud.modal_box.get_parent().scroll_vertical==0,"new page starts at top")
 w.hud.start_modal("测试页面甲","",true,"scroll_test_a")
 for i in 50:w.hud.body("一条足以占据高度的记录",20)
 await frames(6);check(w.hud.modal_box.get_parent().scroll_vertical==240,"returning from another page restores exact scroll position")
 w.hud.show_map();await frames()
 var map=w.hud.map_large;map.flat_projection=true;map.drawing_scale=2;map.origin=Vector2(400,260)
 var click=InputEventMouseButton.new();click.button_index=MOUSE_BUTTON_LEFT;click.pressed=true;click.position=map.project(Vector2(-30,-65));map._gui_input(click)
 check(w.story.flags.get("city_waypoint",[])==[-30.0,-65.0],"map click records waypoint in actual world coordinates")
 click.button_index=MOUSE_BUTTON_RIGHT;map._gui_input(click);check(not w.story.flags.has("city_waypoint"),"right click clears waypoint")
 check(not preload("res://scripts/city_survey.gd").known(w.story,Vector2(95,-65)),"using map never reveals unexplored encounter locations")
 var loot_id="raid_container_apartment_pantry"
 w.player.position=w.targets[loot_id].pos
 var container:Dictionary=w.story.flags.raid_containers["east_district:apartment_pantry"]
 container.searched=true;container.loot={"bandage":2,"military":3}
 w.story.economy.goods={"medkit":30};var rounds=int(w.story.economy.military)
 preload("res://scripts/raid_loot.gd").take_all(w,loot_id)
 check(container.loot=={"bandage":2} and w.story.economy.military==rounds+3,"take all retains oversized loot while collecting currency exactly once")
 w.story.economy.goods={}
 preload("res://scripts/raid_loot.gd").take_all(w,loot_id)
 check(container.loot.is_empty() and w.story.economy.goods.get("bandage",0)==2,"return with space collects exactly the remaining items")
 check("已搜空" in w.targets[loot_id].label,"empty container state is visible in interaction prompt")
 w.queue_free();await frames();print("EXPERIENCE_V30_RESULT ",checks," checks / ",failures," failures");quit(1 if failures else 0)
