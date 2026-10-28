extends "res://scripts/combat_enemy.gd"
## A human guard uses perception and last-known positions, never omniscient pursuit.
var camp
var index=0
var route:Array=[]
var route_index=0
var facing=Vector3.FORWARD
var suspicion=0.0
var last_known=Vector3.INF
var wait_time=1.0
var bullets=3
var gun_reload=0.0
var alerted=false
func configure(owner_camp,i:int,points:Array,saved:Dictionary={}):
 camp=owner_camp;index=i;route=points
 var p:Vector3=points[0]
 if saved.get("position",[]).size()==3:p=Vector3(saved.position[0],saved.position[1],saved.position[2])
 setup(camp.w.combat,p,"greyhound")
 set_meta("loot_key",camp.w.floor_id+"_grey_guard_"+str(i));set_meta("loot_index",i)
 hp=int(saved.get("hp",80));route_index=int(saved.get("route_index",0))%route.size();suspicion=float(saved.get("suspicion",0));wait_time=float(saved.get("wait",1));bullets=int(saved.get("bullets",3));gun_reload=float(saved.get("reload",0));windup=float(saved.get("windup",0));cooldown=float(saved.get("cooldown",0));arrival_time=0
 var f=saved.get("facing",[0,0,1]);facing=Vector3(f[0],0,f[2])
 var last=saved.get("last_known",[])
 if last.size()==3:last_known=Vector3(last[0],last[1],last[2])
 if hp>0 and windup>0:warning=director.enemy_warning(position,windup)
 if hp<=0:collision_layer=0;collision_mask=0;sprite.visible=false
func sees_player()->bool:
 if hp<=0:return false
 var player=camp.w.player;var offset=player.position-position;offset.y=0
 var radius=8.0 if player.sneaking else 12.0
 if offset.length()>radius:return false
 if offset.length()>1.35 and facing.normalized().dot(offset.normalized())<cos(deg_to_rad(43)):return false
 return director.sight(position+Vector3.UP*1.25,player.position+Vector3.UP*1.05)
func hears_player()->bool:
 var p=camp.w.player;var moved=Vector2(p.velocity.x,p.velocity.z).length()>.25
 return moved and position.distance_to(p.position)<(1.6 if p.sneaking else 4.0) and director.sight(position+Vector3.UP*.9,p.position+Vector3.UP*.9)
func damage(amount:int,from_player:bool=false):
 if hp<=0:return
 camp.raise_alarm("枪声暴露了位置")
 super.damage(amount,from_player)
 if hp<=0:
  sprite.visible=false;camp.guard_fell(self)
func move_towards(point:Vector3,delta:float,speed:float):
 repath-=delta
 if repath<=0:path=director.enemy_path(position,point);repath=.65
 while not path.is_empty() and position.distance_to(path[0])<.35:path.remove_at(0)
 var direction=Vector3.ZERO
 if not path.is_empty():direction=path[0]-position;direction.y=0;direction=direction.normalized()
 velocity=direction*speed;velocity.y=-.2;move_and_slide()
 if get_position_delta().length()>.002:facing=direction
 track_progress(delta)
func _physics_process(delta):
 if not is_instance_valid(camp) or hp<=0 or director.paused():return
 animation+=delta;cooldown=maxf(0,cooldown-delta);hurt_time=maxf(0,hurt_time-delta);gun_reload=maxf(0,gun_reload-delta)
 target_body=camp.w.player
 var seen=sees_player();var heard=hears_player()
 if seen:
  last_known=target_body.position;camp.last_seen=last_known
  suspicion=minf(1,suspicion+delta*(.52 if target_body.sneaking else .95))
 elif heard:
  last_known=target_body.position;camp.last_seen=last_known;suspicion=minf(.72,suspicion+delta*.50)
 else:suspicion=maxf(0,suspicion-delta*.23)
 if suspicion>=.95:camp.raise_alarm("守卫认出了入侵者")
 if camp.alarm and self in director.enemies:
  alerted=true
  if seen:camp.lost_time=0
  if gun_reload>0:windup=0;cancel_warning()
  elif windup>0:
   if not seen:windup=0;cancel_warning()
   else:windup=maxf(0,windup-delta)
   velocity=Vector3.ZERO
   if windup<=0 and seen:
    cancel_warning()
    var origin=position+Vector3.UP*1.05;var target=target_body.position+Vector3.UP*.85
    var query=PhysicsRayQueryParameters3D.create(origin,target,1|4|8,[get_rid()])
    var result=get_world_3d().direct_space_state.intersect_ray(query);director.tracer(origin,result.get("position",target),true)
    if result.is_empty() or result.get("collider")==target_body:director.bite(target_body,12,"步枪射击")
    bullets-=1;director.w.get_node("/root/Session").sound("rifle")
    if bullets<=0:gun_reload=2.1;bullets=3
  elif seen:
   velocity=Vector3.ZERO
   var offset=target_body.position-position;offset.y=0;facing=offset.normalized()
   if cooldown<=0 and gun_reload<=0:windup=1.05;cooldown=2.9;warning=director.enemy_warning(position,1.05)
  else:
   windup=0;cancel_warning()
   var point=camp.last_seen if camp.last_seen.is_finite() else (last_known if last_known.is_finite() else route[route_index])
   if position.distance_to(point)>1.1:move_towards(point,delta,1.45)
   else:velocity=Vector3.ZERO;facing=facing.rotated(Vector3.UP,delta*.45)
 else:
  windup=0;alerted=false
  if suspicion>.25 and last_known.is_finite():
   if position.distance_to(last_known)>1.3:move_towards(last_known,delta,1.15)
   else:velocity=Vector3.ZERO;facing=facing.rotated(Vector3.UP,delta*.35)
  else:
   var destination:Vector3=route[route_index]
   if position.distance_to(destination)<.55:
    velocity=Vector3.ZERO;wait_time-=delta
    if wait_time<=0:route_index=(route_index+1)%route.size();wait_time=1.7+float(index)*.3
   else:move_towards(destination,delta,1.10)
 if gun_reload>0 and gun_reload<.01:gun_reload=0
 var row=3 if windup>0 else ([1,0,2,0][int(animation*5)%4] if Vector2(velocity.x,velocity.z).length()>.1 else 0)
 paint(facing,row)
func packet()->Dictionary:
 var out={"position":[position.x,position.y,position.z],"hp":hp,"route_index":route_index,"suspicion":suspicion,"wait":wait_time,"facing":[facing.x,0,facing.z],"bullets":bullets,"reload":gun_reload,"windup":windup,"cooldown":cooldown}
 if last_known.is_finite():out.last_known=[last_known.x,last_known.y,last_known.z]
 return out
