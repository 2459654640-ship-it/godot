extends SceneTree
var checks=0
var failures=0
func _initialize():call_deferred("run")
func check(ok:bool,message:String):
 checks+=1
 if not ok:failures+=1;push_error(message)
func run():
 var w=load("res://scenes/waterworks.tscn").instantiate();root.add_child(w)
 for i in 4:await physics_frame
 w.set_physics_process(false);w.player.set_physics_process(false);w.combat.set_physics_process(false);w.combat.enabled=false
 w.story.give("revolver");w.story.equip_weapon("revolver")
 for art in ["ivan","ivan_masked"]:
  var a=preload("res://scripts/actor.gd").new();a.art_id=art;w.add_child(a);a.setup(w.kit,true);a.set_physics_process(false)
  var p=a.visual.get_node("Painter");p.set_process(false)
  for mode in ["unarmed","armed","reload"]:
   w.story.flags.weapon_drawn=mode!="unarmed";w.combat.reload_time=1 if mode=="reload" else 0
   for angle in 8:
    var right=w.camera.global_basis.x;var depth=w.camera.global_basis.z;depth.y=0;depth=depth.normalized();var direction=right*sin(angle*PI/4)+depth*cos(angle*PI/4)
    a.visual.rotation.y=atan2(-direction.x,-direction.z);a.velocity=direction*2.65;p.direction_ready=false;p.cycle=0
    var center=2 if mode=="reload" else 0;var planted=0;var poses={}
    for frame in 120:
     p._process(1.0/120);poses[p.current_pose]=true
     if p.current_pose==center:planted+=1
     if angle in [0,4]:
      check(not p.material.get_shader_parameter("mirror"),"front/back never flip torso or weapon: "+art+mode+str(angle))
      check(bool(p.material.get_shader_parameter("axial_legs")),"front/back use independent drawn leg poses")
     else:check(not p.material.get_shader_parameter("axial_legs"),"diagonal views retain their authored perspective")
    check(poses.size()==3 and planted>=50,"all eight directions visibly retain both strides and contact poses: "+art+mode+str(angle))
   a.velocity=Vector3.ZERO;p._process(0)
   check(not p.material.get_shader_parameter("axial_legs"),"standing returns to original idle illustration")
  a.queue_free()
 w.queue_free()
 for i in 3:await process_frame
 var image=load("res://assets/characters/ivan_axial_legs.png").get_image()
 for column in 2:
  var left=image.get_region(Rect2i(column*280,352,280,352));var right=image.get_region(Rect2i(column*280,704,280,352))
  left.flip_x()
  check(left.get_data()!=right.get_data(),"opposite stride is distinct artwork, not a mirror of the entire illustration")
 print("IVAN_GAIT_V17_RESULT checks=",checks," failures=",failures);quit(0 if failures==0 else 1)
