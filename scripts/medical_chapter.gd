extends Node
## A physical medical transfer, with an alternative to the northern firefight.
static var authored:Dictionary={}
var w
const ID="c1_lidiya"
const WAYPOINTS=[Vector3(-15.5,0,-8),Vector3(-17,0,3),Vector3(-18,0,15.5)]
static func data()->Dictionary:
 if authored.is_empty():authored=JSON.parse_string(FileAccess.get_file_as_string("res://data/medical_chapter.json"))
 return authored
static func extend(c:Dictionary):
 for section in ["actions","interactions"]:c[section].merge(data()[section].duplicate(true),true)
 c.quests.append_array(data().get("quests",[]).duplicate(true))
static func revised(s)->bool:return s.f("c1_revised")
static func migrate(s):
 if revised(s) or not s.f("field_c1_accepted"):return
 if not s.f("field_c1_in_progress") and not s.f("field_c1_done"):return
 s.flags.c1_revised=true;s.flags.c1_legacy_transfer=true
 if s.f("field_c1_ready") or s.f("field_c1_done"):
  s.flags.c1_lidiya_waiting=true;s.flags.c1_signal_called=true
 if s.f("field_c1_done"):s.flags.c1_clinic_pending=true
static func allowed(s,key:String)->bool:
 if not revised(s):return not key.begins_with("c1_")
 if key in ["c1_backup_read","c1_backup_isolate","c1_spare_take","c1_backup_restore","c1_traffic_notice","c1_linen_read"] and (s.Campaign.Update.mission(s)!="c1" or s.f("field_c1_done")):return false
 if key=="front_restore_signal" and s.Campaign.Update.mission(s)=="c1":return s.f("field_c1_evidence") and s.f("field_c1_scene_seen") and (s.f("battle_c1_north") or s.f("c1_backup_online")) and not s.f("c1_signal_called")
 return true
static func task(s,current:Dictionary,q:Dictionary)->Dictionary:
 if not revised(s) or q.id!="field_c1" or s.f("field_c1_done"):return current
 var v=current.duplicate()
 if s.context.get("floor","")!="railfront":
  v.target="commune_guard" if s.f("field_c1_ready") else "commune_leave";v.place="commune"
  v.step="向亚历山德拉交接药箱和沿途情况，再去医务室看望莉季娅。" if s.f("field_c1_ready") else "备好面具、滤毒罐和武器，到联络气闸选择药品外勤；南口还有本班补给。"
 elif s.f("field_c1_ready"):
  v.target="front_exit";v.place="railfront";v.step="莉季娅已到南口，司机也确认了接送。到南口接送线，一起返回公社。"
 elif s.f("c1_signal_called"):
  v.target=ID;v.place="railfront";v.step="接送已确认。陪莉季娅沿西侧廊道到南口等候处；她会等你，不需要赶时间。"
 elif s.f("field_c1_scene_seen"):
  v.target="c1_backup";v.place="railfront";v.step="任选一条联络办法：修复南控制间的备用有线机，或清理北口后操作信号箱。莉季娅正沿西侧廊道前往南口。"
 elif s.f("field_c1_evidence"):
  v.target=ID;v.place="railfront";v.step="先听莉季娅说明情况，商量证词怎样登记，再安排一起撤回。"
 elif s.f("field_c1_routes"):
  v.target="front_cache";v.place="railfront";v.step="沿站台中段进入西侧廊道，到转移间寻找药箱和医护；先确认沿路安全。"
 else:return current
 return v
static func objective(s)->String:
 if revised(s) and s.context.get("floor","")=="railfront" and s.Campaign.Update.mission(s)=="c1" and not s.f("field_c1_done"):
  return task(s,{}, {"id":"field_c1"}).get("step","")
 return ""
static func decorate(v:Dictionary,s)->Dictionary:
 if not revised(s):return v
 if v.id==ID:
  if s.context.get("floor","")=="commune":
   v.body="莉季娅把借来的杯子洗净，放回医务室的架子。\n莉季娅：「药箱已经拆开了。我先帮值班医护看一会儿登记。等这班结束，我还得写信，告诉家里我到了哪里。」"
   v.options=[s.opt("c_c1_aftercare",data().actions.c1_aftercare.text,s.Campaign.available(s,"c1_aftercare"))]
  elif not s.f("field_c1_scene_seen"):
   v.body="女人站在转移点的灯下，袖口系着褪色的医护标记。她先看你的双手，确认你没有举枪，才朝封好的药箱点了点头。"
   v.options=[s.opt("c_front_take_evidence","「我是来接药品的。这里还有谁需要离开？」",s.Campaign.available(s,"front_take_evidence"))]
  elif s.f("c1_lidiya_waiting"):
   v.body="莉季娅在南口等候处停下来，将背包垫在药箱下面，免得箱底受潮。\n莉季娅：「这边的门还能关上。我在这里等车，你去确认接送，别忘了回来。」"
  else:v.body="莉季娅背好自己的小包，沿西侧廊道向南口走。\n莉季娅：「我走得慢，你不用一直守在旁边。有事去办，回来时叫上我。」"
 if v.id=="front_cache":
  v.body="两只小药箱放在转移点的桌边，封签完整。箱上写着敷料和退热药的数量，旁边压着一张被收回的通行条。莉季娅在灯下等着，得先问清她和药品的情况。"
  if s.f("field_c1_evidence"):v.body="桌边留下了垫药箱的旧布。药品已收进你的背包，封签和数量也记下了。"
 if v.id=="front_routes":v.body="图上标出了西侧转移点、南口候车处和北口信号箱。北端有兽群活动，墙上的维修条注明：南控制间保留备用有线机，能够向同一位司机发出呼叫。"
 return v
static func act(s,key:String):
 if not revised(s):return
 if key=="front_take_evidence":s.give("c1_medicine")
 if key=="field_c1_report":s.take("c1_medicine");s.flags.c1_clinic_pending=true
 if key=="c1_aftercare":s.flags.c1_settled=true
 if key=="front_return" and s.Campaign.Update.mission(s)=="c1":s.flags.next_sequence="c1_return_safe" if s.f("field_c1_ready") else "c1_return_early"
func setup(world):
 w=world;sync()
func sync():
 var s=w.story
 var present=(w.floor_id=="railfront" and s.f("field_c1_in_progress") and not s.f("field_c1_done")) or (w.floor_id=="commune" and s.f("field_c1_done"))
 present=present and revised(s)
 if not present and w.npcs.has(ID):
  w.npcs[ID].queue_free();w.npcs.erase(ID);w.targets.erase(ID);w.living.routes.erase(ID)
 if not revised(s):
  for prefix in ["ReturnedMedicalCase*","CommuneMedicalArrival*"]:
   for node in w.find_children(prefix,"MeshInstance3D",true,false):node.visible=false
  for id in ["c1_backup","c1_spares","c1_orders","c1_linen"]:w.targets.erase(id)
  return
 if present and not w.npcs.has(ID):
  var p=Vector3(-19,0,-12) if w.floor_id=="railfront" else Vector3(-8,0,18.7)
  if w.floor_id=="railfront" and s.f("c1_lidiya_waiting"):p=WAYPOINTS[-1]
  w.person(ID,p,"cloth",false,"coal_medic");var actor=w.npcs[ID];w.living.configure(actor)
  var saved:Dictionary=w.arrival_data.get("npc_positions",{}).get(ID,{})
  if saved.is_empty() and s.flags.get("medical_actor",{}).get("floor","")==w.floor_id:saved=s.flags.medical_actor
  if saved.get("position",[]).size()==3:
   var a=saved.position;actor.position=w.clear_arrival(Vector3(a[0],0,a[2]))
  w.target(ID,actor.position,"莉季娅 / 医护转移者","talk")
 if w.floor_id=="railfront" and s.Campaign.Update.mission(s)=="c1" and not s.f("field_c1_done"):
  for entry in [["c1_backup",Vector3(17.5,0,16.5),"备用有线呼叫机"],["c1_spares",Vector3(-21.3,0,1),"西侧检修柜 / 保护组件"],["c1_orders",Vector3(-20.1,0,-19),"转移间 / 两份命令"],["c1_linen",Vector3(-21.1,0,19.2),"候车处 / 留下的敷料"]]:
   if not w.targets.has(entry[0]):w.target(entry[0],entry[1],entry[2])
  for node in w.find_children("SealedMissionParcel*","MeshInstance3D",true,false):node.visible=not s.f("field_c1_evidence")
  for node in w.find_children("ReturnedMedicalCase*","MeshInstance3D",true,false):node.visible=s.f("c1_lidiya_waiting")
  var lamp=w.get_node_or_null("BackupCallIndicator")
  if is_instance_valid(lamp):lamp.visible=s.f("c1_backup_online")
 elif w.floor_id=="railfront":
  for id in ["c1_backup","c1_spares","c1_orders","c1_linen"]:w.targets.erase(id)
  for node in w.find_children("ReturnedMedicalCase*","MeshInstance3D",true,false):node.visible=false
 if w.floor_id=="commune":
  for node in w.find_children("CommuneMedicalArrival*","MeshInstance3D",true,false):node.visible=s.f("field_c1_done")
func tick(_delta):
 if not revised(w.story) or w.hud.modal_visible() or w.departure_animating:return
 var s=w.story
 if w.floor_id=="railfront" and w.npcs.has(ID) and s.f("field_c1_scene_seen"):
  if not s.f("c1_lidiya_waiting"):
   var stage=clampi(int(s.flags.get("c1_walk_stage",0)),0,WAYPOINTS.size()-1)
   if w.living.direct(ID,"medical_transfer_"+str(stage),WAYPOINTS[stage],true):
    if stage+1<WAYPOINTS.size():s.flags.c1_walk_stage=stage+1
    else:w.living.mark("c1_lidiya_waiting","莉季娅已抵达南口等候处。确认接送后，就能一起返回。")
  if s.f("c1_lidiya_waiting") and s.f("c1_signal_called") and not s.f("field_c1_ready"):
   w.living.mark("field_c1_ready","药箱和同行者已经到齐，可以从南口返回公社。")
  w.targets[ID].pos=w.npcs[ID].position
func capture():
 if not w.npcs.has(ID):return
 var p:Vector3=w.npcs[ID].position
 w.story.flags.medical_actor={"floor":w.floor_id,"position":[p.x,p.y,p.z]}
