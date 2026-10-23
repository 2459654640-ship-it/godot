extends Node
## A persistent inhabited bandit camp: patrol, suspicion, search, combat, disengagement.
const Guard=preload("res://scripts/greyhound_guard.gd")
var w
var guards:Array=[]
var alarm=false
var lost_time=0.0
var last_seen=Vector3.INF
var checkpoint:Dictionary={}
var notice:Label
var meter:ProgressBar
const ROUTES=[
 [Vector3(34,.04,-8),Vector3(34,.04,-3.5),Vector3(39,.04,-3.5),Vector3(39,.04,-7)],
 [Vector3(52,.04,-8),Vector3(52,.04,-17),Vector3(54,.04,-23)],
 [Vector3(33,.04,-25),Vector3(47,.04,-26),Vector3(50,.04,-26)]
]
func setup(world):
 w=world
 var saved:Dictionary=w.story.flags.get("grey_camp",{})
 alarm=saved.get("alarm",false);lost_time=float(saved.get("lost_time",0))
 var last=saved.get("last_seen",[])
 if last.size()==3:last_seen=Vector3(last[0],last[1],last[2])
 var prior:Array=saved.get("guards",[])
 # Combat restore first recreates physics actors; replace only these new
 # guards with their perception controller, preserving exact gun timers/HP.
 var restored=w.combat.enemies.filter(func(e):return e.enemy_kind=="greyhound")
 for i in ROUTES.size():
  var state:Dictionary=prior[i] if i<prior.size() else {}
  if w.story.f("grey_camp_cleared") and state.is_empty():state={"hp":0}
  var guard=Guard.new();w.add_child(guard);guard.configure(self,i,ROUTES[i],state);guards.append(guard)
  var match_guard=restored.filter(func(e):return int(e.get_meta("loot_index",-1))==i)
  if not match_guard.is_empty():
   var old=match_guard[0];guard.position=old.position;guard.hp=old.hp;guard.windup=old.windup;guard.cooldown=old.cooldown
   var slot=w.combat.enemies.find(old);w.combat.enemies[slot]=guard;old.collision_layer=0;old.collision_mask=0;old.visible=false;old.queue_free();alarm=true
 if alarm:
  w.combat.active=true
  if w.combat.encounter=="":w.combat.encounter="grey_camp"
  for guard in guards:
   if guard.hp>0 and guard not in w.combat.enemies:w.combat.enemies.append(guard)
 notice=Label.new();notice.position=Vector2(550,105);notice.size=Vector2(500,30);notice.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;notice.add_theme_font_size_override("font_size",18);notice.add_theme_color_override("font_color",Color("d9bd80"));w.hud.add_child(notice)
 meter=ProgressBar.new();meter.position=Vector2(650,139);meter.size=Vector2(300,8);meter.max_value=1;meter.show_percentage=false;w.hud.add_child(meter)
 meter.add_theme_stylebox_override("background",w.hud.style(Color("14201d"),Color("5b6657"),1,2));meter.add_theme_stylebox_override("fill",w.hud.style(Color("c6a16a"),Color("c6a16a"),0,2))
 capture()
func _physics_process(delta):
 if not is_instance_valid(w) or w.hud.modal_visible():
  if is_instance_valid(notice):notice.visible=false;meter.visible=false
  return
 var live=guards.filter(func(g):return is_instance_valid(g) and g.hp>0)
 if live.is_empty():notice.visible=false;meter.visible=false;w.story.context.camp_loot_safe=true;return
 var distance=INF;var level=0.0
 for g in live:distance=minf(distance,g.position.distance_to(w.player.position));level=maxf(level,g.suspicion)
 if checkpoint.is_empty() and distance<24 and not alarm:checkpoint=w.save_snapshot().duplicate(true)
 notice.visible=distance<24 or alarm;meter.visible=notice.visible and (level>.01 or alarm)
 notice.text="灰狗正在搜查 · 利用遮挡离开视线" if alarm else ("守卫正在确认动静" if level>.25 else ("轻步潜行 · 降低脚步声，留意守卫朝向" if w.player.sneaking else "灰狗营地 · 按住 Ctrl 轻步潜行"))
 meter.value=1 if alarm else level
 if alarm:
  lost_time+=delta
  if live.any(func(g):return g.sees_player()):lost_time=0
  if lost_time>=10 and distance>10:stand_down()
 w.story.context.camp_loot_safe=can_loot()
func raise_alarm(reason:String):
 if alarm:return
 if checkpoint.is_empty():checkpoint=w.save_snapshot().duplicate(true)
 alarm=true;lost_time=0;last_seen=w.player.position
 var c=w.combat
 if not c.active:
  c.checkpoint=checkpoint.duplicate(true);c.encounter="grey_camp";c.active=true
 for guard in guards:
  if guard.hp>0 and guard not in c.enemies:c.enemies.append(guard)
 capture();w.hud.toast(reason+"。可以借掩体交战，或拉开距离藏好。",6)
func on_shot():
 if guards.any(func(g):return is_instance_valid(g) and g.hp>0 and g.position.distance_to(w.player.position)<25):raise_alarm("营地的守卫听见了枪声")
func stand_down():
 alarm=false;lost_time=0
 for guard in guards:
  if guard in w.combat.enemies:w.combat.enemies.erase(guard)
  guard.suspicion=0;guard.last_known=Vector3.INF;guard.windup=0;guard.path.clear();guard.repath=0
  guard.cancel_warning()
 if w.combat.enemies.is_empty():
  w.combat.active=false
  # A roaming creature fight can reach the camp. If its creatures have died,
  # disengaging the surviving humans must also close that mixed encounter.
  if w.combat.encounter!="grey_camp" and w.combat.encounter!="":
   w.story.flags["battle_"+w.combat.encounter]=true
   w.story.Campaign.District.cleared(w,w.combat.encounter);w.combat.sync()
 capture();w.hud.toast("灰狗暂时停止追击，正在返回岗位。",4)
func guard_fell(_guard):
 if guards.any(func(g):return is_instance_valid(g) and g.hp>0):capture();return
 w.story.flags.grey_camp_cleared=true;w.story.flags.battle_grey_camp=true;alarm=false;capture();w.story.changed.emit()
 w.autosave()
func can_loot()->bool:
 for guard in guards:
  if not is_instance_valid(guard) or guard.hp<=0:continue
  if guard.position.distance_to(w.player.position)<3 or guard.sees_player():return false
 return true
func capture():
 var packet={"alarm":alarm,"lost_time":lost_time,"guards":[]}
 for guard in guards:
  packet.guards.append(guard.packet() if is_instance_valid(guard) else {"hp":0})
 if last_seen.is_finite():packet.last_seen=[last_seen.x,last_seen.y,last_seen.z]
 w.story.flags.grey_camp=packet
