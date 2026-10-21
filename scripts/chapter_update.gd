extends RefCounted
## Authored chapter state: no elapsed-time death, random survival roll or hidden item gate.
static var _data:Dictionary={}
static func data()->Dictionary:
 if _data.is_empty():_data=JSON.parse_string(FileAccess.get_file_as_string("res://data/chapter_update.json"))
 return _data
static func extend(c:Dictionary):
 for section in ["actions","interactions"]:
  for key in data()[section]:c[section][key]=data()[section][key].duplicate(true)
 c.quests.append_array(data().quests.duplicate(true))
 # The initial search leads to a visit, not a resolved rescue or romance.
 for q in c.quests:
  if q.id=="north_late":continue
  if q.id=="commune_chapter":q.background="加入公社后，先熟悉居民与工作，再参加出站任务。建立信任需要实际经历。"
static func mission(s)->String:return String(s.flags.get("field_mission",""))
static func ready(s)->bool:return ["rescue_medic_ready","rescue_transport_ready","rescue_route_ready"].all(func(k):return s.f(k))
static func allowed(s,key:String)->bool:
 if key in ["commune_stay","anna_home","ending_workers"] and s.f("sech_member"):return false
 if key in ["sech_stay","ending_train","ending_caravan"] and s.f("commune_member"):return false
 if s.f("anna_dead") and key in data().interactions.commune_anna.options:return false
 if key.begins_with("field_"):
  var parts=key.split("_");var id=parts[1]
  if data().missions.has(id):
   if s.f("field_"+id+"_done"):return false
   if parts[-1]=="accept" and s.f("field_"+id+"_accepted"):return false
 if key=="cross_contact" and s.f("cross_contact_ready"):return false
 if key.begins_with("front_"):
  var id=mission(s)
  if not data().missions.has(id) or s.f("field_"+id+"_done"):return false
  if key=="front_read_routes":return not s.f("field_"+id+"_routes")
  if key=="front_take_evidence":return s.f("battle_"+id+"_west") and not s.f("field_"+id+"_evidence")
  if key=="front_restore_signal":return s.f("field_"+id+"_evidence") and s.f("field_"+id+"_scene_seen") and s.f("battle_"+id+"_north") and not s.f("field_"+id+"_ready")
  if key=="front_supply":return not s.f("field_"+id+"_supplied")
 return true
static func act(s,key:String)->String:
 if key.begins_with("field_") and key.ends_with("_accept"):s.flags.tracked_quest="field_"+key.split("_")[1]
 if key=="anna_warning":s.flags.tracked_quest="anna_rescue"
 if key=="surface_turnin":s.flags.chapter_first_field=true
 if key in ["commune_sech","sech_commune"]:s.flags.cross_contact_ready=false;s.flags.cross_contact_trips=int(s.flags.get("cross_contact_trips",0))+1
 if key.begins_with("field_") and key.ends_with("_depart"):
  var id=key.split("_")[1];s.flags.field_mission=id;s.flags["field_"+id+"_in_progress"]=true
  if not s.has("revolver"):s.give("revolver")
 if key.begins_with("front_"):
  var id=mission(s);var m:Dictionary=data().missions[id]
  match key:
   "front_read_routes":s.flags["field_"+id+"_routes"]=true
   "front_take_evidence":s.flags["field_"+id+"_evidence"]=true;s.flags.next_sequence="field_"+id+"_interlude";return m.evidence
   "front_restore_signal":s.flags["field_"+id+"_ready"]=true;return "接收方复述了本班识别号，南口司机确认收到。你把信号箱关好，准备带记录与沿途见到的人一起回去。"
   "front_supply":
    s.flags["field_"+id+"_supplied"]=true;s.economy.handmade+=24;s.economy.goods.bandage=int(s.economy.goods.get("bandage",0))+2
    return "领取土制子弹 ×24、绷带 ×2。本班补给已签收，领用簿已经登记。"
   "front_return":s.flags.next_sequence="front_back_"+m.faction;return "你核对了回程识别灯，沿南口撤回。本班尚未销号，可以补给后再回去继续处理。"
 if key=="anna_prepare_status":
  var rows:Array[String]=[]
  for entry in [["rescue_medic_ready","医护照护"],["rescue_transport_ready","矿口接送"],["rescue_route_ready","备用撤离出口"]]:rows.append(entry[1]+("：已落实" if s.f(entry[0]) else "：待落实"))
  return "安娜和你逐项核对：\n"+"\n".join(rows)+"\n开始撤离前仍可补齐，医护会等三项核实后再发出转移通知。"
 return ""
static func decorate(v:Dictionary,s)->Dictionary:
 if v.id=="commune_class" and not s.f("anna_dead"):v.options=[]
 if v.id=="commune_anna" and s.f("anna_dead"):
  v.name="安娜留下的课桌";v.options=[]
 if v.id=="coal_medic" and s.f("anna_rescue_started") and not s.f("anna_outcome_done"):
  v.body="医护把转移名单挂到灯下。\n值班医护：「这里仍能补办救护和矿口接送。回风图在班组档案柜，备用出口在最西侧旧支巷。准备齐了再回来，我们一起复核。」"
 if v.id=="coal_brother" and s.f("anna_outcome_done"):
  v.body="阿列克谢已经随医护交换队离开矿区，在公社接受后续照护。休养间的床位登记已经销号。";v.options=[]
 if v.id=="front_cache" and data().missions.has(mission(s)):v.name=data().missions[mission(s)].object
 if v.id=="front_exit" and data().missions.has(mission(s)):
  v.body+="\n本班："+data().missions[mission(s)].name
 return v
static func objective(s)->String:
 var floor:String=s.context.get("floor","")
 if floor=="railfront":
  var id=mission(s)
  if id=="":return "从南口接送线返回聚落"
  if s.f("field_"+id+"_ready"):return "回程信号已确认 · 从南口撤回，向轮值员汇报"
  if s.f("field_"+id+"_evidence"):return "清理北口威胁 · 在北侧信号箱确认回程接送"
  if s.f("field_"+id+"_routes"):return "经检修侧廊前往西侧转移点 · 清理威胁并核对记录"
  return "先在南控制间核对线路图 · 本班补给在南口工具箱"
 if floor=="coal" and s.f("anna_rescue_started") and not s.f("anna_outcome_done"):
  if not s.f("rescue_air_known"):return "到班组档案柜查回风图 · 矿区仍可补办医护与接送"
  if not s.f("rescue_route_ready"):return "到最西侧旧支巷打开回风闸，确认备用撤离路线"
  return "回医护值班处复核撤离条件 · 可以继续准备后再开始"
 if floor in ["commune","sech"] and s.f(floor+"_member"):
  var prefix="c" if floor=="commune" else "s"
  for num in range(1,4):
   var id=prefix+str(num)
   if not s.f("field_"+id+"_done"):return "找本阵营轮值员汇报" if s.f("field_"+id+"_ready") else ("在出发登记处启程："+data().missions[id].name if s.f("field_"+id+"_accepted") else "向本阵营轮值员了解下一轮出站工作")
  return "北线已具备接送条件 · 向轮值员核对东方-7，再考虑前往星城外围"
 return ""
static func migrate(s,revision:int):
 if revision>=22:return
 if s.f("anna_reunited") or s.f("c_done_anna_result"):
  s.flags.anna_first_news=true;s.flags.anna_lesson_seen=true;s.flags.legacy_anna_visit_completed=true
 elif s.f("anna_request"):s.flags.anna_lesson_seen=true
 if s.f("commune_member") and s.f("sech_member"):
  var keep_sech=s.context.get("floor",s.flags.get("campaign_location",""))=="sech"
  s.flags.legacy_dual_membership=true;s.flags["commune_member" if keep_sech else "sech_member"]=false
 # Do not reset possessions, passed checks, read books, old rewards or witnessed scenes.
 if s.flags.get("comic",{}).get("active",false) and s.flags.comic.get("node","") in ["anna_survival","anna_loss_home"]:return
