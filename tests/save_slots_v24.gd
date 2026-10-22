extends SceneTree
const Story=preload("res://scripts/story.gd")
const Store=preload("res://scripts/save_store.gd")
var checks=0
var failures=0
func _initialize():call_deferred("run")
func check(ok:bool,msg:String):
 checks+=1
 if not ok:failures+=1;push_error(msg)
func frames(n:int=5):
 for i in n:await physics_frame
func button(h,text:String):
 for b in h.modal.find_children("*","Button",true,false):
  if b.text==text:return b
 return null
func open(floor:String,s):
 var data=s.serialize();data.floor=floor;data.layout_revision=24
 root.get_node("Session").pending={"story":data,"floor":floor,"position":Vector3.INF}
 var w=load("res://scenes/"+{"life":"d6"}.get(floor,floor)+".tscn").instantiate();root.add_child(w);current_scene=w;await frames()
 w.hud.comic_active=false;w.story.flags.comic={"active":false};w.hud.close();w.set_physics_process(false);return w
func loaded(old):
 for i in 30:
  await process_frame
  if current_scene!=old and is_instance_valid(current_scene) and current_scene.get("initialized"):
   var w=current_scene;w.set_physics_process(false);w.combat.set_physics_process(false)
   for e in w.combat.enemies:e.set_physics_process(false)
   return w
 return null
func run():
 preserve_slots()
 check(Store.manual_paths().size()==6 and Store.automatic_paths().size()==3,"six fixed manual slots and three separate rotating autos")
 var s=Story.new();s.flags.intro_done=true;s.flags.signal_heard=true;s.flags.anna_request=true;s.flags.first_meeting_commune_anna=2
 s.items.assign(["photo","mask","filter"]);s.economy.handmade=31;s.economy.goods.bandage=2;s.read_topics.assign(["semyon_child"])
 s.conversations={"commune_anna":[{"speaker":"ivan","text":"我愿意去查。"},{"speaker":"commune_anna","text":"查不到也回来告诉我。"}]};s.last_greetings.commune_anna="安娜正在抄写编号。"
 for i in 6:
  var d=s.serialize().duplicate(true);d.floor="commune";d.position=[-4.0,.04,20.0];d.played_seconds=1234+i;d.flags.slot_probe=i;d.save_summary={"room":"医务室","quest":"一个确切的名字"}
  check(Store.write(Store.manual_paths()[i],d)==OK,"writes independent slot "+str(i+1))
 for i in 6:
  var data=Store.read(Store.manual_paths()[i]);var t=Story.new();t.restore(data)
  check(int(t.flags.slot_probe)==i and t.items==s.items and t.economy.goods.bandage==2,"inventory and independent branch rewind "+str(i+1))
  check(t.conversations==s.conversations and t.last_greetings==s.last_greetings and t.read_topics==s.read_topics and t.f("signal_heard"),"dialogue transcripts and unlocks roundtrip "+str(i+1))
  check(Store.summary(data).contains("00:20:") and Store.summary(data).contains("医务室") and Store.summary(data).contains("一个确切的名字"),"slot metadata explains location, playtime and quest")
 var auto=Store.auto_path();check(auto in Store.automatic_paths(),"automatic rotation cannot choose a manual slot")
 check(Store.write(auto,s.serialize(),"auto")==OK,"autosave still writes")
 for i in 6:check(int(Store.read(Store.manual_paths()[i]).flags.slot_probe)==i,"autosave preserves slot "+str(i+1))
 # Corruption falls back to the slot's own last good copy.
 var first=Store.read(Store.manual_paths()[0]);first.flags.slot_probe=99;Store.write(Store.manual_paths()[0],first)
 FileAccess.open(Store.manual_paths()[0],FileAccess.WRITE).store_string("{broken")
 check(Store.read(Store.manual_paths()[0]).get("recovered_backup",false),"damaged slot recovers its own backup")
 # Real F5/F9 open the selectable lists; they never silently overwrite/rewind.
 s=Story.new();s.flags.intro_done=true;var w=await open("life",s)
 var event=InputEventAction.new();event.action="save";event.pressed=true;w._unhandled_input(event)
 check(w.hud.dialog_title.text=="保存游戏","F5 opens fixed-slot chooser")
 var choices=w.hud.modal.find_children("*","Button",true,false).filter(func(b):return b.text=="保存到此档位")
 check(choices.size()==6,"all six manual save callbacks render")
 w.hud.receipt("测试：物品已放入背包");await frames(2)
 check(not w.hud.receipt_box.visible,"notifications cannot cover save chooser headings or slot metadata")
 w.story.flags.ui_saved_probe=true;choices[1].pressed.emit();check(w.hud.dialog_title.text=="覆盖这个存档？","occupied slot requires concrete overwrite confirmation")
 check(not Store.read(Store.manual_paths()[1]).flags.get("ui_saved_probe",false),"opening overwrite dialog does not save early")
 button(w.hud,"确认覆盖").pressed.emit();check(Store.read(Store.manual_paths()[1]).flags.get("ui_saved_probe",false),"confirmed slot receives the current world state")
 event.action="load";w._unhandled_input(event);check(w.hud.dialog_title.text=="读取存档","F9 opens rewind chooser")
 check(button(w.hud,"自动与旧版存档")!=null,"autosaves and legacy quick save have their own tab")
 # Saving on a choice retains the illustrated branch, without making a choice for the player.
 w.hud.show_comic("anna_supper");var node=w.story.flags.comic.node;w.hud.show_saves(true);w.save_game(Store.manual_paths()[5])
 var panel_save=Store.read(Store.manual_paths()[5]);check(panel_save.flags.comic.active and panel_save.flags.comic.node==node,"save on a choice retains exact panel and no forced decision")
 w.hud.comic_active=false;w.story.flags.comic={"active":false};w.queue_free();await frames()
 # A mid-combat load restores current enemies, not the room's original full-health wave.
 s=Story.new();s.flags.intro_done=true;s.flags.weapon_issued=true;s.flags.plant_diagram=true;s.give("revolver");s.economy.handmade=41
 w=await open("waterworks",s);w.combat.set_physics_process(false);w.combat.begin("pump")
 for e in w.combat.enemies:e.set_physics_process(false)
 w.combat.enemies[0].hp=17;w.combat.enemies[0].windup=.31;w.combat.enemies[0].cooldown=.88
 w.combat.clip=2;w.combat.reload_time=1.17;w.combat.veteran_health=67;w.combat.veteran_clip=3;w.combat.veteran_reload=.71
 var checkpoint=w.combat.checkpoint.duplicate(true);var p=w.combat.enemies[0].position
 check(w.save_game(Store.manual_paths()[2]),"manual saving is permitted in combat")
 var saved=Store.read(Store.manual_paths()[2]);check(saved.combat_state.enemies.size()==3 and int(saved.combat_state.enemies[0].hp)==17,"live enemy state is present in the file")
 check(saved.combat_state.checkpoint.get("combat_state",{}).is_empty(),"retry checkpoint does not recursively nest combat saves")
 w.story.economy.handmade=0;w.story.economy.health=1;w.load_game(Store.manual_paths()[2]);w=await loaded(w)
 check(is_instance_valid(w),"combat slot loads into an actual world")
 if not is_instance_valid(w):print("SAVE_SLOTS_V24_RESULT checks=",checks," failures=",failures);quit(1);return
 check(w.combat.active and w.combat.encounter=="pump" and w.combat.enemies.size()==3,"same fight and number of living enemies resume")
 check(w.combat.enemies[0].hp==17 and w.combat.enemies[0].position.distance_to(p)<.12,"enemy health and exact location restored")
 check(w.combat.clip==2 and absf(w.combat.reload_time-1.17)<.06 and w.combat.veteran_health==67 and w.combat.veteran_clip==3,"reload, ammunition and companion state preserved")
 check(w.story.economy.handmade==saved.economy.handmade and w.story.economy.health==saved.economy.health,"loading a slot restores resources at save time")
 w.combat.retry();w=await loaded(w)
 check(is_instance_valid(w) and w.story.economy.handmade==checkpoint.economy.handmade and w.story.economy.health==checkpoint.economy.health,"retry after loading still restores original pre-fight resources")
 w.queue_free();await frames()
 var menu=load("res://scenes/main_menu.tscn").instantiate();root.add_child(menu);current_scene=menu;await frames()
 menu.show_saves();check(menu.dialog.find_children("*","Button",true,false).size()>=9,"main menu offers six slots and navigation without overflowing layout")
 menu.show_saves("auto");check(menu.dialog.find_children("*","Button",true,false).any(func(b):return b.text.contains("旧版快速存档")),"main menu retains legacy quick save access")
 menu.queue_free();await frames()
 print("SAVE_SLOTS_V24_RESULT checks=",checks," failures=",failures);quit(0 if failures==0 else 1)

var slot_backup:Dictionary={}
func preserve_slots():
 for path in preload("res://scripts/save_store.gd").paths():
  for suffix in ["",".bak",".tmp"]:
   var file:String=path+suffix
   slot_backup[file]=FileAccess.get_file_as_bytes(file) if FileAccess.file_exists(file) else null
func _finalize():
 # These fixtures exercise the real fixed paths, then put the user's files back.
 for path in slot_backup:
  if slot_backup[path]==null:DirAccess.remove_absolute(path)
  else:
   var file=FileAccess.open(path,FileAccess.WRITE)
   if file:file.store_buffer(slot_backup[path]);file.close()
