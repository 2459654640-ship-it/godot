extends RefCounted
## Decisions belong to the scene. Arrival belongs to two actors walking the map.
const BROTHER="coal_brother"
const ANNA="mine_anna"
const LIFT=Vector3(-32.8,0,-2.72)
const RESERVE=Vector3(-23,0,-25.3)
const MAIN_QUEUE=[Vector3(-34.3,0,1.15),Vector3(-32.35,0,.65)]
const RESERVE_QUEUE=[Vector3(-24.75,0,-25.8),Vector3(-21.35,0,-25.8)]
const PREP=["rescue_medic_ready","rescue_transport_ready","rescue_route_ready"]
static var authored:Dictionary={}

static func data()->Dictionary:
 if authored.is_empty():authored=JSON.parse_string(FileAccess.get_file_as_string("res://data/mine_rescue.json"))
 return authored

static func extend(c:Dictionary):
 for section in ["interactions","actions"]:c[section].merge(data()[section].duplicate(true),true)
 for q in c.quests:
  if q.id=="anna_rescue":
   q.background="安娜回到矿区接阿列克谢。她负责和医护安排同行的家属，伊万要陪伤员到转运处。提升机故障过，备用通道是否可用会改变撤离办法。"

static func available(s)->bool:
 return s.context.get("floor","")=="coal" and s.f("anna_rescue_started") and not s.f("anna_outcome_done")

static func ready(s)->bool:
 return PREP.all(func(id):return s.f(id))

static func allowed(s,key:String)->bool:
 if key=="rescue_review":return available(s) and not s.f("rescue35_walk")
 if key in ["coal_return","workers_return","coal_back_d6"] and available(s) and s.f("rescue35_walk"):return false
 return true

static func act(s,key:String):
 if key=="rescue_review":
  s.flags.next_sequence="rescue35_brief";s.flags.tracked_quest="anna_rescue"
 elif key=="anna_memorial" and s.f("rescue35_stalled"):
  s.flags.next_sequence="rescue35_account"

static func decorate(v:Dictionary,s)->Dictionary:
 if v.id=="coal_medic" and available(s):
  v.body="医护放下转运簿，给阿列克谢留了一张靠门的凳子。\n值班医护：「他能自己走，就是下台阶时站不稳。先问他要不要人跟。他走累了会说。」"
  if not s.f("rescue35_walk"):
   v.body+="\n值班医护：「主提升机早班卡过两次。班组档案柜有回风图，西边闸后是备用转运口。你可以先查路，医护和接送也能在这班补办。」"
  elif s.f("rescue35_stalled"):
   v.body+="\n值班医护：「人先在主提升间歇着。要走备用口，得把接车和照护落实。我可以在这儿补签值班单。」"
  else:v.body+="\n值班医护：「主提升间在煤运巷最西头。我先去安排步子慢的几位。」"
 elif v.id==ANNA and available(s):
  if s.f("rescue35_reserve"):v.body="安娜把哥哥的外套扣好。\n安娜：「这次他自己挑的路。我跟在他后面，你到前面替我们看灯。」"
  elif s.f("rescue35_stalled"):v.body="安娜把来回走动的孩子叫到长椅边，让他们把脚下的路让出来。\n安娜：「我在这儿照看他们。你查清楚还能不能换一条路，我们再走。」"
  elif s.f("rescue35_walk"):v.body="安娜放慢脚步，等阿列克谢自己绕过矿车。\n安娜：「听到哥哥叫你就停一会儿。他不愿意在工友面前被人架着走。」"
  else:v.body="安娜把一双厚袜子递给哥哥。他试着弯腰够到鞋帮，安娜也坐了下来，等他开口。\n安娜：「他还能自己走。你跟我们去主提升间吧，路上得有人知道什么时候等他。」"
 elif v.id==BROTHER and available(s) and s.f("rescue35_walk"):
  v.body="阿列克谢扶着墙，试着把重心移到左脚。\n阿列克谢：「歇一会儿就能继续。你先走到我看得见的地方。」"
  if s.f("rescue35_stalled"):v.body="阿列克谢在长椅边坐下，把工牌攥在手里。\n阿列克谢：「它上回停的时候，他们也让我们等。今天要是换路，给我留个能扶的地方就行。」"
  v.options=[]
 elif v.id=="rescue35_lift" and s.f("rescue35_stalled"):
  v.body="提升笼卡在井口上方。值班员拔下钥匙，把断电牌挂在操纵杆上。候车的人退到黄线外，等下一步安排。"
  v.body+="\n备用转运口已准备好。" if ready(s) else "\n尚待落实："+"、".join(missing(s))+"。可以先补办，再回来改走备用口。"
 elif v.id=="coal_exit" and available(s) and s.f("rescue35_walk"):
  v.body="这是日常探视的回程口。安娜和阿列克谢正在等这一班转运，陪他们完成交接后一起走。"
  v.options=[]
 elif v.id=="commune_aleksei" and s.f("anna_record_public") and s.f("rescue35_stalled"):
  v.body="阿列克谢把夹着袖口的夹子取下来。\n阿列克谢：「家属昨天在议事厅看了那份记录。有人认出自己那一班也签过同一张巡检表。下次开会，我想陪他坐一会儿。」"
 elif v.id=="commune_aleksei" and s.f("anna_record_family") and s.f("rescue35_stalled"):
  v.body="阿列克谢的床头放着一只文件袋。\n阿列克谢：「我给她写了三封信，只有一封寄到。剩下两封和你给我的记录放在一起。等我想说的时候，我会去找娜佳。」"
 if v.id in ["rescue35_lift","rescue35_handoff",ANNA,BROTHER,"coal_medic"] and (available(s) or v.id.begins_with("rescue35_")):
  v.options=v.options.filter(func(o):return o.enabled)
 return v

static func missing(s)->PackedStringArray:
 var pending=PackedStringArray()
 for i in PREP.size():
  if not s.f(PREP[i]):pending.append(["医护照护","接送确认","备用闸门"][i])
 return pending

static func task(s,q:Dictionary,current:Dictionary)->Dictionary:
 if q.id!="anna_rescue" or not available(s):return current
 if s.f("rescue35_reserve_arrived"):
  return objective("rescue35_handoff","两人都到备用转运硐室了。到升降门前与接车值班员核对人数，再回公社。")
 if s.f("rescue35_reserve"):
  var who=ANNA if s.f("rescue35_brother_reserve") else BROTHER
  return objective(who,"沿西侧巷道向北，穿过已打开的回风闸。陪两人到备用转运硐室，中途可以停下来等他们。")
 if s.f("rescue35_stalled"):
  if ready(s):return objective("rescue35_lift","备用转运口、接车和医护都已确认。在主提升间和值班员商量改走备用通道。")
  return objective("rescue35_lift","主提升机已停。到提升间看值班记录，决定继续补齐备用路线，还是使用未经确认的旧作业斜道。待准备："+"、".join(missing(s))+"。")
 if s.f("rescue35_assembled"):
  return objective("rescue35_lift","安娜和阿列克谢已到主提升间。到操纵台与值班员核对乘梯次序。")
 if s.f("rescue35_walk"):
  var who=ANNA if s.f("rescue35_brother_main") else BROTHER
  return objective(who,"陪两人沿煤运巷向西，到主提升间。离他们太远时，他们会停下来等你。")
 return objective(ANNA,"先去东北休养间和安娜、阿列克谢商量怎么走。医护、接车和备用闸门可以提前落实。")

static func objective(id:String,step:String)->Dictionary:
 return {"place":"coal","target":id,"step":step}

static func result(s)->String:
 if s.f("anna_record_public"):return "阿列克谢审核后将事故经过交给公社，公开了安娜的名字。转运班封停旧作业斜道。"
 if s.f("anna_record_family"):return "阿列克谢收下完整记录，决定等自己准备好再谈。转运班已收到封停斜道的请求。"
 if s.f("anna_alive"):return "安娜和阿列克谢随车回到公社。阿列克谢继续休养，安娜已着手恢复孩子们的课程。"
 return "阿列克谢已在公社安顿，安娜留下的物品由家属收好。"

static func sync(w):
 if w.floor_id!="coal":return
 for pair in [["MainHoistReady",not w.story.f("rescue35_stalled")],["MainHoistFault",w.story.f("rescue35_stalled")],["ReserveHoistReady",w.story.f("rescue35_reserve")]]:
  var light=w.get_node_or_null(pair[0])
  if is_instance_valid(light):light.visible=pair[1]
 if available(w.story):
  for entry in [["rescue35_lift",LIFT],["rescue35_handoff",RESERVE]]:
   if not w.targets.has(entry[0]):w.target(entry[0],entry[1],data().interactions[entry[0]].name,"talk")
 else:
  w.targets.erase("rescue35_lift");w.targets.erase("rescue35_handoff")

static func tick(w):
 var s=w.story
 if not available(s) or not s.f("rescue35_walk"):return
 if s.f("rescue35_reserve"):
  escort(w,RESERVE_QUEUE,"reserve","rescue35_reserve_arrived","两人都到备用转运口了。去升降门前完成交接。")
 elif not s.f("rescue35_stalled"):
  escort(w,MAIN_QUEUE,"main","rescue35_assembled","安娜和阿列克谢已到主提升间。去操纵台旁核对乘梯次序。")
 if w.npcs.has(BROTHER) and not s.f("rescue35_walk_words") and w.npcs[BROTHER].position.x<-6:
  s.flags.rescue35_walk_words=true
  w.hud.toast("阿列克谢：「我以前推车从这儿过去。前面绕开那条轨，我跟得上。」",6)

static func map_destination(s)->Vector3:
 if not available(s) or not s.f("rescue35_walk"):return Vector3.INF
 if s.f("rescue35_reserve"):return RESERVE
 if not s.f("rescue35_stalled"):return LIFT
 return Vector3.INF

static func escort(w,positions:Array,leg:String,end_flag:String,notice:String):
 var s=w.story
 if s.f(end_flag):return
 var arrived=true
 for i in 2:
  var id=BROTHER if i==0 else ANNA
  var flag="rescue35_"+("brother_" if i==0 else "anna_")+leg
  var at_destination=w.living.direct(id,end_flag+"_"+id,positions[i],true)
  if at_destination and not s.f(flag):s.flags[flag]=true
  arrived=arrived and at_destination
 if arrived:w.living.mark(end_flag,notice)
