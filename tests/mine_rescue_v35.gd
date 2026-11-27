extends SceneTree

const Story=preload("res://scripts/story.gd")
const Rescue=preload("res://scripts/mine_rescue.gd")
const Cinema=preload("res://scripts/ui_comic.gd")
var w
var checks=0
var failures=0

func _initialize():call_deferred("run")

func check(ok:bool,message:String):
 checks+=1
 if not ok:failures+=1;push_error(message)

func frames(n:int=6):
 for i in n:await physics_frame

func fixture():
 var s=Story.new()
 s.flags.merge({"intro_done":true,"anna_request":true,"anna_first_news":true,"brother_found":true,"anna_warning_seen":true,"anna_rescue_started":true,"arrival_v8_coal":true,"arrival_v8_commune":true,"tracked_quest":"anna_rescue","east_mine_prepared":true,"east_private_mine_entry":true,"late_mine_cover_ready":true},true)
 s.route="hatch";s.flags.d6_wanted=true;s.context.floor="coal"
 s.give("mask");s.give("filter")
 return s

func open(s:Dictionary,p:Vector3):
 root.get_node("Session").pending={"story":s,"floor":"coal","position":p}
 w=load("res://scenes/coal.tscn").instantiate();root.add_child(w);current_scene=w
 await frames();freeze()

func freeze():
 w.set_physics_process(false);w.player.set_physics_process(false);w.hud.close()

func physical_target(id:String):
 var goal:Vector3=w.targets[id].pos
 var route=w.navigation.path(w.player.position,goal)
 check(not route.is_empty() and route[-1].distance_to(goal)<1.5,"accessible map target "+id)

func play_film(choice:int=-1):
 var s=w.story
 for i in 18:
  if not s.flags.get("comic",{}).get("active",false):return
  var panel=s.Comic.panel(s)
  if panel.has("choices") and choice<0:return
  w.hud.comic_choose(choice if panel.has("choices") else -1)
  await frames(2)
 check(false,"film did not terminate")

func follow(flag:String,points:Array,reload:bool=false):
 for i in 6100:
  if w.story.f(flag):return
  var slow=w.npcs.coal_brother if w.npcs.coal_brother.position.distance_to(points[0])>w.npcs.mine_anna.position.distance_to(points[1]) else w.npcs.mine_anna
  # Keep the player within conversation range, beside the travelway.
  w.player.position=w.clear_arrival(slow.position+Vector3(1.85,.04,0))
  w.living.tick(1.0/60.0)
  if reload and i==230:
   var packet=w.save_snapshot();var pos:Vector3=w.npcs.coal_brother.position
   var at:Vector3=w.player.position;w.queue_free();await frames()
   await open(packet,at)
   check(w.npcs.coal_brother.position.distance_to(pos)<.85,"mid-escort save restores the moving NPC")
  await physics_frame
 check(false,"escort stalled "+flag+" at "+str(w.npcs.coal_brother.position)+" / "+str(w.npcs.mine_anna.position))

func read_model(s,selection:int=0):
 for i in 12:
  if not s.flags.comic.active:return
  var p=s.Comic.panel(s);s.Comic.choose(s,selection if p.has("choices") else -1)
 check(false,"model-only sequence did not terminate")

func run():
 var initial=fixture().serialize();initial.floor="coal"
 await open(initial,Vector3(8.1,.04,-4.2))
 check(w.npcs.has("mine_anna") and w.npcs.has("coal_brother"),"both characters are present at the start of the rescue")
 check(not w.story.Campaign.available(w.story,"rescue35_call"),"arriving early at the lift cannot skip the escort")
 physical_target("rescue35_lift")
 check(w.navigation.path(w.player.position,Rescue.RESERVE).is_empty(),"closed old gate seals backup route")
 # Confirm the actual prompt opens the bedside scene and supports non-mutating review.
 w.interact("mine_anna");w.perform("c_rescue_review","mine_anna")
 check(w.hud.comic_active and w.story.flags.comic.node=="rescue35_brief","bedside interaction brings up the new illustrated briefing")
 w.hud.finish_typing();Cinema.advance(w.hud);Cinema.back(w.hud)
 check(w.story.flags.comic.line_index==0 and not w.story.f("rescue35_walk"),"previous subtitle does not change the decision")
 w.hud.finish_typing();check(not Cinema.keyboard(w.hud,KEY_1),"number shortcuts cannot choose on an earlier subtitle")
 w.story.flags.comic.line_index=3;w.hud.show_comic();w.hud.finish_typing()
 check(Cinema.keyboard(w.hud,KEY_1),"keyboard can choose when the final subtitle is complete")
 await play_film();w.hud.close()
 var start:Vector3=w.npcs.coal_brother.position
 w.player.position=Vector3(-12,.04,9);w.living.tick(.016);await frames(12)
 check(w.npcs.coal_brother.story_waiting and w.npcs.coal_brother.position.distance_to(start)<.25,"patient waits when player walks away")
 await follow("rescue35_assembled",Rescue.MAIN_QUEUE,true)
 check(w.npcs.coal_brother.position.distance_to(start)>30,"patient physically crosses the mine")
 check(w.npcs.mine_anna.position.distance_to(Rescue.MAIN_QUEUE[1])<1,"Anna physically arrives in the west landing")
 check(w.InteractionRegions.contains(w.story,"rescue35_lift",Vector3(-31.9,0,-.4)),"lift action is accessible across its approach")
 w.perform("c_rescue35_call","rescue35_lift");await play_film();w.hud.close()
 check(w.story.f("rescue35_stalled") and not w.story.f("anna_outcome_done"),"the malfunction returns the player to the map with a decision")
 check(w.story.Campaign.available(w.story,"rescue35_manual") and not w.story.Campaign.available(w.story,"rescue35_divert"),"incomplete preparations expose the risky choice and not the safe handover")
 var stalled=w.save_snapshot().duplicate(true)
 w.perform("c_rescue35_manual","rescue35_lift");await play_film(0);w.hud.close()
 check(not w.story.f("rescue_risk_confirmed") and not w.story.f("anna_dead"),"declining risk leaves time to prepare")
 for key in ["rescue_air_map","rescue_air_open","rescue_onsite_medic","rescue_onsite_transport"]:
  w.story.act("c_"+key);check(w.story.last_action_valid,"can still prepare after the mechanical failure "+key)
 await create_timer(1.1).timeout
 physical_target("rescue35_handoff")
 check(not w.story.Campaign.available(w.story,"rescue35_manual"),"once prepared the usable alternate route takes priority")
 w.perform("c_rescue35_divert","rescue35_lift");await play_film();w.hud.close()
 check(not w.story.Campaign.available(w.story,"rescue35_handoff"),"backup door cannot count an absent companion")
 await follow("rescue35_reserve_arrived",Rescue.RESERVE_QUEUE)
 check(w.npcs.coal_brother.position.z<-23 and w.npcs.mine_anna.position.z<-23,"both characters have walked beyond the old mine boundary")
 w.perform("c_rescue35_handoff","rescue35_handoff");await play_film();await frames(15)
 w=current_scene;freeze()
 check(w.floor_id=="commune" and w.npcs.has("commune_anna") and w.npcs.has("commune_aleksei"),"survivors return to physical placements in the commune")
 check(not w.story.ending and w.story.f("anna_alive"),"survival closes the rescue while keeping the world playable")
 w.queue_free();await frames()

 var s=Story.new();s.restore(stalled);s.context.floor="coal"
 s.act("c_rescue35_manual");s.Comic.start(s,s.flags.next_sequence);read_model(s,1)
 check(s.f("anna_dead") and not s.f("anna_alive") and s.flags.next_facility=="commune","risk has a complete exclusive outcome and return route")
 var family=s.serialize().duplicate(true)
 var responses=[]
 for choice in [0,1]:
  s=Story.new();s.restore(family);s.context.floor="commune";s.act("c_anna_memorial")
  check(s.flags.next_sequence=="rescue35_account","new outcome starts the family accountability scene")
  s.Comic.start(s,s.flags.next_sequence);read_model(s,choice)
  var v=s.view("commune_aleksei")
  responses.append(v.body)
  check(s.f("anna_aftermath_done") and s.f("anna_record_public")== (choice==0) and s.f("anna_record_family")== (choice==1),"record decision commits exactly one outcome")
 check(responses[0]!=responses[1],"brother's present-day conversation reflects the player's decision")
 print("MINE_RESCUE_V35_RESULT checks=",checks," failures=",failures)
 quit(1 if failures else 0)
