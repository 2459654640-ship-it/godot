extends SceneTree
const Story=preload("res://scripts/story.gd")
const Campaign=preload("res://scripts/campaign.gd")
const Surface=preload("res://scripts/surface_site.gd")
var w
var checks=0
var failures=0
func _initialize():call_deferred("run")
func check(ok:bool,why:String):
 checks+=1
 if not ok:failures+=1;push_error(why)
func frames(n:int=4):
 for i in n:await physics_frame
func act(s,key:String):
 s.act("c_"+key);check(s.last_action_valid,"action allowed: "+key)
func level(id:String):
 w=load("res://scenes/"+id+".tscn").instantiate();root.add_child(w);current_scene=w;await frames(8)
 w.hud.close();w.story.flags.intro_done=true;w.set_physics_process(false);w.player.set_physics_process(false)
 if is_instance_valid(w.combat):w.combat.set_physics_process(false)
func run():
 var s=Story.new();s.context.floor="commune"
 check(not Campaign.available(s,"surface_accept"),"a casual greeting cannot silently accept the sortie")
 act(s,"surface_brief");check(not s.f("surface_job"),"asking about work only reveals an offer")
 act(s,"surface_accept");check(s.has("revolver") and s.f("surface_job"),"explicit acceptance issues the promised loan weapon")
 check(not Campaign.available(s,"surface_depart"),"surface departure requires a mask and filter")
 s.give("mask");s.give("filter");act(s,"surface_depart")
 check(s.f("surface_from_commune") and int(s.flags.surface_trip_id)==1,"sortie records the actual return settlement")
 await level("surface");w.story.restore(s.serialize());w.story.context.floor="surface";w.story.flags.comic={"active":false};w.hud.close()
 var c=w.combat;check(c.enabled and not is_instance_valid(c.veteran),"solo route has working combat without an invented companion")
 check(w.targets.has("surface_exit") and w.targets.has("surface_supply"),"a visible retreat and first supply station exist")
 act(w.story,"surface_supply_take");var reserve=w.story.economy.handmade
 w.story.act("c_surface_supply_take");check(not w.story.last_action_valid and reserve==w.story.economy.handmade,"initial ammunition cannot be claimed twice")
 w.story.act("c_surface_sample_take");check(not w.story.last_action_valid,"sampling cannot skip drainage and combat")
 act(w.story,"surface_notes");w.player.position=Vector3(-7,.04,3);c.begin("surface_yard")
 for enemy in c.enemies:enemy.set_physics_process(false)
 check(c.active and c.enemies.size()==3,"road encounter spawns three real enemies")
 var enemy=c.enemies[0];enemy.position=Vector3(-7,.04,0);await frames()
 w.toggle_weapon();var hp=enemy.hp;var currency=w.story.economy.military
 c.aim=enemy.position+Vector3.UP*.62;c.shoot();await frames()
 check(enemy.hp<hp and w.story.economy.military==currency,"physics shooting hits enemies without spending trading ammunition")
 for other in c.enemies.duplicate():other.damage(1000)
 await frames();check(w.story.f("battle_surface_yard") and not c.active,"clearing actual enemies unlocks the next puzzle")
 check(w.story.flags.surface_loot.size()==3,"every killed enemy creates a persistent resource record")
 var key=w.story.flags.surface_loot.keys()[0];var id="surface_loot_"+key
 var good:String=w.story.flags.surface_loot[key].good;var before=int(w.story.economy.goods.get(good,0))
 w.player.position=w.targets[id].pos;Surface.collect(w,id);Surface.collect(w,id)
 check(int(w.story.economy.goods.get(good,0))==before+1 and w.story.flags.surface_loot[key].taken,"nearby collection is applied exactly once")
 var roundtrip=Story.new();roundtrip.restore(JSON.parse_string(JSON.stringify(w.story.serialize())))
 check(roundtrip.flags.surface_loot==w.story.flags.surface_loot,"taken and uncollected drops survive a JSON save roundtrip")
 act(w.story,"surface_drain");await frames(85)
 check(w.story.f("surface_drain_open") and not w.get_node("SurfaceStandingWater").visible,"drainage changes visible standing water")
 w.player.position=Vector3(-5,.04,-7);c.begin("surface_pool")
 for other in c.enemies:other.set_physics_process(false)
 check(c.enemies.size()==4,"lower pool encounter has its own four-enemy wave")
 var checkpoint=c.checkpoint.duplicate(true);w.story.economy.handmade=0;c.clip=0;w.story.economy.health=1;c.bite(w.player,10)
 check(c.defeated and w.hud.modal_visible(),"combat death opens retry")
 c.retry();await frames(15);w=current_scene;c=w.combat;w.hud.close();w.set_physics_process(false);w.player.set_physics_process(false);c.set_physics_process(false)
 check(w.story.f("raid_active") and c.defeated and w.story.economy.health==0 and w.story.economy.handmade==0,"surface failure cannot invoke a lossless story checkpoint")
 # Continue exercising the independent puzzle and sample flow from the saved pre-fight state.
 root.get_node("Session").enter(checkpoint,"surface",Vector3(-5,.04,-7));await frames(15);w=current_scene;c=w.combat;w.hud.close();w.set_physics_process(false);w.player.set_physics_process(false);c.set_physics_process(false)
 check(w.story.f("battle_surface_yard") and w.story.flags.surface_loot[key].taken,"retry preserves previous encounter progress and collected loot")
 check(not w.targets.has(id) and w.targets.keys().filter(func(t):return String(t).begins_with("surface_loot_")).size()==2,"scene reload restores uncollected drops without duplicating the collected one")
 c.begin("surface_pool")
 for other in c.enemies.duplicate():other.set_physics_process(false);other.damage(1000)
 await frames();act(w.story,"surface_sample_take");check(w.story.has("pool_sample"),"completed puzzle and combat award the sealed quest sample")
 w.story.context.floor="commune";var pay=w.story.economy.military;act(w.story,"surface_turnin")
 check(not w.story.has("pool_sample") and w.story.economy.military==pay+10 and w.story.f("surface_done"),"turn-in consumes the quest sample and pays the agreed reward once")
 w.story.economy.military=100;w.story.economy.handmade=115;var n=int(w.story.economy.goods.get("ammo_pouch",0))
 w.story.Economy.buy(w.story,"ammo_pouch");check(int(w.story.economy.goods.get("ammo_pouch",0))==n+1,"merchant sells a usable ammunition pouch")
 w.story.Economy.consume(w.story,"ammo_pouch");check(w.story.economy.handmade==127,"ammunition is not clamped to the health/food cap")
 w.story.economy.goods.mutant_bone=1;pay=w.story.economy.military;w.story.Economy.sell(w.story,"mutant_bone")
 check(w.story.economy.military==pay+3,"monster resources can be sold for their stated price")
 w.story.flags.battle_surface_pool=true;w.story.context.floor="commune";act(w.story,"surface_depart")
 check(not w.story.f("battle_surface_yard") and not w.story.f("battle_surface_pool") and w.story.flags.surface_loot.is_empty() and w.story.f("surface_supply_taken"),"a repeat sortie resets encounters while retaining the claimed first kit")
 # Retreat is a real usable route even while enemies remain alive.
 w.story.context.floor="surface";w.player.position=w.targets.surface_exit.pos;c.begin("surface_yard")
 for other in c.enemies:other.set_physics_process(false)
 var retreat_ammo=w.story.economy.handmade
 w.interact("surface_exit");check(w.hud.dialogue_id=="surface_exit","live combat still permits interaction with the retreat ladder")
 w.perform("c_surface_back_commune","surface_exit");check(w.hud.comic_active,"retreat choice starts the return journey during combat")
 for retreat_frame in 8:
  if w.hud.comic_active:w.hud.comic_choose()
  await frames(10);w=current_scene
  if w.floor_id in ["commune","east_district"]:break
 check(w.floor_id=="east_district","pump retreat first returns to the physical surface route")
 w.set_physics_process(false);w.player.set_physics_process(false);w.player.position=w.targets.east_commune_entry.pos
 w.perform("c_east_enter_commune","east_commune_entry")
 for retreat_frame in 8:
  if w.hud.comic_active:w.hud.comic_choose()
  await frames(10);w=current_scene
  if w.floor_id=="commune":break
 check(w.floor_id=="commune" and w.story.economy.handmade==retreat_ammo and w.story.f("surface_supply_taken"),"retreat actually reaches the originating settlement without inventing or removing ammunition")
 w.queue_free();await frames()
 # Legacy access and ending flags must not reopen the archived interior.
 await level("starcity");w.story.flags.star_access=true;w.story.flags.father_met=true;w.on_story_changed();await frames()
 check(w.npcs.is_empty() and not is_instance_valid(w.campaign_gate),"perimeter contains no internal NPCs or unlockable inner gate")
 check(not w.targets.has("father") and w.targets.has("star_perimeter_call"),"only exterior contact is available")
 for a in Campaign.data().unreleased_star_actions:check(not Campaign.available(w.story,a),"archived action stays closed with legacy access: "+a)
 act(w.story,"star_perimeter_name");check(w.story.f("star_inquiry_filed") and not Campaign.available(w.story,"father_meet"),"leaving an inquiry does not grant admission")
 w.player.camera=null;w.player.use_override=true;w.player.position=Vector3(0,.04,1.5);w.player.motion_override=Vector2.UP;w.player.set_physics_process(true);await frames(75)
 check(w.player.position.z>.30,"the actual player controller cannot cross the sealed perimeter")
 w.player.motion_override=Vector2.ZERO;w.queue_free();await frames()
 print("EXPEDITION_V19_RESULT checks=",checks," failures=",failures);quit(0 if failures==0 else 1)
