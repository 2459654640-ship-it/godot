extends SceneTree
const Story=preload("res://scripts/story.gd")
var checks=0
var failures=0
func _initialize():call_deferred("run")
func check(ok:bool,msg:String):
 checks+=1
 if not ok:failures+=1;push_error(msg)
func frames(n:int=5):
 for i in n:await physics_frame
func run():
 var s=Story.new();check(not s.equip_weapon("revolver"),"cannot equip an unowned weapon")
 s.give("revolver");check(s.equipped_weapon()=="revolver" and not s.weapon_drawn(),"new firearm occupies its slot without drawing")
 var old=s.serialize().duplicate(true);old.flags.erase("equipment");old.flags.erase("weapon_drawn")
 var t=Story.new();t.restore(old);check(t.equipped_weapon()=="revolver" and not t.weapon_drawn(),"legacy firearm migrates to holstered slot")
 s.equip_weapon("");t.restore(s.serialize());check(t.equipped_weapon()=="" and t.has("revolver"),"explicitly empty slot persists without losing owned gun")
 s.equip_weapon("revolver");s.flags.weapon_drawn=true;t.restore(s.serialize());check(t.weapon_drawn(),"drawn state survives snapshot and retry")
 t.take("revolver");check(t.equipped_weapon()=="" and not t.weapon_drawn(),"removing owned weapon also clears its slot")
 var w=load("res://scenes/waterworks.tscn").instantiate();root.add_child(w);current_scene=w;await frames(8)
 w.hud.close();w.set_physics_process(false);w.player.set_physics_process(false);w.combat.set_physics_process(false)
 var c=w.combat;w.player.position=Vector3(-13,.04,-2);c.begin("pump");await frames()
 for e in c.enemies:e.set_physics_process(false)
 check(not w.story.weapon_drawn(),"seeing enemies and starting encounter never auto-draws")
 var reserve=w.story.economy.handmade;var clip=c.clip
 check(not c.shoot() and clip==c.clip and reserve==w.story.economy.handmade,"holstered shooting input spends no rounds")
 var event=InputEventKey.new();event.keycode=KEY_1;event.physical_keycode=KEY_1;event.pressed=true;w._unhandled_input(event)
 check(w.story.weapon_drawn(),"actual 1 key binding draws manually")
 var enemy=c.enemies[0];enemy.position=Vector3(-13,.04,-5);await frames();var hp=enemy.hp;c.cooldown=0;c.aim=enemy.position+Vector3.UP*.62
 check(c.shoot() and enemy.hp<hp and c.clip==clip-1,"drawn equipped firearm uses real ray combat")
 w._unhandled_input(event);check(not w.story.weapon_drawn(),"same key holsters during an encounter")
 w.hud.show_inventory();w.hud.finish_typing();await frames()
 var labels=w.hud.modal.find_children("*","Label",true,false)
 check(labels.any(func(l):return l.text=="武器栏"),"inventory renders a separate equipment slot")
 var buttons=w.hud.modal.find_children("*","Button",true,false)
 var unequip=buttons.filter(func(b):return b.text=="卸下");check(unequip.size()==1,"equipped firearm has an explicit unequip control")
 if unequip.size()==1:unequip[0].pressed.emit()
 check(w.story.equipped_weapon()=="" and w.story.has("revolver"),"unequip button moves firearm back to owned inventory")
 var weapon_cell=w.hud.modal.find_child("InventoryCell_revolver",true,false)
 check(is_instance_valid(weapon_cell),"owned firearm remains selectable in grid")
 if is_instance_valid(weapon_cell):weapon_cell.pressed.emit()
 buttons=w.hud.modal.find_children("*","Button",true,false)
 var equip=buttons.filter(func(b):return b.text=="装备到武器栏");check(equip.size()==1,"selected unequipped firearm has equip control")
 if equip.size()==1:equip[0].pressed.emit()
 check(w.story.equipped_weapon()=="revolver" and not w.story.weapon_drawn(),"equip button selects weapon without an automatic draw")
 w.queue_free();await frames()
 print("EQUIPMENT_V12_RESULT checks=",checks," failures=",failures);quit(0 if failures==0 else 1)
