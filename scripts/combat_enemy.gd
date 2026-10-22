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
func setup(owner_node,p:Vector3,kind:String="mutant"):
 enemy_kind=kind
 director=owner_node;position=p;collision_layer=8;collision_mask=1|2|4|8
 # One faster flanker per encounter, same health and readable bite windup.
 move_speed=1.95 if director.enemies.size()==2 else 1.65
 var shape=CollisionShape3D.new();var capsule=CapsuleShape3D.new();capsule.radius=.27;capsule.height=.75;shape.shape=capsule;shape.position.y=.375;add_child(shape)
 sprite=Sprite3D.new();sprite.name="MutantPainting";sprite.texture=load("res://assets/characters/tunnel_scavenger.png");sprite.hframes=5;sprite.vframes=4;sprite.pixel_size=.0040;sprite.position.y=.47;sprite.billboard=BaseMaterial3D.BILLBOARD_FIXED_Y;sprite.alpha_cut=SpriteBase3D.ALPHA_CUT_DISCARD;sprite.no_depth_test=false;sprite.shaded=true;add_child(sprite)
 if enemy_kind=="soldier":
  sprite.texture=load("res://assets/characters/veteran_masked_combat.png");sprite.hframes=5;sprite.vframes=7;sprite.pixel_size=1.77/324.0;sprite.scale.x=.762;sprite.position.y=1.77*166.0/324.0;shape.position.y=.85;capsule.height=1.70;move_speed=1.35

func damage(amount:int):
 if hp<=0:return
 hp-=amount;sprite.modulate=Color("ffc1a0");get_tree().create_timer(.09).timeout.connect(func():if is_instance_valid(sprite):sprite.modulate=Color.WHITE)
 if hp<=0:
  director.enemy_fell(self);collision_layer=0;collision_mask=0;sprite.rotation.z=.8;sprite.modulate=Color(.42,.4,.38)
  set_physics_process(false);get_tree().create_timer(1.5).timeout.connect(queue_free)
func _physics_process(delta):
 if not is_instance_valid(director) or hp<=0:return
 if director.paused():velocity=Vector3.ZERO;return
 if arrival_time>0:
  arrival_time-=delta;velocity=Vector3.ZERO;return
 cooldown=maxf(0,cooldown-delta);repath-=delta;animation+=delta
 target_body=director.w.player
 if director.veteran_health>0 and is_instance_valid(director.veteran) and position.distance_to(director.veteran.position)<position.distance_to(target_body.position)*.8:target_body=director.veteran
 var offset:Vector3=target_body.position-position;offset.y=0
 if enemy_kind=="soldier":
  soldier_tick(delta,offset);return
 if windup>0:
  windup-=delta
  if windup<=0 and offset.length()<1.15 and director.sight(position+Vector3.UP*.55,target_body.position+Vector3.UP*.55):director.bite(target_body,10)
  velocity.x=move_toward(velocity.x,0,delta*12);velocity.z=move_toward(velocity.z,0,delta*12)
 elif offset.length()<.85 and director.sight(position+Vector3.UP*.55,target_body.position+Vector3.UP*.55):
  velocity.x=0;velocity.z=0
  if cooldown<=0:windup=.42;cooldown=1.6;director.enemy_warning(position)
 else:
  var direction=chase_direction(offset)
  velocity.x=direction.x*move_speed;velocity.z=direction.z*move_speed
 velocity.y=-.2;move_and_slide()
 track_progress(delta)
 var camera=director.w.camera;var forward=offset.normalized();var view=camera.global_basis.z;view.y=0
 var angle=atan2(forward.dot(camera.global_basis.x),forward.dot(view.normalized()));var slot=posmod(roundi(angle/(PI/4)),8);var column=mini(slot,8-slot)
 sprite.flip_h=slot>4
 var row=3 if windup>0 else (1+int(animation*7)%2 if get_position_delta().length()>.001 else 0)
 sprite.frame=row*5+column

func soldier_tick(delta:float,offset:Vector3):
 var in_sight=offset.length()<13 and director.sight(position+Vector3.UP*.8,target_body.position+Vector3.UP*.8)
 if windup>0:
  windup=maxf(0,windup-delta);velocity=Vector3.ZERO
  if windup<=0 and in_sight:
   var origin=position+Vector3.UP*.8;var target=target_body.position+Vector3.UP*.75
   var result=director.cast(origin,target)
   director.tracer(origin,result.get("position",target),true)
   if result.is_empty() or result.get("collider")==target_body:director.bite(target_body,12)
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
