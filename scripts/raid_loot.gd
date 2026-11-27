extends RefCounted
const Bag=preload("res://scripts/backpack.gd")
const Salvage=preload("res://scripts/salvage_catalog.gd")
const District=preload("res://scripts/district_expedition.gd")
const Prop=preload("res://scripts/loot_prop.gd")
const PREFIX="raid_container_"
const EXITS={
 "life":{"id":"east_d6_entry","name":"D-6 外侧登记口"},
 "commune":{"id":"east_commune_entry","name":"公社支线口"},
 "sech":{"id":"east_sech_entry","name":"谢契检修库口"}
}
const FLOORS=["east_district","surface","grey_shelter"]
const CONTAINERS=[
 ["dispatch_bag","留置室床脚的帆布包",Vector3(-44.8,0,47.1),"medical"],
 ["heating_parts","供热院的检修柜",Vector3(-54.15,0,52.2),"technical"],
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
static func active(w)->bool:return w.floor_id in FLOORS and w.story.f("raid_active")

static func extraction(s)->Dictionary:
 if not s.f("raid_active"):return {}
 return EXITS.get(s.flags.get("raid_home","commune"),EXITS.commune)

static func carried(s)->Dictionary:
 var cargo:Dictionary=s.economy.goods.duplicate()
 for id in Bag.ORDINARY_ITEMS:
  if s.has(id):cargo[id]=1
 cargo.military=s.economy.military;cargo.handmade=s.economy.handmade
 return cargo

static func begin(s,home:String):
 if s.f("raid_active"):return
 s.flags.raid_active=true
 s.flags.raid_home="life" if home=="labor" else home
 s.flags.raid_index=int(s.flags.get("raid_index",0))+1
 s.flags.raid_losses=[];s.flags.raid_departure_goods=s.economy.goods.duplicate();s.flags.raid_departure_money=s.economy.military
 s.flags.raid_departure_counts=carried(s)
 s.flags.raid_searched=0
 s.flags.erase("east_retreat_encounter")
 # Expedition loot and wandering wildlife replenish together after extraction
 # or defeat. Quest wards and the permanent camp clear flag keep their history.
 for key in s.flags.keys():
  if key.begins_with("battle_raid_"):s.flags.erase(key)
 s.flags.raid_containers={}
 var old_drops:Dictionary=s.flags.get("east_loot",{})
 for key in old_drops.keys():
  if key.begins_with("raid_"):old_drops.erase(key)

static func settle(w):
 var s=w.story
 var from:Dictionary=s.flags.get("raid_departure_counts",s.flags.get("raid_departure_goods",{}))
 var finds={}
 var value=0;var quantity=0
 for id in carried(s):
  if id in ["military","handmade"]:continue
  var net=Bag.count(s,id)-int(from.get(id,0))
  if net<=0:continue
  finds[id]=net
  quantity+=net
  value+=net*s.Economy.sale_price(s,id)
 var repayment=mini(int(s.flags.get("raid_loan",0)),int(s.economy.military))
 s.economy.military-=repayment
 s.flags.raid_loan=int(s.flags.get("raid_loan",0))-repayment
 s.flags.raid_active=false;s.flags.raid_last_result="returned"
 s.flags.raid_last_haul=s.economy.goods.duplicate()
 s.flags.raid_return={"items":finds,"units":quantity,"value":value,"repaid":repayment,"searched":int(s.flags.get("raid_searched",0)),"number":int(s.flags.get("raid_index",0))}
 s.flags.erase("east_retreat_encounter")
 w.raid_extracted=true

static func setup(w):
 if w.story.f("raid_active") and (w.floor_id in EXITS or (w.floor_id=="labor" and w.story.flags.get("raid_home")=="life" and w.arrival_data.get("floor","")=="east_district")):
  settle(w)
  return
 if w.floor_id not in FLOORS:return
 # Existing saves in the field get a stable expedition number on first load.
 if not w.story.f("raid_active"):begin(w.story,String(w.story.flags.get("east_home","commune")))
 Prop.prepare(w)
 if w.floor_id=="east_district":
  w.target("grey_shelter_entry",Vector3(42,0,-11.8),"岗哨后方 / 地下避难所入口")
  w.kit.box("ShelterStairDoor",Vector3(42,1.1,-12.5),Vector3(1.9,2.2,.15),"old_iron",true)
  w.kit.box("ShelterStairLintel",Vector3(42,2.3,-12.5),Vector3(2.1,.18,.25),"district_concrete")
  for spec in CONTAINERS:add(w,spec[0],spec[1],spec[2],spec[3])
 if w.floor_id=="grey_shelter":
  add(w,"shelter_salvage","外勤储料间的旧滤件箱",Vector3(-13.6,0,5.8),"technical")
  w.target("grey_shelter_exit",Vector3(-7.5,0,8),"沿楼梯返回地表岗哨")
  for spec in [["shelter_food","厨房配给柜",Vector3(-6,0,-5),"domestic"],["shelter_tools","修械台下的箱子",Vector3(5,0,-5),"arms"],["shelter_bunks","铺位下的背包",Vector3(6,0,5),"medical"]]:add(w,spec[0],spec[1],spec[2],spec[3])
 for spec in District.data().containers[w.floor_id]:
  var coords:Array=spec.point
  add(w,spec.id,spec.name,Vector3(coords[0],0,coords[1]),spec.pool,{},false,spec.kind,deg_to_rad(spec.face),spec.get("stockroom",false))
 var batch=int(w.story.flags.get("raid_index",0))
 for key in w.story.flags.get("raid_containers",{}):
  var rec:Dictionary=w.story.flags.raid_containers[key]
  if rec.get("floor","")!=w.floor_id or not rec.get("dropped",false) or int(rec.get("batch",-1))!=batch:continue
  var p=rec.position
  add(w,key.trim_prefix(w.floor_id+":"),rec.title,Vector3(p[0],p[1],p[2]),"",rec.loot,true,"bag",float(rec.get("facing",0)))

static func setup_hud(w):
 if w.raid_extracted:
  var result:Dictionary=w.story.flags.raid_return
  w.hud.toast("安全撤离 · 带回 %d 件新物资，估价 %d 发制式弹。携带物资可在聚落寄存。"%[result.units,result.value],7)
 if not active(w):return
 var bar=ProgressBar.new();bar.name="FieldSearchProgress";bar.position=Vector2(575,829);bar.size=Vector2(450,7)
 bar.show_percentage=false;bar.max_value=1;bar.visible=false;bar.mouse_filter=Control.MOUSE_FILTER_IGNORE
 bar.add_theme_stylebox_override("background",w.hud.style(Color("1b2825"),Color("596858"),1,0))
 bar.add_theme_stylebox_override("fill",w.hud.style(Color("dbc78e"),Color("dbc78e"),0,0))
 w.hud.add_child(bar);w.loot_progress=bar
 var notice=String(extraction(w.story).name) if w.floor_id=="east_district" else "先返回地表，再前往撤离口"
 if not w.story.f("raid_field_tip"):
  w.story.flags.raid_field_tip=true
  w.hud.toast("外勤开始 · 靠近容器按 E 搜索，移动会中断。打开地图查看撤离口。
"+notice,8)

static func record_key(w,id:String)->String:return w.floor_id+":"+id
static func record(w,target:String)->Dictionary:
 return w.story.flags.get("raid_containers",{}).get(record_key(w,target.trim_prefix(PREFIX)),{})

static func add(w,id:String,title:String,p:Vector3,table:String,contents:Dictionary={},dropped:bool=false,kind:String="",facing:float=0,stockroom:bool=false):
 var key=record_key(w,id)
 var all:Dictionary=w.story.flags.get("raid_containers",{})
 var rec:Dictionary=all.get(key,{})
 var batch=int(w.story.flags.get("raid_index",0))
 if rec.is_empty() or (not dropped and int(rec.get("batch",-1))!=batch):
  var loot=contents.duplicate()
  loot.merge(Salvage.roll(table,District.rng(w.story,key),stockroom))
  var delay=1.0 if dropped else (2.8 if stockroom else 1.85)
  rec={"title":title,"floor":w.floor_id,"position":[p.x,p.y,p.z],"batch":batch,"searched":dropped,"loot":loot,"dropped":dropped,"facing":facing,"duration":delay}
  all[key]=rec;w.story.flags.raid_containers=all
 var target=PREFIX+id
 if w.targets.has(target):return
 if kind=="":
  kind="bag" if dropped or "包" in title else ("cabinet" if "柜" in title or "抽屉" in title else ("case" if "旅行箱" in title else "crate"))
 var fixture=Prop.build(w,id,p,kind,facing)
 w.target(target,fixture.front,title+(" · 已搜空" if rec.searched and rec.loot.is_empty() else ""),"loot")
 w.targets[target].searchable=not rec.loot.is_empty()
 w.loot_contours[target]=fixture.outline

static func can_reach(w,target:String,radius:float=2.3)->bool:
 if not w.targets.has(target):return false
 var p:Vector3=w.player.position;var q:Vector3=w.targets[target].pos
 if absf(p.y-q.y)>1.25 or Vector2(p.x,p.z).distance_squared_to(Vector2(q.x,q.z))>radius*radius:return false
 var ray=PhysicsRayQueryParameters3D.create(p+Vector3.UP*.81,q+Vector3.UP*.81,1)
 var hit=w.get_world_3d().direct_space_state.intersect_ray(ray)
 return hit.is_empty() or hit.position.distance_to(q+Vector3.UP*.81)<.18

static func safe(w)->bool:
 if is_instance_valid(w.grey_camp) and not w.grey_camp.can_loot():return false
 if is_instance_valid(w.combat):
  if w.combat.defeated:return false
  for e in w.combat.enemies:
   if is_instance_valid(e) and e.hp>0 and e.position.distance_to(w.player.position)<7 and w.combat.sight(e.position+Vector3.UP,w.player.position+Vector3.UP):return false
 return true

static func update_contours(w,cue:String):
 if w.loot_contours.is_empty():return
 for id in w.loot_contours:
  var outline:MeshInstance3D=w.loot_contours[id]
  if not w.targets.has(id) or not is_instance_valid(outline):continue
  var show=not w.hud.modal_visible() and w.targets[id].searchable and can_reach(w,id,2.65)
  outline.visible=show
  if show:outline.material_override=w.loot_ink[1 if id==cue else 0]

static func open(w,target:String):
 if not can_reach(w,target):return
 if not safe(w):w.hud.toast("先脱离敌人的视线，再翻找物资。");return
 var rec=record(w,target)
 if rec.is_empty():return
 if rec.searched:
  load("res://scripts/ui_workbench.gd").transfer(w.hud,false,target)
 elif w.loot_search.get("target")==target:
  cancel_search(w,"已收手，容器还没搜完。")
 else:
  w.loot_search={"target":target,"start":w.player.position,"health":w.story.economy.health,"elapsed":0.0}

static func cancel_search(w,message:String=""):
 w.loot_search={}
 if is_instance_valid(w.loot_progress):w.loot_progress.hide()
 if message!="":w.hud.toast(message,3)

static func tick(w,delta:float):
 if w.loot_search.is_empty():return
 if w.hud.modal_visible() or w.departure_animating:
  cancel_search(w)
  return
 var job:Dictionary=w.loot_search
 var target:String=job.target
 if not can_reach(w,target) or w.player.position.distance_to(job.start)>.28 or w.story.economy.health<job.health or Input.is_action_pressed("shoot") or not safe(w):
  cancel_search(w,"搜索中断，物资仍留在容器里。")
  return
 var rec=record(w,target)
 if rec.is_empty():
  cancel_search(w)
  return
 var duration=float(rec.get("duration",1.85))
 job.elapsed+=delta
 if job.elapsed<duration:
  if is_instance_valid(w.loot_progress):
   w.loot_progress.show();w.loot_progress.value=job.elapsed/duration
  w.hud.prompt.text="正在搜索  %s   %.1f 秒 · 移动或按 E 取消"%[rec.title,duration-job.elapsed]
  return
 cancel_search(w)
 rec.searched=true
 w.story.flags.raid_searched=int(w.story.flags.get("raid_searched",0))+1
 w.autosave()
 open(w,target)

static func take(w,target:String,id:String,flush:bool=true,count:int=1)->bool:
 if count<=0 or not can_reach(w,target) or not safe(w):return false
 var rec=record(w,target)
 if rec.is_empty() or not rec.searched or int(rec.loot.get(id,0))<count:return false
 if id not in ["military","handmade"] and (not w.story.Economy.GOODS.has(id) and not w.story.ITEMS.has(id) or not Bag.can_add(w.story,id,count)):return false
 Bag.change(w.story,id,count);rec.loot[id]-=count
 if rec.loot[id]<=0:rec.loot.erase(id)
 if rec.loot.is_empty():
  w.targets[target].label=rec.title+" · 已搜空";w.targets[target].searchable=false
 if flush:w.story.changed.emit();w.autosave()
 return true

static func take_all(w,target:String,only:String=""):
 var rec=record(w,target)
 if rec.is_empty():return
 var received=0
 for id in rec.loot.keys():
  if only!="" and only!=id:continue
  var quantity=int(rec.loot[id])
  if take(w,target,id,false,quantity):
   received+=quantity
   continue
  for n in quantity:
   if not take(w,target,id,false):break
   received+=1
 if received>0:w.story.changed.emit();w.autosave()
 if received==0:w.hud.toast("暂时收不下这些物资。可以旋转物品或腾出连续空格。",4)
 else:w.hud.toast("收取 %d 件物资。"%received+("剩余物品仍在原处。" if not rec.loot.is_empty() else "容器已搜空。"),3)
 open(w,target)

static func store(w,target:String,id:String)->bool:
 if not can_reach(w,target) or not safe(w):return false
 var rec=record(w,target)
 if rec.is_empty() or not rec.searched or Bag.count(w.story,id)<=0:return false
 if id not in Bag.ORDINARY_ITEMS and not w.story.Economy.GOODS.has(id):return false
 Bag.change(w.story,id,-1)
 rec.loot[id]=int(rec.loot.get(id,0))+1
 w.targets[target].searchable=true;w.targets[target].label=rec.title
 w.story.changed.emit();w.autosave()
 return true

static func corpse(w,enemy):
 var id="body_"+String(enemy.get_meta("loot_key","unknown"))+"_"+str(w.story.flags.get("raid_index",0))
 if w.story.flags.get("raid_containers",{}).has(record_key(w,id)):return
 var role:String=enemy.get_meta("patrol_role","rifle")
 var random=District.rng(w.story,id)
 var supplies=Salvage.roll("arms",random)
 supplies.handmade=random.randi_range(3,7) if role=="scout" else random.randi_range(6,10)
 if role in ["sentry","heavy"] or random.randf()<.32:supplies.grey_carbine=1
 if role in ["sentry","heavy"] or (role=="rifle" and random.randf()<.40):supplies.mask=1
 add(w,id,"灰狗留下的武器与行囊",enemy.position,"",supplies,true)
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
 s.flags.raid_active=false;s.flags.erase("raid_return");s.flags.raid_last_result="lost";s.flags.raid_debrief_pending=true;s.flags.raid_losses=losses;s.economy.health=45;s.economy.food=maxi(35,int(s.economy.food))
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
  for group in camp.get("groups",{}).values():
   group.alarm=false;group.lost=0;group.erase("last_seen")
  for guard in camp.get("guards",[]):
   guard.suspicion=0;guard.windup=0;guard.alerted=false;guard.erase("last_known")
 var p=Vector3(-15,.04,-4) if home=="life" else preload("res://scripts/facility_layouts.gd").PLANS[home].spawn
 packet.position=[p.x,p.y,p.z];w.get_node("/root/Session").enter(packet,home,p)
