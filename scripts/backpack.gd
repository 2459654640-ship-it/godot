extends RefCounted
## Real item footprints, bounded stacks and saved placement. Story documents are protected.
const WIDTH=8
const HEIGHT=6
const GEAR=["revolver","grey_carbine","mask","filter"]
const ORDINARY_ITEMS=["revolver","grey_carbine","mask","filter","vodka","cigarettes"]
const SIZES={"revolver":Vector2i(2,2),"grey_carbine":Vector2i(4,2),"mask":Vector2i(2,2),"filter":Vector2i(1,2),"medkit":Vector2i(2,2),"portable_radio":Vector2i(2,2),"scrap_metal":Vector2i(2,1),"mutant_bone":Vector2i(2,1),"vodka":Vector2i(1,2)}
const STACKS={"bandage":3,"ammo_pouch":3,"bread":2,"salvage_cloth":5,"copper_wire":4,"scrap_metal":3,"mutant_bone":3,"mutant_sample":2,"battery":4,"cord":4,"antirad":3}
static func protected_item(id:String)->bool:return id not in ORDINARY_ITEMS
static func size_of(id:String)->Vector2i:return SIZES.get(id,Vector2i.ONE)
static func pieces(s,extra:Dictionary={})->Array:
 var out=[];var goods:Dictionary=s.economy.goods.duplicate()
 for id in extra:goods[id]=int(goods.get(id,0))+int(extra[id])
 for id in goods:
  var n=int(goods[id]);var stack=int(STACKS.get(id,1));var index=0
  while n>0:
   out.append({"key":id+":"+str(index),"id":id,"count":mini(stack,n),"good":true,"size":size_of(id)});n-=stack;index+=1
 for id in s.items:
  if not protected_item(id) and id!=s.equipped_weapon() and id not in ["mask","filter"]:out.append({"key":id+":0","id":id,"count":1,"good":false,"size":size_of(id)})
 out.sort_custom(func(a,b):return a.size.x*a.size.y>b.size.x*b.size.y if a.size.x*a.size.y!=b.size.x*b.size.y else a.key<b.key)
 return out
static func fits(at:Vector2i,size:Vector2i,used:Dictionary)->bool:
 if at.x<0 or at.y<0 or at.x+size.x>WIDTH or at.y+size.y>HEIGHT:return false
 for x in range(at.x,at.x+size.x):
  for y in range(at.y,at.y+size.y):
   if used.has(Vector2i(x,y)):return false
 return true
static func occupy(used:Dictionary,at:Vector2i,size:Vector2i):
 for x in range(at.x,at.x+size.x):
  for y in range(at.y,at.y+size.y):used[Vector2i(x,y)]=true
static func pack(s,extra:Dictionary={},remember:bool=false)->Dictionary:
 var used={};var out=[];var overflow=[];var positions={};var saved:Dictionary=s.flags.get("bag_layout",{})
 for piece in pieces(s,extra):
  var sz:Vector2i=piece.size;var prior=saved.get(piece.key,[]);var at=Vector2i(-1,-1)
  if prior is Array and prior.size()==3:
   if prior[2]:sz=Vector2i(sz.y,sz.x)
   var candidate=Vector2i(prior[0],prior[1])
   if fits(candidate,sz,used):at=candidate
  if at.x<0:
   for y in HEIGHT:
    for x in WIDTH:
     if fits(Vector2i(x,y),sz,used):at=Vector2i(x,y);break
    if at.x>=0:break
  if at.x<0:overflow.append(piece);continue
  piece=piece.duplicate();piece.at=at;piece.size=sz;occupy(used,at,sz);out.append(piece);positions[piece.key]=[at.x,at.y,sz!=size_of(piece.id)]
 if remember:s.flags.bag_layout=positions
 return {"pieces":out,"overflow":overflow,"used":used.size()}
static func can_add(s,id:String,count:int=1)->bool:
 if count<=0:return false
 if s.Economy.GOODS.has(id):return pack(s,{id:count}).overflow.is_empty()
 if s.has(id):return false
 if protected_item(id) or id in ["mask","filter"]:return true
 var old=s.items.duplicate();s.items.append(id);var ok=pack(s).overflow.is_empty();s.items.assign(old);return ok
static func move_piece(s,key:String,at:Vector2i,rotate:bool=false)->bool:
 var packed=pack(s);var match_piece=packed.pieces.filter(func(p):return p.key==key)
 if match_piece.is_empty():return false
 var piece:Dictionary=match_piece[0];var sz:Vector2i=piece.size
 if rotate:sz=Vector2i(sz.y,sz.x)
 var used={}
 for other in packed.pieces:
  if other.key!=key:occupy(used,other.at,other.size)
 if not fits(at,sz,used):return false
 var positions:Dictionary=s.flags.get("bag_layout",{}).duplicate();positions[key]=[at.x,at.y,sz!=size_of(piece.id)];s.flags.bag_layout=positions;s.changed.emit();return true
static func count(s,id:String)->int:
 if id in ["military","handmade"]:return int(s.economy[id])
 return int(s.economy.goods.get(id,0)) if s.Economy.GOODS.has(id) else int(s.has(id))
static func change(s,id:String,amount:int):
 if id in ["military","handmade"]:s.economy[id]=maxi(0,int(s.economy[id])+amount)
 elif s.Economy.GOODS.has(id):
  s.economy.goods[id]=maxi(0,int(s.economy.goods.get(id,0))+amount)
  if s.economy.goods[id]==0:s.economy.goods.erase(id)
 elif amount>0:s.give(id)
 else:s.take(id)
static func name_of(s,id:String)->String:
 if id in ["military","handmade"]:return "制式子弹" if id=="military" else "土制子弹"
 return s.Economy.GOODS[id].name if s.Economy.GOODS.has(id) else s.ITEMS[id][0]
