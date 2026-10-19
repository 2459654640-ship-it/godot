extends SceneTree
const Story=preload("res://scripts/story.gd")
const Campaign=preload("res://scripts/campaign.gd")
const Store=preload("res://scripts/save_store.gd")
const Journal=preload("res://scripts/journal.gd")
var checks=0
var failures=0
var w
func _initialize():call_deferred("run")
func check(ok:bool,why:String):
 checks+=1
 if not ok:failures+=1;push_error(why)
func frames(n:int=4):
 for i in n:await physics_frame
func action(s,key:String):
 var result=s.act(key);check(s.last_action_valid,"allowed action: "+key);return result
func option(s,id:String,key:String)->Dictionary:
 for o in s.view(id).options:
  if o.key==key:return o
 return {}
func finish_comic(s,sequence:String,choice:int=0):
 s.Comic.start(s,sequence)
 var count=0
 while s.flags.comic.active and count<50:
  var p:Dictionary=s.Comic.panel(s)
  check(not p.is_empty() and ResourceLoader.exists("res://assets/cinematics/"+p.get("art","")+".png"),"readable illustrated node "+String(s.flags.comic.node))
  if p.is_empty():break
  s.Comic.choose(s,mini(choice,p.choices.size()-1) if p.has("choices") else -1);count+=1
 check(count<50 and not s.flags.comic.active,"travel terminates: "+sequence)
func run():
 var s=Story.new();s.context.floor="life"
 check(option(s,"semyon","semyon_radio").enabled==false,"unknown frequency cannot be asked about")
 check(not Journal.tasks(s).any(func(t):return t.id=="signal_trace"),"unheard signal not shown as accepted quest")
 action(s,"tune")
 check(s.f("signal_heard") and Journal.tasks(s).any(func(t):return t.id=="signal_trace" and not t.done),"actual broadcast accepts investigation")
 s.context.floor="commune";action(s,"c_commune_route")
 check(s.f("signal_identified") and s.f("star_known"),"qualified answer identifies facility after hearing signal")
 s=Story.new();s.context.floor="commune"
 check(not option(s,"commune_leader","c_commune_route").enabled,"no borrowed clairvoyance after skipping D-6 radio")
 action(s,"c_commune_listen");check(s.f("signal_heard") and s.f("signal_identified"),"later receiver can independently start and resolve clue")
 s=Story.new();s.context.floor="life";s.give("vitamins")
 check(option(s,"mikhail","give_vitamins").is_empty(),"vitamin D is not a relationship gift")
 check(s.ITEMS.vitamins[2]=="配给药品","vitamin is categorized as medicine")
 action(s,"vera_heat")
 check(option(s,"nina","borrow_wrench").enabled,"Vera's task unlocks independent tool request without electrical safety question")
 action(s,"borrow_wrench");var reply=action(s,"nina_job")
 check(s.has("wrench") and reply.contains("先留着") and not option(s,"nina","borrow_wrench").enabled,"Nina acknowledges already borrowed tool")
 check(option(s,"nina","nina_rest").category=="闲聊" and option(s,"nina","claim_permit").category=="任务","dialogue options distinguish task and chat")
 s=Story.new();s.context.floor="commune";action(s,"c_commune_stay");finish_comic(s,"commune_settle")
 check(s.f("commune_member") and not s.ending and not s.flags.has("campaign_ending"),"commune commitment remains playable")
 action(s,"c_commune_assembly");check(not Campaign.available(s,"commune_main_work"),"next main assignment waits for the current greenhouse work")
 for key in ["commune_join","greenhouse_inspect","greenhouse_restart","commune_main_work"]:action(s,"c_"+key)
 check(s.f("workers_job") and s.f("commune_joined"),"assembly opens both practical main tasks")
 for key in ["commune_heat_accept","commune_heat_bleed","commune_heat_open","commune_heat_deliver","meal_accept","meal_record","meal_child","meal_deliver","meal_return"]:action(s,"c_"+key)
 check(s.f("commune_heat_done") and s.f("meal_done") and s.economy.military==28,"domestic quests have actual steps and single rewards")
 var money=s.economy.military;s.act("c_meal_return");check(not s.last_action_valid and money==s.economy.military,"cannot farm delivered meal reward")
 s.flags.greenhouse_fixed=true;s.flags.workers_done=true;action(s,"c_commune_trust")
 check(s.f("commune_trusted") and Campaign.available(s,"commune_star"),"earned commune route opens supported onward travel")
 s=Story.new();s.context.floor="sech";action(s,"c_sech_stay");finish_comic(s,"sech_settle");action(s,"c_sech_oath")
 check(not s.ending and s.f("north_job"),"Sech commitment starts practical chapter")
 for key in ["sech_water","radio_manual","radio_power","radio_tune","north_record","north_chock","north_axle","north_verify","sech_trust"]:action(s,"c_"+key)
 check(s.f("sech_trusted") and Campaign.available(s,"sech_star"),"Sech trust earned via three actual systems")
 for key in ["stove_accept","stove_clear","stove_brush","stove_return","blanket_accept","blanket_find","blanket_return"]:action(s,"c_"+key)
 check(s.f("stove_done") and s.f("blanket_done"),"Sech domestic side quests complete")
 for route in ["official","hatch"]:
  s=Story.new();s.route=route;s.context.floor="labor";s.flags.d6_returned=true;s.flags.departure_official=route=="official"
  check(not Campaign.available(s,"enter_coal"),"no unreviewed mine access: "+route)
  if route=="official":action(s,"c_return_official")
  else:
   action(s,"c_return_explain");action(s,"c_return_audit");action(s,"c_return_limited")
  action(s,"c_enter_coal");finish_comic(s,"coal_descent")
  check(s.flags.next_facility=="coal" and s.f("coal_access"),"reviewed route enters a separate mine map: "+route)
 s.context.floor="coal";s.flags.brother_care=true;s.give("vitamins");action(s,"c_vitamin_plan");action(s,"c_vitamin_leave")
 check(s.f("vitamin_care") and not s.has("vitamins"),"vitamin used in professional long-term care, not an instant cure")
 s=Story.new();s.context.floor="starcity";s.flags.star_access=true;s.give("photo")
 for key in ["father_photo","father_absence","star_handover_accept","weather_clock","weather_power","weather_test","weather_return","star_handover_finish","ending_bridge"]:
  s.act("c_"+key);check(not s.last_action_valid and s.has("photo") and not s.ending,"closed interior retains keepsake and rejects future story: "+key)
 # Safe sale and protected keepsakes.
 s=Story.new();s.give("photo");s.give("wrench");s.economy.goods.bread=2
 var before=s.economy.military;s.Economy.sell(s,"bread");check(s.economy.military==before+2 and s.economy.goods.bread==1,"sell one consumable at a disclosed price")
 s.Economy.sell(s,"photo");check(s.has("photo") and s.Economy.sale_price(s,"wrench")==0,"no sale of family keepsake or essential tool")
 s.economy.radiation=18;s.economy.goods.antirad=1;s.Economy.consume(s,"antirad");check(s.economy.radiation==0 and not s.economy.goods.has("antirad"),"antirad has a real consumable effect")
 # Atomic persistence, corruption recovery, independent slots and old format.
 var path="user://v11_contract/slot.json";var data=s.serialize();data.floor="life";data.position=[1,.04,2]
 check(Store.write(path,data)==OK and not Store.read(path).is_empty(),"checksummed save can actually be loaded")
 data.position=[3,.04,4];check(Store.write(path,data)==OK,"second write succeeds with backup")
 var broken=FileAccess.open(path,FileAccess.WRITE);broken.store_string("{broken");broken.close()
 var recovered=Store.read(path);check(recovered.get("recovered_backup",false) and recovered.position[0]==1,"corrupt primary recovers previous valid backup")
 data.floor="unknown";check(Store.write(path,data)==ERR_INVALID_DATA,"unknown destination cannot replace readable save")
 check(Store.valid({"version":1,"floor":"labor","flags":{},"position":[0,.04,0]}),"legacy save without checksum remains supported")
 for old_end in ["commune","sech","home","tea"]:
  var old=Story.new().serialize();old.content_revision=10;old.ending=true;old.flags.campaign_ending=old_end
  old.flags.failed_quests={"commune_heat":"旅程已经收束。","heat":"离站后未能完成。"}
  s=Story.new();s.restore(old)
  check(not s.ending and not s.flags.failed_quests.has("commune_heat") and s.flags.failed_quests.has("heat"),"reopened legacy route restores only ending-closed quests: "+old_end)
 for sequence in ["commune_road","solo_commune","sech_arrival","coal_road"]:s=Story.new();finish_comic(s,sequence)
 # New map traversal: reachable cells must approach every target from the spawn.
 for id in ["commune","sech","coal"]:
  w=load("res://scenes/"+id+".tscn").instantiate();root.add_child(w);await frames(8);w.hud.close();w.set_physics_process(false)
  var graph=w.navigation.graph;var start=graph.get_closest_point(Vector2(w.player.position.x,w.player.position.z));var seen={start:true};var queue=[start];var cursor=0
  while cursor<queue.size():
   var at=queue[cursor];cursor+=1
   for other in graph.get_point_connections(at):
    if not seen.has(other):seen[other]=true;queue.append(other)
  for target in w.targets:
   var p:Vector3=w.targets[target].pos;var closest=INF
   for node in seen:closest=minf(closest,graph.get_point_position(node).distance_to(Vector2(p.x,p.z)))
   check(closest<1.65,"reachable interaction "+id+"/"+target+" distance="+str(closest))
  check(w.kit.roof_occluders.size()>0,"overhead equipment supports visibility fading: "+id)
  check(w.wall_veil.FADED>=.4,"wall fade retains a readable structural surface")
  check(w.find_children("SignBacking*","MeshInstance3D",true,false).is_empty(),"no black room-purpose signs: "+id)
  if id=="commune":check(w.find_children("StationArchStone*","MeshInstance3D",true,false).is_empty() and w.zones.size()>=10,"expanded commune without floating arches")
  if id=="sech":
   for rail in w.find_children("DepotRail*","MeshInstance3D",true,false):check(rail.position.x>20,"active rails outside all habitation rooms")
   var child=w.npcs.get("resident_ambient_child_1");check(is_instance_valid(child) and child.visual.get_node("Painter").sprite.mesh is QuadMesh and child.visual.get_node("Painter").find_children("*Leg*","MeshInstance3D",true,false).is_empty(),"child uses one complete painted figure without split-leg deformation")
  w.queue_free();await frames()
 print("V11_RESULT checks=",checks," failures=",failures)
 quit(0 if failures==0 else 1)
