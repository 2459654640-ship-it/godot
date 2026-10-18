extends RefCounted
## Accepted work, one player-selected focus, and spoiler-aware leads live separately.
static func row(id:String,name:String,done:bool,place:String,background:String,step:String,target:String="",area:String="")->Dictionary:
	return {"id":id,"name":name,"done":done,"place":place,"background":background,"step":step,"target":target,"area":area}
static func tasks(s)->Array:
	var out=[]
	if s.f("intro_done") or s.f("vitamins_taken"):
		out.append(row("journey","D-6 之外",s.f("departure_committed"),"life","接受D-6的征召加入小队并前往地表，或者想办法逃离D-6。","先下层了解征召；独自走可询问妮娜或米哈伊尔。离站必须备齐面具与滤毒罐。","commander","D-6 两层"))
		out.append(row("vitamins","今天的维生素 D",s.f("vitamins_taken"),"life","老爹嘱咐先领今日配给，再去报到。","生活层东端，第七供应点的柳德米拉留着今天的一份。","supply","第 7 供应点"))
		out.append(row("report","征召报到",s.f("accepted"),"labor","你的名字在明晨出发的小队名单上。","从值班休息区的楼梯下去，在作业层集合区找科瓦廖夫。","commander","征召集合区"))
	if s.f("accepted"):out.append(row("kit","出发准备",s.f("kit"),"labor","中尉签了登记单，面具和滤毒罐由装备库发放。","作业层北侧的装备库；领齐后到东边正门候车区。","armory","装备库"))
	if s.f("nina_job") or s.f("relay"):
		var step="妮娜提过洗漱区的旧配电柜。先找备用保险芯，再去东侧监测箱。"
		var target="cabinet";var area="洗漱 / 储物区"
		if s.has("fuse"):step="带保险芯和扳手，到东侧维修岗的压力监测箱。";target="relay";area="东侧维修岗"
		if s.f("relay"):step="监测已恢复，回维修工坊请妮娜确认并签许可。";target="nina";area="维修工坊"
		out.append(row("pressure","东段压力监测",s.has("permit"),"life","妮娜的监测箱烧坏了保险芯，检修回路已断电。",step,target,area))
	if s.f("cook_job") or s.f("valve"):out.append(row("kitchen","厨房漏水",s.f("soup_claimed"),"life","加琳娜接了一夜漏水，答应给帮忙的人留热汤。","漏已止住，回厨房找加琳娜。" if s.f("valve") else "先向维修工坊的妮娜借扳手，再看食堂灶台旁的回水阀。","cook" if s.f("valve") else ("valve" if s.has("wrench") else "nina"),"公共食堂" if s.has("wrench") or s.f("valve") else "维修工坊"))
	if s.f("heat_job") or s.f("heating_fixed"):out.append(row("heating","西翼暖气",s.has("report"),"life","帕维尔请你看看西翼家属房的暖气。","修好后找帕维尔复核。" if s.f("heating_fixed") else "借扳手，到西翼晾晒架取公用干布；再看家属房的排气阀。","resident" if s.f("heating_fixed") else ("heating" if s.has("rag") else "laundry"),"西翼家属房"))
	if s.f("shift"):out.append(row("shift","换班时的侧门",s.f("side_crossed"),"life","米哈伊尔说黄灯亮起时，侧门有短暂的检修窗口，伊戈尔未必会离岗。","先请伊戈尔去走廊查表，等他实际离开视线，再到压力表旁侧门等黄灯。","side","东侧维修岗"))
	if s.f("quest_photo") or s.f("father"):out.append(row("photo","旧照片",s.f("father"),"life","你决定找老爹问一问照片上的往事。","回相邻卧室，把照片递给谢苗诺夫。","semyon","谢苗诺夫的卧室"))
	if s.f("plant_briefed") or s.f("plant_diagram") or s.f("water_secured"):
		var step="入口气闸的值班桌上压着一张图；就在进门左手、科瓦廖夫附近。";var target="plant_diagram";var area="入口气闸"
		if s.f("plant_diagram"):step="按图先去西侧泵房卸压，备用件在北侧中间的工具修配间。";target="plant_bypass";area="西侧泵房"
		if s.f("plant_bled") and not s.f("plant_fuse"):step="旁通已经开启；去北侧中间的工具修配台取匹配的备用件。";target="plant_bench";area="工具修配"
		if s.f("plant_bled") and s.f("plant_fuse"):step="回南侧中间的送电控制室，把保险件装入柜内。";target="plant_power";area="送电控制室"
		if s.f("plant_power"):step="仓门联锁已松开，去东北侧的封存仓库核对型号。";target="plant_store";area="封存仓库"
		if s.f("water_secured"):step="两箱净水滤芯已装稳，到东南角厂区铁门集合，沿原路运回 D-6。";target="plant_exit";area="厂区铁门"
		out.append(row("water","给 D-6 的滤芯",s.f("c_done_plant_leave"),"waterworks","科瓦廖夫要求先确认设施图，再动泵房的设备。",step,target,area))
	if s.f("commune_joined") or s.f("greenhouse_clean"):out.append(row("garden","温室的回水",s.f("greenhouse_fixed"),"commune","委员会提到温室的循环水不畅。","公社西北侧温室。检查过滤篮，停泵清理后再灌水启动。","commune_greenhouse","地下温室"))
	if s.f("anna_request"):
		var place="commune";var target="commune_records";var area="联络档案室";var step="公社东北侧的联络档案室，先对照班组编号查记录。"
		if s.f("anna_records"):target="commune_leave";area="联络气闸";step="联络函已经备好，到公社东南侧气闸安排探访。"
		if s.context.get("floor","")=="labor" and s.f("d6_returned"):
			place="labor";target="commander" if not s.f("coal_access") else "coal_door";area="返站审核";step="先向科瓦廖夫办理返站身份审核，再从下层煤矿检票口进入。"
		elif s.context.get("floor","")=="coal":
			place="coal";target="coal_clerk";area="探访登记";step="先向西南侧登记员核实工牌，不要只按姓名找人。"
			if s.f("coal_registered"):target="coal_archive";area="班组档案";step="到西北侧班组档案柜，对照旧工伤与转移记录。"
			if s.f("brother_identity"):target="coal_medic";area="医护值班";step="到北侧中间的医护值班室，问清照护和探视安排。"
			if s.f("brother_care"):target="coal_brother";area="井下休养间";step="去东北侧休养间，坐下来慢慢征询本人的意愿。"
			if s.f("brother_found"):target="coal_exit";area="探视出口";step="带着核实结果从东南侧探视出口回公社。"
		elif s.f("brother_found"):target="commune_anna";area="医务与探访";step="回公社南侧医务室，把核实结果交给安娜。"
		out.append(row("anna","一个确切的名字",s.f("anna_reunited"),place,"安娜请你核实哥哥的下落，纸条上有班组编号和旧伤。",step,target,area))
	if s.f("signal_heard") or s.has("frequency"):
		var current_floor:String=s.context.get("floor","life")
		var target="semyon" if current_floor in ["life","labor"] else ("commune_receiver" if current_floor=="commune" else "sech_radio")
		var step="询问见过短波值班记录的人，或在公社联络室、谢契电台继续收听。"
		if s.f("signal_identified"):
			target="star_guard" if current_floor=="starcity" else ("commune_leave" if current_floor=="commune" else "sech_leave")
			step="广播指向星城-2。安排北线通行，抵达外门后请值守核实呼号与人员记录。"
		out.append(row("signal_trace","调查东方-7",s.f("signal_source_verified"),current_floor,"你实际听见了东方-7，记下了频率；还要查清电台在哪里。",step,target,"短波联络"))
	if s.f("sech_joined") or s.f("radio_manual"):
		out.append(row("radio","东方-7" if s.f("signal_heard") else "修复北线电台",s.f("radio_fixed"),"sech","谢契的电台坏了，居民想恢复与北线的日常联络。","西北调度台有接线图；确认接地后，再去左侧调度车厢南段的电台。" if not s.f("radio_power") else "接收机已通电，按纸上刻度慢慢调谐。","sech_manual" if not s.f("radio_manual") else "sech_radio","旧军列调度" if not s.f("radio_manual") else "电台维修室"))
	if s.f("star_registered"):
		var step="蓝门值班室的纸质规程在入口左边的桌上。";var target="star_manual";var area="蓝门值班室"
		if s.f("star_manual"):step="去西北侧配电隔离室，断外线后看机械表。";target="star_isolator";area="配电隔离室"
		if s.f("star_zero"):step="无压已经确认，回南侧中间的内门联锁台合旁路。";target="star_bypass";area="内门联锁台"
		if s.f("star_access"):step="蓝门已经打开，北侧中央的测控室有人在等你。";target="star_father";area="测控室"
		out.append(row("father","蓝门后的人",s.f("father_met"),"starcity","哨兵接通了内线，让你先确认检修回路。",step,target,area))
	if s.context.get("floor","")=="labor" and s.f("d6_returned") and not s.f("return_reviewed"):
		out.append(row("return_entry","返站身份审核",s.f("return_reviewed"),"labor","离站方式会影响返站手续，探访函仍需核验。","到集合区的科瓦廖夫面前说明离站经过，核对记录后申请限区通行。","commander","征召集合区"))
	out.append_array(preload("res://scripts/campaign.gd").side_tasks(s))
	if s.f("igor_debt_known") or s.f("igor_chore") or s.f("igor_settled"):out.append(row("igor_debt","岗哨的一笔旧账",s.f("igor_settled"),"life","伊戈尔替你隐瞒了侧门的事，要求财物补偿或清理岗灯。","清理压力监测箱旁岗灯后找伊戈尔验看；也可用三发制式弹或非任务物资结清。","igor" if s.f("igor_lamp_clean") else "relay","东侧维修岗"))
	if s.f("workers_done"):out.append(row("workers_choice","回信的下一班",s.ending,"commune","工人的征询稿已交付，回信窗口需要有人长期维护。","回议事处找叶莲娜，决定留下联络或继续旅程。","commune_leader","人民议事厅"))
	if s.f("north_done"):out.append(row("train_choice","第一班列车",s.ending,"sech","彼得已复核静态检修。","到东南接送车厢决定巡轨或联络；修复电台后可组织车队。","sech_leave","北线接送车厢"))
	if s.f("weather_done"):out.append(row("weather_choice","观测网的值守",s.ending,"starcity","北线中继测试完成。","与父亲见面后，到联络值班台决定是否留下维护观测网。","star_exit","联络值班台"))
	return preload("res://scripts/progression.gd").annotate(s,out)
static func active(s)->Dictionary:
	var pending=tasks(s).filter(func(t):return not t.done and not t.failed)
	for t in pending:
		if t.id==s.flags.get("tracked_quest","") and (t.place==s.context.get("floor","life") or (t.place in ["life","labor"] and s.context.get("floor","life") in ["life","labor"])):return t
	for t in pending:
		if t.place==s.context.get("floor","life"):return t
	if s.context.get("floor","life") in ["life","labor"]:
		for t in pending:
			if t.place in ["life","labor"]:return t
	return {}
static func track(s,id:String):
	for t in tasks(s):
		if t.id==id and not t.done and not t.failed:s.flags.tracked_quest=id;s.changed.emit();return
static func objective(s)->String:
	var current=active(s)
	return current.name+" · "+current.step if not current.is_empty() else "留意周围的人和留下的纸条"
static func leads(s)->Array:
	var out=[];var floor:String=s.context.get("floor","life")
	if floor=="labor" and s.f("d6_returned"):
		out.append("先找科瓦廖夫核对返站记录，再到下层煤矿检票口办理限区进入。" if not s.f("coal_access") else "煤矿医护知道探访与药物的安排。办完后仍从下层检票口销号。")
	elif floor in ["life","labor"]:
		if not s.f("nina_job") and not s.f("relay"):out.append("妮娜整夜都在修东西。她那里也许有东侧通路的办法。")
		if not s.f("cook_job") and not s.f("valve"):out.append("食堂里又传来接水的响声，加琳娜或许正缺一双手。")
		if not s.f("heat_job"):out.append("西翼那边有人抱怨房间发冷。去听听，也许不只是闲聊。")
		if s.has("photo") and not s.f("quest_photo") and not s.f("father"):out.append("那张旧合影一直在衣袋里。老爹可能还记得照片上的事。")
	elif floor=="waterworks" and not s.f("plant_briefed") and not s.f("plant_diagram"):out.append("科瓦廖夫在入口附近等着。桌上的旧值班图或许能省些弯路。")
	elif floor=="commune":
		if not s.f("anna_request"):out.append("南侧医务室的年轻女人听见 D-6 的名字时，似乎想问点什么。")
		if not s.f("commune_joined"):out.append("叶莲娜正在排轮班表，也许知道公社哪里缺人帮忙。")
	elif floor=="sech" and not s.f("sech_joined"):out.append("长老还在调度台附近，那台没亮灯的电台似乎让他很挂心。")
	elif floor=="starcity" and not s.f("star_registered"):out.append("蓝门值班室的哨兵一直望着入口。先报个姓名，也许比四处摸索更有用。")
	for q in preload("res://scripts/campaign.gd").data().get("quests",[]):
		if q.facility==floor and not s.f(q.accepted) and preload("res://scripts/campaign.gd").quest_offered(s,q):
			if q.id=="father_letters" and not s.f("father_met"):continue
			out.append(q.lead)
	return out
static func encyclopedia(s)->Array:
	var rows=[["D-6 与地下生活","D-6 受中央苏维埃管辖，居民仍按身份和岗位领取物资。生活、维修、作业与守备各有区域；净水故障使征召小队必须上地表寻找零件。"],["配给与维生素 D","居民按名单领取每日维生素。地下难见阳光，配给很重要。"],["身体与食物","活动会缓慢消耗饱食；停下阅读、交谈和暂停时不消耗。饥饿不会直接扣生命，先找落脚处吃点东西。食物充足时，活动中的轻伤会逐渐恢复。"],["两种子弹","左轮使用弹袋里的土制弹。制式弹另装在钱袋里，可购买物资；土制弹不能抵账。"]]
	if s.f("labor_read"):rows.append(["作业层","医务间和装备库在北侧，正门接轨道。生活层楼梯间在集合区西边。"])
	if s.has("frequency"):rows.append(["东方-7","收音机里听到的呼号。知道更多之前，先留着频率。"])
	var floor:String=s.context.get("floor","")
	if floor=="commune" or s.f("commune_joined"):rows.append(["莫斯科公社","反对中央苏维埃特权的革命组织，依靠工人委员会、地下联络和武装守备维持独立。伤病交换窗口只允许有限的人道探访，并未结束敌对。"])
	if floor=="sech" or s.f("sech_joined"):rows.append(["废土谢契","带有哥萨克传统的独立共同体，以旧军列检修库为落脚处；议事、阿塔曼与轮值并存，不服从中央，也未加入公社。"])
	if floor=="starcity" or s.f("star_known"):rows.append(["星城-2","大型地下科研设施，具有测控、材料、低温、供电与生活分区。当前可进入外侧维护与测控区域。不能凭一个呼号确认失联者的身份。"])
	if s.f("father_met"):rows.append(["父亲的工作","父亲在星城的测控技术班维护与校准设备，研究计划由各组共同维持。早期封闭管理和断路造成了失联，之后为何一直没有回去，需要与他当面谈清。"])
	return rows
