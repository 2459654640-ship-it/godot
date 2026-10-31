extends RefCounted
const Bag=preload("res://scripts/backpack.gd")
const FLOORS=["east_district","surface","grey_shelter"]
const CONTAINERS=[
 ["clinic_drawer","诊所治疗室的抽屉",Vector3(-75,0,34),"medical"],
 ["clinic_coat","候诊室遗留的包",Vector3(-88,0,26),"domestic"],
 ["radio_store","通信站备件柜",Vector3(-36,0,-69),"technical"],
 ["workshop_box","修配间工具箱",Vector3(16.5,0,26),"technical"],
 ["freight_case","毁坏住宅的旅行箱",Vector3(-48,0,-12),"domestic"],
 ["freight_cellar","货运路住宅外的地窖箱",Vector3(-81,0,2.3),"domestic"],
 ["south_entry","南街住户门边的旧包",Vector3(-46,0,89),"domestic"],
 ["south_supply","南街公用物资箱",Vector3(46,0,89),"medical"],
 ["east_corner_tools","东侧街角修理箱",Vector3(87,0,41),"technical"],
 ["apartment_pantry","住宅厨房的储物柜",Vector3(-35,0,48),"domestic"],
 ["apartment_workbag","卧室床脚的旧工具包",Vector3(-26,0,43),"technical"],
 ["depot_crate","货场装卸箱",Vector3(56,0,36),"technical"],
 ["camp_food","岗哨旁的食品箱",Vector3(54,0,-9),"domestic"],
 ["camp_arms","灰狗地表哨所弹药箱",Vector3(44.5,0,-18),"arms"]]
const TABLES={"medical":["bandage","medkit","antirad","salvage_cloth"],"domestic":["bread","salvage_cloth","cord","battery"],"technical":["scrap_metal","copper_wire","battery","cord"],"arms":["ammo_pouch","bandage","scrap_metal"]}
static func active(w)->bool:return w.floor_id in FLOORS and w.story.f("raid_active")
static func begin(s,home:String):
 if s.f("raid_active"):return
 s.flags.raid_active=true;s.flags.raid_home="life" if home=="labor" else home;s.flags.raid_index=int(s.flags.get("raid_index",0))+1
 s.flags.raid_losses=[];s.flags.raid_departure_goods=s.economy.goods.duplicate();s.flags.raid_departure_money=s.economy.military
static func setup(w):
 if w.floor_id in ["life","commune","sech"] and w.story.f("raid_active"):
  var repayment=mini(int(w.story.flags.get("raid_loan",0)),int(w.story.economy.military));w.story.economy.military-=repayment;w.story.flags.raid_loan=int(w.story.flags.get("raid_loan",0))-repayment
  w.story.flags.raid_active=false;w.story.flags.raid_last_result="returned";w.story.flags.raid_last_haul=w.story.economy.goods.duplicate()
  return
 if w.floor_id not in FLOORS:return
 # Older saves in the district acquire a trip once; loading never refills it.
 if not w.story.f("raid_active"):begin(w.story,String(w.story.flags.get("east_home","commune")))
 if w.floor_id=="east_district":
  w.target("grey_shelter_entry",Vector3(42,0,-11.8),"岗哨后方 / 地下避难所入口")
  w.kit.box("ShelterStairDoor",Vector3(42,1.1,-12.5),Vector3(1.9,2.2,.15),"old_iron",true)
  w.kit.box("ShelterStairLintel",Vector3(42,2.3,-12.5),Vector3(2.1,.18,.25),"district_concrete")
  for spec in CONTAINERS:add(w,spec[0],spec[1],spec[2],spec[3])
 if w.floor_id=="grey_shelter":
  w.target("grey_shelter_exit",Vector3(-7.5,0,8),"沿楼梯返回地表岗哨")
  for spec in [["shelter_food","厨房配给柜",Vector3(-6,0,-5),"domestic"],["shelter_tools","修械台下的箱子",Vector3(5,0,-5),"arms"],["shelter_bunks","铺位下的背包",Vector3(6,0,5),"medical"]]:add(w,spec[0],spec[1],spec[2],spec[3])
 for key in w.story.flags.get("raid_containers",{}):
  var rec:Dictionary=w.story.flags.raid_containers[key]
  if rec.get("floor","")!=w.floor_id or not rec.get("dropped",false):continue
  var p=rec.position;add(w,key.trim_prefix(w.floor_id+":"),rec.title,Vector3(p[0],p[1],p[2]),"",rec.loot,true)
static func record_key(w,id:String)->String:return w.floor_id+":"+id
static func add(w,id:String,title:String,p:Vector3,table:String,contents:Dictionary={},dropped:bool=false):
 var key=record_key(w,id);var all:Dictionary=w.story.flags.get("raid_containers",{});var rec:Dictionary=all.get(key,{})
 var batch=int(w.story.flags.get("raid_index",0))
 if rec.is_empty() or (not dropped and int(rec.get("batch",-1))!=batch):
  var loot=contents.duplicate()
  if not TABLES.get(table,[]).is_empty():
   var rng=RandomNumberGenerator.new();rng.seed=hash(str(w.story.flags.get("social_seed",0))+key+str(batch))
   for i in rng.randi_range(2,3):
    var item:String=TABLES[table][rng.randi_range(0,TABLES[table].size()-1)];loot[item]=int(loot.get(item,0))+1
  rec={"title":title,"floor":w.floor_id,"position":[p.x,p.y,p.z],"batch":batch,"searched":dropped,"loot":loot,"dropped":dropped};all[key]=rec;w.story.flags.raid_containers=all
 var target="raid_container_"+id
 if w.targets.has(target):return
 if dropped:w.kit.box("SalvagePack",p+Vector3.UP*.14,Vector3(.55,.26,.4),"cloth")
 else:
  if "包" in title or "旅行箱" in title:
   w.kit.ellipsoid("AbandonedCanvasBag",p+Vector3.UP*.2,Vector3(.42,.20,.28),"cloth")
   for x in [-.20,.20]:w.kit.box("BagStrap",p+Vector3(x,.38,0),Vector3(.08,.035,.46),"wood")
  elif "柜" in title or "抽屉" in title:
   w.kit.box("SalvageCabinet",p+Vector3.UP*.36,Vector3(.88,.72,.52),"old_iron",true)
   for y in [.18,.50]:
    w.kit.box("CabinetDrawer",p+Vector3(0,y,.27),Vector3(.78,.25,.035),"metal")
    w.kit.box("CabinetHandle",p+Vector3(0,y,.31),Vector3(.18,.025,.04),"brass")
  else:
   w.kit.crate(p,Vector3(.8,.65,.6));w.kit.box("SalvageBoxLatch",p+Vector3(0,.48,.32),Vector3(.16,.12,.04),"metal")
 w.target(target,p+Vector3(0,0,.65),title+(" · 已搜空" if rec.searched and rec.loot.is_empty() else ""),"inspect")
static func safe(w)->bool:
 if is_instance_valid(w.grey_camp) and not w.grey_camp.can_loot():return false
 if is_instance_valid(w.combat):
  for e in w.combat.enemies:
   if is_instance_valid(e) and e.hp>0 and e.position.distance_to(w.player.position)<7 and w.combat.sight(e.position+Vector3.UP,w.player.position+Vector3.UP):return false
 return true
static func open(w,target:String):
 if not w.targets.has(target) or w.player.position.distance_to(w.targets[target].pos)>2.3:return
 if not safe(w):w.hud.toast("附近的敌人正在盯着这里，先离开他们的视线。");return
 var id=target.trim_prefix("raid_container_");var key=record_key(w,id);var rec:Dictionary=w.story.flags.get("raid_containers",{}).get(key,{})
 if rec.is_empty():return
 var h=w.hud
 if not rec.searched:
  h.start_modal(rec.title,"搜索与转移 · 背包容量有限",true)
  h.body("你靠近检查外壳和封口。打开后，需要花一点时间确认哪些物资还能使用。",20)
  h.modal_box.add_child(h.button("搜索容器 · 约 2 秒",func():search(w,target)))
  return
 load("res://scripts/ui_workbench.gd").transfer(h,false,target)
 return
static func search(w,target:String):
 var key=record_key(w,target.trim_prefix("raid_container_"));var rec:Dictionary=w.story.flags.raid_containers[key]
 w.hud.start_modal(rec.title,"正在翻找…",true)
 var progress=ProgressBar.new();progress.max_value=20;w.hud.modal_box.add_child(progress)
 for i in 20:
  await w.get_tree().create_timer(.1).timeout
  if not is_instance_valid(w) or not is_instance_valid(progress):return
  progress.value=i+1
 rec.searched=true;w.autosave();open(w,target)
static func take(w,target:String,id:String,flush:bool=true)->bool:
 if not w.targets.has(target) or w.player.position.distance_to(w.targets[target].pos)>2.3 or not safe(w):return false
 var key=record_key(w,target.trim_prefix("raid_container_"));var rec:Dictionary=w.story.flags.get("raid_containers",{}).get(key,{})
 if rec.is_empty() or not rec.searched or int(rec.loot.get(id,0))<=0:return false
 if id not in ["military","handmade"] and not Bag.can_add(w.story,id):return false
 Bag.change(w.story,id,1);rec.loot[id]-=1
 if rec.loot[id]<=0:rec.loot.erase(id)
 if rec.loot.is_empty():w.targets[target].label=rec.title+" · 已搜空"
 if flush:w.story.changed.emit();w.autosave()
 return true
static func take_all(w,target:String):
 var key=record_key(w,target.trim_prefix("raid_container_"));var rec:Dictionary=w.story.flags.get("raid_containers",{}).get(key,{})
 if rec.is_empty():return
 var received=0
 for id in rec.loot.keys():
  for n in int(rec.loot[id]):
   if not take(w,target,id,false):break
   received+=1
 if received>0:w.story.changed.emit();w.autosave()
 open(w,target)
 w.hud.toast("收取 %d 份物资。"%received+("剩余物品仍留在原处。" if not rec.loot.is_empty() else "容器已经搜空。"))
static func corpse(w,enemy):
 var id="body_"+String(enemy.get_meta("loot_key","unknown"))+"_"+str(w.story.flags.get("raid_index",0))
 var key=record_key(w,id)
 if w.story.flags.get("raid_containers",{}).has(key):return
 add(w,id,"灰狗的装备与背包",enemy.position,"",{"grey_carbine":1,"handmade":8,"bandage":1,"mask":1},true)
static func discard(w,id:String):
 if Bag.count(w.story,id)<=0:return
 if id not in Bag.ORDINARY_ITEMS and not w.story.Economy.GOODS.has(id):return
 if w.floor_id in FLOORS:
  var serial=int(w.story.flags.get("dropped_serial",0))+1;w.story.flags.dropped_serial=serial
  add(w,"discard_"+str(serial),"你放下的物品",w.player.position,"",{id:1},true)
 else:
  # In a settlement, discarding puts the item in its local locker rather than deleting it.
  var stored:Dictionary=w.story.economy.stashes.get(w.floor_id,{})
  stored[id]=int(stored.get(id,0))+1;w.story.economy.stashes[w.floor_id]=stored
 Bag.change(w.story,id,-1);w.story.changed.emit();w.autosave()
static func resolve_loss(s)->Array:
 if not s.f("raid_active"):return s.flags.get("raid_losses",[])
 var losses=[]
 for id in s.economy.goods:
  if int(s.economy.goods[id])>0:losses.append(Bag.name_of(s,id)+" ×"+str(s.economy.goods[id]))
 s.economy.goods={}
 for id in Bag.ORDINARY_ITEMS:
  if s.has(id):losses.append(s.ITEMS[id][0]);s.take(id)
 for id in ["military","handmade"]:
  if s.economy[id]>0:losses.append(Bag.name_of(s,id)+" ×"+str(s.economy[id]))
  s.economy[id]=0
 s.flags.weapon_magazines={};s.flags.equipment={"weapon":""};s.flags.weapon_clip=0;s.flags.weapon_drawn=false;s.flags.bag_layout={};s.flags.erase("east_retreat_encounter")
 s.flags.raid_active=false;s.flags.raid_last_result="lost";s.flags.raid_debrief_pending=true;s.flags.raid_losses=losses;s.economy.health=45;s.economy.food=maxi(35,int(s.economy.food))
 return losses
static func return_after_loss(w):
 if not active(w) or not w.combat.defeated:return
 var home:String=w.story.flags.get("raid_home","commune")
 if home not in ["life","commune","sech"]:home="commune"
 resolve_loss(w.story)
 w.combat.clip=0;w.combat.reload_time=0
 var packet=w.save_snapshot();packet.combat_state={};packet.floor=home;packet.flags.comic={"active":false};packet.flags.erase("next_sequence");packet.flags.erase("next_facility");packet.flags.erase("resume_dialogue")
 for key in ["grey_camp","grey_shelter_guards"]:
  if not packet.flags.has(key):continue
  var camp:Dictionary=packet.flags[key];camp.alarm=false;camp.lost_time=0;camp.erase("last_seen")
  for guard in camp.get("guards",[]):
   guard.suspicion=0;guard.windup=0;guard.alerted=false;guard.erase("last_known")
 var p=Vector3(-15,.04,-4) if home=="life" else preload("res://scripts/facility_layouts.gd").PLANS[home].spawn
 packet.position=[p.x,p.y,p.z];w.get_node("/root/Session").enter(packet,home,p)
