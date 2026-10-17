extends RefCounted
static func tasks(s)->Array:
	var rows=[]
	rows.append({"name":"今天的维生素 D","done":s.f("vitamins_taken"),"background":"地下没有阳光，维生素按人配给。老爹嘱咐先到第七供应点领取今天的一份，再去报到。","step":"找生活层的柳德米拉。"})
	rows.append({"name":"征召报到","done":s.f("accepted"),"background":"净水设施停运，储水只够约两周。你的名字在明晨出发的小队名单上。","step":"到作业层集合区找科瓦廖夫中尉，问清任务。"})
	if s.f("accepted"):rows.append({"name":"出发准备","done":s.f("kit"),"background":"中尉签了登记单。防毒面具与滤毒罐由装备库发放。","step":"去作业层装备库，再到正门候车区。"})
	if s.f("nina_job"):rows.append({"name":"东段压力监测","done":s.f("relay"),"background":"妮娜负责的监测箱烧坏了保险芯，机械表还在工作。维修回路已经断电。","step":"按妮娜交代，到洗漱区断电柜找 2A 备用件，修好后回去。"})
	if s.f("cook_job"):rows.append({"name":"厨房漏水","done":s.f("valve"),"background":"加琳娜已经接了一夜漏水。紧一紧回水接头，就能替厨房省下些水。","step":"借合适工具处理接头，再让加琳娜确认。"})
	if s.f("heat_job"):rows.append({"name":"西翼暖气","done":s.f("heating_fixed"),"background":"西翼家属房的暖气上凉下热，管里积了气，夜班住户睡不好。","step":"借扳手，去洗衣间拿公用干布，小心排气；修好找帕维尔。"})
	if s.f("shift"):rows.append({"name":"换班时的侧门","done":s.f("side_crossed"),"background":"米哈伊尔告诉你，黄灯亮起时岗哨会去查压力表。","step":"对照已拿到的草图，实地确认侧门和黄灯。"})
	if s.has("photo") or s.f("father"):rows.append({"name":"旧照片","done":s.f("father"),"background":"旧木箱里的合影拍下了你不记得的日子。老爹和父亲曾是战友。","step":"找个合适的时候，把照片给老爹看看。"})
	return rows
static func encyclopedia(s)->Array:
	var rows=[
["D-6 与地下生活","1962 年战争后，幸存者进入地下。二十年里，D-6 的生活、维修、作业和守备各有区域；你熟悉的生活层只是其中一片。"],
["配给与维生素 D","生活层第七供应点按名单发放每日维生素。地下难见阳光，配给对居民很重要。"],
["两种子弹","制式弹规格稳定、可靠，也用于交易。土制弹只能留作弹药，不能抵账；制式弹的威力也更高。"]]
	if s.f("labor_read"):rows.append(["作业层","工人按班轮换，煤运口需要工牌。正门连接地铁轨道；医务间和装备库位于北侧服务区。"])
	if s.has("frequency"):rows.append(["东方-7","收音机里短暂听到的呼号。来源与含义都还没有确认。"])
	if s.f("heating_fixed"):rows.append(["暖气积气","暖气片上凉下热，可能积了气。用布接住阀口的热水，缓慢排气，不把阀芯整颗拧下。"])
	return rows
