extends RefCounted
## First traversable district. Persistent state belongs to Story; no wall-clock respawns.
static var _layout:Dictionary={}
static var _content:Dictionary={}
const FLOOR="east_district"
const HOMES=["commune","sech","labor"]
static func layout()->Dictionary:
	if _layout.is_empty():_layout=JSON.parse_string(FileAccess.get_file_as_string("res://data/east_district_layout.json"))
	return _layout
static func data()->Dictionary:
	if _content.is_empty():_content=JSON.parse_string(FileAccess.get_file_as_string("res://data/east_district.json"))
	return _content
static func extend(c:Dictionary):
	for section in ["actions","interactions","panels"]:c[section].merge(data()[section].duplicate(true),true)
	c.quests.append_array(data().quests.duplicate(true))
	var city:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/city_exploration.json"))
	for section in ["actions","interactions","panels"]:c[section].merge(city[section],true)
	c.quests.append_array(city.quests)
	for home in HOMES:
		var target={"commune":"commune_leave","sech":"sech_leave","labor":"d6_return_desk"}[home]
		c.interactions[target].options.append("east_depart_"+home)
	c.interactions.d6_surface_gate={"facility":"labor","name":"D-6 正门 / 出站登记","role":"D-6 / 地表联络线","spoken":false,"body":"正门连接通往地表的联络线。值守先核对本人的返站与外勤记录，再准许登上工业区的地表支路。煤矿准入另在煤运口办理。","options":["east_depart_labor"]}
	c.interactions.plant_exit.options.append("east_exit_factory")
	c.interactions.commune_printer.options.append("east_mine_contact")
	c.interactions.commune_records.options.append("east_mine_prepare")
	c.actions.surface_depart.text="备好装备，出站寻找旧泵站的地表入口。"
	c.actions.d6_patrol_depart.text="登记外勤，沿地表旧货运路前往泵站。"
static func private_mine(s)->bool:
	return s.f("east_mine_prepared") and s.f("east_private_mine_entry")
static func can_enter_home(s,home:String)->bool:
	if home=="labor":return s.Campaign.Access.public_entry(s)
	if home==String(s.flags.get("east_home","")):return true
	# Crossing to the other community preserves the existing explicit contact cost.
	return s.f("cross_contact_ready")
static func allowed(s,key:String)->bool:
	if key=="east_open_cache":return s.context.get("camp_loot_safe",false)
	if key.begins_with("east_depart_"):
		var home=key.trim_prefix("east_depart_")
		if home=="labor":return s.Campaign.Access.public_entry(s) and s.f("d6_cargo_returned")
	if key in ["east_enter_commune","east_enter_sech","east_enter_labor"]:return can_enter_home(s,key.trim_prefix("east_enter_"))
	if key=="east_enter_railfront":return s.Campaign.Update.mission(s)!=""
	if key=="east_manual_release":return s.context.get("east_side",false) and not s.f("east_crossing_open")
	if key=="east_power_restore":return not s.f("east_power_restored")
	if key=="east_mine_contact":return not s.Campaign.Access.public_entry(s)
	if key=="east_mine_prepare":return not s.f("east_mine_prepared")
	return true
static func depart(s,home:String):
	preload("res://scripts/raid_loot.gd").begin(s,home)
	s.flags.east_trip_active=true;s.flags.east_home=home;s.flags.east_arrival=home
	s.flags.next_sequence="east_depart_"+home
static func act(s,key:String):
	if key.begins_with("east_depart_"):depart(s,key.trim_prefix("east_depart_"))
	if key=="surface_depart":depart(s,"sech" if s.f("surface_from_sech") else "commune")
	if key=="d6_patrol_depart":depart(s,"labor")
	if key in ["commune_star","sech_star"]:
		depart(s,"commune" if key=="commune_star" else "sech");s.flags.star_return_home=s.flags.east_home
	if key.begins_with("east_enter_"):
		var destination=key.trim_prefix("east_enter_")
		if destination in ["commune","sech"] and destination!=s.flags.get("east_home",""):
			s.flags.cross_contact_ready=false;s.flags.cross_contact_trips=int(s.flags.get("cross_contact_trips",0))+1
		if destination=="surface" and s.f("surface_job") and not s.f("surface_done"):s.flags.tracked_quest="surface_survey"
	if key in ["surface_back_commune","surface_back_sech","surface_back_d6"] and s.f("east_trip_active"):
		s.flags.east_arrival="surface";s.flags.next_sequence="east_return_surface"
	if key in ["star_return_commune","star_return_sech"] and s.f("east_trip_active"):
		s.flags.east_arrival="starcity";s.flags.next_sequence="east_return_starcity"
	if key=="east_exit_factory":s.flags.east_arrival="waterworks"
	if key in ["coal_return","workers_return"] and private_mine(s):
		s.flags.east_arrival="coal";s.flags.next_sequence="east_return_coal"
	if key=="east_enter_mine":s.flags.east_arrival="coal"
	if key=="east_mine_contact":s.flags.tracked_quest="east_mine_route"
	if key in ["east_read_routes","east_power_inspect"]:s.flags.tracked_quest="east_power"
static func decorate(v:Dictionary,s)->Dictionary:
	if v.id=="city_radio_panel" and s.f("city_radio_isolated") and not s.f("east_power_restored"):
		v.body="室外天线已经隔离，但机架没有电。先沿工人街去变配电所检查检修柜；烧坏的保护组件存放在工人街西侧的交通维修间。修好供电后，再回来接通低压电源，播放本地录音。"
	if v.id=="coal_clerk" and private_mine(s):
		v.name="瓦西里 / 煤运班副主管";v.role="矿区内部接应"
		v.body="瓦西里将办公室的门带上，先让你坐下。\n「你的来意，联络员说过了。班组和伤病记录由我经手，先把编号核对。医护怎么安排、本人愿不愿意见家属，还要分别问清。」\n「外面的追查没有撤，别从矿口往作业层走。办完到内部出口等我，咱们仍从检修支巷出去。」"
	if v.id=="coal_exit" and private_mine(s):
		v.name="矿区内部 / 撤离会合点";v.body="这里是与瓦西里约定的内部会合点。接应会带你沿封停检修支巷返回地表，不经过 D-6 正门或作业层。"
	if v.id=="commune_leave" and s.f("east_mine_prepared"):
		v.body+="\n矿区的私人接应已确认。先从支线登上地表，再沿厂区东侧检修巷到封停入口，不能去 D-6 正门。"
	if v.id=="east_gate" and s.f("east_crossing_open"):v.body="横穿门已经退到围栏旁，旧货运路可以通过。铁轨保留在专用带内，通行处没有堆放货物。"
	if v.id=="east_relay" and s.f("east_power_restored"):v.body="检修柜读数稳定。门机、路口指示灯与修配间已经通电，换下的旧组件留在标记过的废件盒里。"
	if v.id=="east_camp_cache" and s.f("grey_camp_cleared"):v.body="院内的守卫已被击倒，棚屋里仍有未冷的炉子和整理过的床铺。门旁的运输箱可以打开检查。"
	if v.id in ["east_commune_entry","east_sech_entry"] and not can_enter_home(s,"commune" if v.id=="east_commune_entry" else "sech"):
		v.body+="\n这不是你的本次出发聚落。先通过已认识的联络人落实访问安排，再来走这条线路；找到入口不等于取得通行。"
	if v.id=="east_d6_entry" and not s.Campaign.Access.public_entry(s):v.body+="\n你的现有身份不能公开返站。不要递交姓名；矿区内部接应是另一条路。"
	return v
static func task_stage(s,q:Dictionary,current:Dictionary)->Dictionary:
	var floor:String=s.context.get("floor","")
	# The radio's authored stages are shared by its journal and map target.
	if q.id=="d6_first_duty" and (not s.f("d6_patrol_active") or s.f("d6_patrol_done")):return current
	if floor==FLOOR and q.id in ["surface_survey","d6_first_duty"]:
		return {"target":"east_pump_entry","place":FLOOR,"step":"沿旧货运路到铁路西侧的泵站支路，找到检修井再进入旧泵站。"} if not s.has("pool_sample") else {"target":"east_d6_entry" if s.f("surface_from_d6") else ("east_sech_entry" if s.flags.get("east_home","")=="sech" else "east_commune_entry"),"place":FLOOR,"step":"样本已经封好。沿地图上的本次出发支线返回，向派工人交付。"}
	if floor==FLOOR and q.id=="east_power" and not s.f("east_crossing_open") and s.context.get("east_side",false):
		return {"target":"east_gate_east","place":FLOOR,"step":"先用货场门东侧应急柄脱开门机，步行到西侧核对供电备件。"}
	if q.id in ["workers_network","commune_chapter"] and s.f("workers_draft") and not s.f("workers_signed") and s.f("east_mine_prepared") and floor!="coal":
		return {"target":"east_mine_entry" if floor==FLOOR else "commune_leave","place":FLOOR if floor==FLOOR else "commune","step":"私人接应已经确认。登上地表，沿厂区东侧检修巷进入煤运区；征询原稿留在公社，工人是否回话由本人决定。"}
	return current
static func sync(w):
	if w.floor_id!=FLOOR:return
	var gate=w.get_node_or_null("BasinInspectionGate")
	if is_instance_valid(gate) and gate.get_meta("opened",false)!=w.story.f("city_basin_open"):
		var opened=w.story.f("city_basin_open");gate.set_meta("opened",opened)
		var destination=Vector3(74,1,-61 if opened else -57)
		if not w.initialized:gate.position=destination
		else:
			var motion=w.create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS);motion.tween_property(gate,"position",destination,1.1).set_trans(Tween.TRANS_SINE);motion.finished.connect(func():if is_instance_valid(w.navigation):w.navigation.setup(w))
	var powered=w.story.f("east_power_restored")
	for name in ["EastCrossingLamp","EastWorkshopLamp"]:
		var lamp=w.get_node_or_null(name)
		if is_instance_valid(lamp):lamp.visible=powered
	for head in w.get_tree().get_nodes_in_group("east_power_signals"):
		if w.is_ancestor_of(head):head.material_override=w.kit.mats.green if powered else w.kit.mats.red
static func spawn(s,previous_floor:String)->Vector3:
	var source:String=s.flags.get("east_arrival",previous_floor)
	var alias={"labor":"east_d6_entry","commune":"east_commune_entry","sech":"east_sech_entry","surface":"east_pump_entry","waterworks":"east_waterworks_entry","coal":"east_mine_entry","starcity":"east_north_entry","railfront":"east_transfer_entry"}
	for entrance in layout().entrances:
		if entrance.id==alias.get(source,""):
			var p=entrance.arrival;return Vector3(p[0],.04,p[1])
	return Vector3(-64,.04,46)
static func encounters(s)->Dictionary:
	var sites={"east_road":{"rect":Rect2(-47,-5,14,13),"need":"east_region_ready","skip":"unused_east_skip","name":"货运路旁的游荡兽群","spawns":[Vector3(-43,.04,0),Vector3(-36,.04,2)]},"grey_camp":{"rect":Rect2(30,-29,27,27),"need":"unused_manual_camp_trigger","skip":"unused_east_skip","name":"灰狗营地","spawns":[]}}
	sites.city_basin={"rect":Rect2(76,-75,30,28),"need":"city_basin_open","skip":"unused_city_skip","name":"蓄水池巨兽","enemy_kind":"behemoth","spawns":[Vector3(96,.04,-64)]}
	sites.city_radio_nest={"rect":Rect2(-43,-77,26,24),"need":"east_region_ready","skip":"unused_city_skip","name":"民防站周围的兽群","spawns":[Vector3(-35,.04,-53),Vector3(-23,.04,-54),Vector3(-40,.04,-68)]}
	sites.east_road.spawns.append_array([Vector3(-40,.04,7),Vector3(-35,.04,9)])
	sites.city_radio_nest.spawns.append(Vector3(-41,.04,-58))
	var batch:Dictionary=s.flags.get("east_spawn_batches",{})
	for id in sites:
		var rng=RandomNumberGenerator.new();rng.seed=hash(str(s.flags.get("social_seed",0))+id+str(batch.get(id,0)))
		# Select among deliberately clear positions; never spawn inside arbitrary geometry.
		for i in range(sites[id].spawns.size()-1,0,-1):
			var j=rng.randi_range(0,i);var p:Vector3=sites[id].spawns[i];sites[id].spawns[i]=sites[id].spawns[j];sites[id].spawns[j]=p
		if id=="east_road":sites[id].spawns.resize(2)
		if id=="city_radio_nest":sites[id].spawns.resize(3)
	return sites
static func prepare(w):
	if w.floor_id!=FLOOR:return
	w.story.flags.east_region_ready=true
	# Only a journey from another scene can start a new population batch.
	if w.arrival_data.get("floor",FLOOR)==FLOOR:return
	var times:Dictionary=w.story.flags.get("east_cleared_at",{})
	var batches:Dictionary=w.story.flags.get("east_spawn_batches",{}).duplicate(true)
	for id in times:
		if id not in ["east_road","city_radio_nest"]:continue
		if w.played_seconds-float(times[id])>=900 and w.story.f("battle_"+id):
			w.story.flags.erase("battle_"+id);batches[id]=int(batches.get(id,0))+1
	w.story.flags.east_spawn_batches=batches
static func cleared(w,id:String):
	if id=="city_basin" and not w.story.f("city_basin_rewarded"):
		w.story.flags.city_basin_rewarded=true;w.story.economy.goods.mutant_sample=int(w.story.economy.goods.get("mutant_sample",0))+3
		w.story.economy.military+=18;w.hud.toast("蓄水池已清理 · 获得封存样本 ×3、巡检箱中的制式弹 ×18。",7)
	var times:Dictionary=w.story.flags.get("east_cleared_at",{}).duplicate(true);times[id]=w.played_seconds;w.story.flags.east_cleared_at=times
static func can_retreat(w,id:String)->bool:
	if w.floor_id!=FLOOR:return false
	if not layout().entrances.any(func(e):return e.id==id):return false
	return w.combat.enemies.all(func(e):return not is_instance_valid(e) or e.position.distance_to(w.player.position)>6)
static func safe_interaction(w,id:String)->bool:
	if id in ["grey_shelter_entry","grey_shelter_exit"] or id.begins_with("raid_container_"):return preload("res://scripts/raid_loot.gd").safe(w)
	return w.floor_id==FLOOR and id=="east_camp_cache" and is_instance_valid(w.grey_camp) and w.grey_camp.can_loot()
static func remember_combat(w):
	if w.floor_id!=FLOOR or not w.combat.active:return
	var packet:Dictionary=w.combat.serialize_state()
	# Preserve the original quiet checkpoint across an indoor retreat without
	# nesting an older retreat packet inside the next checkpoint indefinitely.
	var before:Dictionary=packet.get("checkpoint",{}).duplicate(true)
	if not before.is_empty():
		before.flags.erase("east_retreat_encounter");before.combat_state={}
	packet.checkpoint=before;w.story.flags.east_retreat_encounter=packet
static func restore_combat(w):
	if w.floor_id!=FLOOR or w.combat.active:return
	var packet:Dictionary=w.story.flags.get("east_retreat_encounter",{}).duplicate(true)
	w.story.flags.erase("east_retreat_encounter")
	if packet.is_empty():return
	w.combat.restore_state(packet)
	if w.combat.checkpoint.is_empty():
		var checkpoint:Dictionary=w.save_snapshot().duplicate(true);checkpoint.combat_state={};w.combat.checkpoint=checkpoint
static func drop(w,enemy):
	if enemy.enemy_kind=="greyhound":preload("res://scripts/raid_loot.gd").corpse(w,enemy);return
	var batch=int(w.story.flags.get("east_spawn_batches",{}).get(w.combat.encounter,0))
	var source:String=enemy.get_meta("loot_key","")
	if source=="":return
	var key:String=source+"_b"+str(batch)
	var records:Dictionary=w.story.flags.get("east_loot",{}).duplicate(true)
	if key=="" or records.has(key):return
	var p:Vector3=enemy.position;var good="mutant_sample" if enemy.enemy_kind=="spitter" else "mutant_bone"
	if enemy.enemy_kind=="greyhound":good="bandage" if int(enemy.get_meta("loot_index",0))%2==0 else "ammo_pouch"
	records[key]={"position":[p.x,.04,p.z],"good":good,"taken":false};w.story.flags.east_loot=records;build_drop(w,key,records[key])
static func build_drop(w,key:String,entry:Dictionary):
	if entry.taken:return
	var p=Vector3(entry.position[0],.04,entry.position[2]);var id="east_loot_"+key
	var root=Node3D.new();root.name=id;root.position=p;w.add_child(root)
	w.kit.box("BaggedFind",Vector3(0,.12,0),Vector3(.25,.20,.20),"cloth",false,root)
	w.target(id,p,"可收集的"+w.story.Economy.GOODS[entry.good].name,"collect")
static func restore_loot(w):
	for key in w.story.flags.get("east_loot",{}):build_drop(w,key,w.story.flags.east_loot[key])
static func collect(w,id:String):
	var key=id.trim_prefix("east_loot_");var records:Dictionary=w.story.flags.get("east_loot",{})
	if not records.has(key) or records[key].taken or not w.targets.has(id):return
	if w.player.position.distance_to(w.targets[id].pos)>1.9:return
	var good:String=records[key].good
	if not preload("res://scripts/backpack.gd").can_add(w.story,good):w.hud.toast("背包已满，先整理或放下物资。");return
	records[key].taken=true
	w.story.economy.goods[good]=int(w.story.economy.goods.get(good,0))+1
	var node=w.get_node_or_null(id)
	if node:node.queue_free()
	for marker in [w.targets[id].ring,w.targets[id].marker]:
		if is_instance_valid(marker):marker.queue_free()
	w.targets.erase(id);w.story.changed.emit();w.hud.toast("获得："+w.story.Economy.GOODS[good].name+" ×1",4);w.autosave()
