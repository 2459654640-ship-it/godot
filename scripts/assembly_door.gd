extends Node3D
## Public double doors open before an approaching resident reaches the threshold.
var world
var leaves:Array[Node3D]=[]
var motion:Tween
var opened=true
var hold=0.0
const ANGLE=deg_to_rad(86)
func setup(w):
 world=w;position=Vector3(.5,0,-4);w.add_child(self)
 var k=w.kit
 for side in [-1,1]:
  k.box("AssemblyDoorJamb",position+Vector3(side*1.55,1.32,0),Vector3(.16,2.64,.30),"wood")
  k.box("AssemblyJambTrim",position+Vector3(side*1.64,1.32,.13),Vector3(.045,2.70,.06),"brass")
 k.box("AssemblyDoorLintel",position+Vector3(0,2.63,0),Vector3(3.4,.20,.30),"wood")
 k.box("AssemblyTransom",position+Vector3(0,2.45,0),Vector3(3.02,.20,.11),"cream")
 for side in [-1,1]:
  var pivot=Node3D.new();pivot.position=Vector3(side*1.48,0,0);add_child(pivot);leaves.append(pivot)
  var x=-side*.73
  panel(k,pivot,"AssemblyDoorLeaf",Vector3(x,1.18,0),Vector3(1.46,2.35,.12),"wood",true)
  panel(k,pivot,"AssemblyDoorInset",Vector3(x,.83,.073),Vector3(1.12,1.2,.035),"red")
  panel(k,pivot,"AssemblyDoorGlazed",Vector3(x,1.84,0),Vector3(1.1,.52,.13),"cream")
  for dx in [-.6,.6]:panel(k,pivot,"AssemblyDoorMoulding",Vector3(x+dx,1.19,.09),Vector3(.035,2.12,.035),"brass")
  for y in [.21,1.46,2.18]:panel(k,pivot,"AssemblyDoorMoulding",Vector3(x,y,.09),Vector3(1.2,.035,.035),"brass")
  for z in [-.105,.105]:
   panel(k,pivot,"AssemblyDoorHandlePlate",Vector3(-side*1.31,1.02,z),Vector3(.065,.29,.025),"brass")
   panel(k,pivot,"AssemblyDoorPull",Vector3(-side*1.31,1.02,z*1.5),Vector3(.035,.20,.035),"brass")
  pivot.rotation.y=-side*ANGLE
 k.box("AssemblyDoorThreshold",position+Vector3(0,.027,0),Vector3(2.9,.018,.12),"brass")
func panel(k,parent,id,p,size,material,solid=false):
 var mesh=k.box(id,p,size,material,solid,parent);mesh.set_meta("dynamic",true)
func _physics_process(delta):
 if not is_instance_valid(world) or not world.initialized:return
 var nearby=false
 for actor in [world.player]+world.npcs.values():
  var p:Vector3=actor.global_position-global_position;p.y=0
  if absf(p.x)<2.6 and absf(p.z)<3:nearby=true;break
 hold=1.25 if nearby else maxf(0,hold-delta)
 var wanted=hold>0
 if wanted==opened:return
 opened=wanted
 if is_instance_valid(motion):motion.kill()
 motion=create_tween().set_parallel(true)
 for index in leaves.size():
  var side=-1 if index==0 else 1
  motion.tween_property(leaves[index],"rotation:y",-side*ANGLE if opened else 0.0,.65 if opened else 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
