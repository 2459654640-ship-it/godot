extends SceneTree
const Story=preload("res://scripts/story.gd")
const Books=preload("res://scripts/publications.gd")
var w
var checks=0
var failures=0
func _initialize():call_deferred("run")
func frames(n:int=5):
 for i in n:await physics_frame
func check(ok:bool,text:String):
 checks+=1
 if not ok:failures+=1;push_error(text)
func act(s,key):s.act("c_"+key);check(s.last_action_valid,"action available: "+key)
func read_story():
 var n=0
 while w.story.flags.get("comic",{}).get("active",false) and n<30:
  var p=w.story.Comic.panel(w.story);check(not p.is_empty(),"resolved film panel: "+str(w.story.flags.comic.node))
  w.hud.comic_choose(0 if p.has("choices") else -1);await frames();w=current_scene;n+=1
 check(n<30,"scene resolves without a dialogue loop")
func freeze():
 w.set_physics_process(false);w.player.set_physics_process(false);w.combat.set_physics_process(false);w.hud.close()
func run():
 var legacy=Story.new();legacy.context.floor="railfront";legacy.flags.field_mission="c1";legacy.flags.field_c1_scene_seen=true;legacy.flags.field_c1_evidence=true;legacy.flags.battle_c1_north=true
 check(legacy.Campaign.available(legacy,"front_restore_signal"),"an old in-progress chapter does not acquire a new escort gate")
 legacy.flags.field_c1_accepted=true;legacy.flags.field_c1_in_progress=true
 var migrated=Story.new();migrated.restore(legacy.serialize());migrated.context.floor="railfront"
 check(migrated.f("c1_revised") and migrated.f("c1_legacy_transfer"),"restore migrates an actual older in-progress chapter")
 act(migrated,"front_restore_signal")
 check(migrated.f("field_c1_ready"),"legacy completed link is not reset by the new physical escort requirement")
 legacy.flags.field_c1_done=true
 migrated=Story.new();migrated.restore(legacy.serialize())
 check(migrated.f("field_c1_done") and migrated.f("c1_clinic_pending"),"completed legacy mission stays complete and gains the clinic follow-up")
 var alternative=Story.new();alternative.flags.c1_revised=true;alternative.flags.field_mission="c1";alternative.flags.field_c1_in_progress=true;alternative.flags.field_c1_scene_seen=true;alternative.flags.field_c1_evidence=true;alternative.flags.battle_c1_north=true;alternative.context.floor="railfront"
 act(alternative,"front_restore_signal")
 check(alternative.f("c1_signal_called") and not alternative.f("field_c1_ready"),"northern combat remains an alternative link but does not skip the companion")
 act(alternative,"front_return")
 check(alternative.flags.get("next_sequence","")=="c1_return_early" and not alternative.f("field_c1_done"),"early withdrawal preserves the unfinished mission and uses its own scene")
 for choice in ["c1_witness_named","c1_witness_sealed"]:
  var branch=Story.new();branch.flags[choice]=true;branch.flags.anna_dead=true;branch.Comic.start(branch,"c1_after")
  var paragraph=branch.Comic.panel(branch).body
  check(("发表前" in paragraph)==(choice=="c1_witness_named") and ("完整证词先封存" in paragraph)==(choice=="c1_witness_sealed"),"return responds to the chosen testimony privacy: "+choice)
  check(not "安娜" in paragraph,"return does not resurrect an absent or dead character")
 var s=Story.new();s.context.floor="commune";s.flags.commune_member=true;s.flags.commune_joined=true;s.flags.intro_done=true;s.give("mask");s.give("filter")
 root.get_node("Session").pending={"story":s.serialize(),"floor":"commune","position":Vector3(25,.04,2)}
 w=load("res://scenes/commune.tscn").instantiate();root.add_child(w);current_scene=w;await frames();freeze()
 w.perform("c_field_c1_accept","commune_guard");w.hud.finish_typing();check(w.story.f("c1_revised") and w.story.has("revolver"),"new chapter gives usable equipment before departure")
 w.perform("c_field_c1_depart","commune_leave");await read_story();freeze()
 check(w.floor_id=="railfront" and w.npcs.has("c1_lidiya"),"illustrated departure reaches the real medical transfer scene")
 for id in ["c1_lidiya","c1_backup","c1_spares","c1_orders","c1_linen","front_routes","front_exit"]:
  var route=w.navigation.path(w.player.position,w.targets[id].pos)
  check(w.player.position.distance_to(w.targets[id].pos)<1.7 or (not route.is_empty() and route[-1].distance_to(w.targets[id].pos)<1.7),"physical interaction is reachable: "+id)
 w.perform("c_front_read_routes","front_routes");w.hud.close()
 w.combat.begin("c1_west");await frames()
 var kinds=[]
 for enemy in w.combat.enemies:kinds.append(enemy.enemy_kind);enemy.set_physics_process(false)
 check("pouncer" in kinds,"west encounter combines distinct animated threats")
 for enemy in w.combat.enemies.duplicate():enemy.damage(1000)
 await frames();w.hud.close()
 check(w.story.f("battle_c1_west"),"first encounter resolves through real combat actors")
 w.perform("c_front_take_evidence","front_cache");await read_story();w.hud.close()
 check(w.story.has("c1_medicine") and w.story.f("c1_witness_named") and w.story.f("field_c1_scene_seen"),"medicine and consent are recorded after interactive witness scene")
 check("备用有线机" in w.story.objective(),"fallback objective agrees with the actual alternate route")
 check(not w.story.Campaign.available(w.story,"front_restore_signal"),"calling the driver requires an operational link")
 for key in ["c1_backup_read","c1_backup_isolate","c1_spare_take","c1_backup_restore"]:act(w.story,key)
 check(w.story.Campaign.available(w.story,"front_restore_signal") and not w.story.f("battle_c1_north"),"backup wire offers a complete alternative to the northern fight")
 act(w.story,"front_restore_signal");check(not w.story.f("field_c1_ready"),"a call alone does not teleport the missing companion to safety")
 w.hud.close()
 var initial=w.npcs.c1_lidiya.position;var before_save={}
 for i in 3300:
  w.player.position=w.clear_arrival(w.npcs.c1_lidiya.position+Vector3(2,.04,0))
  w.living.tick(1.0/60);w.medical_chapter.tick(1.0/60)
  if i==150:
   before_save=w.save_snapshot();check(before_save.flags.medical_actor.position[0]!=initial.x or before_save.flags.medical_actor.position[2]!=initial.z,"saved escort has physically walked away from initial position")
   var mid_position=w.npcs.c1_lidiya.position
   root.get_node("Session").enter(before_save,"railfront",w.player.position);await frames(12);w=current_scene;freeze()
   check(w.npcs.c1_lidiya.position.distance_to(mid_position)<.9,"mid-walk load resumes the real companion instead of returning her to the initial office")
  await physics_frame
  if w.story.f("field_c1_ready"):break
 check(w.story.f("c1_lidiya_waiting") and w.story.f("field_c1_ready"),"companion walks the full traversable route to the south waiting area")
 check(w.npcs.c1_lidiya.position.distance_to(initial)>20,"escort is a physical journey rather than an arrival flag")
 check(w.targets.c1_lidiya.pos.distance_to(w.npcs.c1_lidiya.position)<.2,"moving character name and interaction stay with the body")
 var saved_position=w.npcs.c1_lidiya.position;var saved=w.save_snapshot()
 root.get_node("Session").enter(saved,"railfront",w.player.position);await frames(12);w=current_scene;freeze()
 check(w.npcs.c1_lidiya.position.distance_to(saved_position)<.9 and w.story.f("field_c1_ready"),"reload preserves companion location and completed transfer")
 w.perform("c_front_return","front_exit");await read_story();freeze()
 check(w.floor_id=="commune" and not w.npcs.has("c1_lidiya"),"early arrival does not place patient in clinic before the formal handover")
 w.perform("c_field_c1_report","commune_guard");await read_story();freeze()
 check(w.story.f("field_c1_done") and not w.story.has("c1_medicine") and w.npcs.has("c1_lidiya"),"handover consumes protected parcel and places the real companion in the clinic")
 check(not w.story.ending,"the completed chapter remains playable")
 act(w.story,"c1_aftercare");check(Books.owned(w.story,"pub_medical_transfer") and Books.read(w.story,"pub_medical_transfer").body.length()>150,"follow-up gives a complete readable personal record")
 var owned=Books.count(w.story);w.story.act("c_c1_aftercare");check(not w.story.last_action_valid and Books.count(w.story)==owned,"aftercare cannot duplicate reward")
 w.queue_free();await frames();print("MEDICAL_V32_RESULT ",checks," checks / ",failures," failures");quit(1 if failures else 0)
