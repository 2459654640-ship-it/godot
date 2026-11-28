extends SceneTree
const Story=preload("res://scripts/story.gd")
const Raid=preload("res://scripts/raid_loot.gd")
const Bag=preload("res://scripts/backpack.gd")
const Catalog=preload("res://scripts/salvage_catalog.gd")
const Expedition=preload("res://scripts/district_expedition.gd")
const Store=preload("res://scripts/save_store.gd")
const FieldLoot=preload("res://scripts/ui_field_loot.gd")
var w
var checks=0
var failures=0

func _initialize():call_deferred("run")
func check(ok:bool,description:String):
 checks+=1
 if not ok:failures+=1;push_error(description)
func frames(count:int=3):
 for i in count:await physics_frame
func freeze():
 w.set_physics_process(false);w.player.set_physics_process(false);w.combat.set_physics_process(false)
 if is_instance_valid(w.grey_camp):
  w.grey_camp.set_physics_process(false)
  for guard in w.grey_camp.guards:
   if is_instance_valid(guard):guard.set_physics_process(false)
 w.hud.comic_active=false;w.hud.close()
func load_floor(floor:String,snapshot:Dictionary,at:Vector3=Vector3.INF):
 root.get_node("Session").pending={"story":snapshot,"floor":floor,"position":at}
 w=load("res://scenes/"+floor+".tscn").instantiate()
 root.add_child(w);current_scene=w
 await frames()
 freeze()
func pause_enemies():
 for enemy in w.combat.enemies:
  if is_instance_valid(enemy):enemy.set_physics_process(false)

func run():
 var s=Story.new()
 s.flags.merge({"intro_done":true,"east_crossing_open":true,"east_power_restored":true,"city_basin_open":true,"east_home":"commune","social_seed":751801})
 s.give("mask");s.give("filter");s.give("revolver");s.equip_weapon("revolver")
 check(Catalog.ITEMS.size()==32,"The salvage catalog exposes 32 original goods")
 for id in Catalog.ITEMS:
  check(ResourceLoader.exists("res://assets/visual/item_"+id+".png"),"Distinct imported item texture "+id)
 check(Bag.size_of("pocket_watch")==Vector2i.ONE and Bag.size_of("pressure_gauge")==Vector2i(2,2) and Bag.size_of("drive_belt")==Vector2i(3,1) and Bag.size_of("oilcloth_roll")==Vector2i(3,2),"Four representative items have different actual dimensions")
 s.economy.goods={"pocket_watch":1,"drive_belt":1}
 s.flags.bag_layout={"pocket_watch:0":[0,0,false],"drive_belt:0":[7,0,true]}
 var packed=Bag.pack(s,{"oilcloth_roll":1})
 check(packed.used==10 and packed.overflow.is_empty(),"A watch, belt, and oilcloth actually consume ten cells")
 check(packed.pieces.any(func(p):return p.key=="drive_belt:0" and p.size==Vector2i(1,3) and p.at==Vector2i(7,0)),"A new bulky piece preserves a previously rotated belt")
 check(packed.pieces.any(func(p):return p.key=="pocket_watch:0" and p.at==Vector2i.ZERO),"New large objects cannot move deliberately placed small objects")
 check(not Bag.move_piece(s,"drive_belt:0",Vector2i(7,0),true),"Rotation still requires a continuous free area")
 var money:int=s.economy.military
 s.Economy.sell(s,"pocket_watch")
 check(s.economy.military==money+22 and Bag.count(s,"pocket_watch")==0,"A small valuable can be sold at its actual buyback")
 s.economy.goods={}
 s.flags.bag_layout={}
 Raid.begin(s,"commune")
 var initial=Expedition.deployment(s)
 Raid.begin(s,"commune")
 check(Expedition.deployment(s)==initial and s.flags.raid_index==1,"Entering the same raid does not reroll routes")
 var serialized=JSON.parse_string(JSON.stringify(s.serialize()))
 var restored=Story.new();restored.restore(serialized)
 check(Expedition.deployment(restored)==initial and Expedition.wildlife(restored)==Expedition.wildlife(s),"JSON save preserves patrol and wildlife deployment")
 await load_floor("east_district",s.serialize())
 var visited=w.targets.keys().filter(func(id):return id.begins_with("raid_container_"))
 check(visited.size()==71,"The district has 71 physically instantiated search targets")
 check(w.combat.encounters.keys().filter(func(id):return id.begins_with("raid_")).size()==7,"Seven optional wildlife encounters are staged in different locations")
 check(w.grey_camp.guards.size()==10 and w.grey_camp.groups.size()==6,"Three camp sentries plus seven wanderers have six independent groups")
 check(Raid.extraction(w.story).id=="east_commune_entry","The map knows the extraction appropriate to the current sortie")
 var id="raid_container_dispatch_ticket"
 var front:Vector3=w.targets[id].pos
 var distant=front+Vector3(0,0,5)
 w.player.position=distant;Raid.update_contours(w,"")
 check(not w.loot_contours[id].visible,"Distant container has no outline")
 w.player.position=front;w.find_nearest()
 check(w.loot_contours[id].visible and Raid.can_reach(w,id,1.7),"Approaching an unobstructed physical container illuminates its edge")
 w.interact(id)
 Raid.tick(w,.5)
 check(not Raid.record(w,id).searched and not w.hud.modal_visible() and w.loot_progress.visible,"Search has a real in-world timer rather than freezing combat")
 w.player.position=front+Vector3(.46,0,0);Raid.tick(w,.2)
 check(w.loot_search.is_empty() and not Raid.record(w,id).searched,"Movement interrupts search without opening the container")
 w.player.position=front;w.interact(id)
 Raid.tick(w,3.0)
 check(Raid.record(w,id).searched and w.hud.modal_visible() and w.hud.get_meta("fixed_screen","")=="field_transfer","Completing the timer opens the actual loot transfer screen")
 await frames()
 check(w.hud.modal.find_child("InventoryGrid",true,false)!=null,"The destination grid is visible during the transfer")
 var transfer_grid=w.hud.modal.find_child("InventoryGrid",true,false)
 check(transfer_grid.field_style and w.hud.modal.find_children("*","ScrollContainer",true,false).is_empty(),"Field transfer uses a fixed container and the complete pack grid")
 var before_shelf=w.story.flags.get("bag_layout",{}).duplicate(true)
 var incoming=FieldLoot.preview(w.story,Bag.pack(w.story),"oilcloth_roll")
 check(incoming.get("size")==Vector2i(3,2) or incoming.get("size")==Vector2i(2,3),"A bulky find visibly previews six contiguous cells")
 check(w.story.flags.get("bag_layout",{})==before_shelf and Bag.count(w.story,"oilcloth_roll")==0,"Preview keeps both inventory and saved placement intact")
 Bag.change(w.story,"oilcloth_roll",1)
 var added=Bag.pack(w.story).pieces.filter(func(piece):return piece.id=="oilcloth_roll")
 check(not added.is_empty() and added[0].at==incoming.get("at") and added[0].size==incoming.get("size"),"Transfer preview matches the real item placement")
 Bag.change(w.story,"oilcloth_roll",-1)
 Bag.change(w.story,"sterile_gauze",1)
 var merged=FieldLoot.preview(w.story,Bag.pack(w.story),"sterile_gauze")
 check(merged.get("key")=="sterile_gauze:0" and not merged.has("at"),"Stackable medicine highlights the existing stack")
 Bag.change(w.story,"sterile_gauze",-1)
 var goods:Dictionary=Raid.record(w,id).loot.duplicate()
 var find:String=goods.keys()[0]
 check(Raid.take(w,id,find) and Bag.count(w.story,find)==1,"One searched item transfers once")
 check(Raid.store(w,id,find) and Bag.count(w.story,find)==0 and Raid.record(w,id).loot==goods,"Putting loot back preserves its quantity and cache")
 w.hud.close();w.player.position=distant
 check(not Raid.take(w,id,find),"Remote looting is rejected")
 var saved=w.save_snapshot()
 check(Store.valid(saved),"New loot and patrol flags serialize through the real save schema")
 w.queue_free();await frames()
 await load_floor("east_district",JSON.parse_string(JSON.stringify(saved)),front)
 var reloaded:Dictionary=Raid.record(w,id)
 var same_amounts=goods.keys().all(func(item):return int(reloaded.loot.get(item,0))==int(goods[item]))
 check(reloaded.searched and reloaded.loot.size()==goods.size() and same_amounts,"Same-trip reload keeps an opened container and exact contents")
 var camp=w.grey_camp
 var heavy=camp.groups.east_patrol.guards[0]
 check(heavy.hp==120 and heavy.shot_harm==17,"The heavy wanderer has a distinct health and rifle profile")
 camp.raise_alarm("west_pair",w.player.position,"测试")
 check(camp.groups.west_pair.alarm and not camp.groups.east_patrol.alarm and not camp.groups.camp.alarm,"Hearing one squad does not alert the rest of the map")
 var reserve:int=w.story.economy.handmade
 w.combat.begin("raid_east_service");pause_enemies()
 check(w.combat.enemies.any(func(e):return e.enemy_kind=="spitter") and w.combat.enemies.any(func(e):return e.enemy_kind=="greyhound"),"Wildlife can enter the encounter while a roaming rifle squad remains")
 check(w.story.economy.handmade==reserve and w.combat.checkpoint.is_empty(),"Optional street combat neither gives free rounds nor creates a lossless retry")
 for enemy in w.combat.enemies.duplicate():
  if enemy.enemy_kind!="greyhound":enemy.damage(1000,true)
 check(w.story.f("battle_raid_east_service") and w.combat.active and w.combat.encounter=="grey_camp","Killing the beasts completes the local encounter without disengaging the rifle patrol")
 camp.stand_down("west_pair")
 check(not w.combat.active and not camp.alarm,"Disengaging a single group clears combat when no threat remains")
 heavy.damage(1000,true);camp.stand_down("east_patrol");await frames(155)
 check(w.story.flags.raid_containers.values().any(func(rec):return rec.dropped and rec.loot.has("grey_carbine") and rec.loot.has("handmade")),"The heavy wanderer leaves a searchable supply and weapon bag after its actor despawns")
 check(not w.story.f("grey_camp_cleared"),"A dead wanderer cannot resolve the separate camp")
 w.player.position=front;check(Raid.take(w,id,find),"Goods are available for the actual return journey")
 var extracted=w.save_snapshot()
 w.queue_free();await frames()
 await load_floor("commune",extracted)
 check(w.raid_extracted and not w.story.f("raid_active") and w.story.flags.raid_return.items.get(find)==1,"Entering the settlement ends the expedition and keeps the carried finds")
 check(not w.story.flags.has("east_retreat_encounter"),"Leaving through extraction clears the active field combat state")
 Raid.begin(w.story,"commune")
 check(w.story.flags.raid_index==2 and w.story.flags.raid_containers.is_empty() and not w.story.f("battle_raid_east_service"),"A genuine new expedition resets local wildlife and reinitializes cache records")
 check(Expedition.deployment(w.story)!=initial,"The next seeded trip changes the patrol deployment in this fixture")
 w.story.economy.stashes={"commune":{"pocket_watch":1}}
 w.story.give("photo")
 Raid.resolve_loss(w.story)
 check(w.story.economy.goods.is_empty() and w.story.has("photo") and w.story.economy.stashes.commune.pocket_watch==1,"Defeat removes carried salvage while keeping protected documents and banked goods")
 w.queue_free();await frames()
 print("DISTRICT_EXPEDITION_V38_RESULT checks=",checks," failures=",failures)
 quit(1 if failures else 0)
