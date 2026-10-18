extends SceneTree
var w
var checks=0
var failures=0
func _initialize():call_deferred("run")
func check(ok:bool,why:String):
 checks+=1
 if not ok:failures+=1;push_error(why)
func frames(n:int=4):
 for i in n:await physics_frame
func run():
 w=load("res://scenes/waterworks.tscn").instantiate();root.add_child(w);current_scene=w;await frames(8)
 w.hud.close();w.story.flags.intro_done=true;w.set_physics_process(false);w.player.set_physics_process(false)
 var c=w.combat;c.set_physics_process(false);w.npcs.plant_veteran.set_physics_process(false)
 check(c.enabled and w.story.has("revolver") and w.story.economy.handmade>=30,"squad issues functional weapon and minimum ammunition")
 check(w.story.economy.goods.get("antirad",0)>=1 and w.story.economy.goods.get("bandage",0)>=2,"first expedition has medicine without purchasing")
 w.story.flags.plant_diagram=true;w.player.position=Vector3(-13,.04,-2);c.begin("pump");await frames()
 check(c.active and c.enemies.size()==3 and c.checkpoint.position[0]==-13,"room encounter makes an exact pre-fight checkpoint")
 w.toggle_weapon()
 for enemy in c.enemies:enemy.set_physics_process(false)
 var enemy=c.enemies[0];enemy.position=Vector3(-13,.04,-5);await frames()
 var military=w.story.economy.military;var hp=enemy.hp;var clip=c.clip
 c.aim=enemy.position+Vector3.UP*.62;c.shoot();await frames()
 check(enemy.hp<hp and c.clip==clip-1,"actual physics ray hits a creature and spends a chambered bullet")
 check(w.story.economy.military==military,"shooting never spends currency ammunition")
 c.cooldown=0
 var obstruction=w.kit.box("TestShotBarrier",Vector3(-13,.65,-3.5),Vector3(2,1.3,.2),"metal",true);await frames()
 hp=enemy.hp;c.shoot();await frames();check(enemy.hp==hp,"wall physics blocks bullets")
 obstruction.queue_free();await frames()
 c.clip=0;c.reload_weapon();check(c.reload_time>1,"reload has a real timed state")
 var reserve=w.story.economy.handmade
 c.reload_time=.01;c._physics_process(.02)
 check(c.clip==6 and w.story.economy.handmade==reserve-6,"reload transfers exact rounds from reserve")
 c.veteran.position=Vector3(-12,.04,-2);c.veteran_cooldown=0;hp=enemy.hp;c.follow_veteran(.1);await frames()
 check(enemy.hp<hp,"veteran actually damages a visible enemy")
 c.veteran_health=1;c.bite(c.veteran,10);check(c.veteran_health==0 and c.veteran_down,"veteran can be downed")
 w.player.position=c.veteran.position+Vector3(1,0,0);c.rescue=1.99;Input.action_press("interact");c._physics_process(.05);Input.action_release("interact")
 check(c.veteran_health==45 and not c.veteran_down,"held nearby interaction rescues companion")
 w.player.position=Vector3(-12,.04,-2);c.veteran.position=Vector3(-12,.04,-2.9);w.player.velocity=Vector3(0,0,-1)
 c.follow_veteran(.05)
 check(c.veteran.yield_time>0 and c.veteran.combat_velocity.length()>1,"following companion steps aside when approached instead of blocking a narrow passage")
 # Actual exposure is paused while reading; antirad can remove accumulated dose.
 w.player.position=Vector3(-16,.04,-12);w.player.velocity=Vector3(1,0,0);w.story.flags.radiation_clock=4.99
 var radiation=w.story.economy.radiation;c._physics_process(.05)
 check(w.story.economy.radiation==radiation+2,"contaminated sediment creates radiation while traversing")
 w.hud.show_inventory();radiation=w.story.economy.radiation;c._physics_process(15)
 check(w.story.economy.radiation==radiation,"reading inventory does not advance radiation or combat")
 w.hud.close();w.story.Economy.consume(w.story,"antirad");check(w.story.economy.radiation==0,"antirad removes actual field exposure")
 # Clear the wave using the same enemy damage/death callback as shooting.
 for other in c.enemies.duplicate():
  if is_instance_valid(other):other.damage(200)
 await frames();check(not c.active and w.story.f("battle_pump"),"wave completion unlocks exploration once")
 c.begin("pump");check(not c.active,"cleared encounter cannot farm supplies or respawn")
 w.story.flags.plant_bled=true;w.player.position=Vector3(-2,.04,-3);c.begin("workshop")
 for other in c.enemies:other.set_physics_process(false)
 var saved=c.checkpoint.duplicate(true);w.story.economy.handmade=0;w.story.economy.health=5;c.clip=0;c.bite(w.player,10)
 check(w.story.economy.health==0 and w.hud.modal_visible(),"death opens retry interface instead of ending or deleting the run")
 c.retry();await frames(12);w=current_scene;c=w.combat;c.set_physics_process(false);w.hud.close()
 check(w.story.economy.health==saved.economy.health and w.story.economy.handmade==saved.economy.handmade and c.clip==int(saved.flags.weapon_clip),"retry restores exact health, chamber and reserve without extra cost")
 check(w.story.f("battle_pump") and not w.story.f("battle_workshop"),"retry preserves earlier cleared encounters and retries only current wave")
 # Movement order: guard reaches the inspection point directly, no routine/yield detours.
 w.queue_free();await frames();w=load("res://scenes/d6.tscn").instantiate();root.add_child(w);current_scene=w;await frames(6);w.hud.close();w.story.flags.intro_done=true;w.player.position=Vector3(-3,.04,1.4)
 w.story.flags.guard_task=true;var guard=w.npcs.igor;var previous=guard.position;var length=0.0
 for frame in 600:
  await physics_frame;length+=guard.position.distance_to(previous);previous=guard.position
  if w.story.guard_clear():break
 check(w.story.guard_clear() and guard.position.z<2.6,"Igor reaches the out-of-sight inspection position")
 check(length<12 and guard.yield_time<=0 and guard.patrol.is_empty(),"Igor's ordered path has no wandering or yielding detour: "+str(length))
 w.queue_free();await frames()
 print("V11_COMBAT_RESULT checks=",checks," failures=",failures)
 quit(0 if failures==0 else 1)
