extends "res://tests/campaign_contract.gd"
func run():
 w=load("res://scenes/starcity.tscn").instantiate();root.add_child(w);current_scene=w;await frames(6)
 check(w.initialized and w.targets.has("star_perimeter_call"),"closed perimeter starts with an exterior intercom")
 check(w.npcs.is_empty() and w.find_children("VacuumVessel*","MeshInstance3D",false,false).is_empty(),"current chapter builds no interior rooms or staff")
 var snapshot=w.save_snapshot();snapshot.layout_revision=17;snapshot.position=[27,.04,-10];snapshot.flags.test_old_starcity=true;snapshot.flags.star_access=true;snapshot.ending=true
 snapshot.flags.comic={"active":true,"sequence":"father_reunion","node":"father_reunion"}
 var path="user://starcity_v19_migration.json";w.SaveStore.write(path,snapshot,"manual");w.load_game(path);await frames(12);w=current_scene
 check(w.story.f("test_old_starcity") and w.player.position.distance_to(w.CampaignMaps.LAYOUTS.starcity.spawn)<.2,"legacy interior save moves to a safe exterior entrance without losing history")
 check(not w.story.ending and not w.hud.comic_active and not w.story.flags.comic.active,"legacy reunion or ending cannot bypass the exterior limit")
 w.story.context.floor="starcity";w.story.act("c_star_perimeter_name");check(w.story.last_action_valid and w.story.f("star_inquiry_filed"),"relocated player can still file an inquiry")
 w.navigation=preload("res://scripts/route_grid.gd").new();w.navigation.setup(w);var seen=reachable()
 for id in w.targets:
  var end:Vector3=w.targets[id].pos;var accessible=false
  for cell in seen:
   var p:Vector2=w.navigation.graph.get_point_position(cell)
   if p.distance_to(Vector2(end.x,end.z))<1.6 and not overlap(Vector3(p.x,.04,p.y)):accessible=true;break
  check(accessible,"exterior target has a capsule approach: "+id)
 DirAccess.remove_absolute(path);w.queue_free();await frames()
 print("STARCITY_V19_RESULT checks=",checks," failures=",failed.size());quit(0 if failed.is_empty() else 1)
