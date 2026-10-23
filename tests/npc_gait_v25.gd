extends SceneTree
var checks=0
var failures=0
func _initialize():call_deferred("run")
func check(ok:bool,why:String):
 checks+=1
 if not ok:failures+=1;push_error(why)
func frames(n:int=4):
 for i in n:await physics_frame
func run():
 var originals=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/resident_v25_standing.json"))
 for id in originals:
  var im:Image=Image.load_from_file("res://assets/characters/"+id+".png")
  var standing=im.get_region(Rect2i(0,0,1200,352))
  var hash=HashingContext.new();hash.start(HashingContext.HASH_SHA256);hash.update(standing.get_data())
  check(hash.finish().hex_encode()==originals[id],"background standing identity and proportions unchanged: "+id)
 for floor in ["commune","sech","waterworks","coal"]:
  var w=load("res://scenes/"+floor+".tscn").instantiate();root.add_child(w);current_scene=w;await frames();w.hud.comic_active=false;w.story.flags.comic={"active":false};w.hud.close();w.set_physics_process(false)
  if is_instance_valid(w.combat):w.combat.set_physics_process(false)
  for id in w.npcs:
   var actor=w.npcs[id];actor.set_physics_process(false);actor.animation_state="walk"
   var painter=actor.visual.get_node_or_null("Painter")
   if not painter:continue
   painter.set_process(false);var size=painter.sprite.mesh.size
   for angle in 8:
    actor.visual.rotation.y=angle*PI/4;painter.direction_ready=false;actor.velocity=Vector3(.8,0,.6)
    var poses=[];var rig=[]
    for phase in [0.0,.25,.5,.75]:
     painter.cycle=phase;painter._process(0);poses.append(painter.current_pose);rig.append(float(painter.material.get_shader_parameter("puppet_stride")))
     check(painter.sprite.mesh.size==size,"walking never rescales character quad: "+floor+"/"+id)
    var drawn=painter.pose_count>=3 and painter.current_column in painter.manifest[painter.atlas_id].get("walk_views",range(painter.source_count))
    if drawn:check(poses.has(0) and poses.has(1 if painter.pose_count<5 else 3) and poses.has(2 if painter.pose_count<5 else 4),"accepted contact frames alternate around planted stance: "+id)
    else:check(poses.all(func(p):return p==0) and rig[0]>.9 and rig[2]<-.9,"unapproved views retain original art with continuous opposite rig phases: "+id)
    actor.velocity=Vector3.ZERO;actor.animation_state="idle";painter._process(0)
    check(is_zero_approx(float(painter.material.get_shader_parameter("puppet_stride"))),"idle feet remain planted: "+id)
    actor.animation_state="walk"
  w.queue_free();await frames()
 print("NPC_GAIT_V25_RESULT checks=",checks," failures=",failures);quit(0 if failures==0 else 1)
