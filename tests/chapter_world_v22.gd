extends SceneTree
const Story=preload("res://scripts/story.gd")
const Front=preload("res://scripts/frontline.gd")
const Store=preload("res://scripts/save_store.gd")
var checks=0
var failures=0
func _initialize():call_deferred("run")
func check(ok:bool,msg:String):
 checks+=1
 if not ok:failures+=1;push_error(msg)
func frames(n:int=5):
 for i in n:await physics_frame
func reachable(w)->Dictionary:
 var g=w.navigation.graph;var start=g.get_closest_point(Vector2(w.player.position.x,w.player.position.z));var seen={start:true};var pending=[start];var i=0
 while i<pending.size():
  var at=pending[i];i+=1
  for next in g.get_point_connections(at):
   if not seen.has(next):seen[next]=true;pending.append(next)
 return seen
func run():
 var s=Story.new();s.flags.field_mission="c3";s.flags.field_c3_in_progress=true;s.flags.field_c3_routes=true;s.flags.intro_done=true;s.flags.commune_member=true;s.give("revolver");s.give("mask");s.give("filter")
 root.get_node("Session").pending={"story":s.serialize(),"floor":"railfront","position":Vector3(0,.04,18)}
 var w=load("res://scenes/railfront.tscn").instantiate();root.add_child(w);current_scene=w;await frames(10);w.hud.close();w.set_physics_process(false);w.player.set_physics_process(false)
 check(w.initialized and w.combat.enabled and w.combat.encounters.size()==2,"new playable station starts with this sortie's encounters")
 check(w.npcs.size()>=3,"station has sheltered noncombatants")
 var seen=reachable(w);check(seen.size()>4000,"new station has a substantial connected exploration area")
 for id in w.targets:
  var end:Vector3=w.targets[id].pos+Vector3.UP*1.2;var visible=false
  for at in seen:
   var p:Vector2=w.navigation.graph.get_point_position(at)
   if p.distance_to(Vector2(end.x,end.z))>1.6:continue
   var ray=w.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(p.x,1.2,p.y),end,1))
   if ray.is_empty() or ray.position.distance_to(end)<.48:visible=true;break
  check(visible,"reachable interaction with an unobstructed sight line: "+id)
 # Actual player capsule traverses the X-plane control-room doorway both ways.
 w.player.camera=null;w.player.use_override=true;w.player.set_physics_process(true)
 for sign in [-1,1]:
  w.player.position=Vector3(10+sign*1.4,.04,13);w.player.velocity=Vector3.ZERO;w.player.motion_override=Vector2(-sign,0);await frames(65);w.player.motion_override=Vector2.ZERO
  check((w.player.position.x-10)*sign<-.35,"control-room doorway traversable in both directions")
 w.player.use_override=false;w.player.set_physics_process(false);w.player.position=Vector3(-18,.04,-5);w.combat.set_physics_process(false)
 w.story.economy.handmade=0;w.combat.clip=0;w.combat.begin("c3_west");await frames(2)
 check(w.combat.enemies.size()==3 and w.combat.enemies.all(func(e):return e.enemy_kind=="soldier"),"late sortie actually includes armed opponents")
 check(w.story.economy.handmade>=12,"main combat preserves a minimum ammunition supply")
 var before=w.story.economy.health;var enemy=w.combat.enemies[0]
 check(is_equal_approx(enemy.sprite.pixel_size*324,1.77) and is_equal_approx(enemy.sprite.scale.x,.762),"armed opponent uses the same world height and projection proportions as resident actors")
 for e in w.combat.enemies:e.set_physics_process(false);e.collision_layer=0
 enemy.position=Vector3(-18,.04,-8);enemy.target_body=w.player;enemy.windup=.01
 enemy.soldier_tick(.02,w.player.position-enemy.position)
 check(w.story.economy.health==before-12,"armed opponent's warned shot damages player through an open sight line")
 var checkpoint=w.combat.checkpoint.duplicate(true);w.story.economy.handmade=0;w.story.economy.health=1;w.combat.retry();await frames(12);w=current_scene
 check(w.story.economy.handmade==checkpoint.economy.handmade and w.story.economy.health==checkpoint.economy.health,"retry restores the actual pre-fight resources")
 var data=w.save_snapshot();check(Store.valid(data),"save validator supports ninth map")
 w.queue_free();await frames()
 # The mine has Anna beside her brother before the operation; the return has the living brother.
 for outcome in ["preparation","alive","dead"]:
  s=Story.new();s.flags.intro_done=true;s.flags.anna_rescue_started=true;s.flags.coal_access=true
  var floor="coal" if outcome=="preparation" else "commune"
  if outcome!="preparation":s.flags.anna_outcome_done=true;s.flags["anna_"+outcome]=true
  root.get_node("Session").pending={"story":s.serialize(),"floor":floor,"position":Vector3(-13,.04,10) if floor=="coal" else Vector3(25,.04,2)}
  w=load("res://scenes/"+floor+".tscn").instantiate();root.add_child(w);current_scene=w;await frames(8);w.hud.close();w.set_physics_process(false)
  if outcome=="preparation":
   check(w.npcs.has("mine_anna") and w.targets.has("mine_anna"),"Anna is physically present during mine preparation")
   w.story.act("c_rescue_air_map");w.story.act("c_rescue_air_open");await frames(75)
   check(w.get_node("MineEscapeGrille").position.x> -21,"backup mine gate opens with a visible animation")
  else:
   check(w.npcs.has("commune_aleksei"),"brother is present after evacuation "+outcome)
   check(w.npcs.has("commune_anna")== (outcome=="alive"),"death cannot leave a talking living Anna in the world")
   check(w.targets.has("commune_class"),"classroom aftermath remains accessible")
  w.queue_free();await frames()
 print("CHAPTER_WORLD_V22_RESULT checks=",checks," failures=",failures);quit(0 if failures==0 else 1)
