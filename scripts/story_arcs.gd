extends RefCounted
## Local stories and the first emergency calls at Star City.
static var _data:Dictionary={}
const FINAL_START_STEPS=["late_shared_packet","late_central_agreement","late_distributed_copy","late_watch_power","late_finish"]
const CALLS=["arc_dispatch_train","arc_dispatch_clinic","arc_dispatch_commune","arc_dispatch_sech","arc_dispatch_d6"]
const QUEST_STARTS={"arc_d6_offer":"arc_d6","arc_sech_offer":"arc_sech","arc_commune_offer":"arc_commune"}

static func data()->Dictionary:
	if _data.is_empty():
		_data=JSON.parse_string(FileAccess.get_file_as_string("res://data/story_arcs.json"))
	return _data

static func extend(c:Dictionary):
	for section in ["actions","interactions","panels"]:
		c[section].merge(data()[section].duplicate(true))
	c.quests.append_array(data().quests.duplicate(true))
	for id in data().extensions:
		if c.interactions.has(id):
			c.interactions[id].options.append_array(data().extensions[id])

static func dispatch_pending(s)->bool:
	return s.f("arc_first_dispatch_pending") and not s.f("arc_first_dispatch_done")

static func allowed(s,key:String)->bool:
	if key.begins_with("arc_d6_"):
		return s.Campaign.Access.public_entry(s)
	if key in FINAL_START_STEPS:
		return not dispatch_pending(s)
	return true

static func decorate(v:Dictionary,s)->Dictionary:
	if v.id=="medical":
		for key in data().extensions.medical:
			if s.Campaign.available(s,key):
				v.options.append(s.opt("c_"+key,data().actions[key].text))
	if v.id=="late_planning" and dispatch_pending(s):
		v.body+="\n外线只剩一对电缆。回配线台发第一轮紧急预警，南口司机仍在挡风墙里待命。"
	if v.id=="arc_commune_liuba" and s.f("arc_commune_terms") and not s.f("arc_commune_done"):
		v.body="柳芭把信夹在封套里，正走向气闸旁的交接台。"
	return v

static func act(s,key:String):
	if QUEST_STARTS.has(key):
		s.flags.tracked_quest=QUEST_STARTS[key]
	if key=="arc_star_resume" and CALLS.any(func(flag):return s.f(flag)):
		s.flags.next_sequence="arc_star_order"

static func result(s,id:String)->String:
	if id=="late_warning" and s.f("late_campaign_complete") and s.f("arc_first_dispatch_done"):
		var record:String=s.Campaign.Complete.result(s,id)+"\n"
		if s.f("arc_dispatch_train"):record+="装卸班七人及时撤出。诊所救出了五人，维克托去世。"
		elif s.f("arc_dispatch_clinic"):record+="诊所六人撤进地窖。装卸棚坍塌，安德烈遇难。"
		else:record+="诊所和装卸班分别确认人员齐备。"
		return record+"东侧第二巡测点仍待核实，下一班保留了呼叫记录。"
	var outcomes:Dictionary=data().results.get(id,{})
	for flag in outcomes:
		if s.f(flag):return outcomes[flag]
	return ""

static func panel(s,p:Dictionary)->Dictionary:
	var node:String=s.flags.get("comic",{}).get("node","")
	if node=="late_final_result" and not s.f("arc_first_dispatch_done"):
		p.next="late_epilogue_people"
	if node=="arc_star_yard_count":
		p.next="arc_after_"+String(s.flags.get("late_final_mode","shared"))
	if node!="late_epilogue_people":return p
	if s.f("arc_commune_done"):
		p.body+="\n\n柳芭的母亲第二天把扳手送了回来。柳芭在机修班领到第一件活儿，用的就是那把扳手。两边的卫生员每周仍对两次班。再有失踪的工人，家属也知道该找谁问。"
	if s.f("arc_d6_signed"):
		p.body+="\n\n军务处来问话时，季娜伊达带去了探视记录，也让斯捷潘自己说完了。他暂时不能回北线值班。医务间把照护口粮改到母亲名下，她终于能领到够两个人吃的面粉。"
	if s.f("arc_d6_bed_number"):
		p.body+="\n\n季娜伊达仍缺两份签名。斯捷潘从病房走到登记台，自己签了第一份。他们把还空着的一联留下，说明早再来。"
	if s.f("arc_sech_roster"):
		p.body+="\n\n瓦莉娅做完说好的三班北灯轮值，跟阿格拉娅一起去旧站。她把母亲留下的最后一只锅洗干净，搬回客铺。那一周她一直没有在簿上写自己要住到哪天。"
	if s.f("arc_sech_guest"):
		p.body+="\n\n瓦莉娅离开客铺后仍回来见阿格拉娅。两人从旧站原来的门开始找，有两个年轻守灯人跟着她们走了一趟。韦拉的名字只抄在家属簿里。"
	if s.f("arc_first_dispatch_done"):
		p.next="arc_star_memory"
	return p
