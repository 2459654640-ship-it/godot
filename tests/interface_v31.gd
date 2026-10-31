extends SceneTree
const UI=preload("res://scripts/ui_workbench.gd")
var checks=0
var failures=0
var w
func _initialize():call_deferred("run")
func frames(n:int=5):
 for i in n:await physics_frame
func check(ok:bool,message:String):
 checks+=1
 if not ok:failures+=1;push_error(message)
func button(text:String):
 var matches=w.hud.modal.find_children("*","Button",true,false).filter(func(b):return b.text==text)
 return matches[0] if not matches.is_empty() else null
func screen_contract(name:String):
 await frames()
 check(w.hud.modal.find_children("*","ScrollContainer",true,false).filter(func(c):return c.is_visible_in_tree()).is_empty(),name+" uses fixed panes rather than scrolling the whole page")
 var viewport=Rect2(Vector2.ZERO,Vector2(1600,1000))
 check(viewport.encloses(w.hud.modal.get_global_rect()),name+" fits logical viewport: "+str(w.hud.modal.get_global_rect()))
 var bounds=w.hud.modal.get_global_rect().grow(2)
 for control in w.hud.modal.find_children("*","Button",true,false):
  if control.is_visible_in_tree():check(bounds.encloses(control.get_global_rect()),name+" button fits screen: "+control.text)
func run():
 w=load("res://scenes/commune.tscn").instantiate();root.add_child(w);current_scene=w;await frames()
 w.set_physics_process(false);w.player.set_physics_process(false);w.combat.set_physics_process(false)
 w.story.flags.comic={"active":false};w.hud.comic_active=false;w.hud.close()
 for id in w.story.ITEMS:w.story.give(id)
 w.story.economy.goods={"bandage":9,"bread":4,"ammo_pouch":2,"medkit":2};w.story.economy.military=100
 for q in w.story.Campaign.data().quests:w.story.flags[q.accepted]=true
 w.hud.show_inventory();await screen_contract("full inventory")
 check(is_instance_valid(w.hud.modal.find_child("InventoryGrid",true,false)),"inventory retains physical drag grid")
 w.hud.shop_actor="commune_guard";w.hud.show_shop();await screen_contract("shop buy")
 var before=w.story.economy.military;var count=int(w.story.economy.goods.get("ammo_pouch",0))
 button("购买一份").pressed.emit();await frames()
 check(w.story.economy.military==before-4 and int(w.story.economy.goods.ammo_pouch)==count+1,"fixed transaction uses real economy exactly once")
 check(w.hud.get_meta("shop_selection_buy")=="ammo_pouch","purchase retains selected item")
 w.hud.show_shop("","sell");await screen_contract("shop sell")
 for tab in ["tasks","closed","leads","collection","lore","history"]:
  w.hud.show_journal(tab);await screen_contract(tab)
 w.hud.show_journal("map","commune");await screen_contract("indoor map")
 check(w.hud.map_large.size.y>=500,"map has actual useful canvas")
 UI.reader(w.hud,"pub_city_family");check(w.hud.modal_visible(),"unowned publication does not expose its text")
 w.hud.Publications.acquire(w.story,"pub_city_family");UI.reader(w.hud,"pub_city_family");await screen_contract("reader")
 var long_text="这是一段包含标点和换行的长记录。为了测试翻页，每一行都需要保留下来。\n".repeat(100)
 var pages=UI.split_text(w.hud,long_text,790,530)
 check(pages.size()>1 and "".join(pages)==long_text,"pagination preserves every character in long records")
 w.hud.show_radiation();await screen_contract("health")
 w.hud.show_settings();await screen_contract("settings")
 w.hud.show_dialogue("commune_anna");w.hud.finish_typing();await screen_contract("dialogue")
 w.hud.show_saves(true);await screen_contract("saves")
 w.player.position=load("res://scripts/supply_storage.gd").LOCKERS.commune;UI.transfer(w.hud,true);await screen_contract("storage")
 w.story.flags.raid_last_result="lost";w.story.take("mask");w.story.take("filter");w.story.take("revolver");w.story.take("grey_carbine")
 UI.raid_debrief(w.hud);await screen_contract("return debrief")
 var task=w.hud.Journal.active(w.story)
 check(task.id=="raid_recovery" and task.target=="personal_storage","loss follows a real reachable recovery target")
 UI.transfer(w.hud,true);await frames()
 var loan=button("借用基础外勤装备 · 撤回后偿还 8 发制式弹")
 check(is_instance_valid(loan),"a player without equipment is offered a concrete recovery loan at the locker")
 if is_instance_valid(loan):loan.pressed.emit()
 check(w.story.has("mask") and w.story.has("filter") and w.story.has("revolver") and w.story.economy.handmade>=8,"loan grants a complete usable kit")
 check(w.hud.Journal.active(w.story).target=="commune_leave" and w.story.Campaign.available(w.story,"east_depart_commune"),"re-equipped player is guided to an available next departure")
 w.queue_free();await frames()
 w=load("res://scenes/east_district.tscn").instantiate();root.add_child(w);current_scene=w;await frames()
 w.set_physics_process(false);w.player.set_physics_process(false);w.combat.set_physics_process(false);w.grey_camp.set_physics_process(false)
 for guard in w.grey_camp.guards:guard.set_physics_process(false)
 w.story.flags.comic={"active":false};w.hud.comic_active=false;w.hud.close()
 w.hud.show_map();await screen_contract("city map");w.hud.close()
 w.player.position=Vector3(-68,.04,8);var guard=w.grey_camp.guards[0];guard.position=Vector3(-63,.04,8);w.set_camera(0,true)
 w.story.give("revolver");w.story.equip_weapon("revolver");w.story.flags.weapon_drawn=true
 var combat=w.combat;combat.clip=6;combat.reload_time=0;combat.enabled=true;await frames()
 for height in [1.3,1.6]:
  var cursor=w.camera.unproject_position(guard.position+Vector3.UP*height)
  combat.aim=combat.aim_from_screen(cursor);combat.cooldown=0
  check(combat.shoot(),"cursor over painted guard fires normally")
 check(guard.hp==16,"two actual cursor chest/head hits deal 64 damage, not ground misses")
 var cover=w.kit.box("BulletTestCover",Vector3(-65.5,.9,8),Vector3(.5,1.8,1.8),"metal",true);await frames()
 combat.cooldown=0;combat.aim=combat.aim_from_screen(w.camera.unproject_position(guard.position+Vector3.UP*1.3));combat.shoot()
 check(guard.hp==16,"aiming at visible artwork never bypasses physical cover")
 cover.queue_free();await frames();combat.cooldown=0;combat.shoot();check(guard.hp<=0,"third unobstructed revolver hit kills an eighty-health guard")
 w.queue_free();await frames();print("INTERFACE_V31_RESULT ",checks," checks / ",failures," failures");quit(1 if failures else 0)
