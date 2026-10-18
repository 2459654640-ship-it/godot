extends SceneTree
var checks=0
var failures=0
func _initialize():call_deferred("run")
func check(ok:bool,message:String):
 checks+=1
 if not ok:failures+=1;push_error(message)
func frames(n:int=4):
 for i in n:await physics_frame
func hits(w,p:Vector3)->Array:
 var cap=CapsuleShape3D.new();cap.radius=.27;cap.height=1.72
 var q=PhysicsShapeQueryParameters3D.new();q.shape=cap;q.collision_mask=1;q.transform=Transform3D(Basis.IDENTITY,p+Vector3(0,.90,0))
 return w.get_world_3d().direct_space_state.intersect_shape(q)
func run():
 for id in ["d6","labor","waterworks","commune","sech","coal","starcity"]:
  var w=load("res://scenes/"+id+".tscn").instantiate();root.add_child(w);await frames()
  w.set_physics_process(false);w.story.flags.intro_done=true;w.story.flags.comic={"active":false};w.hud.comic_active=false;w.hud.close()
  if is_instance_valid(w.combat):w.combat.set_physics_process(false)
  for a in w.npcs.values():a.set_physics_process(false)
  var bad=[]
  for key in w.npcs:
   var a=w.npcs[key]
   if a.art_id in ["ambient_child","commune_child"]:continue
   var obstructions=hits(w,a.position)
   if not obstructions.is_empty():bad.append([key,obstructions.map(func(h):return String(h.collider.get_parent().get_meta("design_id",h.collider.get_parent().name)))])
  check(bad.is_empty(),"standing NPCs do not start inside walls/furniture: "+id+str(bad))
  for mesh in w.find_children("*","MeshInstance3D",true,false):
   if not mesh.has_meta("rug_native_aspect"):continue
   var native:float=mesh.get_meta("rug_native_aspect")
   check(absf(mesh.mesh.size.x/mesh.mesh.size.z-native)<.001,"rug pattern preserves its native proportions: "+id)
  if id=="sech":
   var beds=w.kit.solids.filter(func(s):return s.name=="BedFrame" and s.rect.get_center().y>5 and s.rect.get_center().x< -4)
   check(beds.size()==8,"habitation cars have eight perimeter beds")
   var blockers=w.kit.solids.filter(func(s):return s.name in ["FamilyCurtain","Locker"])
   for b in beds:
    check(blockers.all(func(s):return not s.rect.intersects(b.rect)),"bed is clear of curtains/lockers: "+str(b.rect))
   for mesh in w.find_children("*","MeshInstance3D",true,false):
    if mesh.get_meta("design_id","")=="BedFrame" and mesh.position.x< -4 and mesh.position.z>5:
     check(mesh.get_meta("bed_head").dot(Vector3.LEFT if mesh.position.x< -10 else Vector3.RIGHT)>.99,"beds face foot-first into the center aisle")
    if mesh.get_meta("design_id","")=="BenchSeat" and absf(mesh.position.x-2)<.01 and mesh.position.z< -10 and mesh.position.z> -13:
     check(mesh.get_meta("seat_forward").dot(Vector3(0,0,-11.5-mesh.position.z))>0,"council benches face their meeting table")
   check(hits(w,w.npcs.sech_elder.position).is_empty(),"elder stands clear of the table and the end chair")
   for a in w.npcs.values():a.collision_layer=0
   var p=w.player;p.camera=null;p.use_override=true
   for x in [-14,-6]:
    p.position=Vector3(x,.04,8.3);p.velocity=Vector3.ZERO;p.motion_override=Vector2.DOWN;await frames(60);p.motion_override=Vector2.ZERO
    check(p.position.z<9.10,"privacy curtain physically stops walking through fabric: "+str(x))
   p.position=Vector3(-10,.04,8.3);p.velocity=Vector3.ZERO;p.motion_override=Vector2.DOWN;await frames(60);p.motion_override=Vector2.ZERO
   check(p.position.z>10.6,"curtains preserve the center aisle")
  w.queue_free();await frames()
 print("FURNISHINGS_V16_RESULT checks=",checks," failures=",failures);quit(0 if failures==0 else 1)
