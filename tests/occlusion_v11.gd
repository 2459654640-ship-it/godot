extends SceneTree
var checks=0
var failures=0
func _initialize():call_deferred("run")
func check(ok:bool,message:String):
 checks+=1
 if not ok:failures+=1;push_error(message)
func run():
 var w=load("res://scenes/d6.tscn").instantiate();root.add_child(w)
 for i in 5:await physics_frame
 w.set_physics_process(false);w.player.set_physics_process(false);w.hud.close();w.wall_veil.set_process(false)
 w.player.position=Vector3(-3,.04,1.4);w.set_camera(0,true)
 var veil=w.wall_veil;var p:Vector3=w.player.position;var direction:Vector3=w.camera.global_basis.z
 var full=AABB(p+direction*.8+Vector3(-1.1,-.15,-1.1),Vector3(2.2,3.4,2.2))
 var tip=p+direction*.8+Vector3.UP*1.72;var partial=AABB(tip-Vector3.ONE*.035,Vector3.ONE*.07)
 var whole:float=veil.coverage(full);var edge:float=veil.coverage(partial)
 check(whole>.8 and edge>0 and edge<whole*.5,"coverage measures full-body and grazing obstruction differently")
 var mesh=w.kit.box("OcclusionContract",full.get_center(),full.size,"metal")
 var material=w.kit.new_veil_material(w.kit.mats.metal);mesh.material_override=material
 var solids=w.kit.solids.duplicate(true);veil.add_state(mesh,full,[material],false);var state=veil.states[-1]
 for i in 90:veil._process(1.0/60)
 check(state.opacity>=.419 and state.opacity<.45,"full obstruction retains at least 42 percent wall opacity")
 state.bounds=partial
 for i in 90:veil._process(1.0/60)
 check(state.opacity>.70 and state.opacity<.85,"grazing obstruction stays more opaque than full coverage")
 check(w.kit.solids==solids,"changing transparency never changes collision")
 check(veil.states.any(func(s):return s.roof),"real overhead pipes and lamps participate in the occlusion system")
 check(w.kit.roof_occluders.all(func(entry):return entry.material.shader.resource_path.ends_with("masonry_veil.gdshader")),"overhead render batches actually use a fade-capable material")
 var material_ids={}
 for entry in w.kit.roof_occluders:material_ids[entry.material.get_instance_id()]=true
 check(material_ids.size()==w.kit.roof_occluders.size(),"separate overhead batches cannot overwrite each other's opacity")
 # At this exact camera angle a real 15cm pipe crosses between the sparse
 # wall sample heights. It must still respond when it covers Ivan's face.
 var view=w.player.position+Vector3.UP*.85;w.camera.position=view+Vector3(23,30,27);w.camera.look_at(view)
 var thin_detected=false
 for i in 150:veil._process(1.0/60)
 for entry in veil.states:
  if entry.roof and veil.coverage(entry.bounds,0,true)>0 and entry.opacity<.82:thin_detected=true
 check(thin_detected,"real thin overhead pipe fades at the character's face without needing full-body coverage")
 state.bounds=AABB(Vector3(100,0,100),Vector3.ONE)
 for i in 120:veil._process(1.0/60)
 check(is_equal_approx(state.opacity,1) and not state.active,"unobstructing geometry returns smoothly to opacity one")
 w.queue_free();await physics_frame
 print("OCCLUSION_V11_RESULT checks=",checks," failures=",failures);quit(0 if failures==0 else 1)
