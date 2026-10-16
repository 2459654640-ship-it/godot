extends RefCounted
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
 "photo":["母亲的照片","边角卷曲的全家照。给谢苗诺夫看看，也许他还记得父亲的事。","记忆"],
 "vodka":["战前伏特加","仅此一瓶。可与伊戈尔换通行；交出便无法收回。","交换"],
 "map":["维修通道草图","米哈伊尔标出的两道门与旧检修管线。可辅助辨认侧门。","情报"],
 "wrench":["借来的扳手","维修工妮娜的工具。能拧紧食堂阀门，也可完整拆下检修盖板。","工具"],
 "fuse":["陶瓷保险芯","公共洗漱区旧配电柜里的备用件。可恢复东段的压力监测。","维修"],
 "soup":["一份热汤","帮厨房止住漏水换来的。送给米哈伊尔可获得换班情报。","人情"],
 "permit":["临时检修许可","妮娜签字，伊戈尔可以据此放行。仅覆盖东段维修通道。","通行"],
 "order":["征召登记单","科瓦廖夫签字。去供应点领取出发装备，再到集合气闸报到。","通行"],
 "mask":["防毒面具","空气防护装备，与净水设施的滤芯不是一回事。","装备"],
 "filter":["备用滤毒罐","配合防毒面具使用。原型内不模拟寿命。","装备"],
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
			v.body="箱盖被磨得发亮。里面是老爹留下的旧物，箱底有一道浅浅的撬痕。" if not f("searched") else "匕首、烟和照片已经收好。松动的底板下面，还藏着一层。"
			v.options=[opt("search_box","翻查木箱",not f("searched"),"已搜寻"),opt("open_cache","撬开松动的底板",has("knife") and not f("cache"),"需要旧匕首" if not f("cache") else "暗格已空")]
		"radio":
			v.name="修过三次的收音机"
			v.body="锈死的旋钮后，静电声像细雨。\n「……东方……七……」\n这不是广播时刻表上的呼号。信号很弱，无法判断来自哪里。"
			v.options=[opt("tune","记下频率",not has("frequency"),"已记下")]
		"notice":
			v.name="第 7 供应点 · 征召令"
			v.body="D-6 净水设施核心部件耗尽。储水仅够两周。\n征召小队明晨前往东郊水处理厂，寻找 1962 年封存的净水滤芯。伊万的名字在名单上。\n\n滤毒罐用于呼吸防护，不能修复净水设施。"
			v.options=[opt("read_notice","将征召令记入手记",not f("notice"),"已记录")]
		"chalk":
			v.name="新添的粉笔记号"
			v.body="一颗星星，一道绕行的轨道。粉笔灰还没有被潮气浸透。\n有人昨晚来过。标志不是地图，也不能证明谁还活着。"
			v.options=[opt("chalk","拓下标记",not f("chalk"),"已记录")]
		"semyon":
			v.name="谢苗诺夫"
			v.role="工程兵老爹 / 居民"
			v.body="「先把围巾系紧。地上没有人替你检查面具。」\n他用一截铜丝修眼镜，桌边还留着你的搪瓷杯。"
			v.options=[opt("father","给他看母亲的照片",has("photo"),"需要母亲的照片"),opt("semyon_advice","问起净水设施与自己的选择"),opt("semyon_radio","问起东方-7",has("frequency"),"先调查收音机")]
		"mikhail":
			v.name="米哈伊尔"
			v.role="仓库管理员 / 食堂常客"
			v.body="「伊万。也收到征召令了？」\n他用双手捧着冷掉的搪瓷杯。面包硬得像木头。\n「图我可以给你。可有图不等于有人替你开门。」"
			if f("shift"):v.body="「东侧侧门。灯由白变黄时，伊戈尔会离岗查表。」\n他把杯子推开一点，给你让出桌边的位置。\n「别把两分钟当成一辈子的保证。」"
			v.options=[opt("map","询问东侧维修通道",not has("map"),"已拿到草图"),opt("trade_smoke","用半包烟交换换班情报",has("cigarettes") and not f("shift"),"需要香烟；情报不可重复交换"),opt("give_soup","把热汤递给他，问问换班",has("soup") and not f("shift"),"需要厨房的一份热汤"),opt("give_vitamins","给他维生素 D",has("vitamins") and not f("vitamins_given"),"需要维生素 D；不可重复赠送")]
		"cook":
			v.name="加琳娜"
			v.role="公共食堂 / 厨房负责人"
			v.body="「今天的水，明天还得用。接头又漏了，再滴下去，晚饭只能干嚼。」\n她指向灶台右侧的回水阀。\n「帮忙止住，我给你留碗热的。妮娜那儿有工具。」"
			if f("valve"):v.body="「总算不漏了。热汤留着，带给真正需要它的人。」\n锅盖下的白汽缓缓升起。"
			v.options=[opt("cook_job","答应帮厨房止漏",not f("cook_job"),"已记下"),opt("claim_soup","领取答谢的热汤",f("valve") and not f("soup_claimed"),"先修好灶台边的漏水阀")]
		"valve":
			v.name="厨房回水阀"
			v.body="磨损的压紧螺母边缘渗着水。用手拧不动。\n不需要更换整段管线，合适的扳手就够了。"
			v.options=[opt("fix_valve","用扳手拧紧接头",has("wrench") and not f("valve"),"需要扳手" if not f("valve") else "漏水已止住")]
		"nina":
			v.name="妮娜"
			v.role="东段维修工 / 本次新增人物"
			v.body="「净水滤芯我们造不出来。但能修的，也不能搁着。」\n她敲敲工作单。\n「东侧压力监测烧了保险芯。洗漱间旧配电柜有备用的。帮我换上，我签一张检修许可，再给你借套防护装备。」"
			if f("relay"):v.body="「压力读数回来了。你把能做的做完了。」\n她从工具箱下面抽出检修登记簿。\n「许可写你的名字。离开这儿以后，它就不替你担保了。」"
			v.options=[opt("borrow_wrench","借用扳手",not has("wrench"),"工具在背包里"),opt("nina_job","接下压力监测维修",not f("nina_job"),"已记下"),opt("claim_permit","领取检修许可与防护装备",f("relay") and not has("permit"),"先更换东侧监测箱保险芯")]
		"cabinet":
			v.name="洗漱区 · 旧配电柜"
			v.body="这只柜子早已断电，门栓卡住了。柜内挂着一个纸袋，标注「备用 / 2A」。\n可以用扳手松开门栓，或用匕首轻撬。"
			v.options=[opt("get_fuse","打开断电柜，取出保险芯",(has("wrench") or has("knife")) and not f("fuse_taken"),"需要扳手或匕首" if not f("fuse_taken") else "备用件已取走")]
		"relay":
			v.name="东侧压力监测箱"
			v.body="机械压力表仍在转动，电气读数却是一条直线。\n妮娜已经断开这条低压回路；熔断器座上留着焦痕。"
			v.options=[opt("fix_relay","更换保险芯并复位",has("fuse") and has("wrench") and not f("relay"),"需要保险芯与扳手" if not f("relay") else "监测已恢复")]
		"supply":
			v.name="柳德米拉"
			v.role="第 7 供应点 / 配给员"
			v.body="「今天每人二两。别朝我瞪眼，仓库不会因为我心软就多一袋粮食。」\n她把领取簿翻到出发人员那页。\n「有科瓦廖夫签字，我才能发整套防护装备。维生素是居民配给，可以先领。」"
			v.options=[opt("vitamins","领取今日维生素 D",not f("vitamins_taken"),"今日份已领"),opt("get_kit","凭征召登记单领取出发装备",has("order") and not f("kit"),"需要科瓦廖夫的登记单；不可重复领取")]
		"commander":
			v.name="中尉科瓦廖夫"
			v.role="征召小队 / 指挥官"
			v.body="「我们明天出发。东郊水处理厂，找净水滤芯。」\n他的手指按在一张磨破的清单上。\n「这不是一场远足。你可以先把要问的问完，登记也不等于现在就把门锁上。」"
			v.options=[opt("briefing","询问队伍、风险与准备"),opt("accept","登记参加征召小队",not f("accepted"),"已登记；仍可探索其他路线")]
		"igor":
			v.name="老伊戈尔"
			v.role="东侧岗哨 / 卫兵"
			v.body="「没有命令，谁也不能出去。放你过去，明天坐在审讯室里的就是我。」\n他向压力表看了一眼，又转回来。"
			if f("gate"):v.body="「门开着。别在门口站太久。」\n他把视线移向登记簿，不再催你。"
			v.options=[opt("igor_talk","问问为什么把守旧通道"),opt("use_permit","出示妮娜签字的检修许可",has("permit") and not f("gate"),"需要临时检修许可"),opt("use_vodka","交出战前伏特加，换通行",has("vodka") and not f("gate"),"需要战前伏特加；仅此一瓶")]
		"gate":
			v.name="东侧维修正门"
			v.body="钢门连着地铁 2 号线未完工的延伸段。门后的空气比居住层更冷。\n"+("伊戈尔已经打开门闩。穿过门后，再决定是否离开。" if f("gate") else "门闩扣着。检修许可，或一次真正的交涉，才能让伊戈尔开门。")
		"side":
			v.name="压力表后的检修侧门"
			v.body="换班指示灯每十二秒走过一轮；黄灯持续四秒。\n这是用于测试的压缩时序。门后没有奖励装备，只有一段绕开岗哨的窄路。"
			v.options=[opt("use_shift","按情报等候换班，从侧门通过",f("shift") and has("map") and not f("side"),"需要维修草图与换班情报")]
		"hatch":
			v.name="旧检修盖板"
			v.body="管道接入维修正门后方。盖板宽 0.9 米，只能俯身钻过。\n用扳手可以完整拆卸。匕首也能撬开，但会折断刀尖，且没有任何防护装备作为补偿。"
			v.options=[opt("hatch_wrench","用扳手拆盖板，绕行检修管线",has("wrench"),"需要扳手"),opt("hatch_knife","硬撬盖板，折损匕首后绕行",has("knife"),"需要旧匕首")]
		"lift":
			v.name="集合气闸 · 征召小队"
			v.body="气闸内传来装备碰撞声。出发名册钉在门边。\n离开后，本次 D-6 原型结束；不会跳入尚未制作的水厂章节。"
			v.options=[opt("leave_official","检查装备，准备随队离站",f("accepted") and f("kit"),"需要登记征召并在供应点领取装备")]
		"exit":
			v.name="东段尽头 · 未完工延伸线"
			v.body="身后的灯光到这里便停住了。轨道消失在更冷的黑暗里。\n你可以返回，或确认离开 D-6。本原型到离站为止。"
			v.options=[opt("leave_east","整理背包，准备离开 D-6",route!="", "先通过正门、侧门或检修管线")]
	return v

func act(key: String) -> String:
	# Revalidate the same conditions used by the UI before mutating state.
	var valid=false
	for id in ["box","radio","notice","chalk","semyon","mikhail","cook","valve","nina","cabinet","relay","supply","commander","igor","side","hatch","lift","exit"]:
		for o in view(id).options:
			if o.key==key and o.enabled:valid=true
	if not valid:return "条件尚未满足，或这件事已经做过了。"
	match key:
		"search_box":
			flags.searched=true
			for id in ["knife","cigarettes","photo"]:give(id)
			last_reply="你取出了旧匕首、半包烟和母亲的照片。底板上有一道熟悉的撬痕。"
		"open_cache":
			flags.cache=true
			give("vodka")
			last_reply="底板下是一瓶战前伏特加。封蜡还在，老爹把它藏得很深。\n你可以留住它，也可以拿它交换一次通行。"
		"tune":
			give("frequency")
			know("收音机里出现呼号「东方-7」，来源与含义未证实。")
			last_reply="你把频率抄在纸上。静电声里再也没有完整的句子。"
		"read_notice":
			flags.notice=true
			know("储水只够两周；正式征召需要登记和防护装备。")
			last_reply="你记下了出发流程：找科瓦廖夫登记 → 第 7 供应点领装备 → 集合气闸。"
		"chalk":
			flags.chalk=true
			know("走廊粉笔标记是一颗星与轨道；尚不能与东方-7划等号。")
			last_reply="你拓下标记。它是线索，不是答案。"
		"father":
			flags.father=true
			know("谢苗诺夫记得父亲，却未确认他是否生还。父亲线暂不下结论。")
			last_reply="「你母亲总嫌他拍照不肯笑。」\n老爹用拇指擦了擦照片的边。\n「那天以后，我没有收到过他的信。有人说见过他，我也找过。没找到，不等于死了；传闻，也不等于还活着。把照片收好。」"
		"semyon_advice":last_reply="「别让谁替你决定全部的路。但做决定以前，把别人的水和自己的命都算进去。」\n「妮娜缺人手；米哈伊尔认得旧通道。要走正路，就把出发装备领齐。」"
		"semyon_radio":last_reply="「东方？战前这样的呼号多得很。先记着，不要追着一个声音把命送掉。」\n他把收音机往你这边推了一点。\n「等你有第二条证据，再来问我。」"
		"map":
			give("map")
			know("东段有正门、检修侧门和旧管线。地图不提供通行权限。")
			last_reply="「正门归伊戈尔管。侧门在压力表后边。旧盖板通到门后，不过那不是给人走的。」\n获得：维修通道草图。"
		"trade_smoke","give_soup":
			take("cigarettes" if key=="trade_smoke" else "soup")
			flags.shift=true
			give("map")
			know("黄灯亮起时伊戈尔去查表。已标记侧门；可等候换班穿行。")
			last_reply="「换班的黄灯一亮，他就去查压力表。侧门那儿，顶多一会儿。」\n他把时间写在草图背面。\n获得：换班情报；没有获得防护装备。"
		"give_vitamins":
			take("vitamins")
			flags.vitamins_given=true
			know("米哈伊尔：妮娜能凭检修工作签发许可，避免私放人员连累伊戈尔。")
			last_reply="「你自己也需要的。」\n他终于把杯子放稳了。\n「伊戈尔怕的不是你，是审查。真想让他松口，就帮妮娜做一件能写进登记簿的事。」"
		"cook_job":
			flags.cook_job=true
			last_reply="「回水阀，就在灶台边。别把总阀关了，整层的人都要等饭。」"
		"fix_valve":
			flags.valve=true
			last_reply="你用扳手拧紧接头。最后一滴水落进铁桶，滴答声停了。加琳娜抬头朝你点了一下。"
		"claim_soup":
			flags.soup_claimed=true
			give("soup")
			last_reply="「拿稳。能换来一个人好好说话的东西，现在不多了。」\n获得：一份热汤。"
		"borrow_wrench":
			give("wrench")
			last_reply="「借你。用完别丢，整层没第二把这么顺手的。」\n获得：借来的扳手。"
		"nina_job":
			flags.nina_job=true
			last_reply="维修步骤已记下：洗漱区断电柜取保险芯 → 东侧压力监测箱更换 → 回来找妮娜签字。"
		"get_fuse":
			flags.fuse_taken=true
			give("fuse")
			last_reply="门栓松开。纸袋里还有一枚完好的 2A 陶瓷保险芯。"
		"fix_relay":
			take("fuse")
			flags.relay=true
			last_reply="你换上保险芯，合回低压回路。指针回到了绿色刻度。\n回维修区找妮娜，她可以签发检修许可。"
		"claim_permit":
			for id in ["permit","mask","filter"]:give(id)
			last_reply="妮娜写上你的名字，附上一套借用的防护装备。\n「许可只到东段，别拿它冒充中央的通行证。」"
		"vitamins":
			flags.vitamins_taken=true
			give("vitamins")
			last_reply="你在领取簿上签字。今日份不会再发第二遍。"
		"get_kit":
			flags.kit=true
			for id in ["mask","filter"]:give(id)
			last_reply="柳德米拉核对签字，取出防毒面具和备用滤毒罐。\n「口罩扣紧，到集合气闸前再检查一次。」"
		"briefing":last_reply="「两周储水是上限，不是保证。我们去找净水滤芯，不是面具的滤毒罐。」\n「今晚先检查装备，和该告别的人说句话。你有技术，我们需要你。但我不能保证每个人都回来。」"
		"accept":
			flags.accepted=true
			give("order")
			last_reply="科瓦廖夫在名册上画了一笔。\n获得：征召登记单。去第 7 供应点领取防护装备，准备好后再到集合气闸。"
		"igor_talk":last_reply="「那边接未完工的延伸段。冷、黑，还不在巡逻范围里。」\n「你要有妮娜签字的检修许可，我能给你开门。没文件……别让我难做。」"
		"use_permit":
			flags.gate=true
			flags.gate_route="permit"
			route="permit"
			last_reply="伊戈尔逐行看过许可，把编号抄进登记簿。门闩终于打开。\n检修许可保住了双方的名字，但门外仍没有人保证安全。"
		"use_vodka":
			take("vodka")
			flags.gate=true
			flags.gate_route="bribe"
			route="bribe"
			give("mask")
			give("filter")
			last_reply="「战前的？……这瓶我记得。」\n伊戈尔接过酒，沉默了很久，把备用面具推到桌边。\n「我去查表。你没见过我，我也没见过你。」\n酒已交出。正门打开；这次私放不在登记簿上。"
		"use_shift":
			flags.side=true
			last_reply="你记住了侧门的位置，准备等黄灯。关闭对话后，靠近侧门按 E 开始等候；伊戈尔查表时穿过去。"
		"hatch_wrench","hatch_knife":
			flags.hatch=true
			route="hatch"
			if key=="hatch_knife":take("knife")
			last_reply="盖板挪开了。"+("刀尖折在锈缝里，再也用不上。" if key=="hatch_knife" else "螺栓完整收在口袋，扳手仍可使用。")+"\n你俯身穿过旧管线，来到岗哨后方。这里只通向延伸线，不赠送防护装备。"
		"leave_official":pass
		"leave_east":pass
	changed.emit()
	return last_reply

func objective() -> String:
	if ending:return "本次离站已记录 · 可返回继续比较路线"
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
