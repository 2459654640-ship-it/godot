extends Node
## Room-sized realtime encounters with exact, non-punitive pre-fight rollback.
const Enemy=preload("res://scripts/combat_enemy.gd")
var w
var enabled=false
var encounters:Dictionary={}
var active=false
var defeated=false
var encounter=""
var enemies:Array=[]
var veteran
var veteran_health=100
var veteran_down=false
var rescue=0.0
var checkpoint:Dictionary={}
var clip=6
var cooldown=0.0
var reload_time=0.0
var veteran_cooldown=0.0
var veteran_clip=5
var veteran_reload=0.0
var aim=Vector3.ZERO
var clock=0.0
var label:Label
var reticle:Control
var next_path=0.0
var veteran_path=PackedVector3Array()
var enemy_navigation=preload("res://scripts/route_grid.gd").new()
var enemy_navigation_revision=-1
const ENCOUNTERS={
 "pump":{"rect":Rect2(-19,-14,13,14),"need":"plant_diagram","skip":"plant_bled","name":"泵房的动静","spawns":[Vector3(-17,.04,-6),Vector3(-8,.04,-9),Vector3(-8,.04,-3)]},
 "workshop":{"rect":Rect2(-6,-10,11,10),"need":"plant_bled","skip":"plant_fuse","name":"修配间的巢穴","spawns":[Vector3(-3,.04,-8),Vector3(3,.04,-8),Vector3(2,.04,-2)]},
 "warehouse":{"rect":Rect2(5,-14,14,14),"need":"plant_power","skip":"water_secured","name":"封存仓库","spawns":[Vector3(8,.04,-5),Vector3(15,.04,-5),Vector3(12,.04,-11),Vector3(17,.04,-2)]}}
func setup(world):
 w=world;enabled=w.floor_id in ["waterworks","surface","railfront"];encounters=preload("res://scripts/surface_site.gd").ENCOUNTERS if w.floor_id=="surface" else ENCOUNTERS
 if w.floor_id=="railfront":encounters=preload("res://scripts/frontline.gd").encounters(w.story)
 if not enabled:return
 veteran=w.npcs.get("plant_veteran")
 if is_instance_valid(veteran):veteran.combat_controlled=true
 if w.floor_id=="waterworks" and not w.story.f("weapon_issued"):
  w.story.flags.weapon_issued=true;w.story.give("revolver");w.story.economy.handmade+=18
  w.story.economy.goods.bandage=int(w.story.economy.goods.get("bandage",0))+2
  w.story.economy.goods.antirad=int(w.story.economy.goods.get("antirad",0))+1
  w.hud.toast("老兵递来左轮、18 发土制弹与药品。左轮已放入武器栏：按 1 拔枪 / 收枪，I 可更换装备。",10)
 clip=int(w.story.flags.get("weapon_clip",6));veteran_health=int(w.story.flags.get("veteran_health",100))
 label=Label.new();label.position=Vector2(420,855);label.size=Vector2(800,35);label.add_theme_font_size_override("font_size",19);label.add_theme_color_override("font_color",Color("dec99d"));w.hud.add_child(label)
 var backing=StyleBoxFlat.new();backing.bg_color=Color(.025,.045,.04,.94);backing.border_color=Color("776b4f");backing.set_border_width_all(1);backing.set_corner_radius_all(3);backing.content_margin_left=10;backing.content_margin_right=10;backing.content_margin_top=5;backing.content_margin_bottom=5;label.add_theme_stylebox_override("normal",backing)
 reticle=Control.new();reticle.mouse_filter=Control.MOUSE_FILTER_IGNORE;w.hud.add_child(reticle)
 for offset in [Vector2(-9,0),Vector2(4,0),Vector2(0,-9),Vector2(0,4)]:
  var line=ColorRect.new();line.color=Color("dbc7a0");line.position=offset;line.size=Vector2(5,1) if offset.y==0 else Vector2(1,5);line.mouse_filter=Control.MOUSE_FILTER_IGNORE;reticle.add_child(line)
func paused()->bool:return not enabled or w.hud.modal_visible() or w.departure_animating
func enemy_path(from:Vector3,to:Vector3)->PackedVector3Array:
 # Creatures cannot use the player's small-step controller. Curbs, pool rims
 # and low cargo therefore need a route around them, not one over them.
 # Door animations rebuild the world grid; refresh this grid at that revision.
 if enemy_navigation_revision!=w.navigation.revision:
  enemy_navigation.setup(w,.06);enemy_navigation_revision=w.navigation.revision
 return enemy_navigation.path(from,to)
func _physics_process(delta):
 if not enabled:return
 if defeated:
  label.hide();reticle.hide()
  if not w.hud.modal_visible():w.hud.show_combat_defeat()
  return
 label.visible=not w.hud.modal_visible();reticle.visible=label.visible and active and w.story.weapon_drawn()
 if paused():
  if is_instance_valid(veteran):veteran.combat_velocity=Vector3.ZERO
  return
 clock+=delta;cooldown=maxf(0,cooldown-delta);veteran_cooldown=maxf(0,veteran_cooldown-delta)
 reticle.position=w.hud.get_local_mouse_position()
 var point=w.camera.project_ray_origin(w.get_viewport().get_mouse_position());var ray=w.camera.project_ray_normal(w.get_viewport().get_mouse_position())
 var hit=Plane(Vector3.UP,.62).intersects_ray(point,ray)
 if hit!=null:aim=hit
 if Input.is_action_just_pressed("reload") and w.story.weapon_drawn():reload_weapon()
 w.player.aim_direction=aim-w.player.position if w.story.weapon_drawn() else Vector3.ZERO
 if active:
  if Input.is_action_pressed("shoot") and cooldown<=0 and reload_time<=0:shoot()
 else:
  for id in encounters:
   var e:Dictionary=encounters[id]
   if (w.floor_id!="waterworks" or not w.story.f("water_secured")) and not w.story.f("battle_"+id) and not w.story.f(e.skip) and w.story.f(e.need) and e.rect.has_point(Vector2(w.player.position.x,w.player.position.z)):begin(id);break
 if reload_time>0:
  reload_time=maxf(0,reload_time-delta)
  if reload_time<=0:
   var rounds=mini(6-clip,int(w.story.economy.handmade));clip+=rounds;w.story.economy.handmade-=rounds;sync()
 follow_veteran(delta)
 if veteran_health<=0 and is_instance_valid(veteran):
  var near=w.player.position.distance_to(veteran.position)<1.65
  rescue=rescue+delta if near and Input.is_action_pressed("interact") else 0
  if rescue>=2:veteran_health=45;veteran_down=false;rescue=0;w.hud.toast("老兵重新站起，握住了步枪。",4);sync()
 var radiation=" · 辐射 %d"%w.story.economy.radiation if w.story.economy.radiation>0 else ""
 label.text=("武器栏空置 · I 装备武器" if w.story.equipped_weapon()=="" else ("装填中… %.1f"%reload_time if reload_time>0 else (("左轮 %d / 6 · 土制弹 %d"%[clip,w.story.economy.handmade])+ (" · 1 收枪" if w.story.weapon_drawn() else " · 1 拔枪"))))+("  /  老兵 "+("倒地：靠近并按住 E 2 秒" if veteran_health<=0 else "%d"%veteran_health) if is_instance_valid(veteran) else "")+radiation
 if rescue>0:label.text+="  救援 %d%%"%int(rescue*50)
 if w.floor_id=="waterworks" and Rect2(-19,-14,7,7).has_point(Vector2(w.player.position.x,w.player.position.z)) and not w.story.f("radiation_warned"):
  w.story.flags.radiation_warned=true;w.hud.toast("旧沉积物带有辐射，尽量绕开西北角的污泥积水。抗辐射药可在背包使用。",7)
 # Exposure only while moving near contaminated sediment; never while reading.
 if w.floor_id=="waterworks" and Rect2(-18,-13,5,5).has_point(Vector2(w.player.position.x,w.player.position.z)) and Vector2(w.player.velocity.x,w.player.velocity.z).length()>.2:
  var exposure=float(w.story.flags.get("radiation_clock",0))+delta
  if exposure>=5:
   exposure-=5;w.story.economy.radiation=mini(60,w.story.economy.radiation+2)
   if not w.story.f("radiation_warned"):w.story.flags.radiation_warned=true;w.hud.toast("脚边是带放射性沉积物的积水。离开这片区域；抗辐射药可在背包使用。",7)
  w.story.flags.radiation_clock=exposure
func sync():
 w.story.flags.weapon_clip=clip;w.story.flags.veteran_health=veteran_health;w.story.changed.emit()
func begin(id:String):
 if active or w.story.f("battle_"+id):return
 encounter=id
 # Visible field ammunition left by the squad prevents resource softlocks.
 var missing=maxi(0,encounters[id].spawns.size()*4-int(w.story.economy.handmade)-clip)
 if missing>0 and w.floor_id in ["waterworks","railfront"]:w.story.economy.handmade+=missing;w.hud.toast("从小队随身弹袋补入 %d 发土制弹。"%missing,5)
 sync();checkpoint=w.save_snapshot().duplicate(true);w.autosave()
 active=true
 if w.floor_id=="railfront":w.sync_event_music("frontline_theme")
 for p in encounters[id].spawns:
  var enemy=Enemy.new();w.add_child(enemy);enemy.setup(self,w.clear_arrival(p),encounters[id].get("enemy_kind","mutant"));enemy.set_meta("loot_key",id+"_"+str(enemies.size()));enemy.set_meta("loot_index",enemies.size());enemies.append(enemy)
 w.hud.toast(encounters[id].name+" · "+("1 拔枪 · " if not w.story.weapon_drawn() else "")+"左键射击 / R 换弹；先清理威胁，再操作设备。",7)
func reload_weapon():
 if reload_time>0 or clip>=6:return
 if int(w.story.economy.handmade)<=0:w.hud.toast("土制弹已用完。可救起老兵，或从暂停页重试本场战斗。",5);return
 reload_time=1.55;w.get_node("/root/Session").sound("reload")
func shoot()->bool:
 if paused() or not active or cooldown>0 or reload_time>0:return false
 if not w.story.weapon_drawn():
  cooldown=.8;w.hud.toast("武器栏为空，先在背包装备左轮。" if w.story.equipped_weapon()=="" else "武器已收起，按 1 拔枪。可在背包中查看武器栏。",3);return false
 if clip<=0:reload_weapon();return false
 clip-=1;cooldown=.36 if w.story.f("weapon_serviced") else .42;sync()
 var origin=w.player.position+Vector3.UP*.72
 var direction=aim-origin;direction.y=clampf(direction.y,-.08,.08)
 if direction.length()<.1:direction=-w.player.visual.global_basis.z;direction.y=0
 direction=direction.normalized()
 var result=cast(origin,origin+direction*25)
 if not result.is_empty() and result.collider.has_method("damage"):result.collider.damage(32)
 tracer(origin,result.get("position",origin+direction*25),false)
 w.player.visual.get_node("Painter").react("shot")
 w.get_node("/root/Session").sound("shot");return true
func cast(from:Vector3,to:Vector3)->Dictionary:
 return w.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(from,to,1|8))
func sight(from:Vector3,to:Vector3)->bool:
 return w.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(from,to,1)).is_empty()
func follow_veteran(delta:float):
 if veteran_reload>0:
  veteran_reload=maxf(0,veteran_reload-delta)
  if veteran_reload<=0:veteran_clip=5
 if not is_instance_valid(veteran):return
 veteran.combat_velocity=Vector3.ZERO
 if veteran_health<=0:veteran.animation_state="down";return
 # Make room at narrow doors even when his ordinary follow distance would
 # leave him standing still directly in the player's path.
 var away:Vector3=veteran.position-w.player.position;away.y=0
 var driving=(w.player.use_override and w.player.motion_override.length()>.1) or Input.get_vector("move_left","move_right","move_up","move_down").length()>.1 or w.player.velocity.dot(away)>.05
 if away.length()<1.10 and driving and veteran.yield_time<=0:
  var side=Vector3(-away.z,0,away.x).normalized()
  for candidate in [side,-side,away.normalized()]:
   if candidate.length()>.1 and not veteran.test_move(veteran.global_transform,candidate*.7):
    veteran.yield_direction=candidate;veteran.yield_time=.5;break
 var point=w.player.position-w.camera.global_basis.x.normalized()*1.5
 if veteran.yield_time>0:
  veteran.yield_time=maxf(0,veteran.yield_time-delta);veteran.combat_velocity=veteran.yield_direction*1.4
 elif veteran.position.distance_to(point)>1.8:
  next_path-=delta
  if next_path<=0:veteran_path=w.navigation.path(veteran.position,point);next_path=.45
  while not veteran_path.is_empty() and veteran.position.distance_to(veteran_path[0])<.5:veteran_path.remove_at(0)
  if not veteran_path.is_empty():veteran.combat_velocity=(veteran_path[0]-veteran.position).normalized()*2.2
 var closest=null;var distance=14.0
 for enemy in enemies:
  if not is_instance_valid(enemy) or enemy.hp<=0:continue
  var d=veteran.position.distance_to(enemy.position)
  if d<distance and sight(veteran.position+Vector3.UP*.65,enemy.position+Vector3.UP*.55):closest=enemy;distance=d
 if closest:
  veteran.aim_direction=closest.position-veteran.position
  if veteran_cooldown<=0 and veteran_reload<=0:
   veteran_cooldown=1.05;veteran_clip-=1
   if veteran_clip<=0:veteran_reload=2.3
   var origin=veteran.position+Vector3.UP*.7;var result=cast(origin,closest.position+Vector3.UP*.5)
   if not result.is_empty() and result.collider.has_method("damage"):result.collider.damage(25)
   tracer(origin,result.get("position",closest.position+Vector3.UP*.5),true)
   veteran.visual.get_node("Painter").react("shot");w.get_node("/root/Session").sound("rifle")
 else:veteran.aim_direction=Vector3.ZERO
func bite(body,amount:int):
 if body==veteran:
  veteran_health=maxi(0,veteran_health-amount);veteran_down=veteran_health<=0;sync()
 else:
  w.story.economy.health=maxi(0,w.story.economy.health-amount);w.story.changed.emit();w.hud.toast("遭到撕咬 · -%d 生命"%amount,1.2)
  if w.story.economy.health<=0:
   defeated=true;w.player.blocked=true;w.hud.show_combat_defeat()
func enemy_fell(enemy):
 if w.floor_id=="surface":preload("res://scripts/surface_site.gd").drop(w,enemy)
 enemies.erase(enemy)
 if enemies.is_empty():
  active=false;w.story.flags["battle_"+encounter]=true;sync();w.autosave()
  if w.floor_id=="railfront":w.sync_event_music("")
  w.hud.toast("周围安静下来。可以检查设备、包扎伤口，再继续前进。",5)
func retry():
 if checkpoint.is_empty():return
 var p=checkpoint.position
 w.get_node("/root/Session").enter(checkpoint,checkpoint.floor,Vector3(p[0],p[1],p[2]))
func enemy_warning(p:Vector3):
 var light=OmniLight3D.new();light.position=p+Vector3.UP*.7;light.light_color=Color("bd6748");light.light_energy=.45;light.omni_range=1.4;w.add_child(light);get_tree().create_timer(.35).timeout.connect(light.queue_free)
func tracer(from:Vector3,to:Vector3,rifle:bool):
 var beam=MeshInstance3D.new();var mesh=ImmediateMesh.new();beam.mesh=mesh;var mat=StandardMaterial3D.new();mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;mat.albedo_color=Color("d0ab6b") if rifle else Color("ead4a0");beam.material_override=mat
 mesh.surface_begin(Mesh.PRIMITIVE_LINES);mesh.surface_add_vertex(from);mesh.surface_add_vertex(to);mesh.surface_end();w.add_child(beam);get_tree().create_timer(.06).timeout.connect(beam.queue_free)
