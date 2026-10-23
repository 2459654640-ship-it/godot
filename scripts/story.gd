extends RefCounted
const Narrative=preload("res://scripts/narrative.gd")
const Comic=preload("res://scripts/comic.gd")
const Chapter=preload("res://scripts/d6_chapter.gd")
const Economy=preload("res://scripts/economy.gd")
const Conversation=preload("res://scripts/conversation.gd")
const FirstMeetings=preload("res://scripts/first_meetings.gd")
const Campaign=preload("res://scripts/campaign.gd")
const Progression=preload("res://scripts/progression.gd")
const Life=preload("res://scripts/resident_dialogue.gd")
## State and authored dialogue live outside level geometry; no future chapters are fixed.
signal changed
var flags: Dictionary = {}
var items: Array[String] = []
var intel: Array[String] = []
var route = ""
var ending = false
var last_reply = ""
var departure_checkpoint:Dictionary={}
var economy:Dictionary=Economy.fresh()
var conversations:Dictionary={}
var last_greetings:Dictionary={}
var context:Dictionary={}
var last_outcome:Dictionary={}
var last_action_valid=false
var read_topics:Array[String]=[]
# Tests can inject the roll without changing saves or the displayed chance.
var roll_override=-1.0

func _init():
	flags.social_seed=int(randi())
	flags.intro_done=false

func guard_clear() -> bool:return context.get("hatch_clear",false)

func resolve_check(key:String,chance:int) -> bool:
	var records:Dictionary=flags.get("social_checks",{}).duplicate(true)
	if records.has(key):return records[key].success
	var hash_text=(str(flags.social_seed)+":"+key).sha256_text()
	var roll=float(hash_text.substr(0,8).hex_to_int()%10000)/100.0
	if roll_override>=0.0:roll=roll_override
	var success=roll<float(chance)
	records[key]={"chance":chance,"roll":roll,"success":success}
	flags.social_checks=records
	last_outcome={"kind":"success" if success else "failure","chance":chance,"key":key}
	return success
const ITEMS = {
 "pool_sample":["沉淀池封存样本","地表委托所需的污染样本，已单独封口。交给公社守备或谢契军需处，不能出售。","任务物品"],
 "moro_card":["莫罗的手抄歌页","下工之后第一次排练留下的歌页，页角有你参与的炭笔画。","纪念"],
 "memory_card":["巴拉诺夫的家庭记述","对照交接本、现场见证与家属授权制作的家庭抄本。","私人文件"],
 "revolver":["小队左轮","六发左轮手枪，使用土制弹。放入武器栏后按 1 拔枪 / 收枪，鼠标瞄准、左键射击、R 换弹。水厂战斗可以无损重试。","武器"],
 "water_core":["封存净水滤芯","核对过型号的两箱净水替换件，已经绑在小队的运输架上。","任务"],
 "relay_part":["控制回路保险件","水厂修配台取出的备用件，供仓门控制回路维修。","维修"],
 "anna_note":["安娜的寻亲纸条","姓名、班组编号和左手旧伤。核对身份，不能只靠同名。","任务"],
 "transit_pass":["公社探访函","煤运探访的正式联络文件，见到本人前仍须核实记录。","通行"],
 "archive":["转移名册抄页","星城档案中的姓名和护送记录，不足以替当事人回答二十年的事。","记忆"],
 "knife":["旧匕首","谢苗诺夫留下的工具。可以撬开卧室暗格与检修口；硬撬会损坏刃口。","工具"],
 "cigarettes":["半包香烟","受潮但仍可交换。米哈伊尔知道岗哨换班的空隙。","交换"],
 "photo":["母亲的照片","父母年轻时的合影，背面留着母亲的铅笔字。可以问老爹往事，也可以留给失散的父亲辨认。","记忆"],
 "vodka":["战前伏特加","仅此一瓶。可与伊戈尔换通行；交出便无法收回。","交换"],
 "map":["维修通道草图","米哈伊尔标出的两道门与旧检修管线。可辅助辨认侧门。","情报"],
 "wrench":["借来的扳手","维修工妮娜的工具。能拧紧食堂阀门，也可完整拆下检修盖板。","工具"],
 "fuse":["陶瓷保险芯","公共洗漱区旧配电柜里的备用件。可恢复东段的压力监测。","维修"],
 "soup":["一份热汤","帮厨房止住漏水换来的。送给米哈伊尔可获得换班情报。","人情"],
 "permit":["临时检修许可","妮娜签字，伊戈尔可以据此放行。仅覆盖东段维修通道。","通行"],
 "order":["征召登记单","科瓦廖夫签字。去作业层装备库领取出发装备，再到集合气闸报到。","通行"],
 "mask":["防毒面具","贴合脸部的橡胶面罩，连接滤毒罐后用于过滤吸入的空气。","装备"],
 "filter":["备用滤毒罐","配合防毒面具使用。出发前检查接口密封，别让罐口受潮。","装备"],
 "vitamins":["维生素 D","地下居民的维生素 D 配给。用于预防缺乏；伤病者应先由医护评估，不会立即治愈旧伤。","配给药品"],
 "frequency":["手抄频率","收音机里断续出现的「东方-7」。尚未证实与父亲有关。","线索"],
 "rag":["公用干布","洗衣间借来的。排气时垫住阀口，防止热水烫手；用完放回盆里。","维修"],
 "report":["暖气维修记录","帕维尔签过字的支管记录。当班值守须到主通道总表复核，可请伊戈尔过去。","凭据"]
}
const ROUTES = {"official":"随征召小队出发", "permit":"持检修许可离站", "bribe":"用战前酒换取通行", "shift":"趁换班走侧门", "hatch":"绕行旧检修管线"}

func has(id: String) -> bool: return id in items
func f(id: String) -> bool: return flags.get(id,false)
func give(id: String):
	if not has(id):items.append(id)
	if id=="revolver" and not flags.has("equipment"):equip_weapon(id)
func take(id: String):
	var was_equipped=equipped_weapon()==id
	items.erase(id)
	if was_equipped:equip_weapon("")
func equipped_weapon()->String:
	var slots=flags.get("equipment",{})
	if not slots is Dictionary:return ""
	var id=String(slots.get("weapon",""))
	return id if has(id) and id=="revolver" else ""
func equip_weapon(id:String)->bool:
	if id!="" and (id!="revolver" or not has(id)):return false
	flags.equipment={"weapon":id};flags.weapon_drawn=false;changed.emit();return true
func weapon_drawn()->bool:return equipped_weapon()!="" and bool(flags.get("weapon_drawn",false))
func know(text: String):
	if text not in intel:intel.append(text)
func opt(key: String, text: String, allowed: bool = true, reason: String = "") -> Dictionary:
	return {"key":key,"text":text,"enabled":allowed,"reason":reason}
func view(id: String) -> Dictionary:
	var v={"id":id,"name":"","role":"调查","body":"","options":[]}
	match id:
		"box":
			v.name="床下的旧木箱"
			v.options=[opt("search_box","翻查木箱",not f("searched"),"已搜寻"),opt("open_cache","撬开松动的底板",has("knife") and not f("cache"),"需要旧匕首" if not f("cache") else "暗格已空")]
		"radio":
			v.name="修过三次的收音机"
			v.options=[opt("tune","调谐收音机，记下能辨认的呼号",not has("frequency"),"已记下")]
		"notice":
			v.name="第 7 供应点 · 征召令"
			v.options=[opt("read_notice","将征召令记入手记",not f("notice"),"已记录")]
		"chalk":
			v.name="新添的粉笔记号"
			v.options=[opt("chalk","拓下标记",not f("chalk"),"已记录")]
		"semyon":
			v.name="谢苗诺夫"
			v.role="工程兵老爹 / 居民"
			v.options=[opt("father","给他看母亲的照片",has("photo"),"需要母亲的照片"),opt("semyon_advice","问起净水设施与自己的选择"),opt("semyon_radio","问起东方-7",has("frequency"),"先调查收音机")]
		"mikhail":
			v.name="米哈伊尔"
			v.role="仓库管理员 / 食堂常客"
			v.options=[opt("map","询问东侧维修通道",not has("map"),"已拿到草图"),opt("trade_smoke","用半包烟交换换班情报",has("cigarettes") and not f("shift"),"需要香烟；情报不可重复交换"),opt("give_soup","把热汤递给他，问问换班",has("soup") and not f("shift"),"需要厨房的一份热汤"),opt("give_vitamins","给他维生素 D",has("vitamins") and not f("vitamins_given"),"需要维生素 D；不可重复赠送")]
		"cook":
			v.name="加琳娜"
			v.role="公共食堂 / 厨房负责人"
			v.options=[opt("cook_job","答应帮厨房止漏",not f("cook_job"),"已记下"),opt("claim_soup","领取答谢的热汤",f("valve") and not f("soup_claimed"),"先修好灶台边的漏水阀")]
		"valve":
			v.name="厨房回水阀"
			v.options=[opt("fix_valve","用扳手拧紧接头",has("wrench") and not f("valve"),"需要扳手" if not f("valve") else "漏水已止住")]
		"nina":
			v.name="妮娜"
			v.role="东段维修工"
			v.options=[opt("borrow_wrench","借用扳手",not has("wrench"),"工具在背包里"),opt("nina_job","接下压力监测维修",not f("nina_job"),"已记下"),opt("claim_permit","领取检修许可与防护装备",f("relay") and not has("permit"),"先更换东侧监测箱保险芯")]
		"cabinet":
			v.name="洗漱区 · 旧配电柜"
			v.options=[opt("get_fuse","打开断电柜，取出保险芯",(has("wrench") or has("knife")) and not f("fuse_taken"),"需要扳手或匕首" if not f("fuse_taken") else "备用件已取走")]
		"relay":
			v.name="东侧压力监测箱"
			v.options=[opt("fix_relay","更换保险芯并复位",has("fuse") and has("wrench") and not f("relay"),"需要保险芯与扳手" if not f("relay") else "监测已恢复")]
		"supply":
			v.name="柳德米拉"
			v.role="第 7 供应点 / 配给员"
			v.options=[opt("vitamins","领取今日维生素 D",not f("vitamins_taken"),"今日份已领"),opt("get_kit","凭征召登记单领取出发装备",has("order") and not f("kit"),"需要科瓦廖夫的登记单；不可重复领取")]
		"commander":
			v.name="中尉科瓦廖夫"
			v.role="征召小队 / 指挥官"
			v.options=[opt("briefing","询问队伍、风险与准备"),opt("accept","登记参加征召小队",not f("accepted"),"已登记；仍可探索其他路线")]
		"igor":
			v.name="老伊戈尔"
			v.role="东侧岗哨 / 卫兵"
			v.options=[opt("igor_talk","问问为什么把守旧通道"),opt("use_permit","出示妮娜签字的检修许可",has("permit") and not f("gate"),"需要临时检修许可"),opt("use_vodka","交出战前伏特加，换通行",has("vodka") and not f("gate"),"需要战前伏特加；仅此一瓶")]
		"gate":
			v.name="东侧维修门"
		"side":
			v.name="压力表后的检修侧门"
			v.options=[opt("use_shift","按情报等候换班，从侧门通过",f("shift") and has("map") and not f("side"),"需要维修草图与换班情报")]
		"hatch":
			v.name="旧检修盖板"
			v.options=[opt("hatch_wrench","用扳手拆盖板，绕行检修管线",has("wrench"),"需要扳手"),opt("hatch_knife","硬撬盖板，折损匕首后绕行",has("knife"),"需要旧匕首")]
		"lift":
			v.name="集合气闸 · 征召小队"
			v.options=[opt("leave_official","检查装备，准备随队离站",f("accepted") and f("kit"),"需要登记征召并在作业层装备库领取装备")]
		"exit":
			v.name="东侧维修坡道"
			v.options=[opt("leave_east","整理背包，准备离开 D-6",route!="" and has("mask") and has("filter"), "先通过维修门、侧门或检修管线")]
	v=Progression.decorate(Economy.decorate(Campaign.decorate(Chapter.decorate(Life.decorate(Narrative.decorate(v,self),self),self),self),self),self)
	if id=="medical":v.options.append(opt("c_lower_broadcast","停在门边，听完伤员病房的这一段广播",Campaign.available(self,"lower_broadcast")))
	v=FirstMeetings.decorate(v,self)
	if id=="radio":v.options.append(opt("room_radio_music","打开音乐频道",context.get("floor","")=="life"))
	if id=="mikhail":v.options=v.options.filter(func(o):return o.key!="give_vitamins")
	for option in v.options:
		var influence=option.key in ["accept","leave_official","leave_east","use_vodka","trade_smoke","give_soup","guard_bluff","hatch_knife","buy_protection"]
		var quest_related=option.key in ["borrow_wrench","nina_job","cook_job","vera_heat","heat_job","father","tune","get_kit","vitamins","claim_soup","claim_report","claim_permit","nina_safety"]
		if option.key.begins_with("c_"):
			var action:Dictionary=Campaign.data().actions.get(option.key.substr(2),{})
			influence=action.has("ending") or action.has("travel") or option.key in ["c_father_anger","c_father_truth","c_father_quiet"]
			for quest in Campaign.data().get("quests",[]):
				if option.key.substr(2) in quest.get("actions",[]):quest_related=true
			if not action.get("flags",{}).is_empty() or not action.get("give",[]).is_empty():quest_related=true
		option.category="决定" if influence else ("任务" if quest_related else ("闲聊" if once_topic(option.key) else "调查"))
		if option.key.begins_with("c_"):
			option.category=Campaign.data().actions.get(option.key.substr(2),{}).get("category",option.category)
		if option.key.begins_with("meet_"):option.category="闲聊"
		if once_topic(option.key) and option.key in read_topics:option.enabled=false;option.reason="已聊过，记在聊天记录里"
	return v

func act(key: String) -> String:
	# Revalidate the same conditions used by the UI before mutating state.
	var valid=false
	last_action_valid=false
	last_outcome={}
	for id in ["box","radio","notice","chalk","semyon","mikhail","cook","valve","nina","cabinet","relay","supply","commander","igor","side","hatch","lift","exit"]+Life.IDS+Chapter.IDS+Progression.IDS+Campaign.data().interactions.keys():
		for o in view(id).options:
			if o.key==key and o.enabled:valid=true
	if not valid:return "条件尚未满足，或这件事已经做过了。"
	last_action_valid=true
	if key=="room_radio_music":return "你把旋钮转到居民音乐转播的频段。"
	if key.begins_with("decontam_"):
		last_reply=Economy.Radiation.treat(self);changed.emit();return last_reply
	if key.begins_with("meet_"):
		last_reply=FirstMeetings.act(self,key);changed.emit();return last_reply
	if once_topic(key):read_topics.append(key)
	if Progression.handles(key):
		last_reply=Progression.act(self,key);changed.emit();return last_reply
	if key.begins_with("meal_"):
		last_reply=Economy.meal(self,key.substr(5))
		return last_reply
	if key.begins_with("c_"):
		last_reply=Campaign.act(self,key.substr(2))
		changed.emit()
		return last_reply
	if Chapter.handles(key):
		last_reply=Chapter.act(key,self)
		changed.emit()
		return last_reply
	if Life.handles(key):
		last_reply=Life.act(key,self)
		changed.emit()
		return last_reply
	if Narrative.CHAT.has(key):
		last_reply=Narrative.CHAT[key][2]
		changed.emit()
		return last_reply
	last_reply=""
	match key:
		"search_box":
			flags.searched=true
			for id in ["knife","cigarettes","photo"]:give(id)
		"open_cache":
			flags.cache=true
			give("vodka")
		"tune":
			give("frequency")
			flags.signal_heard=true
			know("收音机里出现呼号「东方-7」，来源与含义未证实。")
		"read_notice":
			flags.notice=true
			know("储水只够两周；正式征召需要登记和防护装备。")
		"chalk":
			flags.chalk=true
			know("走廊粉笔标记是一颗星与轨道；尚不能与东方-7划等号。")
		"father":
			flags.father=true
			know("老爹说，那天之后没再见过父亲。他托人找过，一直没有准信。")
		"semyon_advice":pass
		"semyon_radio":pass
		"map":
			give("map")
			know("东段有维修门、检修侧门和旧管线。地图不提供通行权限。")
		"trade_smoke","give_soup":
			take("cigarettes" if key=="trade_smoke" else "soup")
			flags.shift=true
			give("map")
			know("黄灯亮起时伊戈尔去查表。已标记侧门；可等候换班穿行。")
		"give_vitamins":
			take("vitamins")
			flags.vitamins_given=true
			know("米哈伊尔：妮娜能凭检修工作签发许可，避免私放人员连累伊戈尔。")
		"cook_job":
			flags.cook_job=true
		"fix_valve":
			flags.valve=true
		"claim_soup":
			flags.soup_claimed=true
			give("soup")
		"borrow_wrench":
			give("wrench")
		"nina_job":
			flags.nina_job=true
		"get_fuse":
			flags.fuse_taken=true
			give("fuse")
		"fix_relay":
			take("fuse")
			flags.relay=true
		"claim_permit":
			for id in ["permit","mask","filter"]:give(id)
		"vitamins":
			flags.vitamins_taken=true
			give("vitamins")
		"get_kit":
			flags.kit=true
			for id in ["mask","filter"]:give(id)
		"briefing":flags.briefed=true
		"accept":
			flags.accepted=true
			give("order")
		"igor_talk":pass
		"use_permit":
			flags.gate=true
			flags.gate_route="permit"
			route="permit"
		"use_vodka":
			take("vodka")
			flags.gate=true
			flags.gate_route="bribe"
			route="bribe"
			give("mask")
			give("filter")
		"use_shift":
			flags.side=true
		"hatch_wrench","hatch_knife":
			flags.hatch=true
			route="hatch"
			if key=="hatch_knife":take("knife")
		"leave_official":pass
		"leave_east":pass
	last_reply=Narrative.reply(key,last_reply)
	if key=="nina_job" and has("wrench"):last_reply="「那把扳手你先留着，也能开监测箱的盖板。洗漱间的旧柜里有 2A 保险芯，我已经断开维修回路。换好以后看读数，回来说一声。」"
	if key=="nina_job" and not has("wrench"):last_reply="「先跟我借把扳手，再到洗漱间旧柜里取 2A 保险芯。监测箱在东侧岗哨，我已经断开维修回路。工具借给你，用完回来告诉我。」"
	changed.emit()
	return last_reply

func objective() -> String:
	var chapter_objective=Campaign.objective(self)
	if chapter_objective!="":return chapter_objective
	if ending:return "打开日志，回看已经经历的旅程"
	if f("intro_done") and not f("vitamins_taken"):return "去第七供应点领取今日维生素 D"
	if f("guard_task") and not f("hatch"):return "伊戈尔在查表 · 用工具拆下旧盖板" if guard_clear() else "等伊戈尔离开岗哨，再检查旧盖板"
	if f("gate") or route=="hatch" or route=="shift":return "穿过东侧维修通道，从坡道离站"
	if f("kit"):return "到作业层正门随征召小队离站"
	if f("accepted"):return "到作业层装备库领取防护装备"
	if f("relay") and not has("permit"):return "监测已恢复 · 回维修区请妮娜签字"
	if f("nina_job"):return "找备用保险芯，修复东侧压力监测箱"
	return "到作业层找科瓦廖夫中尉报到" if f("vitamins_taken") else "去第七供应点领取今日维生素 D"

static func once_topic(key:String)->bool:
	return Narrative.CHAT.has(key) or key in ["father","vera_heat","semyon_advice","semyon_radio","briefing","igor_talk","armory_check","gate_daily","coal_ask","resident_shift","resident_igor","vera_day","vera_nina","knock_rooms","nina_reckless"]

func serialize() -> Dictionary:
	return {"version":1,"content_revision":26,"flags":flags,"items":items,"intel":intel,"route":route,"ending":ending,"economy":economy,"conversations":conversations,"last_greetings":last_greetings,"checkpoint":departure_checkpoint,"read_topics":read_topics}
func restore(data: Dictionary):
	flags=data.get("flags",{}).duplicate(true)
	preload("res://scripts/publications.gd").normalize(self)
	read_topics.assign(data.get("read_topics",[]))
	departure_checkpoint=data.get("checkpoint",{}).duplicate(true)
	if not flags.has("intro_done") and not flags.has("comic"):flags.intro_done=true
	economy=Economy.restored(data.get("economy",{}))
	conversations=data.get("conversations",{}).duplicate(true)
	last_greetings=data.get("last_greetings",{}).duplicate(true)
	if not flags.has("social_seed"):
		flags.social_seed=JSON.stringify(data).sha256_text().substr(0,8).hex_to_int()
	context={}
	last_outcome={}
	items.assign(data.get("items",[]))
	if not flags.has("equipment") and has("revolver"):
		flags.equipment={"weapon":"revolver"};flags.weapon_drawn=false
	intel.assign(data.get("intel",[]))
	route=data.get("route","")
	ending=data.get("ending",false)
	if not data.has("read_topics"):
		# Old saves already kept the actual choices; infer only witnessed topics.
		for id in conversations:
			for option in view(id).options:
				if not once_topic(option.key):continue
				var spoken=option.text.begins_with("「")
				var choice=option.text.trim_prefix("「").trim_suffix("」") if spoken else "你"+option.text
				for line in conversations[id]:
					if line.speaker==("ivan" if spoken else "narrator") and line.text==choice:
						if option.key not in read_topics:read_topics.append(option.key)
	if int(data.get("content_revision",0))<8:
		# Reopen only corrected informational answers. Keep quests, rewards and witnessed history.
		var corrected=flags.get("c_done_commune_route",false)
		for key in ["commune_route","sech_father","father_semyon","anna_talk"]:flags.erase("c_done_"+key)
		if corrected:
			var note="联络记录复核：东方-7 是星城的短波呼号，尚不能确认父亲下落。可再向叶莲娜核实。"
			know(note)
			if conversations.has("commune_leader"):conversations.commune_leader.append({"speaker":"narrator","text":note})
	if int(data.get("content_revision",0))<9:
		for key in ["sech_father","commune_route","father_work"]:flags.erase("c_done_"+key)
	if int(data.get("content_revision",0))<10:
		for key in ["grow_talk","veteran_road","plant_brief","plant_people"]:flags.erase("c_done_"+key)
		read_topics.erase("igor_semyon")
	if int(data.get("content_revision",0))<19:
		# These corrected answers carry no material reward. Preserve witnessed
		# transcripts, inventories, reward locks and all accepted quest progress.
		for key in ["commune_route","commune_frequency","sech_father","sech_visitors"]:flags.erase("c_done_"+key)
	if int(data.get("content_revision",0))<11:
		if has("frequency"):flags.signal_heard=true
		if f("vitamins_given") and not has("vitamins"):give("vitamins");flags.vitamins_given=false
		if f("sech_water_fixed"):flags.water_tank_fixed=true
		if f("plant_bled"):flags.battle_pump=true
		if f("plant_fuse"):flags.battle_workshop=true
		if f("radio_fixed") or f("commune_radio_known"):flags.signal_identified=true
		var old_end=String(flags.get("campaign_ending",""))
		if old_end in ["commune","anna","workers","sech","rail","caravan"]:
			flags["commune_member" if old_end in ["commune","anna","workers"] else "sech_member"]=true
			flags.erase("campaign_ending");flags.erase("chapter_endpoint");ending=false
		if old_end in ["commune","anna","workers","sech","rail","caravan","home","tea"]:
			var closed:Dictionary=flags.get("failed_quests",{}).duplicate(true)
			for id in closed.keys():
				if String(closed[id]).contains("旅程已经收束"):closed.erase(id)
			flags.failed_quests=closed
		if old_end in ["home","tea"]:
			flags.erase("campaign_ending");flags.erase("chapter_endpoint");flags.filter_return_job=true;ending=false
			Comic.start(self,"home_water" if old_end=="home" else "tea_return")
		for key in ["commune_route","sech_custom"]:flags.erase("c_done_"+key)
		read_topics.erase("semyon_child");read_topics.erase("semyon_advice")
	# A v4 completion meant only "left D-6", not the unseen new chapter.
	if ending and not flags.has("chapter_endpoint") and not flags.get("comic",{}).get("active",false) and route!="":
		ending=false
		flags.v4_departure_carried=true
		Comic.start(self,"official" if route=="official" else "solo")
	Campaign.Update.migrate(self,int(data.get("content_revision",0)))
	Campaign.Living.migrate(self,int(data.get("content_revision",0)))
	Campaign.Journey.migrate(self,data)
	changed.emit()
