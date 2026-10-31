extends SceneTree
var checks=0
var failures=0
var w
func _initialize():call_deferred("run")
func check(ok:bool,msg:String):
 checks+=1
 if not ok:failures+=1;push_error(msg)
func frames(n:int=6):
 for i in n:await physics_frame
func read_to_end():
 var guard=0
 while is_instance_valid(current_scene) and guard<30:
  w=current_scene
  if not w.story.flags.get("comic",{}).get("active",false):break
  var panel=w.story.Comic.panel(w.story)
  check(not panel.is_empty(),"real HUD resolves "+str(w.story.flags.comic.node))
  w.hud.comic_choose(0 if panel.has("choices") else -1);guard+=1;await frames()
 w=current_scene;check(guard<30,"HUD/scene transition completes without a loop")
func run():
 w=load("res://scenes/commune.tscn").instantiate();root.add_child(w);current_scene=w;await frames()
 w.story.flags.intro_done=true;w.story.flags.commune_member=true;w.story.flags.commune_joined=true;w.story.give("mask");w.story.give("filter");w.hud.close()
 w.perform("c_field_c1_accept","commune_guard");w.hud.finish_typing()
 check(w.story.f("field_c1_accepted"),"HUD accepts first faction sortie")
 w.perform("c_field_c1_depart","commune_leave");await read_to_end()
 check(w.floor_id=="railfront" and w.story.flags.field_mission=="c1" and w.story.f("arrival_v8_railfront"),"first sortie reaches actual map through its first-arrival reader")
 w.combat.set_physics_process(false);w.hud.close()
 w.perform("c_front_read_routes","front_routes");w.story.flags.battle_c1_west=true
 w.perform("c_front_take_evidence","front_cache");await read_to_end()
 check(w.story.f("field_c1_scene_seen") and w.story.f("c1_witness_named") and w.hud.dialogue_id=="front_cache","evidence opens an interactive interlude and returns to the correct object")
 w.story.flags.c1_lidiya_waiting=true;w.story.flags.battle_c1_north=true;w.perform("c_front_restore_signal","front_signal")
 check(w.story.f("field_c1_ready"),"signal confirms actual mission readiness")
 w.perform("c_front_return","front_exit");await read_to_end()
 check(w.floor_id=="commune" and w.story.f("field_c1_ready"),"return reader restores mission state in sponsoring settlement")
 w.perform("c_field_c1_report","commune_guard");await read_to_end()
 check(w.story.f("field_c1_done") and not w.story.ending and w.hud.dialogue_id=="commune_guard","report reader returns to a playable faction NPC")
 check(w.story.Campaign.available(w.story,"field_c2_accept") and not w.story.Campaign.available(w.story,"commune_star"),"next main assignment unlocks while Star City remains later")
 # The grief reader resumes at the classroom object, not an absent living NPC.
 w.story.flags.anna_dead=true;w.story.flags.anna_outcome_done=true;w.story.flags.anna_rescue_started=true
 w.hud.show_comic("anna_account_family");await read_to_end()
 check(w.story.f("anna_aftermath_done") and w.hud.dialogue_id=="commune_class" and not w.story.ending,"grief conclusion returns to classroom and leaves mainline playable")
 w.queue_free();await frames()
 print("CHAPTER_FLOW_V22_RESULT checks=",checks," failures=",failures);quit(0 if failures==0 else 1)
