extends RefCounted
const Narrative=preload("res://scripts/narrative.gd")
## State and authored dialogue live outside level geometry; no future chapters are fixed.
signal changed
var flags: Dictionary = {}
var items: Array[String] = []
var intel: Array[String] = []
var route = ""
var ending = false
var last_reply = ""
const ITEMS = {
 "knife":["旧匕首","谢苗诺夫留下的工具。可以撬开卧室暗格与检修口；硬撬会损坏刃口。","工具"],
 "cigarettes":["半包香烟","受潮但仍可交换。米哈伊尔知道岗哨换班的空隙。","交换"],
 "photo":["母亲的照片","父母年轻时的合影，边角已经卷曲。给谢苗诺夫看看，也许他还记得当时的事。","记忆"],
 "vodka":["战前伏特加","仅此一瓶。可与伊戈尔换通行；交出便无法收回。","交换"],
 "map":["维修通道草图","米哈伊尔标出的两道门与旧检修管线。可辅助辨认侧门。","情报"],
 "wrench":["借来的扳手","维修工妮娜的工具。能拧紧食堂阀门，也可完整拆下检修盖板。","工具"],
 "fuse":["陶瓷保险芯","公共洗漱区旧配电柜里的备用件。可恢复东段的压力监测。","维修"],
 "soup":["一份热汤","帮厨房止住漏水换来的。送给米哈伊尔可获得换班情报。","人情"],
 "permit":["临时检修许可","妮娜签字，伊戈尔可以据此放行。仅覆盖东段维修通道。","通行"],
 "order":["征召登记单","科瓦廖夫签字。去供应点领取出发装备，再到集合气闸报到。","通行"],
 "mask":["防毒面具","空气防护装备，与净水设施的滤芯不是一回事。","装备"],
 "filter":["备用滤毒罐","配合防毒面具使用。出发前检查接口密封，别让罐口受潮。","装备"],
 "vitamins":["维生素 D","供应员留给居民的配给。米哈伊尔的手一直在抖。","人情"],
 "frequency":["手抄频率","收音机里断续出现的「东方-7」。尚未证实与父亲有关。","线索"]
}
const ROUTES = {"official":"随征召小队出发", "permit":"持检修许可离站", "bribe":"用战前酒换取通行", "shift":"趁换班走侧门", "hatch":"绕行旧检修管线"}

func has(id: String) -> bool: return id in items
func f(id: String) -> bool: return flags.get(id,false)
func give(id: String):
	if not has(id):items.append(id)
func take(id: String):items.erase(id)
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
			v.options=[opt("tune","记下频率",not has("frequency"),"已记下")]
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
			v.role="东段维修工 / 本次新增人物"
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
			v.name="东侧维修正门"
		"side":
			v.name="压力表后的检修侧门"
			v.options=[opt("use_shift","按情报等候换班，从侧门通过",f("shift") and has("map") and not f("side"),"需要维修草图与换班情报")]
		"hatch":
			v.name="旧检修盖板"
			v.options=[opt("hatch_wrench","用扳手拆盖板，绕行检修管线",has("wrench"),"需要扳手"),opt("hatch_knife","硬撬盖板，折损匕首后绕行",has("knife"),"需要旧匕首")]
		"lift":
			v.name="集合气闸 · 征召小队"
			v.options=[opt("leave_official","检查装备，准备随队离站",f("accepted") and f("kit"),"需要登记征召并在供应点领取装备")]
		"exit":
			v.name="东段尽头 · 未完工延伸线"
			v.options=[opt("leave_east","整理背包，准备离开 D-6",route!="", "先通过正门、侧门或检修管线")]
	return Narrative.decorate(v,self)

func act(key: String) -> String:
	# Revalidate the same conditions used by the UI before mutating state.
	var valid=false
	for id in ["box","radio","notice","chalk","semyon","mikhail","cook","valve","nina","cabinet","relay","supply","commander","igor","side","hatch","lift","exit"]:
		for o in view(id).options:
			if o.key==key and o.enabled:valid=true
	if not valid:return "条件尚未满足，或这件事已经做过了。"
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
			know("东段有正门、检修侧门和旧管线。地图不提供通行权限。")
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
		"briefing":pass
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
	changed.emit()
	return last_reply

func objective() -> String:
	if ending:return "离站记录已收好"
	if f("gate") or route=="hatch" or route=="shift":return "穿过东侧通道，在延伸线尽头确认离站"
	if f("kit"):return "准备好后，到集合气闸随征召小队离站"
	if f("accepted"):return "携登记单到第 7 供应点领取防护装备"
	if f("relay") and not has("permit"):return "监测已恢复 · 回维修区请妮娜签字"
	if f("nina_job"):return "找备用保险芯，修复东侧压力监测箱"
	return "了解净水危机，决定如何离开 D-6"

func serialize() -> Dictionary:
	return {"version":1,"flags":flags,"items":items,"intel":intel,"route":route,"ending":ending}
func restore(data: Dictionary):
	flags=data.get("flags",{}).duplicate()
	items.assign(data.get("items",[]))
	intel.assign(data.get("intel",[]))
	route=data.get("route","")
	ending=data.get("ending",false)
	changed.emit()
