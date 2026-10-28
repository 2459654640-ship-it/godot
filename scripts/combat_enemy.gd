extends CharacterBody3D
var director
var hp=62
var cooldown=0.0
var windup=0.0
var target_body
var path=PackedVector3Array()
var repath=0.0
var animation=0.0
var arrival_time=.9
var move_speed=1.65
var material:StandardMaterial3D
var sprite:Sprite3D
var enemy_kind="mutant"
var blocked_time=0.0
var attack_direction=Vector3.FORWARD
var charge_time=0.0
var recovery=0.0
var hurt_time=0.0
var charge_hit=false
var warning
var boss_mode="charge"
var boss_round=0
const Catalog=preload("res://scripts/monster_catalog.gd")
func setup(owner_node,p:Vector3,kind:String="mutant"):
 enemy_kind=kind
 director=owner_node;position=p;collision_layer=8;collision_mask=1|2|4|8
 # One faster flanker per encounter, same health and readable bite windup.
 move_speed=1.95 if director.enemies.size()==2 else 1.65
 var shape=CollisionShape3D.new();var capsule=CapsuleShape3D.new();capsule.radius=.27;capsule.height=.75;shape.shape=capsule;shape.position.y=.375;add_child(shape)
 sprite=Sprite3D.new();sprite.name="MutantPainting";sprite.texture=load("res://assets/characters/tunnel_scavenger.png");sprite.hframes=5;sprite.vframes=4;sprite.pixel_size=.0040;sprite.position.y=.47;sprite.billboard=BaseMaterial3D.BILLBOARD_FIXED_Y;sprite.alpha_cut=SpriteBase3D.ALPHA_CUT_DISCARD;sprite.no_depth_test=false;sprite.shaded=true;add_child(sprite)
 if enemy_kind in ["pouncer","spitter","behemoth"]:
  var spec=Catalog.get_kind(enemy_kind)
  hp=spec.hp;move_speed=spec.speed;capsule.height=spec.height;capsule.radius=spec.radius;shape.position.y=spec.height/2
  sprite.texture=load("res://assets/characters/"+spec.texture+".png");sprite.vframes=spec.rows;sprite.pixel_size=spec.pixel;sprite.position.y=spec.center
 if enemy_kind=="soldier":
  sprite.texture=load("res://assets/characters/veteran_masked_combat.png");sprite.hframes=5;sprite.vframes=7;sprite.pixel_size=1.77/324.0;sprite.scale.x=.762;sprite.position.y=1.77*166.0/324.0;shape.position.y=.85;capsule.height=1.70;move_speed=1.35
 if enemy_kind=="greyhound":
  sprite.texture=load("res://assets/characters/greyhound_guard.png");sprite.hframes=5;sprite.vframes=4;sprite.pixel_size=1.76/324.0;sprite.scale.x=.762;sprite.position.y=1.76*166.0/324.0;shape.position.y=.85;capsule.height=1.70;hp=80;move_speed=1.1

func cancel_warning():
 if is_instance_valid(warning):warning.queue_free()
 warning=null
func damage(amount:int,from_player:bool=false):
 if hp<=0:return
 hp-=roundi(amount*1.35) if enemy_kind=="behemoth" and recovery>1 else amount;hurt_time=.13
 if from_player:director.confirm_hit(position+Vector3.UP*.5,hp<=0)
 if hp<=0:
  cancel_warning();director.enemy_fell(self);collision_layer=0;collision_mask=0
  if enemy_kind in ["pouncer","spitter","behemoth"]:sprite.frame=30+sprite.frame%5
  else:sprite.rotation.z=.8
  sprite.modulate=Color(.62,.6,.57);set_physics_process(false);get_tree().create_timer(2.5).timeout.connect(queue_free)
 elif enemy_kind in ["pouncer","spitter"] and windup>0:
  cancel_warning();windup=0;recovery=.45;cooldown=maxf(cooldown,1.6)
func _exit_tree():cancel_warning()
func attack_state()->Dictionary:
 return {"direction":[attack_direction.x,attack_direction.y,attack_direction.z],"charge":charge_time,"recovery":recovery,"hurt":hurt_time,"hit":charge_hit,"boss_mode":boss_mode,"boss_round":boss_round}
func restore_attack(state:Dictionary):
 var d=state.get("direction",[0,0,-1]);attack_direction=Vector3(d[0],d[1],d[2]);charge_time=float(state.get("charge",0));recovery=float(state.get("recovery",0));hurt_time=float(state.get("hurt",0));charge_hit=state.get("hit",false)
 boss_mode=state.get("boss_mode","charge");boss_round=int(state.get("boss_round",0))
 if windup>0:warning=director.enemy_warning(position,windup,position+attack_direction*(7.6 if enemy_kind=="behemoth" else 2.45),"charge" if enemy_kind=="behemoth" and boss_mode=="charge" else ("pounce" if enemy_kind=="pouncer" else "bite"))
func _physics_process(delta):
 if not is_instance_valid(director) or hp<=0:return
 if director.paused():velocity=Vector3.ZERO;return
 if arrival_time>0:
  arrival_time-=delta;velocity=Vector3.ZERO;return
 cooldown=maxf(0,cooldown-delta);repath-=delta;animation+=delta;hurt_time=maxf(0,hurt_time-delta)
 target_body=director.w.player
 if director.veteran_health>0 and is_instance_valid(director.veteran) and position.distance_to(director.veteran.position)<position.distance_to(target_body.position)*.8:target_body=director.veteran
 var offset:Vector3=target_body.position-position;offset.y=0
 if enemy_kind=="behemoth":
  boss_tick(delta,offset);return
 if enemy_kind=="soldier":
  soldier_tick(delta,offset);return
 if enemy_kind in ["pouncer","spitter"]:
  special_tick(delta,offset);return
 if windup>0:
  windup-=delta
  if windup<=0 and offset.length()<1.15 and director.sight(position+Vector3.UP*.55,target_body.position+Vector3.UP*.55):director.bite(target_body,10)
  velocity.x=move_toward(velocity.x,0,delta*12);velocity.z=move_toward(velocity.z,0,delta*12)
 elif offset.length()<.85 and director.sight(position+Vector3.UP*.55,target_body.position+Vector3.UP*.55):
  velocity.x=0;velocity.z=0
  if cooldown<=0:windup=.55;cooldown=1.6;warning=director.enemy_warning(position,.55)
 else:
  var direction=chase_direction(offset)
  velocity.x=direction.x*move_speed;velocity.z=direction.z*move_speed
 velocity.y=-.2;move_and_slide()
 track_progress(delta)
 var camera=director.w.camera;var forward=offset.normalized();var view=camera.global_basis.z;view.y=0
 var angle=atan2(forward.dot(camera.global_basis.x),forward.dot(view.normalized()));var slot=posmod(roundi(angle/(PI/4)),8);var column=mini(slot,8-slot)
 sprite.flip_h=slot>4
 var row=3 if windup>0 else ([1,0,2,0][int(animation*8)%4] if get_position_delta().length()>.001 else 0)
 sprite.frame=row*5+column

func special_tick(delta:float,offset:Vector3):
 var visible_target=director.sight(position+Vector3.UP*.55,target_body.position+Vector3.UP*.55)
 var facing=offset.normalized()
 velocity=Vector3.ZERO
 if recovery>0:recovery=maxf(0,recovery-delta)
 elif charge_time>0:
  facing=attack_direction
  velocity=attack_direction*5.3
  charge_time=maxf(0,charge_time-delta)
  velocity.y=-.2;move_and_slide()
  for i in get_slide_collision_count():
   var collision=get_slide_collision(i)
   if absf(collision.get_normal().y)>.7:continue
   var body=collision.get_collider()
   if not charge_hit and (body==director.w.player or body==director.veteran):director.bite(body,12,"扑击");charge_hit=true
   charge_time=0
  if not charge_hit and offset.length()<.9 and visible_target:director.bite(target_body,12,"扑击");charge_hit=true
  if charge_time<=0:recovery=.7
  paint(facing,4);return
 elif windup>0:
  facing=attack_direction;windup=maxf(0,windup-delta)
  if windup<=0:
   cancel_warning()
   if enemy_kind=="pouncer":charge_time=.42;charge_hit=false
   else:
    director.launch_projectile(position+Vector3.UP*.55+attack_direction*.42,attack_direction);recovery=.38
 elif cooldown<=0 and visible_target and offset.length()<(3.2 if enemy_kind=="pouncer" else 7.0):
  attack_direction=offset.normalized();windup=.9 if enemy_kind=="pouncer" else .95;cooldown=2.6 if enemy_kind=="pouncer" else 3.0
  warning=director.enemy_warning(position,windup,position+attack_direction*2.45,"pounce" if enemy_kind=="pouncer" else "bite")
  director.creature_cue(enemy_kind)
 else:
  var direction=Vector3.ZERO
  if enemy_kind=="spitter" and visible_target and offset.length()<3.5:
   var away=-offset.normalized()
   if clear_motion(away*.6):direction=away
   else:
    for angle in [PI/2,-PI/2]:
     var side=away.rotated(Vector3.UP,angle)
     if clear_motion(side*.6):direction=side;break
  elif enemy_kind=="pouncer" or not visible_target or offset.length()>6:direction=chase_direction(offset)
  velocity=direction*move_speed
 velocity.y=-.2;move_and_slide();track_progress(delta)
 var row=0
 if get_position_delta().length()>.002:row=[1,0,2,0][int(animation*8)%4]
 if windup>0:row=3
 elif recovery>0:row=4 if recovery>.2 else 0
 if hurt_time>0:row=5
 paint(facing,row)
func paint(forward:Vector3,row:int):
 var camera=director.w.camera;var view=camera.global_basis.z;view.y=0
 var angle=atan2(forward.dot(camera.global_basis.x),forward.dot(view.normalized()));var slot=posmod(roundi(angle/(PI/4)),8)
 sprite.flip_h=slot>4;sprite.frame=row*5+mini(slot,8-slot)

func soldier_tick(delta:float,offset:Vector3):
 var in_sight=offset.length()<13 and director.sight(position+Vector3.UP*.8,target_body.position+Vector3.UP*.8)
 if windup>0:
  windup=maxf(0,windup-delta);velocity=Vector3.ZERO
  if windup<=0 and in_sight:
   var origin=position+Vector3.UP*.8;var target=target_body.position+Vector3.UP*.75
   var result=director.cast(origin,target)
   director.tracer(origin,result.get("position",target),true)
   if result.is_empty() or result.get("collider")==target_body:director.bite(target_body,12,"射击")
   director.w.get_node("/root/Session").sound("rifle")
 elif in_sight and offset.length()>2:
  velocity=Vector3.ZERO
  if cooldown<=0:windup=.85;cooldown=2.7;director.enemy_warning(position)
 else:
  var direction=chase_direction(offset)
  velocity=direction*move_speed
 velocity.y=-.2;move_and_slide()
 track_progress(delta)
 var camera=director.w.camera;var view=camera.global_basis.z;view.y=0
 var angle=atan2(offset.dot(camera.global_basis.x),offset.dot(view.normalized()));var slot=posmod(roundi(angle/(PI/4)),8)
 sprite.flip_h=slot>4
 var walk_row=[3,0,4,0][int(animation*6)%4] if Vector2(velocity.x,velocity.z).length()>.1 else 0
 sprite.frame=walk_row*5+mini(slot,8-slot)

func clear_motion(motion:Vector3)->bool:
 motion.y=0
 return not test_move(global_transform,motion)

func chase_direction(offset:Vector3)->Vector3:
 if repath<=0:
  path=director.enemy_path(position,target_body.position);repath=.65
 # Only skip a waypoint if the actual capsule can reach the next one. A large
 # arrival radius cut across corners and sent creatures into their cover.
 while not path.is_empty():
  var step=path[0]-position;step.y=0
  if step.length()<.08:path.remove_at(0)
  elif path.size()>1 and clear_motion(path[1]-position):path.remove_at(0)
  else:break
 var direction=Vector3.ZERO
 if not path.is_empty():direction=path[0]-position;direction.y=0;direction=direction.normalized()
 elif offset.length()>.7 and clear_motion(offset.normalized()*maxf(0,offset.length()-.7)):direction=offset.normalized()
 if direction==Vector3.ZERO:return direction
 # Keep separation inside walkable space. Pushing away from another creature
 # must not push this one into a wall or override the route around a corner.
 var separated=direction
 for other in director.enemies:
  if other==self or not is_instance_valid(other) or other.hp<=0:continue
  var apart=position-other.position;apart.y=0
  if apart.length()<.75:separated+=apart.normalized()*.35
 if separated.length()>.1 and clear_motion(separated.normalized()*.5):return separated.normalized()
 if clear_motion(direction*.25):return direction
 # Temporary body congestion: slide aside, then rejoin the route. Never warp
 # through scenery, and never fall back to charging through an unreachable wall.
 for angle in [PI/4,-PI/4,PI/2,-PI/2]:
  var aside=direction.rotated(Vector3.UP,angle)
  if clear_motion(aside*.45):return aside
 return Vector3.ZERO

func track_progress(delta:float):
 if windup<=0 and Vector2(velocity.x,velocity.z).length()>.1 and get_position_delta().length()<move_speed*delta*.15:blocked_time+=delta
 else:blocked_time=0
 if blocked_time>.4:repath=0;path.clear();blocked_time=0

func boss_tick(delta:float,offset:Vector3):
 var visible=director.sight(position+Vector3.UP*.7,target_body.position+Vector3.UP*.7)
 var facing=attack_direction if windup>0 or charge_time>0 else offset.normalized()
 velocity=Vector3.ZERO
 if recovery>0:recovery=maxf(0,recovery-delta)
 elif charge_time>0:
  velocity=attack_direction*6.3;velocity.y=-.2;move_and_slide();charge_time=maxf(0,charge_time-delta)
  for i in get_slide_collision_count():
   var hit=get_slide_collision(i)
   if absf(hit.get_normal().y)>.7:continue
   var body=hit.get_collider()
   if not charge_hit and (body==director.w.player or body==director.veteran):director.bite(body,24,"冲撞");charge_hit=true
   charge_time=0;recovery=2.4;director.impact_effect(position+Vector3.UP*.6,true)
  if not charge_hit and offset.length()<1.3 and visible:director.bite(target_body,24,"冲撞");charge_hit=true
  if charge_time<=0:recovery=maxf(recovery,1.1)
  paint(facing,4);return
 elif windup>0:
  windup=maxf(0,windup-delta)
  if windup<=0:
   cancel_warning()
   if boss_mode=="charge":charge_time=1.2;charge_hit=false
   elif boss_mode=="spit":
    for angle in [-.24,0,.24]:director.launch_projectile(position+Vector3.UP*.75+attack_direction*.65,attack_direction.rotated(Vector3.UP,angle))
    recovery=1.2
   else:
    if offset.length()<1.8 and visible:director.bite(target_body,18,"重击")
    recovery=1.0
 elif cooldown<=0 and visible and offset.length()<12:
  attack_direction=offset.normalized();boss_round+=1
  boss_mode="bite" if offset.length()<1.6 else ("spit" if hp<230 and boss_round%2==0 else "charge")
  windup=1.25 if boss_mode=="charge" else 1.05;cooldown=3.6
  warning=director.enemy_warning(position,windup,position+attack_direction*7.6,"charge" if boss_mode=="charge" else "bite")
  director.w.get_node("/root/Session").sound("creature_warn")
 else:velocity=chase_direction(offset)*move_speed
 velocity.y=-.2;move_and_slide();track_progress(delta)
 var row=[1,0,2,0][int(animation*6)%4] if get_position_delta().length()>.002 else 0
 if windup>0:row=3
 elif recovery>.8:row=5
 paint(facing,row)
