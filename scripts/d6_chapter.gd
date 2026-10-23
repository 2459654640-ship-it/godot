extends RefCounted
const IDS=["armory","medical","coal_door","main_gate","labor_notice","stairs_up","other_life"]
static func home_access(s)->bool:
	return (not s.f("d6_returned") and not s.f("departure_committed") and not s.f("d6_wanted")) or (preload("res://scripts/d6_access.gd").public_entry(s) and s.f("departure_official") and s.f("d6_cargo_returned"))
static func decorate(v:Dictionary,s)->Dictionary:
	match v.id:
		"supply":
			v.options=v.options.filter(func(o):return o.key!="get_kit")
			v.options.push_front(s.opt("shop","看看柜台上的物资"))
			v.body="「醒了？今天的维生素留着呢，先领了。」\n柳德米拉翻开配给本。\n「明早要出去的人，装备到下面作业层的库里领。我这里卖吃的、药和零碎，也有一套可以另买的备用面具。随队领用的装备凭中尉签字去下层库里领。」"
			if s.f("vitamins_taken"):v.body="「今天的维生素领过了，别多吃。」\n柳德米拉把配给本合上一半。\n「要买东西就看柜台。制式弹抵账，土制的不收；随队领用的装备到下层库里办；另买备用面具可以问我。」"
		"lift":
			v.name="楼梯 / 通往作业层"
			v.body="楼梯间传来手推车的声响。下面是作业层，医务间、装备库和正门都在那里。扶手摸上去冰凉。"
			v.options=[s.opt("travel_down","下楼，前往作业层")]
		"stairs_up":
			v.name="楼梯 / 返回生活层"
			v.body="上方有食堂的热气和断断续续的说话声。顺着楼梯可以回生活层。"
			v.options=[s.opt("travel_up","返回生活层",home_access(s))]
		"armory":
			v.name="装备库 / 值班军需员";v.role="作业层 · 装备领用"
			v.body="「登记单给我。密封圈自己再试一遍，别等出了门才发现松了。」\n军需员把防毒面具和滤毒罐放在柜台后。\n「生活物资去上面的第七供应点，我这里不做买卖。」"
			v.options=[s.opt("get_kit","递上中尉签字的登记单，领取装备",s.has("order") and not s.f("kit")),s.opt("armory_check","「面具该怎么检查？」")]
			if s.f("kit"):v.body="「领用签过了？面具再试一遍。齐了就去正门，别把东西落在这里。」\n军需员把你的那一页夹回册子。"
		"main_gate":
			v.name="D-6 正门 / 当班卫兵";v.role="作业层 · 地铁轨道口"
			v.body="「外门锁着，别过黄线。」\n卫兵核对名册。厚钢门下的轨道一直通向站外，候车区里停着一辆电瓶轨道车。\n「随队出发的，先找中尉报到，再到装备库。人齐了才开门。」"
			v.options=[s.opt("leave_official","装备已经齐了，随队离站",s.f("accepted") and s.f("kit")),s.opt("gate_daily","「正门一直有人守吗？」")]
		"medical":
			v.name="医务间 / 值班台"
			v.body="白瓷盆里放着消毒过的镊子，帘子后有一张病床。值班表上写着：普通处置三发制式弹，药品另计。生活层供应点有密封药包。"
			v.options=[s.opt("clinic_treat","支付 3 发制式弹，清理伤口",s.economy.health<100 and s.economy.military>=3)]
		"coal_door":
			v.name="煤运检票口"
			v.body="铁门后传来绞车和煤斗的声音。工牌挂在钉子上，只有当班的人才能进去。\n牌子上写着：下井必须登记，禁止携带明火。"
			v.options=[s.opt("coal_ask","向守门人问问通往哪里")]
		"labor_notice":
			v.name="作业层值班板"
			v.body="生活层在楼上。医务间、装备库在北侧混凝土房。中尉在集合区核对名册；正门连接地铁轨道，由卫兵守备。煤运口只供当班作业。"
			v.options=[s.opt("read_labor","记下作业层的通路",not s.f("labor_read"))]
		"other_life":
			v.name="生活区通路 / 暂闭"
			v.body="门后还有其他生活区，走廊两侧亮着稀疏的灯。今天这道门暂时关闭，过不去。"
			v.options=[]
		"exit":
			v.name="东侧维修坡道 / 离开 D-6"
			v.body="坡道两侧围着旧木板和铁皮，下方是没有照明的废弃轨道区。冷风沿坡道灌上来。\n这条检修路没有卫兵登记。从这里走出去，就等于擅自离开 D-6。"
		"commander":
			v.body="「伊万，过来。老谢跟你说了吧？」\n科瓦廖夫把出发名册压在桌上。\n「净水设施停了，现有储水只够两周。我们明晨去东郊水处理厂，找档案里封存的净水部件。先把你想问的问清楚。」"
			if s.f("accepted"):v.body="「名已经报上了。」\n中尉看了看你。\n「装备去库里领；齐了就到正门等点名。还有事想问，现在就问。」"
	return v
static func handles(key:String)->bool:
	return key in ["shop","travel_down","travel_up","armory_check","gate_daily","clinic_treat","coal_ask","read_labor"]
static func act(key:String,s)->String:
	match key:
		"shop":return "「制式弹抵账，土制的不收。东西先看清楚，酒也能拿来卖。」"
		"travel_down","travel_up":return "你扶着栏杆，走过两段转折的楼梯。"
		"armory_check":return "「堵住滤罐接口，轻轻吸气。面罩能贴住脸，边上不进气才算密封。围巾压在外边，别夹进密封圈。」"
		"gate_daily":return "「上下班、煤车、补给，都得从登记簿上过。外门不是给谁随便推开的，里面还隔着一道气闸。」"
		"clinic_treat":
			s.economy.military-=3;s.economy.health=mini(100,s.economy.health+30)
			s.economy.ledger.append({"kind":"clinic","rounds":3})
			return "值班员替你清理伤处，换上干净敷料。\n「这几天别沾脏水。」"
		"coal_ask":return "「煤矿。到点了煤车上来，没工牌的人别往里钻。」\n守门人指了指通行牌，又低头去核对当班人数。"
		"read_labor":s.flags.labor_read=true;s.know("作业层北侧有医务间和装备库；正门接地铁轨道，煤运口不对外开放。")
	return "你把值班板上的通路记进日志。"
