extends SceneTree
var checks=0
var failures=0
func _initialize():call_deferred("run")
func check(ok:bool,message:String):
 checks+=1
 if not ok:failures+=1;push_error(message)
func frames(n:int=3):
 for i in n:await physics_frame
func run():
 var w=load("res://scenes/waterworks.tscn").instantiate();root.add_child(w);await frames()
 w.set_physics_process(false);w.player.set_physics_process(false);w.combat.set_physics_process(false);w.combat.enabled=false
 for npc in w.npcs.values():npc.set_physics_process(false)
 w.story.give("revolver");w.story.equip_weapon("revolver")
 for art in ["ivan","ivan_masked"]:
  var a=preload("res://scripts/actor.gd").new();a.art_id=art;w.add_child(a);a.setup(w.kit,true);a.set_physics_process(false)
  var p=a.visual.get_node("Painter");p.set_process(false)
  for mode in ["unarmed","armed","reload"]:
   w.story.flags.weapon_drawn=mode!="unarmed";w.combat.reload_time=1 if mode=="reload" else 0
   for angle in 8:
    var right=w.camera.global_basis.x;var depth=w.camera.global_basis.z;depth.y=0;depth=depth.normalized()
    var direction=right*sin(angle*PI/4)+depth*cos(angle*PI/4)
    a.visual.rotation.y=atan2(-direction.x,-direction.z);a.velocity=direction*2.65;p.direction_ready=false
    var poses=[]
    for phase in [0,.25,.5,.75]:
     p.cycle=phase;p._process(0);poses.append(p.current_pose)
     if angle in [3,5]:check(bool(p.material.get_shader_parameter("mirror"))==false,"rear-diagonal drawing faces the actual travel side in this source atlas: "+art+mode+str(angle)+str(phase))
    var expected=[1,0,2,0] if p.pose_count==3 else ([5,2,6,2] if mode=="reload" else [3,0,4,0])
    check(poses==expected,"both strides and planted middle pose render in order: "+art+mode+str(angle))
   # Reproduce a low-frame-rate spike: consecutive screen frames must not
   # jump directly from one stride to the other, bypassing the planted pose.
   p.cycle=0;var actual=[]
   for i in 9:p._process(.7);actual.append(p.current_pose)
   var center=2 if mode=="reload" and p.pose_count>=7 else 0
   var legal=true
   for i in range(1,actual.size()):
    if actual[i]!=actual[i-1] and actual[i]!=center and actual[i-1]!=center:legal=false
   check(legal and actual.has(center),"slow render frames retain visible middle poses: "+art+mode)
  a.queue_free();await frames()
 w.queue_free();await frames()
 print("IVAN_GAIT_V16_RESULT checks=",checks," failures=",failures);quit(0 if failures==0 else 1)
