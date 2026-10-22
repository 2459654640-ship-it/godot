extends SceneTree
const Story=preload("res://scripts/story.gd")
var checks=0
var failures=0
func _initialize():call_deferred("run")
func check(ok:bool,msg:String):
 checks+=1
 if not ok:failures+=1;push_error(msg)
func frames(n:int):
 for i in n:await physics_frame
func open(floor:String,s,snapshot:Dictionary={}):
 var packed=snapshot.duplicate(true) if not snapshot.is_empty() else s.serialize()
 if snapshot.is_empty():packed.floor=floor
 packed.layout_revision=24
 root.get_node("Session").pending={"story":packed,"position":Vector3.INF}
 var w=load("res://scenes/"+floor+".tscn").instantiate();root.add_child(w);current_scene=w;w.combat.set_physics_process(false);await frames(5)
 w.hud.comic_active=false;w.story.flags.comic={"active":false};w.hud.close();w.set_physics_process(false)
 w.player.use_override=true;w.player.motion_override=Vector2.ZERO
 # Observer follows the actor but cannot obstruct its doorways; scenery collisions stay enabled.
 w.player.collision_layer=0;w.player.collision_mask=1;return w
func follow(w,id:String,limit:int=4800,arrived:String="")->bool:
 var a=w.npcs[id];var last=a.position;var travel=0.0
 for i in limit:
  # A test camera/player follows alongside; all NPC movement remains swept physics.
  var close=w.player.position.distance_to(a.position)<1.4
  var path=w.navigation.path(w.player.position,a.anchor if close else a.position)
  if w.player.position.distance_to(a.position)>2.6 or close:
   while path.size()>1 and path[0].distance_to(w.player.position)<.30:path.remove_at(0)
   var direction=(path[0] if not path.is_empty() else a.position)-w.player.position;direction.y=0
   w.player.camera=null;w.player.motion_override=Vector2(direction.x,direction.z).normalized()
  else:w.player.motion_override=Vector2.ZERO
  w.living.tick(1.0/60.0);await physics_frame
  travel+=a.position.distance_to(last);last=a.position
  if (arrived!="" and w.story.f(arrived)) or (arrived=="" and a.reached_anchor and not a.purposeful):
   w.player.motion_override=Vector2.ZERO;print("WALK ",id," travel=",travel," frames=",i," end=",a.position);return true
 w.player.motion_override=Vector2.ZERO;print("STUCK ",id," at=",a.position," goal=",a.anchor," player=",w.player.position," remaining=",a.path_points.size());return false
func run():
 var s=Story.new();s.flags.anna_lesson_seen=true;s.flags.anna_walk_started=true
 var w=await open("commune",s);var a=w.npcs.commune_anna
 check(a.visual.get_node("Painter").pose_count==3 and w.npcs.commune_moro.visual.get_node("Painter").pose_count==3,"both travelling characters use painted standing and two distinct walk poses")
 # Put the player at a real nearby clear cell, not on the actor capsule.
 w.player.position=w.clear_arrival(a.position+Vector3(1.5,.04,0))
 w.living.tick(0);var start=a.position;await frames(30)
 check(a.position.distance_to(start)>.1,"Anna actually walks, never slides by a position assignment")
 w.hud.show_dialogue("commune_anna");await frames(20);var paused=a.position;await frames(40)
 check(a.position.distance_to(paused)<.03,"dialogue freezes story travel")
 w.hud.close();check(await follow(w,"commune_anna",4000,"anna_walk_arrived"),"Anna crosses medical doorway and reaches canteen using physical capsules")
 check(w.targets.commune_anna.pos.distance_to(a.position)<.1,"map and name target follow Anna")
 var save=w.save_snapshot();check(save.npc_positions.has("commune_anna"),"moving NPC position is saved")
 w.queue_free();await frames(3);s=Story.new();s.restore(save);w=await open("commune",s,save)
 check(w.npcs.commune_anna.position.distance_to(Vector3(save.npc_positions.commune_anna.position[0],0,save.npc_positions.commune_anna.position[2]))<.20,"exact moving actor position survives a real snapshot reload")
 check(w.story.f("anna_walk_arrived") and not w.story.f("anna_request"),"save keeps walk completion distinct from request")
 w.save_path="user://living_resume_v24.json";w.save_game()
 w.story.flags.anna_dead=true;w.story.changed.emit();await frames(3)
 check(not w.npcs.has("commune_anna"),"outcome reconciles physical actor immediately")
 w.load_game();await frames(5)
 check(w.npcs.has("commune_anna") and w.targets.has("commune_anna") and not w.story.f("anna_dead"),"in-place loading recreates only the living actor and its target")
 w.hud.show_comic("anna_supper");w.hud.finish_typing()
 var labels=w.hud.modal.find_children("*","Label",true,false)
 check(labels.any(func(label):return label.text=="安娜") and not labels.any(func(label):return label.text.begins_with("voice_")),"cinematic shows human speaker names, never parser identifiers")
 w.hud.comic_active=false;w.story.flags.comic={"active":false};w.hud.close()
 DirAccess.remove_absolute("user://living_resume_v24.json")
 w.queue_free();await frames(3)
 # Moro travels through production corridor, assembly and south service rooms.
 s=Story.new();s.flags.moro_known=true;s.flags.moro_job=true;w=await open("commune",s)
 for id in w.npcs:
  if id!="commune_moro":w.npcs[id].set_physics_process(false)
 a=w.npcs.commune_moro;w.player.position=w.clear_arrival(a.position+Vector3(0,.04,1.5))
 for step in [["moro_at_workshop","moro_parts"],["moro_at_boiler","moro_power_plan"],["moro_at_workshop","moro_repair"],["moro_at_guard","moro_permission"]]:
  check(await follow(w,"commune_moro",6000,step[0]),"Moro physically reaches "+step[1])
  w.story.act("c_"+step[1]);check(w.story.last_action_valid,"arrived dialogue permits "+step[1])
  w.story.flags.erase("next_sequence");w.living.tick(0)
 var visiting=w.save_snapshot();var remembered=w.npcs.commune_moro.position;visiting.floor="sech"
 w.queue_free();await frames(3);s=Story.new();s.restore(visiting);w=await open("commune",s,visiting)
 check(w.npcs.commune_moro.position.distance_to(remembered)<.25,"returning from another map retains Moro's actual waiting place")
 w.queue_free();await frames(3)
 # Defenders guard a crossing while three independently animated bodies evacuate.
 s=Story.new();s.flags.sided_veteran=true;s.flags.field_mission="c1";s.flags.veteran_defense_started=true
 w=await open("railfront",s);w.player.position=Vector3(-12,.04,12)
 check(w.targets.has("front_veteran") and w.npcs.has("evac_third"),"veteran and three evacuees physically exist")
 check(w.combat.encounters.has("living_passage"),"dedicated playable defense encounter registered")
 # This movement fixture isolates civilian navigation; actual combat is tested below.
 w.combat.set_physics_process(false);w.story.flags.veteran_defense_deployed=true;w.story.flags.battle_living_passage=true;w.story.flags.battle_living_passage_rear=true;w.story.flags.battle_living_passage_last=true
 var completed=false
 for i in 4800:
  w.living.tick(1.0/60);await physics_frame
  if w.story.f("veteran_defense_safe"):completed=true;break
 for id in w.living.evac_ids:print("EVAC ",id," pos=",w.npcs[id].position," anchor=",w.npcs[id].anchor," wait=",w.npcs[id].story_waiting)
 check(completed and int(w.story.flags.get("veteran_evac_count",0))==3,"all three civilians cross independently and reach safe bay")
 for id in w.living.evac_ids:check(w.npcs[id].position.z>18,"evacuee truly reached south: "+id)
 w.story.flags.battle_living_passage=false;w.story.flags.veteran_defense_safe=false
 w.combat.begin("living_passage");check(w.combat.active and w.combat.enemies.size()==3,"actual defense spawns three enemies")
 var before=w.combat.checkpoint.duplicate(true)
 for e in w.combat.enemies.duplicate():e.damage(999)
 check(w.story.f("battle_living_passage") and not w.combat.active,"normal combat victory feeds evacuation story")
 check(before.flags.veteran_defense_started and not before.flags.get("battle_living_passage",false),"retry checkpoint precedes victory and preserves accepted quest")
 for wave in ["living_passage_rear","living_passage_last"]:
  w.story.flags["battle_"+wave]=false;w.combat.begin(wave)
  check(w.combat.active and w.combat.enemies.size()==2,"two subsequent flanking waves are real combat: "+wave)
  for e in w.combat.enemies.duplicate():e.damage(999)
 w.queue_free();await frames(3)
 # Mine presence is exclusive even if loading an accepted older state.
 s=Story.new();s.flags.anna_rescue_started=true;w=await open("commune",s)
 check(not w.npcs.has("commune_anna") and not w.targets.has("commune_anna"),"Anna cannot remain in commune during mine trip")
 w.queue_free();await frames(3)
 print("LIVING_WORLD_V24_RESULT checks=",checks," failures=",failures);quit(0 if failures==0 else 1)
