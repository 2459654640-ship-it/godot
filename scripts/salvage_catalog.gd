extends RefCounted
## Salvage is distinct from quest items. Price is the settlement buyback per unit.
const ITEMS={
 "canned_stew":{"name":"牛肉罐头","detail":"库房封条还在，罐身也没有胀起。食用恢复 38 点饱食。","price":5,"size":Vector2i(1,1),"stack":2,"effect":"food","amount":38},
 "brick_tea":{"name":"压制茶砖","detail":"包纸上还有旧合作社的印章。交易时整块交付。","price":6,"size":Vector2i(2,1),"stack":2},
 "sugar_packet":{"name":"防潮袋白糖","detail":"外袋有些老化，封口之内的糖还很干燥。聚落食堂会收。","price":3,"size":Vector2i(1,1),"stack":3},
 "condensed_milk":{"name":"炼乳罐头","detail":"一小罐甜炼乳。食用恢复 24 点饱食。","price":4,"size":Vector2i(1,1),"stack":2,"effect":"food","amount":24},
 "sewing_tin":{"name":"针线盒","detail":"里面有骨针、卷线和几枚扣子，适合交给聚落的缝补间。","price":4,"size":Vector2i(1,1)},
 "wool_socks":{"name":"羊毛袜","detail":"一双干燥厚袜，鞋跟已经缝过一回。","price":3,"size":Vector2i(1,1),"stack":2},
 "wrapped_soap":{"name":"纸包肥皂","detail":"包装褪了色，皂块仍然完整。公共盥洗处需要这种物资。","price":3,"size":Vector2i(1,1),"stack":3},
 "enamel_mug":{"name":"搪瓷杯","detail":"杯口缺了一块釉，杯底还完好。","price":1,"size":Vector2i(1,1)},
 "glass_ampoules":{"name":"封存安瓿盒","detail":"有原盒和可辨认的批号。将它带回医务点可以换取物资。","price":8,"size":Vector2i(2,1),"stack":2},
 "sterile_gauze":{"name":"无菌纱布","detail":"夹在油纸内的敷料。使用恢复 10 点生命。","price":3,"size":Vector2i(1,1),"stack":3,"effect":"health","amount":10},
 "iodine_bottle":{"name":"棕瓶消毒液","detail":"旧诊所留下的小棕瓶，瓶盖上仍封着蜡。供商人收购。","price":4,"size":Vector2i(1,1),"stack":2},
 "filter_sheet":{"name":"活性炭滤材","detail":"一片裁好的滤材，维修工会拿去翻修滤毒罐。单片不能装在面具上。","price":5,"size":Vector2i(2,1),"stack":2},
 "folding_camera":{"name":"皮腔折叠相机","detail":"皮腔松软，快门还能响一声。合起来方便携带，在聚落有买家。","price":18,"size":Vector2i(2,2)},
 "pocket_watch":{"name":"银壳怀表","detail":"指针停在五点多。表壳没有刻名字，短链仍在。","price":22,"size":Vector2i(1,1)},
 "enamel_badge":{"name":"红釉工厂徽章","detail":"见习车间发给工人的徽章。釉色保存得很好。","price":7,"size":Vector2i(1,1),"stack":2},
 "photo_film":{"name":"未开封的胶卷","detail":"铁盒里装着一卷未曝光的黑白片。照相机和冲印材料都很少见。","price":10,"size":Vector2i(1,1),"stack":2},
 "bakelite_plug":{"name":"电木插头","detail":"外壳略有缺口，两只插脚都能重新接线。","price":2,"size":Vector2i(1,1),"stack":3},
 "ceramic_insulator":{"name":"陶瓷绝缘子","detail":"带螺纹的瓷件。沉且不好堆放，只有线路维修的人愿意出价。","price":4,"size":Vector2i(2,1),"stack":2},
 "porcelain_fuses":{"name":"瓷管熔断器","detail":"用布包住的一对旧熔断器。标记清晰，维修时好找替件。","price":6,"size":Vector2i(1,1),"stack":3},
 "salvage_relay":{"name":"配电继电器","detail":"触点完好，可作旧配电柜的备件，适合交给器材收购处。","price":11,"size":Vector2i(2,1)},
 "ball_bearing":{"name":"钢制滚珠轴承","detail":"厚油下面能看见完好的滚道。修理间收这种齿轮箱备件。","price":6,"size":Vector2i(1,1),"stack":2},
 "salvage_solenoid":{"name":"备件电磁线圈","detail":"线圈外裹着黑布，焊点还有漆封。适合拆修电气设备。","price":9,"size":Vector2i(2,2)},
 "pressure_gauge":{"name":"黄铜压力表","detail":"表盘完整，指针仍回到零位。矿区和水厂都缺这样的仪表。","price":14,"size":Vector2i(2,2)},
 "drive_belt":{"name":"泵机传动带","detail":"盘紧以后仍很占地方，曲折处没有露出里面的纤维。","price":7,"size":Vector2i(3,1)},
 "machine_oil":{"name":"机油壶","detail":"一壶还能使用的机油，搬运时要把螺盖重新拧紧。","price":8,"size":Vector2i(2,2)},
 "gasket_roll":{"name":"垫片卷材","detail":"机修间按需裁成垫片。背包空位不够宽时可以旋转放置。","price":5,"size":Vector2i(3,1)},
 "oilcloth_roll":{"name":"油布卷","detail":"折起来又厚又沉。可用于铺设临时防潮层，聚落会按整卷收。","price":4,"size":Vector2i(3,2)},
 "brass_valve":{"name":"铜制小阀","detail":"完整的阀芯和手轮，价值比相同重量的废钢高。","price":12,"size":Vector2i(2,2)},
 "drafting_compass":{"name":"盒装制图圆规","detail":"钢腿、延长杆和一小管笔芯都在。测绘员收这种小盒。","price":13,"size":Vector2i(2,1)},
 "salvage_optic":{"name":"光学校准组件","detail":"保护环完好，镜片没有雾。仪器工愿意为完整的一套多付一些。","price":25,"size":Vector2i(2,2)},
 "sealed_components":{"name":"铅封元件包","detail":"收发室按批次封好的一包微型元件，封印还能辨认。","price":15,"size":Vector2i(1,1),"stack":2},
 "portable_voltmeter":{"name":"便携式电压表","detail":"电木壳内带量程拨盘，读数面板保存完整。","price":17,"size":Vector2i(2,2)}
}

const POOLS={
 "medical":{"bandage":16,"sterile_gauze":18,"iodine_bottle":12,"antirad":4,"medkit":5,"glass_ampoules":7,"filter_sheet":3,"wrapped_soap":8},
 "domestic":{"bread":14,"condensed_milk":8,"canned_stew":7,"brick_tea":7,"sugar_packet":11,"wool_socks":11,"wrapped_soap":10,"enamel_mug":12,"salvage_cloth":12,"sewing_tin":8,"enamel_badge":2},
 "technical":{"scrap_metal":13,"copper_wire":14,"bakelite_plug":11,"ceramic_insulator":8,"porcelain_fuses":9,"battery":9,"cord":8,"salvage_relay":4,"ball_bearing":9,"gasket_roll":5},
 "mechanical":{"scrap_metal":14,"ball_bearing":14,"drive_belt":10,"gasket_roll":10,"machine_oil":6,"pressure_gauge":4,"brass_valve":6,"salvage_solenoid":5,"oilcloth_roll":9},
 "electronics":{"battery":16,"porcelain_fuses":14,"bakelite_plug":12,"copper_wire":16,"salvage_relay":9,"sealed_components":5,"portable_voltmeter":4,"salvage_optic":2},
 "personal":{"enamel_mug":13,"sewing_tin":11,"wool_socks":10,"wrapped_soap":8,"enamel_badge":9,"photo_film":6,"pocket_watch":2,"folding_camera":4,"brick_tea":8,"drafting_compass":5},
 "archive":{"drafting_compass":14,"photo_film":14,"salvage_optic":3,"sealed_components":6,"enamel_badge":7,"folding_camera":4,"battery":12},
 "arms":{"ammo_pouch":15,"bandage":10,"filter_sheet":7,"wrapped_soap":8,"canned_stew":10,"cord":10,"sterile_gauze":8,"porcelain_fuses":4},
 "provisions":{"bread":12,"canned_stew":15,"condensed_milk":15,"sugar_packet":13,"wrapped_soap":6,"brick_tea":10}
}

static func goods()->Dictionary:
 var out={}
 for id in ITEMS:
  var item=ITEMS[id].duplicate()
  item.merge({"stock":0,"icon":id,"effect":"","amount":0,"category":"supplies" if item.has("effect") else "materials","purchase":false})
  out[id]=item
 return out

static func resale()->Dictionary:
 var out={}
 for id in ITEMS:out[id]=ITEMS[id].price
 return out

static func roll(table:String,rng:RandomNumberGenerator,cache:bool=false)->Dictionary:
 var pool:Dictionary=POOLS.get(table,{}).duplicate()
 var contents={}
 if pool.is_empty():return contents
 var draws=rng.randi_range(2,3) if cache else rng.randi_range(1,3)
 for draw in draws:
  var total=0
  for weight in pool.values():total+=int(weight)
  var ticket=rng.randi_range(1,total)
  for id in pool.keys():
   ticket-=int(pool[id])
   if ticket>0:continue
   var stack:int=ITEMS.get(id,{}).get("stack",2)
   contents[id]=2 if stack>1 and rng.randf()<.20 else 1
   pool.erase(id)
   break
 return contents
