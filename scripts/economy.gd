extends RefCounted
## Standard ammunition is money; handmade ammunition is a separate reserve.
const GOODS={
"bread":{"name":"黑面包","price":4,"stock":8,"icon":"bread","detail":"一份当天的黑面包。恢复 30 点饱食。","effect":"food","amount":30},
"bandage":{"name":"洁净绷带","price":5,"stock":5,"icon":"bandage","detail":"洗净煮过的布与包扎材料。恢复 15 点生命。","effect":"health","amount":15},
"medkit":{"name":"急救包","price":12,"stock":2,"icon":"medkit","detail":"密封药品和敷料。恢复 40 点生命。","effect":"health","amount":40},
"antirad":{"name":"抗辐射药","price":10,"stock":2,"icon":"antirad","detail":"减少 20 点已受辐射。辐射达到 20 后，自行恢复会变慢；面具无法阻挡全部外照射。","effect":"radiation","amount":20},
"battery":{"name":"干电池","price":7,"stock":3,"icon":"battery","detail":"防潮包内的电池，留给照明和小型设备使用。","effect":"","amount":0},
"cord":{"name":"细绳与布胶带","price":3,"stock":4,"icon":"cord","detail":"捆扎行李、固定松动物件的常用耗材。","effect":"","amount":0}}
const AMMO={"military":{"name":"制式子弹","damage":1.4,"tradable":true},"handmade":{"name":"土制子弹","damage":1.0,"tradable":false}}
const VODKA_PRICE=18
const RESALE={"bread":2,"bandage":2,"medkit":6,"antirad":5,"battery":3,"cord":1,"vodka":18}
static func sale_price(s,id:String)->int:
	if id=="vodka":return 18 if s.has(id) else 0
	return int(RESALE.get(id,0)) if int(s.economy.goods.get(id,0))>0 else 0
static func sell(s,id:String)->String:
	var price=sale_price(s,id)
	if price<=0:return "这件物品不收购。任务物品与个人纪念物请自己保管。"
	if id=="vodka":return sell_vodka(s)
	s.economy.goods[id]-=1
	if s.economy.goods[id]<=0:s.economy.goods.erase(id)
	s.economy.stock[id]=int(s.economy.stock.get(id,0))+1
	s.economy.military+=price
	s.economy.ledger.append({"kind":"sell","id":id,"rounds":price})
	s.changed.emit()
	return "柳德米拉收下一份%s，付给你 %d 发制式子弹。"%[GOODS[id].name,price]
static func fresh()->Dictionary:
	var stock={}
	for id in GOODS:stock[id]=GOODS[id].stock
	return {"military":18,"handmade":12,"goods":{},"stock":stock,"health":100,"food":60,"radiation":0,"ledger":[],"activity_clock":0.0,"recovery_clock":0.0}
static func restored(saved:Dictionary)->Dictionary:
	var data=fresh()
	for key in data:
		if saved.has(key):data[key]=saved[key].duplicate(true) if saved[key] is Dictionary or saved[key] is Array else saved[key]
	for kind in ["military","handmade"]:data[kind]=maxi(0,int(data[kind]))
	return data
static func buy(s,id:String)->String:
	if not GOODS.has(id):return "这里没有这种物资。"
	var g:Dictionary=GOODS[id]
	if s.economy.stock.get(id,0)<=0:return "这批已经卖完了，等下一次补货。"
	if s.economy.military<g.price:return "制式子弹不够。土制弹不能抵账。"
	s.economy.military-=g.price
	s.economy.goods[id]=int(s.economy.goods.get(id,0))+1
	s.economy.stock[id]-=1
	s.economy.ledger.append({"kind":"buy","id":id,"rounds":g.price})
	s.changed.emit()
	return "柳德米拉点过子弹，把%s推到柜台边。"%g.name
static func sell_vodka(s)->String:
	if not s.has("vodka"):return "背包里没有这瓶酒。"
	s.take("vodka")
	s.economy.military+=VODKA_PRICE
	s.economy.ledger.append({"kind":"sell","id":"vodka","rounds":VODKA_PRICE})
	s.flags.vodka_sold=true
	s.changed.emit()
	return "柳德米拉看了封口，把酒收到柜下，数给你 18 发制式弹。\n「这酒不是拿来兑水的。账上算我收的。」"
static func consume(s,id:String)->String:
	if not GOODS.has(id) or int(s.economy.goods.get(id,0))<=0:return "背包里没有这种物资。"
	var g:Dictionary=GOODS[id]
	if g.effect=="":return "先收好，暂时没有需要用它的地方。"
	var stat:String=g.effect
	if stat=="radiation" and s.economy.radiation<=0:return "目前不需要服药。"
	if stat!="radiation" and s.economy[stat]>=100:return "现在用会浪费，先留着。"
	s.economy.goods[id]-=1
	if s.economy.goods[id]==0:s.economy.goods.erase(id)
	s.economy[stat]=maxi(0,s.economy[stat]-g.amount) if stat=="radiation" else mini(100,s.economy[stat]+g.amount)
	s.changed.emit()
	return "你使用了%s。"%g.name
static func spend_ammo(s,kind:String,count:int)->bool:
	if not AMMO.has(kind) or count<=0 or s.economy[kind]<count:return false
	s.economy[kind]-=count
	s.changed.emit()
	return true

const MEALS={"cook":"life","commune_leader":"commune","sech_elder":"sech","coal_medic":"coal","commune_cook":"commune","sech_cook":"sech"}
static func meal_key(s,id:String)->String:
	var kitchen={"commune_leader":"commune_cook","sech_elder":"sech_cook"}.get(id,id)
	return "meal_%s_%d"%[kitchen,int(s.flags.get("story_day",16))]
static func decorate(v:Dictionary,s)->Dictionary:
	if MEALS.get(v.id,"")==s.context.get("floor","?") and not s.f(meal_key(s,v.id)) and s.economy.food<75:
		v.options.append(s.opt("meal_"+v.id,"「还有居民的热饭吗？我想坐下吃一点。」"))
	return v
static func meal(s,id:String)->String:
	if MEALS.get(id,"")!=s.context.get("floor","?") or s.f(meal_key(s,id)):return "今天这份饭已经吃过了。"
	s.flags[meal_key(s,id)]=true
	s.economy.food=maxi(int(s.economy.food),75)
	s.economy.health=mini(100,int(s.economy.health)+5)
	s.changed.emit()
	return "你坐下来吃完一份热饭，慢慢暖了过来。\n「今天这份算居民伙食。路上别只顾着走，包里的面包也记得吃。」"
static func advance(s,delta:float,moving:bool):
	if not moving or s.ending:return
	var clock:float=float(s.economy.get("activity_clock",0))+maxf(delta,0)
	var ticks=floori(clock/120.0)
	s.economy.activity_clock=fmod(clock,120.0)
	if ticks>0:s.economy.food=maxi(0,int(s.economy.food)-ticks)
	# Hunger affects comfort, never causes passive damage or a death spiral.
	if s.economy.food>=40 and s.economy.health<100:
		var recovery:float=float(s.economy.get("recovery_clock",0))+maxf(delta,0)
		var interval=180.0 if int(s.economy.radiation)>=20 else 90.0
		var recovered=floori(recovery/interval)
		s.economy.recovery_clock=fmod(recovery,interval)
		if recovered>0:s.economy.health=mini(100,int(s.economy.health)+recovered)
