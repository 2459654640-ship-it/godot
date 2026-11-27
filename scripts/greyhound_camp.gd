extends Node
## Each patrol shares sightings only with its own partners.
const Guard=preload("res://scripts/greyhound_guard.gd")
const Expedition=preload("res://scripts/district_expedition.gd")
const ROUTES=[
 [Vector3(34,.04,-8),Vector3(34,.04,-3.5),Vector3(39,.04,-3.5),Vector3(39,.04,-7)],
 [Vector3(52,.04,-8),Vector3(52,.04,-17),Vector3(54,.04,-23)],
 [Vector3(33,.04,-25),Vector3(47,.04,-26),Vector3(50,.04,-26)]
]
var w
var guards:Array=[]
var groups:Dictionary={}
var alarm:bool:
 get:
  for group in groups.values():
   if group.alarm:return true
  return false
var notice:Label
var meter:ProgressBar
var state_key="grey_camp"
var cleared_key="grey_camp_cleared"

func deployment()->Array:
 if w.floor_id=="grey_shelter":
  state_key="grey_shelter_guards";cleared_key="grey_shelter_cleared"
  return [
   {"group":"camp","label":"地下岗哨","role":"sentry","points":[Vector3(-4,.04,-4),Vector3(-3,.04,-1),Vector3(-2,.04,-4)]},
   {"group":"camp","label":"地下岗哨","role":"sentry","points":[Vector3(4,.04,2),Vector3(7,.04,1.5),Vector3(7,.04,-3)]}]
 var specs=[]
 for points in ROUTES:specs.append({"group":"camp","label":"灰狗地表岗哨","role":"sentry","points":points})
 specs.append({"group":"street_scout","label":"灰狗游荡者","role":"scout","points":[Vector3(-26,.04,17),Vector3(-26,.04,27),Vector3(-21,.04,27),Vector3(-21,.04,17)],"transient":true})
 specs.append({"group":"ruin_scout","label":"灰狗游荡者","role":"rifle","points":[Vector3(-51,.04,1),Vector3(-51,.04,-9),Vector3(-44,.04,-11),Vector3(-44,.04,-3)],"transient":true})
 specs.append_array(Expedition.deployment(w.story))
 return specs

func setup(world):
 w=world
 var specs=deployment()
 var saved:Dictionary=w.story.flags.get(state_key,{})
 var prior:Array=saved.get("guards",[])
 var batch=int(w.story.flags.get("raid_index",0))
 var same_batch=int(saved.get("batch",batch))==batch
 var restored=w.combat.enemies.filter(func(e):return e.enemy_kind=="greyhound")
 for i in specs.size():
  var spec:Dictionary=specs[i]
  var name:String=spec.group
  if not groups.has(name):
   var prior_group:Dictionary=saved.get("groups",{}).get(name,{}) if same_batch else {}
   var last:Array=prior_group.get("last_seen",[])
   var old_sighting=Vector3(last[0],last[1],last[2]) if last.size()==3 else Vector3.INF
   groups[name]={"label":spec.label,"guards":[],"alarm":bool(prior_group.get("alarm",false)),"lost":float(prior_group.get("lost",0)),"last_seen":old_sighting}
  var state:Dictionary={}
  if i<prior.size():
   if same_batch:state=prior[i]
   elif not spec.get("transient",false):state={"hp":int(prior[i].get("hp",80))}
  if name=="camp" and w.story.f(cleared_key):state={"hp":0}
  var route=tactical_route(spec.points)
  var guard=Guard.new();w.add_child(guard)
  guard.configure(self,i,route,state,name,spec.role)
  guards.append(guard);groups[name].guards.append(guard)
  # Old combat snapshots stored temporary generic actors. Restore real guards
  # in their place and preserve saved alert/weapon timings.
  for old in restored:
   if int(old.get_meta("loot_index",-1))!=i:continue
   if same_batch and guard.hp>0:
    guard.position=old.position;guard.hp=old.hp
    guard.windup=old.windup;guard.cooldown=old.cooldown
    groups[name].alarm=true
   w.combat.enemies.erase(old);old.collision_layer=0;old.collision_mask=0;old.visible=false;old.queue_free()
  if same_batch and saved.get("alarm",false) and not saved.has("groups") and guard.hp>0 and guard.position.distance_to(w.player.position)<18:
   groups[name].alarm=true
 for name in groups:
  var group:Dictionary=groups[name]
  if group.alarm:engage(group)
 notice=Label.new();notice.position=Vector2(500,105);notice.size=Vector2(600,30)
 notice.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;notice.add_theme_font_size_override("font_size",18)
 notice.add_theme_color_override("font_color",Color("d9bd80"));w.hud.add_child(notice)
 meter=ProgressBar.new();meter.position=Vector2(650,139);meter.size=Vector2(300,8)
 meter.max_value=1;meter.show_percentage=false;w.hud.add_child(meter)
 meter.add_theme_stylebox_override("background",w.hud.style(Color("14201d"),Color("5b6657"),1,2))
 meter.add_theme_stylebox_override("fill",w.hud.style(Color("c6a16a"),Color("c6a16a"),0,2))
 capture()

func tactical_route(points:Array)->Array:
 var route=[]
 for p in points:
  var cell=w.navigation.graph.get_closest_point(Vector2(p.x,p.z))
  if cell<0:continue
  var q:Vector2=w.navigation.graph.get_point_position(cell)
  var clear=Vector3(q.x,.04,q.y)
  if route.is_empty() or w.navigation.graph.get_point_path(w.navigation.graph.get_closest_point(Vector2(route[-1].x,route[-1].z)),cell).size()>0:
   if clear not in route:route.append(clear)
 return points if route.is_empty() else route

func _physics_process(delta):
 if not is_instance_valid(w) or w.hud.modal_visible():
  if is_instance_valid(notice):notice.hide();meter.hide()
  return
 var nearest:Dictionary={}
 var best=INF
 var level=0.0
 for name in groups:
  var group:Dictionary=groups[name]
  var distance=INF
  var suspicion=0.0
  var seen=false
  for guard in group.guards:
   if not is_instance_valid(guard) or guard.hp<=0:continue
   distance=minf(distance,guard.position.distance_to(w.player.position))
   suspicion=maxf(suspicion,guard.suspicion)
   if group.alarm and guard.sees_player():seen=true
  if group.alarm:
   group.lost=0.0 if seen else group.lost+delta
   if group.lost>=9 and distance>9:stand_down(name)
  # A far-away squad doesn't hide a close patrol's warning.
  var score=distance-11 if group.alarm else distance
  if score<best:
   best=score;nearest=group;level=suspicion
 var close=not nearest.is_empty() and best<23
 notice.visible=close
 meter.visible=close and (level>.01 or nearest.alarm)
 if close:
  notice.text=nearest.label+(" · 正在搜查，离开视线" if nearest.alarm else (" · 正在确认动静" if level>.25 else " · 按住 Ctrl 轻步"))
  meter.value=1.0 if nearest.alarm else level
 w.story.context.camp_loot_safe=can_loot()

func engage(group:Dictionary):
 var combat=w.combat
 for guard in group.guards:
  if is_instance_valid(guard) and guard.hp>0 and guard not in combat.enemies:combat.enemies.append(guard)
 if not combat.enemies.is_empty() and not combat.active:
  combat.encounter="grey_camp";combat.active=true

func raise_alarm(name:String,point:Vector3,reason:String):
 var group:Dictionary=groups[name]
 var first=not group.alarm
 group.alarm=true;group.lost=0.0;group.last_seen=point
 engage(group)
 if first:w.hud.toast(group.label+"："+reason+"。",4)

func on_shot():
 var p:Vector3=w.player.position
 for name in groups:
  for guard in groups[name].guards:
   if not is_instance_valid(guard) or guard.hp<=0:continue
   var distance=guard.position.distance_to(p)
   if distance>23 or (distance>7 and not w.combat.sight(guard.position+Vector3.UP,p+Vector3.UP)):continue
   raise_alarm(name,p,"听见了枪声")
   break

func stand_down(name:String):
 var group:Dictionary=groups[name]
 group.alarm=false;group.lost=0.0;group.last_seen=Vector3.INF
 for guard in group.guards:
  if not is_instance_valid(guard):continue
  w.combat.enemies.erase(guard)
  guard.suspicion=0;guard.last_known=Vector3.INF;guard.windup=0;guard.path.clear();guard.repath=0
  guard.alerted=false
  guard.cancel_warning()
 w.combat.patrol_disengaged()
 capture()

func guard_fell(guard):
 var group:Dictionary=groups[guard.squad]
 if group.guards.all(func(other):return not is_instance_valid(other) or other.hp<=0):
  group.alarm=false
  if guard.squad=="camp":
   w.story.flags[cleared_key]=true
   w.story.flags.battle_grey_camp=true
 capture();w.story.changed.emit();w.autosave()

func can_loot()->bool:
 for guard in guards:
  if not is_instance_valid(guard) or guard.hp<=0:continue
  if guard.position.distance_to(w.player.position)<3 or guard.sees_player():return false
 return true

func capture():
 var saved_groups={}
 for name in groups:
  var group:Dictionary=groups[name]
  var entry={"alarm":group.alarm,"lost":group.lost}
  if group.last_seen.is_finite():entry.last_seen=[group.last_seen.x,group.last_seen.y,group.last_seen.z]
  saved_groups[name]=entry
 var saved_guards=[]
 for guard in guards:saved_guards.append(guard.packet() if is_instance_valid(guard) else {"hp":0})
 w.story.flags[state_key]={"batch":int(w.story.flags.get("raid_index",0)),"alarm":alarm,"groups":saved_groups,"guards":saved_guards}
