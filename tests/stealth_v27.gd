extends SceneTree
const Store=preload("res://scripts/save_store.gd")
const District=preload("res://scripts/east_district.gd")
var w
var checks=0
var failures=0
func _initialize():call_deferred("run")
func check(ok:bool,why:String):
 checks+=1
 if not ok:failures+=1;push_error(why)
func frames(n:int=4):
 for i in n:await physics_frame
func freeze():
 w.set_physics_process(false);w.player.set_physics_process(false);w.combat.set_physics_process(false);w.grey_camp.set_physics_process(false)
 for guard in w.grey_camp.guards:
  if is_instance_valid(guard):guard.set_physics_process(false)
 w.story.flags.intro_done=true;w.story.flags.comic={"active":false};w.hud.comic_active=false;w.hud.close()
func place_player(p:Vector3,sneak:bool=false):
 w.player.position=p;w.player.velocity=Vector3.ZERO;w.player.sneaking=sneak
func journey():
 for i in 30:
  while current_scene==null:await process_frame
  w=current_scene
  if not w.story.flags.get("comic",{}).get("active",false):break
  var panel=w.story.Comic.panel(w.story);w.hud.comic_choose(0 if panel.has("choices") else -1);await frames()
 w=current_scene
 if w.floor_id=="east_district":freeze()
 else:
  w.set_physics_process(false);w.player.set_physics_process(false);w.hud.close()
func run():
 w=load("res://scenes/east_district.tscn").instantiate();root.add_child(w);current_scene=w;await frames();freeze()
 w.story.give("mask");w.story.give("filter");w.story.give("revolver");w.story.equip_weapon("revolver");w.story.flags.weapon_drawn=true
 var camp=w.grey_camp;var g=camp.guards[0]
 check(camp.guards.size()==5 and not w.combat.active,"camp has three sentries and two roaming scavengers without starting automatic combat")
 check(g.enemy_kind=="greyhound" and g.sprite.texture.resource_path.ends_with("greyhound_guard.png") and g.sprite.shaded,"bandits use their own lit, equipped human art")
 check(g.sprite.hframes==5 and g.sprite.vframes==4 and is_equal_approx(g.sprite.pixel_size*324,1.76),"new animation has matching adult height, three gait poses and separate aim")
 place_player(Vector3(43.5,.04,-19))
 for i in 80:w.wall_veil._process(1.0/60)
 check(w.wall_veil.states.any(func(s):return s.bounds.has_point(Vector3(43.5,2.8,-19)) and s.opacity<.99 and s.opacity>=.38),"shelter roof fades enough to see Ivan without changing physical cover")
 place_player(Vector3(-64,.04,46))
 var starts=camp.guards.map(func(e):return e.position)
 for guard in camp.guards:guard.set_physics_process(true)
 await frames(600)
 for i in camp.guards.size():
  var guard=camp.guards[i];guard.set_physics_process(false)
  check(guard.position.distance_to(starts[i])>1.2,"guard actually patrols through the authored scenery: "+str(i))
  check(guard.sprite.frame>=0 and guard.sprite.frame<20,"walking selects only complete authored animation frames")
 g.collision_mask=1
 for route in camp.ROUTES:
  for p in route:check(not g.test_move(Transform3D(Basis.IDENTITY,p),Vector3(.01,0,0)),"authored patrol point fits the scenery around the real guard capsule: "+str(p))
 g.collision_mask=1|2|4|8
 g.position=Vector3(34,.04,-8);g.facing=Vector3.BACK
 place_player(Vector3(34,.04,-4))
 check(g.sees_player(),"guard sees an unobstructed player in front")
 place_player(Vector3(34,.04,-12));check(not g.sees_player(),"guard cannot see a player behind him")
 place_player(Vector3(39,.04,-8));check(not g.sees_player(),"peripheral targets outside the view cone remain unseen")
 g.position=Vector3(52,.04,-20);place_player(Vector3(52,.04,-11));check(g.sees_player(),"ordinary movement can be seen at nine metres")
 w.player.sneaking=true;check(not g.sees_player(),"quiet movement reduces long-distance recognition")
 g.position=Vector3(34,.04,-8)
 place_player(Vector3(34,.04,-5.5));w.player.velocity=Vector3.RIGHT
 check(g.hears_player(),"nearby ordinary footsteps create suspicion")
 w.player.sneaking=true;check(not g.hears_player(),"quiet footsteps at the same distance do not create suspicion")
 g.position=Vector3(33,.04,-16);g.facing=Vector3.BACK;place_player(Vector3(33,.04,-10))
 check(not g.sees_player(),"actual stacked crates block line of sight")
 var health=w.story.economy.health;g.windup=.01;g.cooldown=0;camp.alarm=true;g._physics_process(.02)
 check(w.story.economy.health==health and g.windup<=0,"stepping behind cover prevents an aimed shot from dealing damage")
 camp.alarm=false;g.windup=0;g.suspicion=0;g.position=Vector3(34,.04,-8);g.facing=Vector3.BACK;place_player(Vector3(34,.04,-4),true)
 g._physics_process(.2);check(g.suspicion>0 and g.suspicion<.95 and not camp.alarm,"brief sighting raises visible suspicion instead of instantly revealing the player")
 place_player(Vector3(34,.04,-12));var prior=g.suspicion;g._physics_process(.2)
 check(g.suspicion<prior,"suspicion falls after breaking the view cone")
 # The service gap and crate allow theft while guards remain alive.
 place_player(Vector3(42,.04,-10));g.position=Vector3(34,.04,-8);g.facing=Vector3.LEFT
 camp.guards[1].position=Vector3(52,.04,-17);camp.guards[1].facing=Vector3.RIGHT
 camp.guards[2].position=Vector3(48,.04,-26);camp.guards[2].facing=Vector3.FORWARD
 w.refresh_guard_context();w.story.act("c_east_open_cache")
 check(w.story.last_action_valid and w.story.f("east_cache_taken") and camp.guards.all(func(e):return e.hp>0),"a successful unseen approach can take the same reward without killing anyone")
 # Quiet movement changes actual velocity, without substituting Ivan's approved gait art.
 place_player(Vector3(20,.04,40));w.player.use_override=true;w.player.motion_override=Vector2.RIGHT;Input.action_press("sneak");w.player._physics_process(.2)
 check(w.player.sneaking and Vector2(w.player.velocity.x,w.player.velocity.z).length()<1.4,"Ctrl physically slows the player and retains the existing animation controller")
 Input.action_release("sneak");w.player.motion_override=Vector2.ZERO;w.player.use_override=false
 # Unprovoked firing is possible; ammunition is taken after the retry checkpoint.
 place_player(Vector3(32,.04,-21),true);camp.checkpoint={};var rounds=w.combat.clip;var supplies=w.story.economy.handmade
 w.combat.aim=Vector3(28,.8,-21);w.combat.cooldown=0;check(w.combat.shoot(),"manual weapons can be fired before any automatic encounter")
 check(camp.alarm and w.combat.active and w.combat.encounter=="grey_camp" and w.combat.clip==rounds-1,"nearby gunfire alerts the actual camp and consumes one round")
 check(w.combat.checkpoint.get("flags",{}).get("weapon_clip",0)==rounds,"checkpoint precedes the player's first provocative shot")
 for guard in camp.guards:guard.suspicion=.9;guard.last_known=Vector3(32,.04,-21)
 place_player(Vector3(-64,.04,46));camp.lost_time=10.1;camp._physics_process(.1)
 check(not camp.alarm and not w.combat.active and camp.guards.all(func(e):return e.suspicion==0),"breaking sight and retreating lets the player disengage and restores patrol behavior")
 # Save/load must not revive the first dead guard or lose the others' controllers.
 place_player(Vector3(32,.04,-21));camp.raise_alarm("测试");camp.guards[0].damage(1000,true);camp.guards[1].hp=39;camp.guards[2].route_index=2
 var snapshot=w.save_snapshot();check(Store.valid(snapshot),"live bandit combat and its pre-fight checkpoint use the supported save schema")
 get_root().get_node("Session").enter(snapshot,"east_district",w.player.position);await frames(10);w=current_scene;freeze();camp=w.grey_camp
 check(camp.guards[0].hp<=0 and camp.guards[1].hp==39 and camp.guards[2].route_index==2,"loading preserves the dead guard slot, injured guard and patrol progress")
 check(camp.alarm and w.combat.active and w.combat.enemies.all(func(e):return e.has_method("sees_player")),"restored combat replaces every guard with a perception controller")
 var goods=w.story.flags.raid_containers.values();check(goods.any(func(e):return e.loot.has("grey_carbine") and e.loot.has("mask")),"human guards leave searchable weapons and protective equipment")
 w.story.flags.east_home="commune";w.story.flags.east_trip_active=true;place_player(w.targets.east_commune_entry.pos)
 w.perform("c_east_enter_commune","east_commune_entry");await journey()
 check(w.floor_id=="commune" and not w.story.flags.get("east_retreat_encounter",{}).get("checkpoint",{}).is_empty(),"an actual indoor retreat retains the original pre-fight checkpoint")
 w.perform("c_east_depart_commune","commune_leave");await journey();camp=w.grey_camp
 check(w.floor_id=="east_district" and camp.alarm and camp.guards[0].hp<=0 and camp.guards[1].hp==39,"returning outdoors resumes the same partially resolved human encounter")
 var count_before=w.combat.enemies.size();w.combat.retry();check(w.combat.enemies.size()==count_before and w.story.f("raid_active"),"raid combat cannot invoke the old lossless checkpoint retry")
 camp.stand_down()
 w.combat.begin("east_road");camp.raise_alarm("测试混合遭遇")
 for enemy in w.combat.enemies.duplicate():
  if enemy.enemy_kind!="greyhound":enemy.damage(1000)
 place_player(Vector3(-64,.04,46));camp.lost_time=10.1;camp._physics_process(.1)
 check(not w.combat.active and w.story.f("battle_east_road") and not w.story.f("grey_camp_cleared"),"disengaging living bandits after killing nearby creatures correctly closes a mixed encounter")
 for guard in camp.guards.duplicate():guard.damage(1000,true)
 check(w.story.f("grey_camp_cleared") and w.story.f("battle_grey_camp") and not w.combat.active,"direct combat also resolves the inhabited camp")
 w.played_seconds+=1000;w.arrival_data.floor="commune";District.prepare(w)
 check(w.story.f("grey_camp_cleared") and w.story.f("battle_grey_camp"),"human camp residents are not recreated by the roaming-monster refresh timer")
 w.queue_free();await frames();print("STEALTH_V27_RESULT checks=",checks," failures=",failures);quit(0 if failures==0 else 1)
