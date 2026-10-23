extends RefCounted
## Identity is checked at actions and scene transitions, never just in dialogue.
## Public entry never grants deserter immunity. Private coal contact is separate.
static func public_entry(s)->bool:
	return s.route=="official" and not s.f("sided_veteran") and not s.f("d6_wanted") and not s.f("commune_member") and not s.f("sech_member")
static func blocked_return(s)->bool:
	return not public_entry(s) and (s.f("anna_records") or s.f("workers_draft") or s.f("anna_warning_seen"))
static func extend(c:Dictionary):
	c.actions.d6_withdraw={"text":"退回站外，返回公社。","reply":"","once":false,"req":{"floor":["labor"]},"travel":"d6_checkpoint_withdraw"}
	for id in ["d6_return_desk","coal_gate_entry"]:c.interactions[id].options.append("d6_withdraw")
	c.actions.d6_entry_question={"text":"「这些材料不能通行，那该怎么进入矿区？」","reply":"娜佳：「D-6 只认他们内部的准许记录。我们还在和中央交战，不能把你当成正式来访的人送进去。你若仍在追查名册上，递交姓名就可能被扣住。」\n她把班组抄页推回你面前。\n「目前还没有能保证你安全进出的接应安排。先把材料留好，别急着去正门。」","once":true,"req":{"floor":["commune"],"any":["anna_records","workers_draft","anna_warning_seen"]},"flags":{}}
	c.interactions.commune_printer.options.append("d6_entry_question")
	for q in c.quests:
		if q.id=="commune_chapter":q.stages[0].step="到人民议事厅的座席区，按 E 参加居民议事；不必绕到讲台后找人。"
		if q.id=="sech_chapter":q.stages[0].step="进入谢契议事室的会合区域，按 E 参加入伙轮值。"
static func allowed(s,key:String)->bool:
	if key in ["return_explain","return_witness","return_audit","return_limited"]:return false
	if key=="workers_coal":return false # Pending the separately reviewed private-contact chapter.
	if key in ["east_depart_labor","east_enter_labor"]:return public_entry(s)
	if key=="d6_entry_question":return (blocked_return(s) or s.f("workers_draft")) and not s.f("east_mine_prepared")
	if key in ["commune_coal","return_official","enter_coal","return_filters","return_assignment","return_commune","coal_back_d6","anna_rescue_depart"] and not public_entry(s):return false
	if key=="d6_withdraw":return not public_entry(s)
	return true
static func decorate(v:Dictionary,s)->Dictionary:
	if v.id in ["d6_return_desk","coal_gate_entry"] and not public_entry(s):
		v.role="D-6 / 返站资格受限"
		v.body="警卫的名册里留着你的离站记录。科瓦廖夫没有接你的寻人材料。\n科瓦廖夫：「这份材料不能撤销你的擅离记录。你没有返站许可，再往里走，卫兵就会扣人。现在退回站外。」\n公开进入 D-6 的办法行不通。你需要先离开这里，另找安全的进入方式。"
		if s.route=="official" and not s.f("sided_veteran") and not s.f("d6_wanted"):
			v.body="科瓦廖夫核对完本次批准的返站名单，合上了登记簿。\n科瓦廖夫：「你以前的随队记录还在，但不能代替这次的返站批准。你现在不在准入名单里，带来的寻人材料也不能用于通行。先退回站外。」\n需要另行解决进入矿区的问题，不能直接前往生活层或煤矿。"
		v.options=v.options.filter(func(o):return o.key=="c_d6_withdraw" and o.enabled)
	if v.id=="commune_leave" and blocked_return(s):
		v.body+="\n你仍在 D-6 的追查名册上，手中的寻亲材料不能让你通过正门。安娜的委托仍记在手记里，公开返站这条路暂时走不通。"
	if v.id=="commune_records" and blocked_return(s) and not s.f("east_mine_prepared"):
		v.body+="\n抄页只能帮助核实矿工身份，没有通行效力。联络室尚未确认能避开正门检查的进入方式。"
	if v.id=="commune_anna" and s.f("anna_warning_seen") and not s.f("anna_outcome_done") and not public_entry(s):
		v.body+="\n安娜：「你不能再从 D-6 正门进去，我知道。哥哥那边的消息我会继续打听。我们先把接应办法弄清楚，不能让你也被扣在那里。」"
	return v
static func migrate(s,saved:Dictionary):
	# A pre-fix save can be paused before an unauthorised visit actually
	# entered the mine. Cancelling that journey must not strand Anna there.
	var comic:Dictionary=s.flags.get("comic",{})
	if not public_entry(s) and saved.get("floor","")!="coal" and comic.get("active",false) and comic.get("sequence","")=="anna_rescue_road":
		s.flags.erase("anna_rescue_started")
		s.flags.erase("c_done_anna_rescue_depart")
