extends RefCounted
const MATERIALS=["scrap_metal","copper_wire","salvage_cloth","mutant_bone","mutant_sample","battery","cord"]
const TABS=[["all","全部"],["equipment","装备"],["supplies","补给"],["materials","材料"],["quest","任务与文件"],["keepsakes","个人物品"]]
static func entries(s)->Array:
 var out=[]
 for id in s.items:
  var d=s.ITEMS[id];var category="equipment" if d[2] in ["武器","装备","工具","维修"] else ("keepsakes" if d[2] in ["记忆","纪念"] else "quest")
  out.append({"id":id,"name":d[0],"detail":d[1],"kind":d[2],"category":category,"count":1,"good":false})
 for id in s.economy.goods:
  if int(s.economy.goods[id])<=0 or not s.Economy.GOODS.has(id):continue
  var d=s.Economy.GOODS[id]
  out.append({"id":id,"name":d.name,"detail":d.detail,"kind":"消耗品" if d.effect!="" else "物资","category":"materials" if id in MATERIALS else ("equipment" if id=="portable_radio" else "supplies"),"count":int(s.economy.goods[id]),"good":true})
 out.sort_custom(func(a,b):return a.category<b.category if a.category!=b.category else a.id<b.id)
 return out
static func render(h,tab:String="all",selected:String=""):
 load("res://scripts/ui_workbench.gd").inventory(h,tab,selected)
