extends RefCounted
## One route and one purpose, shared by the journal, HUD and map. No enemy radar.
const EXITS={"commune":"commune_leave","sech":"sech_leave","labor":"main_gate","waterworks":"plant_exit","surface":"surface_exit","junction":"junction_exit","relay":"relay_exit","star_interior":"late_star_exit","starcity":"star_perimeter_call","grey_shelter":"grey_shelter_exit","railfront":"front_exit"}
const CITY_ENTRIES={"commune":"east_commune_entry","sech":"east_sech_entry","labor":"east_d6_entry","life":"east_d6_entry","surface":"east_pump_entry","waterworks":"east_waterworks_entry","coal":"east_mine_entry","starcity":"east_north_entry","relay":"east_north_entry","star_interior":"east_north_entry","junction":"late_junction_entry","railfront":"east_transfer_entry","grey_shelter":"grey_shelter_entry"}
const AREAS={"surface_yard":Vector3(0,0,4),"surface_pool":Vector3(4,0,-10),"pump":Vector3(-12,0,-6),"workshop":Vector3(-1,0,-5),"warehouse":Vector3(12,0,-6)}
static func bridge(s,task:Dictionary)->Dictionary:
 var here:String=s.context.get("floor","");var there:String=task.place
 var out=task.duplicate();out["destination_place"]=there;out["remote_step"]=task.step
 var target="";var text=""
 if here=="east_district" and there in ["commune","sech"] and not s.Campaign.District.can_enter_home(s,there):
  var base:String=s.flags.get("east_home","sech" if s.f("sech_member") else "commune")
  out.place=here;out.target=CITY_ENTRIES.get(base,"east_commune_entry");out.step="本次访站尚未落实。先回出发聚落找联络人安排接触，不能直接进入另一阵营。";out["travel_leg"]=true;return out
 if here=="east_district" and there in ["life","labor"] and not s.Campaign.Access.public_entry(s):return {}
 if here=="east_district":
  target=CITY_ENTRIES.get(there,"")
  text={"surface":"沿旧货运路寻找旧泵站检修井，进入后再检查排水与兽群。","coal":"到城区西北、厂区东侧的封停检修口等内部接应；不要去 D-6 正门。","junction":"去铁路货场检修阶梯，下到北线换乘线。","commune":"从西南公社支线返站，再找原派工人交接。","sech":"沿货场道路回谢契支线，再找原派工人交接。","labor":"去 D-6 支线口核对外勤记录，登记返站。","starcity":"沿北线联络口前往星城外围；介绍信不能代替核验。","star_interior":"先到北线联络口，再在星城外围按工作许可入站。","relay":"先到北线联络口，再从星城外围的外线检修路进入中继站。","grey_shelter":"到货场营地棚屋后的地下入口；可避开卫兵，也可利用掩体交战。"}.get(there,"从已确认的联络口前往任务设施。")
 elif here=="life" and there not in ["life","labor"]:target="lift";text="先从生活层楼梯下到作业层，再按当前身份安排出站。"
 elif here=="starcity" and there=="relay":target="late_perimeter_relay";text="从隔离门外的检修路进入中继站，无须穿越星城内区。"
 elif here=="starcity" and there=="star_interior":target="star_perimeter_call";text="在声讯柱核对检修与工作许可，完成去污及装备登记后入站。"
 elif EXITS.has(here):
  target=EXITS[here];text="先从本设施出口返回联络路，再前往"+s.Campaign.NAMES.get(there,"任务地点")+"。"
 if target=="":return {}
 out.place=here;out.target=target;out.step=text;out.area="前往任务地点";out["travel_leg"]=true
 return out
static func stage(s,q:Dictionary,current:Dictionary)->Dictionary:
 var out=current.duplicate();var here:String=s.context.get("floor","")
 if out.get("target","")=="d6_surface_gate":out.target="main_gate"
 if q.id in ["surface_survey","d6_first_duty"] and here=="surface":
  out.place=here
  if s.f("surface_sample_sealed"):out.target="surface_exit";out.step="样本已封好。回西南检修梯，再沿地表返回"+(" D-6 支线，向中尉交付。" if q.id=="d6_first_duty" else ("谢契支线，向军需处交付。" if s.flags.get("east_home","")=="sech" or s.f("surface_from_sech") else "公社支线，向守备班交付。"))
  elif not s.f("surface_notes"):out.target="surface_board";out.step="先看西南控制箱旁的排水图，确认下池入口；检修梯旁可领首次补给。"
  elif not s.f("battle_surface_yard"):out.target="surface_valve";out.step="去院落运货路，清理堵在泄水阀前的兽群。按 1 拔枪，借混凝土挡板侧移避开扑击。"
  elif not s.f("surface_drain_open"):out.target="surface_valve";out.step="院落通路已清理。到西侧泄水阀按 E，按图排低水位。"
  elif not s.f("battle_surface_pool"):out.target="surface_sample";out.step="进入北侧下池，清理采样口附近的兽群；喷吐可借挡板躲避，仍可从西南检修梯撤回。"
  else:out.target="surface_sample";out.step="下池已清理。到沉积层采样口按 E，封存委托样本；随后回西南检修梯。"
 return out
static func point(w,task:Dictionary)->Vector3:
 if task.is_empty() or task.place!=w.floor_id:return Vector3.INF
 if task.id in ["surface_survey","d6_first_duty"] and w.floor_id=="surface" and w.story.f("surface_notes"):
  if not w.story.f("battle_surface_yard"):return AREAS.surface_yard
  if w.story.f("surface_drain_open") and not w.story.f("battle_surface_pool"):return AREAS.surface_pool
 if w.targets.has(task.target):return w.targets[task.target].pos
 return Vector3.INF
static func briefing(s,task:Dictionary)->Dictionary:
 if task.id not in ["surface_survey","d6_first_duty","water","city_basin","late_s2","field_c1","late_c2","late_s3","late_d1","late_star_access","late_warning"]:return {}
 var defaults={"purpose":task.background,"return":"按手记当前目标交接。","reward":"实际完成阶段后记录结果；清理威胁不等于已经交付。"}
 if task.id in ["surface_survey","d6_first_duty"]:
  defaults.purpose="兽群正在逼近运输路。调查沉积物，确认污染有没有继续进入地下水路。"
  defaults["route"]="聚落出站 → 工业片区旧泵站入口 → 西南排水图 → 院落 → 下池采样 → 原路返站"
  defaults["return"]="D-6 作业层找科瓦廖夫交样本。" if task.id=="d6_first_duty" else ("谢契军需处交付封存样本。" if s.flags.get("east_home","")=="sech" or s.f("surface_from_sech") else "回公社守备班交付封存样本。")
  defaults.reward="完成委托：10 发制式弹、两卷绷带；额外骨片和样本可出售。" if task.id=="surface_survey" else "返站报告决定医护或路线后续；委托样本单独保护。"
 if task.id=="water":defaults["route"]="值班图 → 泵房卸压 → 修配台取保险件 → 控制室送电 → 仓库取滤芯 → 铁门集合";defaults["return"]="先把两箱滤芯交给小队，沿原路返程；返回途中再决定立场。"
 if task.id=="late_s2":defaults["route"]="谢契听取情况 → 地表营地 → 地下住户铺位 → 陪运输员到出口 → 谢契当面说明";defaults["return"]="谢契找谢尔盖听取运输员说明，再向长老交接。";defaults.reward="营救可以避开守卫；取得战利品不是完成营救的条件。"
 if task.id=="city_basin":defaults["route"]="西侧控制台检查 → 旁通泄压 → 关闭进水 → 入池迎战";defaults["return"]="威胁解除后检查战利品，可从西侧检修口撤离；无需另找派工人。";defaults.reward="这是发现后自行选择的探索挑战，可暂缓；没有隐藏的交付要求。"
 return defaults
static func encounter(id:String)->Dictionary:
 var rows={
 "pump":["通过泵房","兽群占住卸压设备附近，先保持距离，清理操作空间。","威胁解除后，到西侧旁通阀按 E 卸压。"],
 "workshop":["取得匹配的保险件","修配台附近有兽群。利用工作台挡住喷吐，别堵在门口。","清场后检查工具修配台，取保险件，再去送电控制室。"],
 "warehouse":["取回 D-6 净水滤芯","仓库内的兽群挡住封存箱，先观察冲锋与喷吐预警。","清场后核对滤芯箱，再到东南厂区铁门集合。"],
 "surface_yard":["打通泄水阀前的通路","院落兽群靠近运货路；先清出检修操作空间。","回西侧泄水阀排水，再去北侧下池。"],
 "surface_pool":["清出沉积层采样口","下池兽群守在采样口附近。保持移动，借挡板避开喷吐。","到沉积层采样口封存样本，再从西南检修梯返站。"],
 "city_basin":["蓄水池探索挑战","巨兽冲锋前会停顿蓄势。侧移，让实体挡板隔开直线。","检查巨兽留下的资源；本次探索可从西侧检修口结束。"],
 "east_road":["货运路遭遇","游荡兽群封住附近路段，可以交战，也可以绕巷撤开。","回到原任务方向；这场遭遇没有单独的交付要求。"],
 "city_radio_nest":["民防站附近的兽群","这里是可能经过的探索区域。可清理威胁，也可先避开北侧废墟。","要调查广播，进入通信站读操作记录；路过则继续原行程。"],
 "relay_feeder":["中继馈线检修","兽群在天线场活动，西侧控制屋能遮挡视线。","继续隔离馈线、接线和收发校验；未完成维修不能申请入站。"],
 "relay_final":["保护外线行动","先利用控制屋与挡风墙避开巨兽冲锋，留意其它兽类。","按所选方案继续接应、供电或模块交接，最后回星城核对回执。"]}
 if rows.has(id):var r=rows[id];return {"title":r[0],"purpose":r[1],"after":r[2]}
 if id.begins_with("junction_"):return {"title":"换乘线通行","purpose":"兽群占住中部轨道。带人通过前先清路，也可走西侧维修廊。","after":"回到本班要接的人或车辆旁，按手记安排接送；清场不等于同行者已到南口。"}
 if id.ends_with("_west") or id.ends_with("_north"):return {"title":"联络线外勤","purpose":"威胁挡在当前外勤通路上，借掩体推进，仍可从南口退回。","after":"继续当前外勤的交接与接送安排，手记会指出下一处操作。"}
 return {"title":"现场交火","purpose":"先找掩体，留意攻击预警；必要时退回安全通路。","after":"按手记继续现场工作，战利品与任务交付分开处理。"}
