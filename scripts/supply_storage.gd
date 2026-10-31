extends RefCounted
## Local storage: contents stay at the settlement, serialized with the economy.
const LOCKERS={"life":Vector3(-14.2,0,-2),"commune":Vector3(3.1,0,22.5),"sech":Vector3(-15,0,12)}
const NAMES={"life":"伊万的储物柜","commune":"公社客人物资柜","sech":"住户车厢寄存柜"}
static func setup(w):
 if LOCKERS.has(w.floor_id):w.target("personal_storage",LOCKERS[w.floor_id]+Vector3(0,0,.8),NAMES[w.floor_id])
static func accessible(w)->bool:
 if not LOCKERS.has(w.floor_id) or (is_instance_valid(w.combat) and w.combat.active):return false
 return Vector2(w.player.position.x,w.player.position.z).distance_to(Vector2(LOCKERS[w.floor_id].x,LOCKERS[w.floor_id].z))<2.5
static func move(s,place:String,id:String,count:int,deposit:bool)->bool:
 var bag=preload("res://scripts/backpack.gd")
 if not LOCKERS.has(place) or s.context.get("floor","")!=place or count<=0:return false
 if id not in bag.ORDINARY_ITEMS and id not in ["military","handmade"] and not s.Economy.GOODS.has(id):return false
 var all:Dictionary=s.economy.stashes;var stored:Dictionary=all.get(place,{})
 if deposit:
  if bag.count(s,id)<count:return false
  bag.change(s,id,-count);stored[id]=int(stored.get(id,0))+count
 else:
  if int(stored.get(id,0))<count:return false
  if id not in ["military","handmade"] and not bag.can_add(s,id,count):return false
  stored[id]-=count;bag.change(s,id,count)
  if stored[id]==0:stored.erase(id)
 all[place]=stored;s.changed.emit();return true
static func render(h,deposit:bool=true):
 load("res://scripts/ui_workbench.gd").transfer(h,true)
