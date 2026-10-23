extends RefCounted
static var _data:Dictionary={}
static func data()->Dictionary:
	if _data.is_empty():_data=JSON.parse_string(FileAccess.get_file_as_string("res://data/journey_update.json"))
	return _data
static func extend(c:Dictionary):
	c.actions.merge(data().actions.duplicate(true),true)
	c.quests.append_array(data().quests.duplicate(true))
	c.interactions.surface_exit.options.append("surface_back_d6")
	c.interactions.coal_exit.options.append("coal_back_d6")
	for key in ["d6_duty_offer","d6_patrol_depart","d6_patrol_turnin","d6_followup"]:c.interactions.d6_return_desk.options.append(key)
	for pair in [["coal_brother","mine_visit_story"],["coal_medic","mine_observe_offer"],["coal_medic","mine_heat_finish"],["coal_archive","mine_heat_record"],["coal_clerk","mine_heat_negotiate"]]:c.interactions[pair[0]].options.append(pair[1])
	c.actions.return_filters.reply="中尉签收运输架，妮娜核对型号与封存年份，请维修班将两箱滤芯送往净水间检验。\n科瓦廖夫：「物资收到了。遇难的三个人，我会向上级和家属说明。你先回去休息，老谢在等你。缓过来以后，我们再谈下一趟巡查。」"
	# The crates stay with the returning party until an explicit handover.
	c.actions.plant_leave.erase("take")
	c.actions.coal_brother.travel="mine_bedside"
static func allowed(s,key:String)->bool:
	if key in ["return_assignment","d6_duty_offer","d6_patrol_depart"] and (s.f("commune_member") or s.f("sech_member") or s.f("sided_veteran")):return false
	if key=="return_assignment" and s.f("d6_duty_accepted"):return false
	if key=="d6_patrol_depart" and s.has("pool_sample"):return false
	if key=="return_commune" and s.f("d6_cargo_returned") and not s.f("anna_request"):return false
	if key in ["coal_return","workers_return"] and s.f("d6_cargo_returned") and not s.f("anna_request"):return false
	return true
static func decorate(v:Dictionary,s)->Dictionary:
	var extras={"semyon":["d6_home_talk"],"medical":["d6_medical_brief","d6_medical_followup"],"armory":["d6_field_supply","d6_route_followup"]}
	for key in extras.get(v.id,[]):
		if s.Campaign.available(s,key):v.options.append(s.opt("c_"+key,s.Campaign.data().actions[key].text))
	if v.id=="semyon" and s.f("d6_cargo_returned"):
		v.body="谢苗诺夫将椅子从桌边拉开。\n「回来了就坐下。要说什么慢慢说，今天不急着赶你出门。」"
		v.options=v.options.filter(func(o):return o.key.begins_with("c_") or o.key in ["father","semyon_radio"])
	if v.id=="armory" and s.f("d6_cargo_returned"):v.body="军需员翻到返站装备页。\n「旧装备先检查，坏了的记下来。新任务的弹药另签，不会算成你已经领过的那一批。」"
	if v.id=="d6_return_desk" and s.f("d6_cargo_returned"):
		v.body="科瓦廖夫收好了滤芯交接页。\n「物资交接办完了。生活层可以回去，外勤另行登记。煤矿的当班范围也要分开核对。」"
		if s.f("d6_patrol_done"):v.body="科瓦廖夫将泵站报告和样本收据夹在一起。\n「这次任务已销号。去休息吧，有新的外勤安排，我会让人通知你。」"
	if v.id=="coal_brother" and s.f("mine_visit_seen"):v.body="阿列克谢靠着枕头休息，写好的纸条放在床头。医护提醒你，他一次不宜说太久。"
	return v
static func act(s,key:String):
	if key in ["return_assignment","d6_duty_offer"]:s.flags.tracked_quest="d6_first_duty"
	if key=="mine_observe_offer":s.flags.tracked_quest="mine_warm_night"
	if key=="d6_patrol_depart":
		s.flags.surface_from_d6=true;s.flags.surface_from_commune=false;s.flags.surface_from_sech=false;s.flags.surface_trip_active=true
		s.flags.surface_trip_id=int(s.flags.get("surface_trip_id",0))+1;s.flags.surface_loot={}
		for flag in ["battle_surface_yard","battle_surface_pool","surface_drain_open","surface_notes","surface_sample_sealed","c_done_surface_notes","c_done_surface_drain","c_done_surface_sample_take"]:s.flags.erase(flag)
	if key=="surface_depart":s.flags.surface_from_d6=false
static func objective(s)->String:
	if not s.f("d6_duty_accepted") or s.f("d6_patrol_done"):return ""
	for row in s.Campaign.side_tasks(s):
		if row.id=="d6_first_duty":return row.step
	return ""
static func migrate(s,saved:Dictionary):
	if int(saved.get("content_revision",0))>=25:return
	# v24 removed the crates on leaving the factory, before D-6 could sign
	# for them. Restore only that unfulfilled cargo, never transferred goods.
	var node:String=s.flags.get("comic",{}).get("node","")
	var returning=node in ["return_crossing","return_veteran","return_standoff","tea_return","home_water"]
	var at_home=s.f("d6_returned") and saved.get("floor","") in ["","life","labor"]
	if s.route=="official" and s.f("water_secured") and s.f("c_done_plant_leave") and (returning or at_home) and not s.f("sided_veteran") and not s.f("cargo_sent_with_lieutenant") and not s.f("d6_cargo_returned"):
		s.give("water_core");s.flags.legacy_return_cargo_recovered=true
