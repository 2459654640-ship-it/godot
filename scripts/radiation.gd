extends RefCounted
## Reversible exposure effects. Never deals passive damage or blocks movement.
const TIERS=[
	{"min":0,"name":"无明显反应","interval":90.0,"food":40,"medicine":1.0,"detail":"正常自然恢复；饱食达到 40 时，每活动 90 秒恢复 1 点生命。"},
	{"min":20,"name":"轻度反应","interval":180.0,"food":40,"medicine":1.0,"detail":"自然恢复速度减半：饱食达到 40 时，每活动 180 秒恢复 1 点生命。"},
	{"min":40,"name":"中度反应","interval":270.0,"food":55,"medicine":1.0,"detail":"饱食须达到 55 才能自然恢复，每活动 270 秒恢复 1 点生命。"},
	{"min":60,"name":"重度反应","interval":0.0,"food":55,"medicine":1.0,"detail":"暂停自然恢复；绷带、急救包和医务治疗仍正常生效。"},
	{"min":80,"name":"严重反应","interval":0.0,"food":55,"medicine":0.75,"detail":"暂停自然恢复；绷带和急救包恢复量降至 75%。医务治疗不减效。"}
]
const CLINICS={"medical":"labor","coal_medic":"coal","commune_anna":"commune","commune_leader":"commune","sech_quartermaster":"sech"}
static func index(value:int)->int:return clampi(value/20,0,4)
static func state(s)->Dictionary:return TIERS[index(int(s.economy.radiation))]
static func heal_amount(s,amount:int)->int:return maxi(1,floori(amount*float(state(s).medicine)))
static func describe(s)->String:return "辐射 %d / 100 · %s\n%s\n抗辐射药降低 20 点；聚落医护可免费安排污染处置，每次降低 30 点。不会直接掉血或降低移动速度。"%[s.economy.radiation,state(s).name,state(s).detail]
static func decorate(v:Dictionary,s)->Dictionary:
	if CLINICS.get(v.id,"")==s.context.get("floor","?") and int(s.economy.radiation)>0 and not (v.id=="commune_anna" and s.f("anna_dead")):
		v.options.append(s.opt("decontam_"+v.id,"请医护安排污染处置（免费，辐射降低 30）"))
	return v
static func treat(s)->String:
	var before=int(s.economy.radiation);s.economy.radiation=maxi(0,before-30);s.economy.recovery_clock=0.0
	return "医护安排你脱下外衣，清理附着的污染物，检查伤口并记录情况。\n本次处置不收费，辐射降低 %d 点。当前：%s。仍有污染时可以继续接受处置。"%[before-int(s.economy.radiation),state(s).name]
