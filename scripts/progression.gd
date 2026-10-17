extends RefCounted
## Quest outcomes only change at explicit irreversible choices; walking away is harmless.
const IDS=["inner_latch"]
static func annotate(s,rows:Array)->Array:
	var main=["journey","report","kit","water","anna","radio","father","workers_network","north_train","weather_link","workers_choice","train_choice","weather_choice"]
	var failed:Dictionary=s.flags.get("failed_quests",{})
	for t in rows:
		t.kind=t.get("kind","主线" if t.id in main else "支线")
		var diverted=(t.id in ["report","kit"] and s.f("departure_committed") and s.route!="official") or (t.kind=="主线" and s.ending and not t.done)
		if diverted:t.done=true
		t.failed=failed.has(t.id) and not t.done
		t.status="已改道" if diverted else ("已失败" if t.failed else ("已完成" if t.done else "进行中"))
		if t.failed:t.step=failed[t.id];t.target=""
	return rows
static func fail(s,places:Array,reason:String):
	var records:Dictionary=s.flags.get("failed_quests",{}).duplicate(true)
	for t in preload("res://scripts/journal.gd").tasks(s):
		if t.kind=="支线" and not t.done and not t.failed and (places.is_empty() or t.place in places):records[t.id]=reason
	s.flags.failed_quests=records
static func failed_action(s,key:String)->bool:
	for q in s.Campaign.data().get("quests",[]):
		if s.flags.get("failed_quests",{}).has(q.id) and key in q.get("actions",[]):return true
	return false
static func decorate(v:Dictionary,s)->Dictionary:
	if v.id=="igor" and s.f("igor_suspicious"):
		v.body="伊戈尔用手抵着已经关好的门，额头上全是汗。\n「这门我走时锁着。伊万，你别看别处。换个人，我早交上去了……老谢照顾过我，我不告发你。」\n他又压低声音。\n「可这次差点把我也搭进去。拿三发制式弹，或一样值点钱的东西来。手头没有，就替我把岗哨的灯擦干净。」"
		if s.f("igor_settled"):v.body="伊戈尔看了你一眼，又去摸门闩。\n「东西收到了。这事到我这里为止。以后拿手续走，别再让我替你提着心。」"
		v.options.append(s.opt("igor_pay","交给他 3 发制式弹",not s.f("igor_settled") and s.economy.military>=3))
		v.options.append(s.opt("igor_gift","拿一份绳带或干电池作补偿",not s.f("igor_settled") and (s.economy.goods.get("cord",0)>0 or s.economy.goods.get("battery",0)>0)))
		v.options.append(s.opt("igor_work","「我手头紧。灯在哪里？我来清理。」",not s.f("igor_settled") and not s.f("igor_chore")))
		v.options.append(s.opt("igor_done","请伊戈尔验看清理好的岗灯",s.f("igor_lamp_clean") and not s.f("igor_settled")))
	if v.id=="relay" and s.f("igor_chore") and not s.f("igor_settled"):
		v.options.append(s.opt("igor_lamp","用岗哨旁的干布清理灯罩",not s.f("igor_lamp_clean")))
	if v.id=="exit" and (not s.has("mask") or not s.has("filter")):
		v.body+="\n检查牌要求面具与滤毒罐齐全。可以从内侧安全闩返回，去供应点购买；也可以下楼登记征召，免费领取装备。"
	if v.id=="inner_latch":
		v.name="侧门 / 内侧安全闩";v.role="内侧检修";v.body="侧门内侧留有机械安全闩，供检修者返回岗哨，不受外面的锁芯限制。拉动会让守卫发现这道门曾被使用。"
		v.options=[s.opt("inner_return","拉开内侧安全闩，返回岗哨",s.context.get("floor","")=="life")]
	if v.id=="supply" and not s.has("mask"):v.options.append(s.opt("buy_protection","购买防毒面具与配套滤毒罐 · 8 发制式弹",s.economy.military>=8))
	# Unfamiliar subjects are introduced by an open question, not by clairvoyance.
	if v.id=="semyon" and not s.has("frequency"):
		for o in v.options:
			if o.key=="semyon_radio":o.enabled=false
	if v.id=="sech_sergey" and not s.f("father"):
		for o in v.options:
			if o.key=="c_sech_father":o.text="「星城接受外人来访吗？」"
	return v
static func handles(key:String)->bool:return key in ["inner_return","igor_pay","igor_gift","igor_work","igor_lamp","igor_done","buy_protection"]
static func act(s,key:String)->String:
	match key:
		"inner_return":s.flags.side_inside_release=true;s.flags.side_pass=true;s.flags.igor_suspicious=true;return "你拉下内侧安全闩，门沿导轨缓缓升起。回到岗哨后，门会重新关好。"
		"buy_protection":
			s.economy.military-=8;s.give("mask");s.give("filter");return "柳德米拉让你试好密封，再把备用滤毒罐包上。\n「八发，记账了。出去前再查一遍接口。」"
		"igor_pay":s.economy.military-=3;s.flags.igor_settled=true;return "伊戈尔把三发子弹拢进掌心，终于松开门闩。\n「算了。老谢那边，我不会说。」"
		"igor_gift":
			var good="cord" if s.economy.goods.get("cord",0)>0 else "battery"
			s.economy.goods[good]-=1
			if s.economy.goods[good]==0:s.economy.goods.erase(good)
			s.flags.igor_settled=true;return "伊戈尔将物资收到抽屉里。\n「能用上。这回就到这儿。」"
		"igor_work":s.flags.igor_chore=true;return "「压力监测箱旁边那盏岗灯。干布就在灯脚，别动电线。擦亮了叫我。」"
		"igor_lamp":s.flags.igor_lamp_clean=true;return "你取下灯罩外侧的灰，擦净玻璃，再把干布放回灯脚。灯光终于照清了门边的工牌。"
		"igor_done":s.flags.igor_settled=true;return "伊戈尔凑近看了看，又退回原来的位置。\n「行，干净了。欠的就抵了。走吧，别让我再想起这事。」"
	return ""
