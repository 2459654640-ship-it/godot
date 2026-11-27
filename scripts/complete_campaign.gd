extends RefCounted
## Complete campaign events. State describes actual work, not an invisible morality score.
static var authored:Dictionary={}
const NEW_FLOORS=["junction","relay","star_interior"]
const WEAPONS=["revolver","grey_carbine"]
static func data()->Dictionary:
 if authored.is_empty():authored=JSON.parse_string(FileAccess.get_file_as_string("res://data/complete_campaign.json"))
 return authored
static func extend(c:Dictionary):
 for section in ["actions","interactions","panels","endings"]:c[section].merge(data()[section].duplicate(true),true)
 c.quests.append_array(data().quests.duplicate(true))
 for id in data().extensions:
  if not c.interactions.has(id):continue
  for key in data().extensions[id]:
   if key not in c.interactions[id].options:c.interactions[id].options.append(key)
 # Public routes use an explicit late-work or inquiry gate below.
 c.actions.east_take_north.req={"all":["east_power_restored","star_known"],"any":["north_inquiry_ready","late_d3_started","late_star_admitted"]}
 for id in ["c2","c3","s1","s2","s3"]:
  c.actions["field_"+id+"_depart"].req["not"].append("late_"+id+"_started")
  c.actions["field_"+id+"_report"].req["not"].append("late_"+id+"_started")
static func home(s)->String:
 var base=s.Campaign.District.Contacts.home(s)
 return base if base in ["commune","sech","labor"] else "commune"
static func completed_route(s)->bool:
 match home(s):
  "commune":return s.f("field_c1_done") and (s.f("late_c3_done") or s.f("field_c3_done"))
  "sech":return s.f("late_s3_done") or s.f("field_s3_done")
  "labor":return s.f("late_d3_done")
 return false
static func job_ready(s,id:String)->bool:
 var keys={"c2":"late_c2_evacuated","s1":"late_s1_driver_arrived","s3":"late_s3_evacuated","d1":"late_d1_evacuated"}
 return s.f(keys.get(id,"late_"+id+"_done"))
static func active_job(s)->String:
 var id:String=s.flags.get("late_active_job","")
 return id if data().jobs.has(id) and not s.f(data().jobs[id].done) else ""
static func migrate(s):
 for id in ["c2","c3","s1","s2","s3"]:
  if s.f("field_"+id+"_done"):s.flags["late_"+id+"_done"]=true
 # Do not infer admission, family conversations or final preparation from old star_access.
static func allowed(s,key:String)->bool:
 if key in ["east_take_north","late_take_north_foot"]:return s.f("late_d3_started") or (s.f("north_story_ready") and s.f("north_inquiry_ready")) or s.f("late_star_admitted")
 if key=="late_north_contact":return completed_route(s) and s.context.get("floor","")==home(s)
 if key=="late_relay_depart":return s.f("late_relay_assigned") or s.f("late_d3_started") or s.f("late_star_admitted")
 if key=="late_star_request":return completed_route(s) and s.f("north_story_ready")
 if key=="late_father_photo" and not s.has("photo"):return false
 if key=="late_final_confirm":return s.flags.get("late_final_mode","") in ["shared","central","distributed","watch"] and not s.f("late_campaign_complete")
 if key.begins_with("late_plan_") and s.f("late_campaign_complete"):return false
 if key in ["late_c2_consent","late_c2_public"] and s.f("late_c2_escort"):return false
 if key in ["late_d2_truth","late_d2_polish"] and s.f("late_d2_reported"):return false
 if key=="late_s3_people" and s.f("late_s3_depart_ready"):return false
 if key=="late_s3_both" and s.f("late_s3_depart_ready"):return false
 if key in ["late_d1_civilian","late_d1_both","late_d1_fuel"] and s.f("late_d1_dispatched"):return false
 if key=="late_junction_enter":return active_job(s) in ["c2","s1","s3","d1"] or s.f("late_star_admitted")
 if key=="late_junction_to_star":return s.f("late_star_admitted")
 var active=active_job(s)
 if key.begins_with("front_") and active!="":return false
 if key=="east_enter_railfront" and active!="":return false
 if data().actions.has(key):
  var a:Dictionary=data().actions[key]
  if a.has("mode") and (s.flags.get("late_final_mode","")!=a.mode or s.f("late_campaign_complete")):return false
  for id in data().jobs:
   if key==data().jobs[id].accept and active!="" and active!=id:return false
 if key=="late_c2_report" and not s.f("late_c2_home_arrived"):return false
 if key in ["late_s1_report","late_s3_report","late_d1_report"] and not s.f(key.trim_suffix("_report")+"_home_arrived"):return false
 return true
static func safe_interaction(w,id:String)->bool:
 if w.floor_id not in ["junction","relay"] and id!="late_captive":return false
 return w.combat.enemies.all(func(e):return not is_instance_valid(e) or e.hp<=0 or e.position.distance_to(w.player.position)>6 or not w.combat.sight(e.position+Vector3.UP*.7,w.player.position+Vector3.UP*.7))
static func include_quest(s,q:Dictionary)->bool:
 if q.id.begins_with("field_") and s.f("late_"+q.id.trim_prefix("field_")+"_started"):return false
 if q.id=="north_late" and s.f("late_north_contacted"):return false
 return true
static func result(s,id:String)->String:
 var rows={"late_c2":"尤里已平安返站，书信交由巴拉诺娃按收件人分别转交。尚未查到下落的人继续留在查找簿上。", "late_c3":"家属支路修复，温室与家属房轮换供暖；居民参与核对温度，原通知已更正。", "late_s1":"检修车恢复制动与旁线，安东已返站并获得休息班。", "late_s2":"阿尔乔姆已回到谢契，当面说明被扣经过；争议货物另行追查。", "late_s3":"四名住户已交给谢契接应。"+("修复拖车后，粮食与乘员同班抵达。" if s.f("late_s3_all_carried") else "伤病者先抵达，粮食由留下的值守看护，下一班接运。"), "late_d1":"伤员已交医务间，运输次序与燃料延误保留在交接记录。", "late_d2":"公共取水支路已经恢复。"+("报告保留总管与住区的两组实际读数。" if s.f("late_d2_truthful") else "总表按恢复填写，未通住区的问题保留在维修附注。"), "late_d3":"两处独立测量已交回，技术联络委派已签发；星城仍需自行核验入站申请。", "late_perimeter":"已向星城说明技术来意，领取外线检修安排；这份介绍没有代替门禁核查。", "late_star_access":"外线收发校验通过，去污及装备登记完成，获得有限工作区准入。", "late_family":"核实身份、共同标定和查阅通信记录后，已与父亲谈过他的责任。今后的私人关系仍由你决定。", "late_warning":"已完成“"+String(data().endings.get("warning_"+String(s.flags.get("late_final_mode","shared")),{}).get("title","预警与撤离"))+"”。人物后续保存在已读经历中，未完支线仍可继续。", "late_mine_cover":"报班铃已试响，瓦西里确认这一班的带路人与撤离安排。私人接应没有撤销通缉，也不允许公开进入 D-6。"}
 return rows.get(id,"已交付，报酬与经过记入手记。")
static func task_stage(s,q:Dictionary,current:Dictionary)->Dictionary:
 var f:String=s.context.get("floor","")
 var c=current.duplicate()
 if q.id=="anna_rescue" and not s.Campaign.Access.public_entry(s) and not s.f("anna_rescue_started"):
  if not s.f("east_mine_prepared"):return {"target":"commune_printer","place":"commune","step":"先请娜佳确认矿区内部接应、检修入口和退路，寻亲材料不能用于正门通行。"}
  if not s.f("late_mine_cover_ready"):return {"target":"coal_clerk","place":"coal","step":"从已侦察的检修路找瓦西里，确认安娜同行这一班的带路人与撤离；报班铃可亲手修，也可出维修料请工友修。"}
 if q.id=="late_perimeter" and f==home(s):
  c.target={"commune":"commune_leave","sech":"sech_leave","labor":"d6_surface_gate"}[f];c.place=f;c.step="从本聚落出站，沿北线接送路到星城外围，在声讯柱申请外线检修。"
 if q.id=="late_d3" and s.f("late_d3_street") and f=="starcity" and not s.f("late_d3_relay"):
  c.target="late_perimeter_relay";c.place=f;c.step="从外侧检修路进入中继站，取得暴露区第二组读数；不需要越过星城隔离门。"
 if q.id.begins_with("late_") and q.id.trim_prefix("late_") in data().jobs:
  var id=q.id.trim_prefix("late_");var j:Dictionary=data().jobs[id]
  if f=="east_district" and not s.f("late_"+id+"_home_arrived"):
   if id in ["c2","s1","s3","d1"] and not s.f("late_"+id+"_evacuated") and not s.f("late_"+id+"_ready") and not s.f("late_"+id+"_dispatched"):
    c.target="late_junction_entry";c.place=f;c.step="沿北线货场外侧到检修阶梯，进入地下换乘线。"
   elif id=="s2" and not s.f("late_s2_evacuated"):
    c.target="grey_shelter_entry";c.place=f;c.step="在灰狗营地棚屋旁找到地下入口。可从围栏缺口轻步潜入，或利用掩体交战。"
   elif id!="d3" or s.f("late_d3_relay"):
    c.target="east_"+{"commune":"commune_entry","sech":"sech_entry","labor":"d6_entry"}[j.home];c.place=f;c.step="沿地图回到所属聚落入口，交接这趟的人员、物资与记录。"
 if q.id=="late_d1" and s.f("late_d1_dispatched") and not s.f("late_d1_evacuated"):
  c={"target":"junction_patients","place":"junction","step":"回候车室接两位能自行走动的伤员，陪他们走到南口；重伤员已由担架队安置在车内。"}
 if q.id=="late_s1" and s.f("late_s1_ready") and not s.f("late_s1_driver_arrived"):
  c={"target":"late_driver","place":"junction","step":"车已经修好，陪安东到南口接送处；他会等你靠近后继续。"}
 if q.id=="late_star_access":
  if f=="starcity" and not s.f("late_relay_verified"):c.target="late_perimeter_relay";c.place=f;c.step="从外侧检修路进入中继站，检查并校验馈线。"
  elif f=="relay" and s.f("late_relay_verified"):c.target="relay_exit";c.place=f;c.step="维修回执已核验。返回外围接受去污和装备登记。"
 if q.id=="late_warning":
  if s.f("late_exposed_reading") and not s.f("late_sheltered_reading"):c={"target":"late_street_probe","place":"east_district","step":"去工人街诊所外的背风测点，用同一台仪器测量；主线设备已配给。"}
  elif s.f("late_risk_confirmed") and not s.f("late_father_truth_seen"):c={"target":"late_father","place":"star_interior","step":"先读私人通信记录，再和父亲谈明责任；公共方案不以原谅他为前提。"}
  elif s.f("late_final_started"):
   var mode:String=s.flags.get("late_final_mode","");var done_steps:Array=data().endings["warning_"+mode].steps
   var tasks={
    "late_shared_packet":["late_planning","star_interior","先制作有来源的预警副本，将人员名单与公开风险分开。"],"late_shared_receiver":["junction_final_receiver","junction","到换乘站接通独立接收机，取得逐项复述的回执。"],"late_shared_evac":["relay_generator","relay","到中继站南侧安排改道住户，陪他们走到接应点。"],
    "late_central_agreement":["late_planning","star_interior","先与中央明确民用警报、撤离席位和发布时间，双方各留副本。"],"late_central_train":["junction_final_receiver","junction","到换乘站核对民用乘员，锁定撤离列车的进路。"],"late_central_alarm":["relay_generator","relay","在中继站打开本地警报，核对民用列车回执。"],
    "late_distributed_copy":["late_planning","star_interior","先发紧急预警，再制作维修与校准副本。"],"late_distributed_modules":["relay_generator","relay","到中继站隔离备用回路，装箱两只可搬模块。"],"late_distributed_handover":["junction_final_receiver","junction","将模块交给受训值守，现场完成独立校验。"],
    "late_watch_power":["relay_generator","relay","检修中继站备用供电，测试主电源断开后的切换。"],"late_watch_shift":["junction_final_receiver","junction","到换乘站安排外部接收与人员撤离交班。"],"late_watch_broadcast":["late_watchdesk","star_interior","回测控台完成下一轮测量，取得外部复述后播发。"]}
   for key in done_steps:
    if not s.f(key):var t:Array=tasks[key];return {"target":t[0],"place":t[1],"step":t[2]}
   if mode=="shared" and not s.f("late_final_execution_done"):return {"target":"relay_evac_group","place":"relay","step":"与控制屋前的改道住户会合，陪他们沿西侧检修路走到南口接应点。"}
   c={"target":"late_planning","place":"star_interior","step":"核对本轮回执与同行者结果，完成最终交接。"}
 return c
static func objective(s)->String:
 if s.f("late_campaign_complete"):return "本轮预警与撤离已完成，可以继续自由探索；手记保留人物后续与未完成支线。"
 var desired="late_perimeter"
 if active_job(s)!="":desired="late_"+active_job(s)
 elif s.f("late_star_admitted"):desired="late_warning" if s.f("late_father_truth_seen") else "late_family"
 elif s.f("late_relay_assigned"):desired="late_star_access"
 for q in data().quests:
  if q.id!=desired or not s.f(q.accepted) or s.f(q.done):continue
  var current:Dictionary=q.stages[0]
  for st in q.stages:
   if s.Campaign.permits(s,st.when):current=st
  return task_stage(s,q,current).step
 return ""
static func decorate(v:Dictionary,s)->Dictionary:
 # Base D-6 actors are outside campaign.json; append their late-work options here.
 if not s.Campaign.data().interactions.has(v.id):
  for key in data().extensions.get(v.id,[]):
   if s.Campaign.available(s,key):v.options.append(s.opt("c_"+key,data().actions[key].text))
 if v.id=="plant_veteran" and s.context.get("floor","") in ["junction","relay","starcity"]:
  v.body="老兵正在检查背带，听到你过来，抬头示意你说。"
  v.options=[]
  for key in ["late_veteran_route","late_veteran_family"]:
   if s.Campaign.available(s,key):v.options.append(s.opt("c_"+key,data().actions[key].text))
 if v.id in ["commune_guard","sech_elder","d6_return_desk"] and active_job(s)!="":
  var id=active_job(s);v.body+="\n当前工作："+data().jobs[id].name+"。\n"+objective(s)
 if v.id=="commune_anna" and s.f("late_mine_cover_ready") and not s.f("anna_rescue_started"):
  v.body+="\n安娜：「瓦西里把班次确认了。我跟工友走地下搬运支线，你从检修巷进，我们在休养间会合。没有人会去正门替你递材料。」"
  for option in v.options:
   if option.key=="c_anna_rescue_depart":option.text="按内部接应安排出发，与安娜在矿区会合。"
 if v.id=="late_planning":
  var mode:String=s.flags.get("late_final_mode","")
  v.body+="\n当前方案："+(data().endings["warning_"+mode].title if mode!="" else "尚未选择")+"。"
  if s.f("late_final_started"):v.body+="\n本轮当前目标："+objective(s)
  else:v.body+="\n确认时会单独保存“最终行动前”，不覆盖六个手动档位。"
 if v.id=="late_father" and s.f("late_father_truth_seen"):
  v.body="父亲收好你们共同签认的工作卡。\n父亲：「我会按约留下记录。家里的事，你什么时候愿意谈，我就什么时候回答。先把这一班该核对的事情做完。」"
 if v.id=="junction_yuri" and s.context.get("floor","")=="commune":v.body="尤里在食堂喝过热水，正在帮忙核对余下的信封。\n尤里：「没有查到的几封，我已经另外记下。等腿好一点，我还会再去问，不会让他们一直只等着。」";v.options=[]
 if v.id=="late_captive" and s.f("late_s2_escort"):
  v.body="阿尔乔姆在厨房端着一碗饭，正等谢尔盖坐下。他已经把自己的经过说清，不再需要偷偷躲在门边。" if s.context.get("floor","")=="sech" else "阿尔乔姆已经收好自己的东西，会等伊万靠近后沿通路到出口。"
 if v.id=="junction_yuri" and s.f("late_c2_escort") and s.context.get("floor","")=="junction":v.body="尤里背着装有私人物品的小包，沿西侧廊道向南口走。他会等你，不会独自跑进兽群。"
 v.options=v.options.filter(func(o):return not data().actions.has(String(o.key).trim_prefix("c_")) or s.Campaign.available(s,String(o.key).trim_prefix("c_")))
 return v
static func act(s,key:String)->String:
 if key=="anna_rescue_depart" and not s.Campaign.Access.public_entry(s):
  s.Campaign.District.depart(s,String(s.context.get("floor",home(s))));s.flags.next_sequence="anna_private_depart"
 for id in data().jobs:
  var j:Dictionary=data().jobs[id]
  if key==j.accept:
   s.flags.late_active_job=id;s.flags.tracked_quest="late_"+id
  if key=="late_"+id+"_depart":
   s.flags.field_mission=id;s.flags["field_"+id+"_in_progress"]=true
   s.Campaign.District.depart(s,j.home);s.flags.next_sequence="late_"+id+"_road"
  if key=="late_"+id+"_report":
   s.flags.late_active_job=""
   if completed_route(s):s.flags.north_story_ready=true
 if key=="late_d3_accept":s.flags.star_known=true
 if key=="late_junction_return":
  var id=active_job(s);var dest=home(s)
  if id!="" and job_ready(s,id):s.flags["late_"+id+"_home_arrived"]=true
  s.flags.next_sequence="late_junction_home_"+dest
 if key=="late_north_contact":
  s.flags.star_return_home=home(s);s.flags.tracked_quest="late_perimeter"
 if key=="late_star_request":s.flags.tracked_quest="late_star_access"
 if key=="late_star_decontam" or key=="late_star_enter":
  if not s.f("late_arms_deposited"):
   s.flags.late_held_weapon=s.equipped_weapon()
   var held=[]
   for id in WEAPONS:
    if s.has(id):held.append(id);s.take(id)
   s.flags.late_held_arms=held;s.flags.late_arms_deposited=true;s.flags.weapon_drawn=false
  s.flags.tracked_quest="late_family" if not s.f("late_father_truth_seen") else "late_warning"
 if key=="late_star_exit":
  for id in s.flags.get("late_held_arms",[]):s.give(id)
  var selected:String=s.flags.get("late_held_weapon","")
  if selected!="" and s.has(selected):s.equip_weapon(selected)
  s.flags.late_held_arms=[];s.flags.late_arms_deposited=false;s.flags.weapon_drawn=false
 if key=="late_star_return_home":s.flags.east_arrival="starcity"
 if key=="late_weather_review":s.flags.tracked_quest="late_warning"
 if key=="late_final_confirm":s.flags.tracked_quest="late_warning"
 if key=="late_veteran_route":
  if s.context.get("floor","")=="relay":return "老兵：「风把废墟里的尘土卷起来了，面具别摘。你修设备，我盯着中间那条路。西侧挡风墙后能绕行，别站在空地里和它们耗。」"
  if s.context.get("floor","")=="starcity":return "老兵：「他们只给了你工作证，我在外面等。值守自己的规矩，你把检修和家里的事分别问清楚。要走了来叫我，别一个人闷着。」"
  return "老兵：「中间的轨道有兽群，西侧维修廊能绕。带人走的时候先看他们跟上没有，别只顾着自己的脚步。我在后面看着。」"
 if key=="late_c2_letters" and s.f("late_c2_public_consent"):return "巴拉诺娃先征询每位收件人的意见，再把愿意署名的收信名单留给委员会。地址和接应人仍不公开；没有消息的几封继续单独查找。尤里坐在门边，帮她读被水浸淡的字。"
 if key=="late_plan_review":return objective(s)+"\n必要校验仪、接头和便携模块由主线配给；无须随机搜刮或出售关键物品换取。"
 return ""
static func panel(s,p:Dictionary)->Dictionary:
 var node:String=s.flags.get("comic",{}).get("node","")
 if node=="late_north_signal":p.end="resume:"+{"commune":"commune_guard","sech":"sech_elder","labor":"d6_return_desk"}[home(s)]
 if node=="late_final_result":
  var mode:String=s.flags.get("late_final_mode","shared")
  var result={
   "shared":[["换乘调度员","收到。南口的车改走西边旁线。诊所也接到了，你等一下，我还在叫第二处路口。"],["伊万","我等你。电台开着。"]],
   "central":[["换乘调度员","居民这班先发。两副担架已经固定好，军运车还在旁线。民用警报开了，时间我写在回执上。"],["伊万","好。请司机到站再报一次人数。"]],
   "distributed":[["换乘值守","两台备用机分别对过标定。一台留这儿，另一台昨晚装上车。西端的覆盖会先少一段，我把转接号码贴在门边。"],["伊万","把你们下次试机的时刻也写上。我会来听。"]],
   "watch":[["父亲","风向又转了一点。看你那台表，别照我的填。"],["伊万","我这边读数在降。时间是零七点三十六。南口能听见吗？"],["换乘值守","听见了。车已经过去，我们记下这轮读数。"]]}
  write_scene(p,result.get(mode,result.shared))
  p.art=data().endings["warning_"+mode].art
 if node=="late_epilogue_people":
  var rows:Array[String]=[]
  if s.f("anna_dead"):rows.append("安娜的哥哥按医护安排继续休养。课堂由接替她的人上课，孩子们仍保留她写的进度本。你没有把她的离去算成一次交换来的胜利；有些位置会一直空着，也有人继续照顾坐在旁边的人。")
  elif s.f("anna_alive"):rows.append("安娜照顾哥哥，也逐渐把孩子们叫回课堂。她说起自己见过或还想去看的地方时，会先把面具和回程准备好。你们仍会为她该休息多久争两句，她也保留了自己决定日子的脾气。")
  elif s.f("anna_request"):rows.append("安娜仍在等哥哥的确切消息。你完成了预警，并不代表她的问题已经解决；回到公社以后，医务室的灯还会亮着，你仍可以继续帮助她。")
  if s.f("moro_done"):rows.append("莫罗仍在锅炉房轮班。演出用过的线和纸没有扔，下次谁想唱歌，要先和靠近场地的住户商量。变革在歌里，也在愿意听别人说完的一次次日常里。")
  if s.f("late_c3_heat_restored"):rows.append("公社家属房和温室继续轮换供暖。住户按班次核对温度，通知上会写清尚未恢复的部分。")
  if s.f("late_s3_all_carried"):rows.append("谢契那辆修好的拖车继续跑运输。住户记得那次人和粮食都没有留下，检修簿也保留了第二辆车要怎样维护。")
  if s.f("late_s3_people_first") and not s.f("late_s3_all_carried"):rows.append("谢契先安置了伤病者，下一班才运回粮食。留下值守的人回站后补了休息，没人把那一班的延误悄悄从簿上删去。")
  if s.f("late_d2_truthful"):rows.append("D-6 的供水报告保留总管与住区两组读数。中尉仍要面对上级的追问，排队的人也终于能在实际出水口接到水。")
  if s.f("sided_veteran"):rows.append("老兵没有因此重新穿回中央的制服。他会问你谁还没有收到消息，再帮下一班人检查枪和背带。")
  p.body="\n\n".join(rows) if not rows.is_empty() else "聚落里的人继续轮班、做饭和修理设备。有人按预警换了一条路，回到住处后又把消息告诉邻居。战争仍在，已经被人亲自核实过的消息却有了新的去处。"
 if node=="late_epilogue_family":
  var rows=[["旁白","你把台上已经复述过的站点抄进交班簿，把还在等的那一栏留白。换班的人把耳机接过去，你找了张不再用的表单，在背面给老爹写信。"],
   ["伊万（信）","老爹，我吃过饭了。标定台接到一半时停过电，好在我先把端子号写下来了。你要在跟前，肯定会问我怎么现在才写。"]]
  if s.f("late_family_closed"):rows.append(["伊万（信）","我见到了父亲。我们这几天一起做事，家里的话我还没准备好说。等我回去，先跟你说。"])
  elif s.f("late_family_open"):rows.append(["伊万（信）","父亲把两封退回来的信给了我。等我带回去，你陪我看看，好吗？我想知道母亲当时住的那条巷子是什么样。"])
  else:rows.append(["伊万（信）","父亲还在这儿。他手里有两封信，我还没去看。今天先给你写这封。"])
  rows.append(["旁白","你特意在信封上写了工坊的门和上一班的名字，请送信人当面交给谢苗诺夫。隔壁又有人开始报站号，你听了一会儿，把自己的地址也补在背面。"])
  write_scene(p,rows)
 if node=="late_epilogue_people":p.erase("lines")
 return p

static func write_scene(panel:Dictionary,entries:Array):
 panel.lines=[]
 var paragraphs:Array[String]=[]
 for entry in entries:
  panel.lines.append({"speaker":entry[0],"text":entry[1]})
  paragraphs.append(entry[1] if entry[0]=="旁白" else entry[0]+"：「"+entry[1]+"」")
 panel.body="\n".join(paragraphs)

static func finish(s):
 var id="warning_"+String(s.flags.get("late_final_mode","shared"))
 s.flags.late_campaign_complete=true;s.flags.campaign_ending=id;s.flags.chapter_endpoint="ending:"+id;s.ending=true
 var seen:Array=s.flags.get("endings_seen",[])
 if id not in seen:seen.append(id)
 s.flags.endings_seen=seen
