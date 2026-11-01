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
 if s.f("commune_member"):return "commune"
 if s.f("sech_member"):return "sech"
 if s.f("d6_cargo_returned") and not s.f("sided_veteran"):return "labor"
 return String(s.flags.get("east_home","commune"))
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
static func task_stage(s,q:Dictionary,current:Dictionary)->Dictionary:
 var f:String=s.context.get("floor","")
 var c=current.duplicate()
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
 if v.id in ["commune_guard","sech_elder","d6_return_desk"] and active_job(s)!="":
  var id=active_job(s);v.body+="\n当前工作："+data().jobs[id].name+"。\n"+objective(s)
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
 if key=="late_c2_letters" and s.f("late_c2_public_consent"):return "巴拉诺娃先征询每位收件人的意见，再把愿意署名的收信名单留给委员会。地址和接应人仍不公开；没有消息的几封继续单独查找。尤里坐在门边，帮她读被水浸淡的字。"
 if key=="late_plan_review":return objective(s)+"\n必要校验仪、接头和便携模块由主线配给；无须随机搜刮或出售关键物品换取。"
 return ""
static func panel(s,p:Dictionary)->Dictionary:
 var node:String=s.flags.get("comic",{}).get("node","")
 if node=="late_north_signal":p.end="resume:"+{"commune":"commune_guard","sech":"sech_elder","labor":"d6_return_desk"}[home(s)]
 if node=="late_final_result":
  var mode:String=s.flags.get("late_final_mode","shared")
  var result={"shared":"多个独立接收点发回了复述。警告保留了读数来源与时间，人员名单没有随公开信息传播。几处运输线据此改道；还有没有回执的地方，值守继续呼叫，没有把沉默写成平安。","central":"中央列车的实际班次与民用席位逐项对上。地方警报已经先行发出，备用路线留在各站，不必等待下一份宣传口径。你支持了集中调度，也保留了能检验承诺的记录；这份责任不会因为行动结束就消失。","distributed":"紧急预警先于设备转移发出。两处受训值守接到了模块、标定方法与维修副本，原设施覆盖缩小的区域也明确告知。以后不再只依赖一扇门内的机器，但维护、备件与信任仍要一班班继续。","watch":"外部接收人复述了新一轮测量。你选择留在这一班的观测岗位，备用供电经过实际测试，撤离人员已经交到接应者手中。父亲和你能否重新成为家人，仍由今后的相处决定，工作不再要求把个人生活永远搁置。"}
  p.body=result[mode];p.art=data().endings["warning_"+mode].art
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
  var relation="你们约好以后再谈，有些话仍需时间。" if s.f("late_family_later") else ("你保留了与父亲共事的关系，也明确了私人相处的距离。" if s.f("late_family_closed") else "你愿意再见父亲，原谅并没有抹去他必须承担的责任。")
  p.body="你在给谢苗诺夫的信里先报平安，再写这一趟经过。"+relation+"\n\n养大你的人不会从这些年里被替换掉。你仍记得那间工坊、编号纸，以及老爹在出门前反复让你检查的面具。下一班要去哪里，现在由你自己决定。"
 if node in ["late_final_result","late_epilogue_people","late_epilogue_family"]:p.erase("lines")
 return p
static func finish(s):
 var id="warning_"+String(s.flags.get("late_final_mode","shared"))
 s.flags.late_campaign_complete=true;s.flags.campaign_ending=id;s.flags.chapter_endpoint="ending:"+id;s.ending=true
 var seen:Array=s.flags.get("endings_seen",[])
 if id not in seen:seen.append(id)
 s.flags.endings_seen=seen
