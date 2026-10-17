extends RefCounted
## Standard ammunition is money; handmade ammunition is a separate reserve.
const GOODS={
"bread":{"name":"黑面包","price":4,"stock":8,"icon":"bread","detail":"一份当天的黑面包。恢复 30 点饱食。","effect":"food","amount":30},
"bandage":{"name":"洁净绷带","price":5,"stock":5,"icon":"bandage","detail":"洗净煮过的布与包扎材料。恢复 15 点体力。","effect":"health","amount":15},
"medkit":{"name":"急救包","price":12,"stock":2,"icon":"medkit","detail":"密封药品和敷料。恢复 40 点体力。","effect":"health","amount":40},
"antirad":{"name":"抗辐射药","price":10,"stock":2,"icon":"antirad","detail":"减少 20 点已受辐射，不能代替防毒面具。","effect":"radiation","amount":20},
"battery":{"name":"干电池","price":7,"stock":3,"icon":"battery","detail":"防潮包内的电池，留给照明和小型设备使用。","effect":"","amount":0},
"cord":{"name":"细绳与布胶带","price":3,"stock":4,"icon":"cord","detail":"捆扎行李、固定松动物件的常用耗材。","effect":"","amount":0}}
const AMMO={"military":{"name":"制式子弹","damage":1.4,"tradable":true},"handmade":{"name":"土制子弹","damage":1.0,"tradable":false}}
const VODKA_PRICE=18
static func fresh()->Dictionary:
	var stock={}
	for id in GOODS:stock[id]=GOODS[id].stock
	return {"military":18,"handmade":12,"goods":{},"stock":stock,"health":100,"food":60,"radiation":0,"ledger":[]}
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
