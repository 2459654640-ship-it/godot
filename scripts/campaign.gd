extends RefCounted
## Authored continuation. Content is local JSON; no remote services or generated dialogue at runtime.
static var _data:Dictionary={}
const NAMES={"waterworks":"东郊水处理厂","commune":"莫斯科公社","sech":"废土谢契","starcity":"星城-2","coal":"D-6 煤运休养区"}
const ITEM_ART={"water_core":"filter","relay_part":"fuse","anna_note":"report","transit_pass":"permit","archive":"map"}
static func data()->Dictionary:
	if _data.is_empty():_data=JSON.parse_string(FileAccess.get_file_as_string("res://data/campaign.json"))
	return _data
static func permits(s,req:Dictionary)->bool:
	if req.has("any") and not req.any.any(func(flag):return s.f(flag)):return false
	if req.has("floor") and s.context.get("floor","") not in req.floor:return false
	for flag in req.get("all",[]):
		if not s.f(flag):return false
	for flag in req.get("not",[]):
		if s.f(flag):return false
	for item in req.get("items",[]):
		if not s.has(item):return false
	for good in req.get("goods",{}):
		if int(s.economy.goods.get(good,0))<int(req.goods[good]):return false
	return true
static func available(s,key:String)->bool:
	if not data().actions.has(key):return false
	var a:Dictionary=data().actions[key]
	if s.Progression.failed_action(s,key):return false
	return not (a.get("once",true) and s.f("c_done_"+key)) and permits(s,a.get("req",{}))
static func decorate(v:Dictionary,s)->Dictionary:
	if not data().interactions.has(v.id):return v
	var d:Dictionary=data().interactions[v.id]
	v.name=d.name;v.role=d.role;v.body=d.body;v.options=[]
	for variant in d.get("after",[]):
		if permits(s,variant[0]) if variant[0] is Dictionary else s.f(variant[0]):v.body=variant[1]
	for key in d.options:
		var words:String=data().actions[key].text
		if key=="coal_return" and not s.f("brother_found"):words="沿原探访通路返回公社，稍后再来"
		if key=="commune_route" and not s.has("frequency"):words="「北线能联系到什么地方？」"
		v.options.append(s.opt("c_"+key,words,s.context.get("floor","")==d.facility and available(s,key)))
	return v
static func act(s,key:String)->String:
	var a:Dictionary=data().actions[key]
	if not available(s,key):return "这件事已经做过，或还没有准备好。"
	if a.get("once",true):s.flags["c_done_"+key]=true
	for flag in a.get("flags",{}):s.flags[flag]=a.flags[flag]
	for item in a.get("give",[]):s.give(item)
	for item in a.get("take",[]):s.take(item)
	for good in a.get("goods",{}):
		s.economy.goods[good]=int(s.economy.goods.get(good,0))+int(a.goods[good])
		if s.economy.goods[good]<=0:s.economy.goods.erase(good)
	var reward:Dictionary=a.get("reward",{})
	for kind in ["military","handmade"]:
		var count=maxi(0,int(reward.get(kind,0)))
		if count>0:
			s.economy[kind]+=count
			s.economy.ledger.append({"kind":"quest","id":key,"ammo":kind,"rounds":count})
	if key=="plant_leave":s.Progression.fail(s,["waterworks"],"小队已带物资离开水厂，无法再返回处理。")
	if a.has("travel"):s.flags.next_sequence="coal_back" if key=="coal_return" and not s.f("brother_found") else a.travel
	if a.has("ending"):finish(s,a.ending)
	if a.get("reply","")!="":s.know(data().actions[key].text+"："+a.reply)
	var reply:String=a.get("reply","")
	var receipts=[]
	for kind in reward:
		if int(reward[kind])>0:receipts.append(("制式子弹" if kind=="military" else "土制子弹")+" ×"+str(reward[kind]))
	for good in a.get("goods",{}):
		if int(a.goods[good])>0:receipts.append(s.Economy.GOODS[good].name+" ×"+str(a.goods[good]))
	if not receipts.is_empty():reply+="\n入袋："+"、".join(receipts)+"。"
	return reply

static func side_tasks(s)->Array:
	var rows=[]
	for q in data().get("quests",[]):
		if not s.f(q.accepted):continue
		var current:Dictionary=q.stages[0]
		for stage in q.stages:
			if permits(s,stage.when):current=stage
		var target:String=current.target
		rows.append({"kind":q.get("kind","支线"),"id":q.id,"name":q.name,"done":s.f(q.done),"place":current.get("place",q.facility),"background":q.background,"step":"已交付，报酬与经过记入手记。" if s.f(q.done) else current.step,"target":target,"area":data().interactions[target].name})
	return rows
static func finish(s,id:String):
	s.Progression.fail(s,[],"旅程已经收束，这项委托未能完成。")
	s.flags.campaign_ending=id
	s.flags.chapter_endpoint="ending:"+id
	s.ending=true
	var unlocked:Array=s.flags.get("endings_seen",[])
	if id not in unlocked:unlocked.append(id)
	s.flags.endings_seen=unlocked
static func objective(s)->String:
	if s.ending:return data().endings.get(s.flags.get("campaign_ending",""),{}).get("title","这段旅程已记入手记")
	match s.context.get("floor",""):
		"waterworks":
			if s.f("water_secured"):return "两箱净水滤芯已装稳 · 到东南厂区铁门集合"
			if s.f("plant_power"):return "压力恢复 · 打开封存仓库"
			if s.f("plant_bled") and s.f("plant_fuse"):return "把备用件装入送电柜，恢复仓门回路"
			if s.f("plant_diagram"):return "按值班图卸压，并到修配台取备用件"
			return "查阅水厂值班图，再检查泵房"
		"commune":
			if s.f("brother_found") and not s.f("anna_reunited"):return "回医务室，把核实结果交给安娜"
			if s.f("anna_records") and not s.f("brother_found"):return "到联络气闸，持探访函返回 D-6"
			if s.f("anna_request") and not s.f("anna_records"):return "到联络室核对安娜哥哥的班组记录"
			return "与公社居民交谈 · 选择留在这里或继续旅程"
		"sech":
			if s.f("radio_fixed"):return "东方-7 已接通 · 决定留下或前往星城"
			if s.f("radio_power"):return "按纸条刻度调谐电台，辨认呼号"
			return "查阅调度台接线图，恢复短波电台"
		"coal":
			if s.f("brother_found"):return "带着探视回执返回公社"
			if s.f("brother_care"):return "到休养间，征询本人的探视意愿"
			if s.f("brother_identity"):return "找医护了解照护与探视安排"
			return "先到登记台核对工牌，再查班组档案"
		"starcity":
			if s.f("father_met"):return "把想问的话问完，再到联络值班台决定去留"
			if s.f("star_access"):return "蓝门已开 · 去测控室见父亲"
			if s.f("star_zero"):return "确认身份后，到内门台合上旁路"
			return "向哨兵报姓名 · 按规程隔离外线"
	return ""
static func tasks(s)->Array:
	var rows=[]
	var quests=[
		["plant_briefed","water_secured","给 D-6 的水","按值班图处理旁通、供电与仓库压力锁，核对封存滤芯。"],
		["commune_joined","greenhouse_fixed","温室的回水","先检查并停泵清理过滤篮，再灌满管线重新启动。"],
		["anna_request","anna_reunited","一个确切的名字","核对公社记录，持函去 D-6 煤运登记处，确认身份和照护安排后回报安娜。"],
		["sech_joined","radio_fixed","东方-7","先查接线图，再恢复电源并调谐电台。"],
		["star_registered","father_met","蓝门后的人","按纸质规程隔离外线、确认无压、合旁路；然后去测控室。"]]
	for q in quests:
		if s.f(q[0]):rows.append({"name":q[2],"done":s.f(q[1]),"background":q[3],"step":objective(s)})
	return rows
