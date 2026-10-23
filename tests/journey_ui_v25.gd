extends SceneTree
const Story=preload("res://scripts/story.gd")
const Video=preload("res://scripts/video_settings.gd")
var checks=0
var failures=0
func _initialize():call_deferred("run")
func check(ok:bool,why:String):
 checks+=1
 if not ok:failures+=1;push_error(why)
func frames(n:int=4):
 for i in n:await physics_frame
func act(s,key:String):
 s.act("c_"+key);check(s.last_action_valid,"action available: "+key)
func scene(s,key:String,choice:int=0):
 s.Comic.start(s,key)
 var n=0
 while s.flags.comic.active and n<20:
  var p=s.Comic.panel(s)
  check(not p.is_empty() and ResourceLoader.exists("res://assets/cinematics/"+p.art+".png"),"cinematic has real illustration: "+String(s.flags.comic.node))
  if p.is_empty():break
  if p.get("music","")!="":check(ResourceLoader.exists("res://assets/audio/"+p.music+".ogg") or ResourceLoader.exists("res://assets/audio/"+p.music+".wav"),"score exists: "+p.music)
  s.Comic.choose(s,mini(choice,p.choices.size()-1) if p.has("choices") else -1);n+=1
 check(n<20 and not s.flags.comic.active,"cinematic terminates: "+key)
func formal()->Object:
 var s=Story.new();s.route="official";s.context.floor="waterworks";s.flags.intro_done=true;s.flags.water_secured=true;s.give("water_core");s.give("mask");s.give("filter")
 act(s,"plant_leave");check(s.has("water_core"),"crates remain with team until actual D-6 handover")
 scene(s,"return_standoff",0);check(s.f("arrested_veteran") and s.has("water_core"),"supporting lieutenant preserves return cargo")
 s.context.floor="labor";s.flags.d6_returned=true;s.flags.departure_official=true
 act(s,"return_filters");check(not s.has("water_core") and s.Chapter.home_access(s),"handover consumes crates once and restores home access")
 return s
func run():
 var session=root.get_node("Session");var original=session.video.duplicate();var old_settings=FileAccess.get_file_as_bytes("user://metro_settings.cfg") if FileAccess.file_exists("user://metro_settings.cfg") else PackedByteArray()
 var invalid=Video.sanitize({"mode":99,"quality":-3,"width":20,"height":99,"fps":999})
 check(invalid.mode==2 and invalid.quality==0 and invalid.width==960 and invalid.height==600 and invalid.fps==60,"invalid display settings normalize to valid values")
 session.preview_video({"mode":0,"fill":true,"quality":0,"fps":30});check(session.video_preview and root.content_scale_aspect==Window.CONTENT_SCALE_ASPECT_IGNORE and root.msaa_3d==Viewport.MSAA_DISABLED and Engine.max_fps==30,"preview actually changes display and render settings")
 session._process(16);check(not session.video_preview and session.video==original,"unconfirmed settings time out to original display")
 session.preview_video({"quality":1,"fill":false});session.preview_video({"quality":0});session.revert_video();check(session.video==original,"repeated previews retain the original recovery snapshot")
 session.preview_video({"quality":1,"fill":false});session.confirm_video();var cfg=ConfigFile.new();cfg.load("user://metro_settings.cfg")
 check(int(cfg.get_value("video","quality"))==1 and not session.video_preview,"confirmed video settings persist in config")
 var legacy=Story.new();legacy.route="official";legacy.flags.merge({"intro_done":true,"water_secured":true,"c_done_plant_leave":true,"d6_returned":true,"departure_official":true},true)
 var saved=legacy.serialize().duplicate(true);saved.content_revision=24;saved.floor="labor"
 var migrated=Story.new();migrated.restore(saved);check(migrated.has("water_core") and migrated.f("legacy_return_cargo_recovered"),"old returned save recovers crates consumed by v24 before handover")
 migrated.context.floor="labor";act(migrated,"return_filters");check(migrated.f("d6_cargo_returned") and not migrated.has("water_core"),"recovered old cargo can actually be delivered")
 var second=Story.new();second.restore(migrated.serialize());check(not second.has("water_core"),"reloading cannot duplicate already delivered cargo")
 for flag in ["sided_veteran","cargo_sent_with_lieutenant","d6_cargo_returned"]:
  var invalid_old=saved.duplicate(true);invalid_old.flags[flag]=true;var t=Story.new();t.restore(invalid_old);check(not t.has("water_core"),"migration cannot recreate transferred cargo: "+flag)
 var s=formal();act(s,"return_assignment");check(s.flags.next_sequence=="d6_briefing" and not s.Campaign.available(s,"return_commune"),"formal assignment no longer opens a diplomatic shortcut into enemy commune")
 scene(s,"d6_briefing");s.context.floor="life"
 check(s.view("semyon").options.any(func(o):return o.key=="c_d6_home_talk" and o.enabled),"homecoming is reachable from actual Semyon conversation")
 act(s,"d6_home_talk");scene(s,"d6_home_evening");check(s.f("d6_home_seen") and s.f("d6_shared_grief"),"home conversation choice and progression recorded")
 var restored=Story.new();restored.restore(JSON.parse_string(JSON.stringify(s.serialize())));s=restored;s.context.floor="labor"
 check(s.f("d6_home_seen"),"new stages survive a save/load roundtrip")
 check(s.view("medical").options.any(func(o):return o.key=="c_d6_medical_brief"),"native medical dialogue includes next objective")
 act(s,"d6_medical_brief");scene(s,"d6_ward_brief");act(s,"d6_field_supply");var ammo=s.economy.handmade
 s.act("c_d6_field_supply");check(not s.last_action_valid and s.economy.handmade==ammo,"supply cannot be farmed")
 act(s,"d6_patrol_depart");check(s.f("surface_from_d6") and not s.f("surface_from_commune") and not s.f("surface_from_sech"),"D-6 sortie has separate origin identity")
 scene(s,"d6_patrol_road");s.context.floor="surface"
 act(s,"surface_back_d6");scene(s,"d6_patrol_back");check(s.flags.next_facility=="labor","early retreat returns to D-6, never commune or Star City")
 s.context.floor="labor";act(s,"d6_patrol_depart");s.context.floor="surface"
 s.act("c_surface_drain");check(not s.last_action_valid,"pump puzzle requires reading diagram and defeating yard threat")
 act(s,"surface_notes");s.flags.battle_surface_yard=true;act(s,"surface_drain");s.flags.battle_surface_pool=true;act(s,"surface_sample_take")
 var task=s.Campaign.side_tasks(s).filter(func(t):return t.id=="d6_first_duty")[0]
 check(task.target=="surface_exit" and task.step.contains("D-6"),"journal follows sampling progress and correct return destination")
 act(s,"surface_back_d6");s.context.floor="labor";act(s,"d6_patrol_turnin");scene(s,"d6_patrol_report",0)
 check(s.f("d6_patrol_done") and s.f("d6_report_medical") and not s.ending and not s.has("pool_sample"),"first D-6 mission resolves without ending game")
 act(s,"d6_medical_followup");check(s.economy.goods.get("medkit",0)==1,"report emphasis enables a concrete medical follow-up")
 s.act("c_d6_patrol_turnin");check(not s.last_action_valid,"mission cannot be delivered twice")
 s.context.floor="coal";check(not s.Campaign.available(s,"coal_return"),"D-6 resident cannot use mine exit as a free transfer to hostile commune")
 act(s,"coal_back_d6");scene(s,"coal_return_d6");check(s.flags.next_facility=="labor","mine exit preserves D-6 resident return destination")
 var other=formal();other.flags.commune_member=true;other.act("c_return_assignment");check(not other.last_action_valid,"hostile faction member cannot silently become D-6 operative")
 var mine=Story.new();mine.context.floor="coal";mine.flags.coal_access=true
 for key in ["coal_register","coal_archive","coal_medic","coal_brother"]:act(mine,key)
 check(mine.flags.next_sequence=="mine_bedside","first actual bedside visit opens interactive cinematic")
 scene(mine,"mine_bedside",1);check(mine.f("mine_visit_seen") and mine.f("mine_message_chosen"),"bedside choice recorded")
 act(mine,"mine_observe_offer");mine.act("c_mine_heat_finish");check(not mine.last_action_valid,"ward care cannot skip worker agreement")
 for key in ["mine_heat_record","mine_heat_negotiate","mine_heat_finish"]:act(mine,key)
 scene(mine,"mine_warm_evening");check(mine.f("mine_warm_done"),"optional mine duty has an actual conclusion and aftermath")
 root.get_node("Session").pending={"story":s.serialize(),"floor":"labor","position":Vector3(23,.04,-9)}
 var w=load("res://scenes/labor.tscn").instantiate();root.add_child(w);current_scene=w;await frames();w.hud.comic_active=false;w.story.flags.comic={"active":false};w.hud.close();w.set_physics_process(false)
 session.preview_video({"quality":0});check(w.find_children("*","Light3D",true,false).all(func(l):return not l.shadow_enabled),"low quality removes real shadow rendering")
 session.preview_video({"quality":2});check(w.find_children("*","DirectionalLight3D",true,false).any(func(l):return l.shadow_enabled),"high quality restores authored shadows")
 session.revert_video()
 w.story.economy.goods.medkit=2;w.story.economy.health=40;w.hud.show_inventory();await frames()
 var grid=w.hud.modal.find_child("InventoryGrid",true,false);check(is_instance_valid(grid) and grid.columns==5,"inventory is a five-column item grid")
 var cell=w.hud.modal.find_child("InventoryCell_medkit",true,false);check(is_instance_valid(cell),"stacked consumable has its own selectable cell")
 cell.pressed.emit();await frames();var use=w.hud.modal.find_children("*","Button",true,false).filter(func(b):return b.text=="使用一份")
 check(use.size()==1,"selected consumable exposes usable detail action")
 if not use.is_empty():use[0].pressed.emit();await frames()
 check(w.story.economy.health==80 and w.story.economy.goods.medkit==1,"grid consumption updates health and stack once")
 w.hud.show_settings();await frames();check(w.hud.modal.find_children("*","OptionButton",true,false).size()==6,"pause settings exposes every video control")
 w.hud.show_task_detail("d6_first_duty");await frames();check(w.hud.modal.find_children("*","Label",true,false).any(func(l):return l.text=="任务结果"),"task detail has explicit current objective / result hierarchy")
 w.queue_free();await frames()
 var menu=load("res://scenes/main_menu.tscn").instantiate();root.add_child(menu);current_scene=menu;await frames();menu.show_settings();await frames()
 check(menu.dialog.find_children("*","OptionButton",true,false).size()==6,"main menu uses the same video options")
 menu.queue_free();await frames();session.video=original;Video.apply(session)
 if not old_settings.is_empty():var file=FileAccess.open("user://metro_settings.cfg",FileAccess.WRITE);file.store_buffer(old_settings);file.close()
 elif FileAccess.file_exists("user://metro_settings.cfg"):DirAccess.remove_absolute("user://metro_settings.cfg")
 print("JOURNEY_UI_V25_RESULT checks=",checks," failures=",failures);quit(0 if failures==0 else 1)
