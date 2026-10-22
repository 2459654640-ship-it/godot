extends SceneTree
const Kit=preload("res://scripts/kit.gd")
const Grid=preload("res://scripts/route_grid.gd")
const Enemy=preload("res://scripts/combat_enemy.gd")
const Combat=preload("res://scripts/combat.gd")
const Story=preload("res://scripts/story.gd")
class QuietHUD extends RefCounted:
 func modal_visible():return false
 func toast(_text,_duration=0):pass
class Arena extends Node3D:
 var zones=[{"rect":Rect2(-8,-8,16,16)}]
 var kit
 var navigation
 var story=Story.new()
 var player=CharacterBody3D.new()
 var camera=Camera3D.new()
 var hud=QuietHUD.new()
 var departure_animating=false
 var floor_id="test"
 var campaign_gate_flag="test_gate_open"
var w
var director
var checks=0
var failures=0
func _initialize():call_deferred("run")
func check(ok:bool,why:String):
 checks+=1
 if not ok:failures+=1;push_error(why)
func frames(n:int=4):
 for i in n:await physics_frame
func arena():
 w=Arena.new();root.add_child(w);current_scene=w;w.kit=Kit.new(w)
 w.kit.box("FloorTest",Vector3(0,-.1,0),Vector3(16,.2,16),"concrete",true)
 w.add_child(w.player);w.player.collision_layer=2;w.player.collision_mask=1
 var c=CollisionShape3D.new();var capsule=CapsuleShape3D.new();capsule.radius=.27;capsule.height=1.7;c.shape=capsule;c.position.y=.85;w.player.add_child(c)
 w.add_child(w.camera);w.camera.position=Vector3(10,15,10);w.camera.look_at(Vector3.ZERO)
 w.story.economy.health=10000
 director=Combat.new();w.add_child(director);director.w=w;director.enabled=true;director.veteran_health=0;director.set_physics_process(false)
func spawn(p:Vector3,kind:String="mutant"):
 var e=Enemy.new();w.add_child(e);e.setup(director,p,kind);e.arrival_time=0;director.enemies.append(e);return e
func grid():
 w.navigation=Grid.new();w.navigation.setup(w)
func dispose():
 w.queue_free();await frames();w=null
func run():
 # A low rim used to be omitted by navigation even though the creature's
 # actual body cannot step over it. Test movement, not merely an A* result.
 arena();w.kit.box("LowPoolRim",Vector3(0,.10,0),Vector3(5,.20,.3),"concrete",true);grid()
 w.player.position=Vector3(0,.04,4);var e=spawn(Vector3(0,.04,-4));var went_around=false
 for i in 780:
  await physics_frame
  if absf(e.position.x)>2.8:went_around=true
  if e.position.distance_to(w.player.position)<.85:break
 check(went_around and e.position.distance_to(w.player.position)<.95,"mutant physically routes around low cover instead of freezing on it")
 check(director.enemy_navigation.path(Vector3(0,0,-4),Vector3(0,0,4)).size()>8,"creature grid treats the low rim as an obstacle")
 await dispose()
 # Target is within bite radius, but separated by a wall. It must route
 # around before winding up, and cannot inflict damage through the wall.
 arena();w.kit.box("ThinCover",Vector3(0,.7,0),Vector3(3,1.4,.14),"metal",true);grid()
 w.player.position=Vector3(0,.04,.4);e=spawn(Vector3(0,.04,-.4));var initial_hp=w.story.economy.health;went_around=false
 for i in 480:
  await physics_frame
  if absf(e.position.x)>1.8:went_around=true
  if i<30:check(w.story.economy.health==initial_hp,"thin cover prevents damage before reaching its edge")
  if e.position.z>.25 and e.position.distance_to(w.player.position)<.85:break
 check(went_around and e.position.z>.25,"nearby target behind a wall does not lock mutant into an impossible bite")
 await dispose()
 # Closed gate stays closed. After the usual grid rebuild, a live pursuer
 # acquires the newly opened route without restarting the encounter.
 arena();var gate=w.kit.box("CampaignInnerGate",Vector3(0,.8,0),Vector3(16,1.6,.2),"metal",true);grid()
 w.player.position=Vector3(0,.04,3);e=spawn(Vector3(0,.04,-3));await frames(150)
 check(e.position.z<-.3 and w.story.economy.health==10000,"unreachable target does not cause wall penetration or phantom damage")
 gate.position.y=-3;w.story.flags.test_gate_open=true;w.navigation.setup(w);await frames(360)
 check(e.position.z>2 and director.enemy_navigation_revision==w.navigation.revision,"opening a gate refreshes enemy routes in the same encounter")
 await dispose()
 # Armed enemies use the same obstacle-aware routing until they gain LOS.
 arena();w.kit.box("TallCover",Vector3(0,1,0),Vector3(4,2,.4),"metal",true);grid()
 w.player.position=Vector3(0,.04,4);e=spawn(Vector3(0,.04,-4),"soldier");went_around=false
 for i in 600:
  await physics_frame
  if absf(e.position.x)>2.15:went_around=true
  if w.story.economy.health<10000:break
 check(went_around and w.story.economy.health<10000,"soldier navigates around cover and then fires along an unobstructed line")
 await dispose()
 # Several creatures must negotiate the same cover without their separation
 # force pinning the rear ones to its face or to one another.
 arena();w.kit.box("GroupCover",Vector3(0,.5,0),Vector3(3,1,1),"wood",true);grid()
 w.player.position=Vector3(0,.04,4)
 for x in [-.7,0,.7]:spawn(Vector3(x,.04,-4))
 await frames(840)
 check(director.enemies.all(func(enemy):return enemy.position.z>1 and enemy.position.distance_to(w.player.position)<1.8),"three creatures all get around the same crate without a stationary queue")
 await dispose()
 print("ENEMY_ROUTES_V23_RESULT checks=",checks," failures=",failures);quit(0 if failures==0 else 1)
