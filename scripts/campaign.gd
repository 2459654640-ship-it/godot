extends RefCounted
## Authored continuation. Content is local JSON; no remote services or generated dialogue at runtime.
static var _data:Dictionary={}
const Living=preload("res://scripts/living_story.gd")
const Update=preload("res://scripts/chapter_update.gd")
const Journey=preload("res://scripts/journey_update.gd")
const NAMES={"waterworks":"东郊水处理厂","commune":"莫斯科公社","sech":"废土谢契","starcity":"星城-2","coal":"D-6 煤运休养区","surface":"地表旧泵站","railfront":"旧联络线换乘站"}
const ITEM_ART={"pool_sample":"mutant_sample","moro_card":"report","memory_card":"report","revolver":"revolver","water_core":"filter","relay_part":"fuse","anna_note":"report","transit_pass":"permit","archive":"map"}
static func data()->Dictionary:
	if _data.is_empty():
		_data=JSON.parse_string(FileAccess.get_file_as_string("res://data/campaign.json"))
		Update.extend(_data)
		Living.extend(_data)
		Journey.extend(_data)
	return _data
static func permits(s,req:Dictionary)->bool:
	if req.has("any") and not req.any.any(func(flag):return s.f(flag)):return false
	if req.has("not_all") and req.not_all.all(func(flag):return s.f(flag)):return false
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
	if not Journey.allowed(s,key):return false
	if key in data().get("unreleased_star_actions",[]):return false
	if not Living.allowed(s,key):return false
	if not Update.allowed(s,key):return false
	if key.begins_with("star_return_") and key!="star_return_"+String(s.flags.get("star_return_home","sech" if s.f("sech_member") else "commune")):return false
	if not data().actions.has(key):return false
	var a:Dictionary=data().actions[key]
	if s.Progression.failed_action(s,key):return false
	if a.has("offer_for") and not s.f(a.offer_for):
		if not permits(s,a.get("offer_unlock",{})):return false
		for busy in a.get("offer_busy",[]):
			if s.f(busy[0]) and not s.f(busy[1]):return false
	return not (a.get("once",true) and s.f("c_done_"+key)) and permits(s,a.get("req",{}))
static func quest_offered(s,q:Dictionary)->bool:
	for key in q.get("actions",[]):
		if data().actions[key].get("flags",{}).get(q.accepted,false) and available(s,key):return true
	return false
static func decorate(v:Dictionary,s)->Dictionary:
	if not data().interactions.has(v.id):return Journey.decorate(v,s)
	var d:Dictionary=data().interactions[v.id]
	v.name=d.name;v.role=d.role;v.body=d.body;v.options=[]
	for variant in d.get("after",[]):
		if permits(s,variant[0]) if variant[0] is Dictionary else s.f(variant[0]):v.body=variant[1]
	for key in d.options:
		var words:String=data().actions[key].text
		if key=="coal_return" and not s.f("brother_found"):words="沿原探访通路返回公社，稍后再来"

		v.options.append(s.opt("c_"+key,words,s.context.get("floor","")==d.facility and available(s,key)))
	return Journey.decorate(Living.decorate(Update.decorate(v,s),s),s)
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
	if key=="surface_accept" and not s.has("revolver"):s.give("revolver")
	if key=="surface_depart":
		var home:String=s.context.get("floor","commune")
		s.flags.surface_from_commune=home=="commune";s.flags.surface_from_sech=home=="sech";s.flags.surface_trip_active=true
		s.flags.surface_trip_id=int(s.flags.get("surface_trip_id",0))+1;s.flags.surface_loot={}
		if not s.f("surface_done"):s.flags.tracked_quest="surface_survey"
		for reset in ["battle_surface_yard","battle_surface_pool","surface_drain_open","surface_notes","c_done_surface_notes","c_done_surface_drain"]:s.flags.erase(reset)
		s.economy.stock.ammo_pouch=maxi(4,int(s.economy.stock.get("ammo_pouch",0)))
	if key=="star_perimeter_name":s.flags.signal_source_verified=true
	if key in ["commune_coal","workers_coal"]:s.flags.d6_returned=true;s.flags.departure_official=s.route=="official" and not s.f("sided_veteran")
	if key=="star_name":s.flags.signal_source_verified=true
	if key=="sech_water":s.flags.water_tank_fixed=true
	if key=="plant_leave":s.flags.filter_return_job=true
	if key=="plant_leave":s.Progression.fail(s,["waterworks"],"小队已带物资离开水厂，无法再返回处理。")
	if a.has("travel"):s.flags.next_sequence="coal_back" if key=="coal_return" and not s.f("brother_found") else a.travel
	if a.has("ending"):finish(s,a.ending)
	if a.get("reply","")!="":s.know(data().actions[key].text+"："+a.reply)
	var reply:String=a.get("reply","")
	Living.act(s,key)
	var updated=Update.act(s,key)
	if updated!="":reply=updated
	Journey.act(s,key)
	var receipts=[]
	for kind in reward:
		if int(reward[kind])>0:receipts.append(("制式子弹" if kind=="military" else "土制子弹")+" ×"+str(reward[kind]))
	for good in a.get("goods",{}):
		if int(a.goods[good])>0:receipts.append(s.Economy.GOODS[good].name+" ×"+str(a.goods[good]))
	if not receipts.is_empty():reply+="\n入袋："+"、".join(receipts)+"。"
	for book in preload("res://scripts/publications.gd").reward(s,key):
		reply+="\n"+book.get("reward_reply","对方又从自己的书里挑出一册，递给你：")+book.title+"。已收入手记的刊物收藏。"
	return reply

static func side_tasks(s)->Array:
	var rows=[]
	for q in data().get("quests",[]):
		if not s.f(q.accepted):continue
		var current:Dictionary=q.stages[0]
		for stage in q.stages:
			if permits(s,stage.when):current=stage
		var target:String=current.target
		if q.id=="north_late" and s.f("sech_member"):
			current=current.duplicate();current.place="sech";current.target="sech_leave" if s.f("north_inquiry_ready") else "sech_quartermaster";target=current.target
		if q.facility=="starcity":current={"target":"star_perimeter_call","place":"starcity","step":"暂缓：星城内区封闭，先保留已取得的记录。"};target="star_perimeter_call"
		if q.id=="surface_survey":
			current=current.duplicate()
			var home="sech" if s.f("surface_from_sech") else "commune"
			if s.context.get("floor","") in ["commune","sech"]:home=s.context.floor
			if s.context.get("floor","")=="surface" and s.f("surface_sample_sealed"):
				current.target="surface_exit";current.place="surface";current.step="样本已经封存。回西南侧检修梯，沿来路返回"+("谢契" if home=="sech" else "公社")+"交付。"
			elif s.context.get("floor","")!="surface":
				current.target="sech_quartermaster" if home=="sech" else "commune_guard";current.place=home
				current.step="将封存样本和记录交给派工人。" if s.f("surface_sample_sealed") else "在聚落守备处备好面具、滤毒罐与武器，再出发前往地表旧泵站。"
			target=current.target
		current=Living.task_stage(s,q,current)
		target=current.target
		var area:String=data().interactions.get(target,{}).get("name",{"semyon":"谢苗诺夫的房间","medical":"作业层医务间","armory":"作业层装备库"}.get(target,target))
		rows.append({"kind":q.get("kind","支线"),"id":q.id,"name":q.name,"done":s.f(q.done),"place":current.get("place",q.facility),"background":q.background,"step":"已交付，报酬与经过记入手记。" if s.f(q.done) else current.step,"target":target,"area":area})
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
	var duty=Journey.objective(s)
	if duty!="":return duty
	var living=Living.objective(s)
	if living!="":return living
	var updated=Update.objective(s)
	if updated!="" and not s.ending:return updated
	if s.ending:return data().endings.get(s.flags.get("campaign_ending",""),{}).get("title","这段旅程已记入手记")
	match s.context.get("floor",""):
		"waterworks":
			if s.f("water_secured"):return "两箱净水滤芯已装稳 · 到东南厂区铁门集合"
			if s.f("plant_power"):return "仓门回路已供电 · 打开封存仓库"
			if s.f("plant_bled") and s.f("plant_fuse"):return "把备用件装入送电柜，恢复仓门回路"
			if s.f("plant_diagram"):return "按值班图卸压，并到修配台取备用件"
			return "查阅水厂值班图，再检查泵房"
		"commune":
			if s.f("brother_found") and not s.f("anna_first_news"):return "回医务室，把核实结果交给安娜"
			if s.f("anna_records") and not s.f("brother_found"):return "到联络气闸，持探访函返回 D-6"
			if s.f("anna_request") and not s.f("anna_records"):return "到联络室核对安娜哥哥的班组记录"
			return "与公社居民交谈 · 选择留在这里或继续旅程"
		"sech":
			if s.f("radio_fixed"):return "东方-7 已辨认 · 可尝试前往星城外围留信"
			if s.f("radio_power"):return "按纸条刻度调谐电台，辨认呼号"
			return "查阅调度台接线图，恢复短波电台"
		"coal":
			if s.f("brother_found"):return "带着探视回执返回公社"
			if s.f("brother_care"):return "到休养间，征询本人的探视意愿"
			if s.f("brother_identity"):return "找医护了解照护与探视安排"
			return "先到登记台核对工牌，再查班组档案"
		"starcity":return "星城内区封闭 · 在外侧声讯柱留下询问信，然后返回聚落"
		"surface":
			if s.f("surface_done"):return "地表巡查 · 可以清理兽群、收集资源，随时从检修梯撤回"
			if s.f("surface_sample_sealed"):return "样本已经封好 · 可从西南侧检修梯撤回交付"
			if s.f("surface_drain_open"):return "清理下池威胁 · 到北侧沉淀池取样"
			if s.f("surface_notes"):return "清理院内兽群 · 再转动西侧泄水阀"
			return "先检查背风装卸台的补给，再到西侧控制箱读排水记录"
	return ""
static func tasks(s)->Array:
	var rows=[]
	var quests=[
		["plant_briefed","water_secured","给 D-6 的滤芯","按值班图处理旁通、供电与仓库压力锁，核对封存滤芯。"],
		["commune_joined","greenhouse_fixed","温室的回水","先检查并停泵清理过滤篮，再灌满管线重新启动。"],
		["anna_request","anna_reunited","一个确切的名字","核对公社记录，持函去 D-6 煤运登记处，确认身份和照护安排后回报安娜。"],
		["sech_joined","radio_fixed","东方-7","先查接线图，再恢复电源并调谐电台。"],
		["star_inquiry_filed","unused_father_done","隔离线外的询问信","已留下寻找父亲的询问，尚无人员核查结果；内区封闭，可以先返回聚落。"]]
	for q in quests:
		if s.f(q[0]):rows.append({"name":q[2],"done":s.f(q[1]),"background":q[3],"step":objective(s)})
	return rows
