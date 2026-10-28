extends SceneTree
const Bag=preload("res://scripts/backpack.gd")
const Raid=preload("res://scripts/raid_loot.gd")
const Story=preload("res://scripts/story.gd")
const Store=preload("res://scripts/save_store.gd")
var failures=0
var checks=0
var w
func _initialize():call_deferred("run")
func check(ok:bool,why:String):
 checks+=1
 if not ok:failures+=1;push_error(why)
func frames(n=3):
 for i in n:await physics_frame
func freeze():
 w.set_physics_process(false);w.player.set_physics_process(false);w.combat.set_physics_process(false);w.grey_camp.set_physics_process(false)
 for g in w.grey_camp.guards:g.set_physics_process(false)
 w.story.flags.intro_done=true;w.story.flags.comic={"active":false};w.hud.comic_active=false;w.hud.close()
func run():
 var s=Story.new();s.economy.goods={"medkit":2,"bandage":4,"scrap_metal":5}
 var packed=Bag.pack(s,{},true);check(packed.overflow.is_empty() and packed.used==14,"bounded stacks occupy actual rectangles")
 check(packed.pieces.filter(func(p):return p.id=="bandage").size()==2,"bandage stack cap splits four into two pieces")
 var first=packed.pieces[0];check(not Bag.move_piece(s,first.key,Vector2i(7,5)),"multi-cell item cannot cross backpack edge")
 var save=JSON.parse_string(JSON.stringify(s.serialize()));var loaded=Story.new();loaded.restore(save);check(Bag.pack(loaded).used==packed.used and Bag.pack(loaded).pieces==packed.pieces,"grid positions survive JSON saves")
 s.economy.goods={"medkit":30};check(not Bag.can_add(s,"bandage"),"full or legacy-overflow backpack rejects new loot")
 s.economy.goods={"bread":2};s.give("photo");s.give("pool_sample");s.give("mask");s.give("revolver");s.economy.stashes={"commune":{"medkit":3,"military":20}};Raid.begin(s,"commune")
 var trip=s.flags.raid_index;Raid.begin(s,"commune");check(s.flags.raid_index==trip,"reloading or reentering active trip never changes loot seed")
 var losses=Raid.resolve_loss(s);check(not losses.is_empty() and s.economy.goods.is_empty() and not s.has("mask") and not s.has("revolver") and s.economy.military==0,"surface failure actually loses carried gear, goods and ammunition")
 check(s.has("photo") and s.has("pool_sample") and s.economy.stashes.commune.medkit==3 and s.economy.stashes.commune.military==20,"story keepsakes, mandatory items and deposited supplies survive")
 check(Raid.resolve_loss(s)==losses,"loss settlement is idempotent")
 w=load("res://scenes/east_district.tscn").instantiate();root.add_child(w);current_scene=w;await frames();freeze()
 check(w.get_node_or_null("SiteBoundary")==null,"city no longer enclosed by the generic square perimeter wall")
 var plan=preload("res://scripts/east_district.gd").layout()
 var map_builder=preload("res://scripts/east_district_map.gd")
 for parcel in plan.parcels:
  var b=parcel.building
  check(not map_builder.road_conflict(plan,Vector3(b[0],0,b[1]),Vector2(b[2],b[3])),"authored building clears every road: "+parcel.id)
 check(w.navigation.points.size()>25000 and w.navigation.points.size()<48000,"city district graph covers rebuilt layout at bounded density")
 check(w.grey_camp.guards.size()==5,"camp sentries and separate street scavengers both exist")
 for target_id in ["city_clinic","city_medicine","city_radio_log","city_radio_panel","raid_container_clinic_drawer","east_mine_entry"]:
  var target:Vector3=w.targets[target_id].pos;var path=w.navigation.path(w.player.position,target)
  check(not path.is_empty() and path[-1].distance_to(target)<1.7,"walkable approach to "+target_id)
 check(w.targets.has("grey_shelter_entry") and w.targets.has("raid_container_clinic_drawer"),"actual shelter entrance and searchable city containers exist")
 for id in ["city_clinic","city_medicine","city_radio_log","city_radio_panel","city_basin_controls","city_basin_supplies"]:
  check(w.targets.has(id),"authored exploration interaction exists: "+id)
 var event=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_WHEEL_DOWN;event.pressed=true;w.interaction_candidates.clear()
 for i in 50:w._unhandled_input(event)
 w.set_camera(0,true);check(w.camera.size<=19,"normal mouse wheel never reveals district overview")
 w.overview=true;w.set_camera(0,true);check(not w.overview and w.camera.size<=19,"old overview state cannot leak into normal play")
 var tab=InputEventAction.new();tab.action="overview";tab.pressed=true;w._unhandled_input(tab);check(w.hud.modal_visible() and not w.overview,"Tab opens journal map")
 w.hud.close();w.story.give("revolver");w.story.equip_weapon("revolver");w.story.economy.goods={"medkit":2,"bandage":4};w.hud.show_inventory();await frames()
 check(w.hud.modal.find_child("InventoryGrid",true,false).columns==8,"inventory exposes actual eight-column placement grid")
 var scroll:ScrollContainer=w.hud.modal_box.get_parent();scroll.scroll_vertical=150
 preload("res://scripts/ui_inventory.gd").render(w.hud,"all","revolver");await frames(2)
 check(w.hud.modal_box.get_parent().scroll_vertical>0,"switching inventory section retains scroll position")
 w.hud.close()
 var seen=w.story.flags.get("city_seen",{});check(seen.size()>0 and seen.size()<30,"starting discovery only reveals local reachable sight cells")
 check(not preload("res://scripts/city_survey.gd").known(w.story,Vector2(95,-65)),"reservoir is unknown at station start")
 var id="raid_container_clinic_drawer";w.player.position=w.targets[id].pos
 var rec=w.story.flags.raid_containers["east_district:clinic_drawer"];var before=rec.loot.duplicate();rec.searched=true
 var good:String=rec.loot.keys()[0];var count=Bag.count(w.story,good);check(Raid.take(w,id,good),"searched container transfers an item when nearby and safe");check(Bag.count(w.story,good)==count+1,"loot adds exact quantity")
 Raid.add(w,"clinic_drawer","same",Vector3(-75,0,34),"medical");check(rec.loot!=before,"rebuilding container does not reroll collected contents")
 w.player.position=Vector3(-64,.04,46);check(not Raid.take(w,id,good),"cannot loot a container remotely")
 w.story.context.floor="east_district";w.story.act("c_city_radio_power");check(not w.story.last_action_valid,"radio cannot power on before isolated and supplied")
 for action in ["city_clinic_read","city_medicine_leave","city_radio_read","city_radio_isolate"]:w.story.act("c_"+action);check(w.story.last_action_valid,"narrative action: "+action)
 w.story.act("c_city_medicine_take");check(not w.story.last_action_valid,"medical supply choice cannot be claimed after leaving it")
 w.story.flags.east_power_restored=true
 for action in ["city_radio_power","city_radio_test","city_basin_inspect","city_basin_bypass","city_basin_open"]:w.story.act("c_"+action);check(w.story.last_action_valid,"ordered equipment action: "+action)
 w.hud.close();w.player.position=Vector3(90,.04,-58);w.combat.begin("city_basin")
 var boss=w.combat.enemies[0];boss.set_physics_process(false);boss.arrival_time=0
 check(boss.enemy_kind=="behemoth" and boss.sprite.vframes==7 and boss.hp==460,"unique animated reservoir boss is playable")
 boss.target_body=w.player;boss.position=Vector3(90,.04,-65);boss.cooldown=0;boss.boss_tick(.016,w.player.position-boss.position)
 check(boss.windup>1 and is_instance_valid(boss.warning),"boss telegraphs a locked-direction charge")
 var state=w.combat.serialize_state();check(Store.valid_combat(state),"boss charge state passes save validation")
 boss.hp=200;boss.windup=0;boss.cooldown=0;boss.boss_round=1;boss.boss_tick(.016,w.player.position-boss.position);check(boss.boss_mode=="spit","wounded boss alternates a different attack")
 w.combat.restore_state(JSON.parse_string(JSON.stringify(state)));await frames();freeze();check(w.combat.enemies[0].boss_mode=="charge" and w.combat.enemies[0].windup>0,"saving during windup restores exact attack")
 w.combat.enemies[0].damage(1000);check(w.story.f("battle_city_basin") and w.story.f("city_basin_rewarded"),"boss death resolves optional objective and reward")
 var reward=w.story.economy.military;w.story.Campaign.District.cleared(w,"city_basin");check(w.story.economy.military==reward,"boss reward cannot duplicate")
 check(Store.valid(w.save_snapshot()),"complete city state uses supported save schema")
 w.story.flags.raid_home="commune";w.story.give("photo");w.story.give("pool_sample");w.story.economy.stashes={"commune":{"medkit":2,"military":16}}
 w.combat.bite(w.player,1000);check(w.combat.defeated and w.hud.modal_visible(),"surface death opens the loss screen")
 Raid.return_after_loss(w);await frames(12)
 while current_scene==null:await process_frame
 w=current_scene;w.set_physics_process(false);w.player.set_physics_process(false);w.hud.comic_active=false;w.hud.close()
 check(w.floor_id=="commune" and w.story.economy.health==45 and not w.story.f("raid_active"),"actual defeat returns to origin settlement")
 check(w.story.economy.goods.is_empty() and not w.story.has("revolver") and w.story.has("pool_sample") and w.story.has("photo") and w.story.economy.stashes.commune.medkit==2,"cross-scene loss preserves protected inventory and stash only")
 check(int(w.story.flags.weapon_clip)==0,"defeat cannot restore rounds from old combat snapshot")
 w.queue_free();await frames();root.get_node("Session").pending={}
 w=load("res://scenes/grey_shelter.tscn").instantiate();root.add_child(w);current_scene=w;await frames();freeze()
 check(w.targets.has("grey_shelter_exit") and w.grey_camp.guards.size()==2 and w.combat.enabled,"underground bandit shelter contains exit, armed occupants and combat")
 check(w.targets.has("raid_container_shelter_food") and w.targets.has("raid_container_shelter_bunks"),"shelter has multiple meaningful container types")
 check(Store.valid(w.save_snapshot()),"shelter is a valid independently saved scene")
 w.queue_free();await frames();print("CITY_V29_RESULT ",checks," checks / ",failures," failures");quit(1 if failures else 0)
