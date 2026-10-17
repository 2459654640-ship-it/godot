extends RefCounted
## Additional conversations and small local errands. Story owns persistence.
const IDS=["resident","diner","heating","laundry","residents_board","closed_rooms","pipe_exit"]
const REPLIES={
"heat_job":"「不是整层都冷，就我们这根支管，夜里咕噜咕噜响。」\n帕维尔在纸上画了个阀门的位置。\n「妮娜忙不开。你要能帮着排排气，我替你把维修记录签了。干布在洗衣间，别拿晾着的那几件衣服。」",
"take_rag":"你从公用篮里取出一块叠好的干布。篮沿贴着纸条：修管线用，脏了放回水池边。",
"fix_heating":"你垫着布，慢慢拧开排气阀。先是一阵嘶嘶声，随后有热水渗出来。你关紧阀门，把水擦干。\n过了一会儿，暖气片的上沿也热了。湿布留在接水盆里。",
"claim_report":"帕维尔摸过暖气片，把纸压在柜顶，写好支管号和时间。\n「拿给伊戈尔吧。当班的人还得去走廊总表复核一遍。你帮了忙，也省得他隔着门挨骂。」",
"resident_shift":"「四张床，不是四个人从早睡到晚。白班走了，夜班才回来。」\n帕维尔把一双袜子塞进柜里。\n「东边那几间也是住户。门关着，不是没人，是刚睡下。你们那两间原来是工程兵值守房，老谢才住得清静些。」",
"resident_igor":"「伊戈尔？腰坏了，嘴没坏。」\n帕维尔笑了一声。\n「这根管子归他当班看总表，不归他修。真有维修记录，他会来；空口说坏了，他怕又白跑一趟。」",
"vera_heat":"「半夜还是冷的，我把另一条毯子也拿出来了。」\n维拉看了一眼暖气片。\n「你要会弄，就帮忙看看。帕维尔记着支管号，洗衣间有干布。别把阀门拧下来，热水会烫人。」",
"vera_day":"「他上白班，我上晚班。能一起吃顿饭，就算这一天过得不错。」\n维拉把桌上的书合起来。\n「不是人人都有单间。隔壁床按班轮着睡，我们算运气好的。」",
"vera_nina":"「妮娜上次给这儿换过灯，没收东西，就问能不能借个干净杯子。」\n维拉朝洗衣间指了指。\n「她把工具弄得干干净净，自己袖口倒全是油。你看见她，叫她把外套送来洗。」",
"read_residents":"你看过登记板。西翼有四铺的轮班宿舍和家属房；B 区几道关着的门后，还有按班休息的住户。\n供暖支管号抄在维修栏下，复核位置是主通道的总压力表。",
"knock_rooms":"门里先传来一声床架响。\n「夜班刚躺下……有急事吗？」\n你说没有，只是路过。\n「那就轻点。开水在洗衣间，别再拧走廊那个漏水龙头。」",
"nina_safety":"「东侧监测箱，低压维修回路，已经断开。开关上有我的检修牌。」\n妮娜把扳手递给你。\n「先问清楚是对的。换完看读数，别碰旁边还在供电的那一路。」",
"nina_reckless":"妮娜没有笑。\n「你要觉得带电换也一样，我就不能把这活交给你。先把断电的事问明白，别拿自己试。」",
"guard_greet":"「只有我。接班的人去领东西了。」\n伊戈尔换了条腿站着。\n「你要出去，就拿手续。要聊天，站边上，别把门口堵了。」",
"guard_listen":"「搬煤那年伤的。站久了就这样，坐久了也一样。」\n他摆了摆手。\n「别替我操心。真有故障，报支管号，我还得去看总表；没事我可不能随便离岗。」",
"guard_report":"伊戈尔核对了支管号和帕维尔的签字。\n「排过气了？行，我去看看总表，再补一条记录。」\n他拿起铅笔。\n「你站开点，门口别碰。」",
"semyon_fear":"「怕很正常。」\n老爹看着你，没有急着往下说。\n「你父亲出任务前也会把扣子扣错。别逞着说不怕，把该查的都查了，心里会稳一点。」",
"semyon_bravado":"「有把握是好事，别把有把握当成不会出事。」\n他轻轻敲了敲你的背包。\n「先试面具，再看行李。嘴上再硬，也堵不住一条漏气的边。」"
}

static func check_option(s,key:String,text:String,chance:int) -> Dictionary:
	var attempted=s.flags.get("social_checks",{}).has(key)
	var option=s.opt(key,text,not attempted and not s.f("guard_task"),"这种说法已经试过了，换个办法" if attempted else "伊戈尔已经答应离岗检查")
	option.check={"chance":chance,"tier":"高" if chance>=70 else ("中" if chance>=45 else "低")}
	return option

static func decorate(v:Dictionary,s) -> Dictionary:
	match v.id:
		"resident":
			v.name="帕维尔";v.role="夜班检修工 / 西翼住户"
			v.body="「是老谢家那个伊万吧？进来，别踢着床下的鞋。」\n帕维尔把柜门合上，朝走廊看了看。\n「这班算下来了，回屋还得等暖气。家属房那根支管一夜没热，妮娜一个人哪顾得过来。」"
			v.options=[s.opt("heat_job","「暖气怎么了？我去看看。」",not s.f("heat_job"),"已记下"),s.opt("claim_report","「暖气热了，麻烦你签一下记录。」",s.f("heating_fixed") and not s.has("report"),"先处理家属房的暖气"),s.opt("resident_shift","「这里的床够住吗？」"),s.opt("resident_igor","「伊戈尔会管这事吗？」")]
			if s.f("heating_fixed"):v.body="「暖气热了，刚才摸过。辛苦你。」\n帕维尔把笔找出来。\n「维修记录我签。值班员还得看一眼总表，免得别的支管又闹。」"
		"diner":
			v.name="维拉";v.role="洗衣值班 / 家属房住户"
			v.body="「鞋底蹭一下，刚擦过地。」\n维拉把另一张床上的毯子抻平。\n「暖气没热，夜里拿几条毯子都不够。你找我，还是找帕维尔？」"
			v.options=[s.opt("vera_heat","「我看看暖气，阀门在哪儿？」"),s.opt("vera_day","「你们什么时候能歇一歇？」"),s.opt("vera_nina","「你和妮娜熟吗？」")]
			if s.f("heating_fixed"):v.body="「热了，真的热了。」\n维拉把手放在暖气片上，终于松了口气。\n「谢谢。干布脏了放盆里就行，我来洗。记录找帕维尔签，他记得支管号。」"
		"heating":
			v.name="家属房 · 暖气排气阀"
			v.body="暖气片下半截温热，上半截却凉着。管内有气，阀口还能看见旧水迹。\n用扳手慢慢排气，再用干布接住溢出的热水。"
			v.options=[s.opt("fix_heating","垫着干布，用扳手排气",s.has("wrench") and s.has("rag") and not s.f("heating_fixed"),"需要扳手和干布" if not s.f("heating_fixed") else "暖气已经恢复")]
			if s.f("heating_fixed"):v.body="暖气片上下都温热了。阀门关得很紧，地上也擦干了。"
		"laundry":
			v.name="洗衣间 · 公用干布"
			v.body="几条洗净的布巾晾在管子下。旁边的篮子里放着修管线用的干布，贴着住户共同写的纸条：用完放回盆里。"
			v.options=[s.opt("take_rag","拿一块公用干布",not s.f("rag_taken"),"已经拿过一块")]
		"residents_board":
			v.name="西翼住户登记板"
			v.body="轮班宿舍：四铺，白夜班错开休息。\n家属房：维拉一家。\nB 区：夜班休息，走廊请轻声。\n\n维修栏：家属房支管积气。排气后由当班值守到主通道总表复核，住户签字。"
			v.options=[s.opt("read_residents","记下住户与维修安排",not s.f("residents_read"),"已经记下")]
		"closed_rooms":
			v.name="B 区 · 夜班宿舍门"
			v.body="门后有人轻轻咳了一声。床板吱呀响过，屋里又静下来。门上挂着牌子：夜班刚回，请勿打扰。"
			v.options=[s.opt("knock_rooms","轻轻敲门问候")]
		"pipe_exit":
			v.name="检修管线 · 另一端"
			v.body="盖板挪在一边。沿着这段窄管道，能回到岗哨后面的入口。"
			v.options=[s.opt("return_pipe","沿管线返回生活层",s.f("hatch"),"先从另一端打开盖板")]
		"nina":
			v.options.push_front(s.opt("nina_safety","「先确认一下：哪条回路已经断电？」",not s.f("nina_safety"),"断电范围已经确认"))
			v.options.append(s.opt("nina_reckless","「换个保险芯，带电也能干吧？」",not s.f("nina_safety"),"她已经说明安全步骤"))
			for o in v.options:
				if o.key=="borrow_wrench" and not s.f("nina_safety"):o.enabled=false;o.reason="先向妮娜确认断电范围"
		"semyon":
			v.options.append(s.opt("semyon_fear","「老爹，说实话，我有点怕。」"))
			v.options.append(s.opt("semyon_bravado","「放心，我能应付。」"))
		"igor":
			v.options.append(s.opt("guard_greet","「今天还是你站这班？」",not s.f("guard_chat"),"已打过招呼"))
			if s.f("guard_chat"):
				v.options.append(s.opt("guard_listen","「腰又疼了？还得去查表？」",not s.f("guard_listened"),"已经聊过他的值班"))
				var chance=75 if s.f("guard_listened") else 45
				if s.f("guard_wary"):chance-=20
				v.options.append(check_option(s,"guard_appeal","「去总表那边活动一下，我在这里等。」",chance))
			v.options.append(check_option(s,"guard_bluff","「中尉说总表不稳，叫你过去。」",55 if s.f("briefed") else 30))
			v.options.append(s.opt("guard_report","递上住户签字的维修记录，请他复核总表",s.has("report") and not s.f("guard_task"),"需要暖气维修记录" if not s.has("report") else "他已经答应去检查"))
			var priority=[]
			var rest=[]
			for o in v.options:
				if o.key in ["guard_greet","guard_listen"] and not o.enabled:continue
				if o.key.begins_with("guard_"):priority.append(o)
				else:rest.append(o)
			v.options=priority+rest
			if s.f("guard_task"):v.body="「知道了，我去总表那里看看。」\n伊戈尔拿起铅笔，朝主通道看了一眼。\n「门口别碰，有事等我回来再说。」"
		"hatch":
			for o in v.options:
				if not s.guard_clear():o.enabled=false;o.reason="伊戈尔还看得到这里，得先让他离开岗哨"
				if s.f("hatch"):o.enabled=false;o.reason="盖板已经拆开"
			if s.f("hatch"):v.options.append(s.opt("hatch_pass","钻过已经打开的检修管线"))
			elif not s.guard_clear():v.body+="\n\n伊戈尔就在不远处。现在动盖板，他一定会听见。"
	return v

static func handles(key:String) -> bool:
	return key in REPLIES or key in ["guard_appeal","guard_bluff","hatch_pass","return_pipe"]

static func act(key:String,s) -> String:
	match key:
		"heat_job","vera_heat":s.flags.heat_job=true
		"take_rag":s.flags.rag_taken=true;s.give("rag")
		"fix_heating":s.flags.heating_fixed=true;s.take("rag")
		"claim_report":s.give("report")
		"read_residents":s.flags.residents_read=true;s.know("西翼有轮班宿舍与家属房；暖气排气后，值班员须到主通道总表复核。")
		"nina_safety":s.flags.nina_safety=true;s.give("wrench")
		"nina_reckless":s.flags.nina_caution=true
		"guard_greet":s.flags.guard_chat=true
		"guard_listen":s.flags.guard_listened=true
		"guard_report":s.flags.guard_task=true
		"guard_appeal","guard_bluff":
			var chance=30
			for o in s.view("igor").options:
				if o.key==key:chance=o.check.chance
			var success=s.resolve_check(key,chance)
			if success:
				s.flags.guard_task=true
				return "伊戈尔想了一会儿，把登记簿夹在腋下。\n「行，我去看一眼。你站旁边，门别碰。」\n他得走出岗哨，才有机会动盖板。"
			else:
				s.flags.guard_wary=true
				return "「真是中尉的安排，让他写个条子。」\n伊戈尔没有动。" if key=="guard_bluff" else "「活动归活动，岗还得有人站。不能听你一句话就走。」\n他摇摇头。\n「有维修记录，我去复核；没手续，别让我为难。」"
		"hatch_pass":return "你侧过身，沿着已经拆开的管线钻到岗哨后方。工具和背包都带着。"
		"return_pipe":return "你沿着管线爬回生活层，推开盖板旁的空隙，重新站到熟悉的灯下。"
	return REPLIES.get(key,"")
