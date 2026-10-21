extends SceneTree
var checks=0
var failures=0
func _initialize():call_deferred("run")
func check(ok:bool,message:String):
 checks+=1
 if not ok:failures+=1;push_error(message)
func frames(n:int=4):
 for i in n:await physics_frame
func freeze(w):
 w.story.flags.intro_done=true;w.story.flags.comic={"active":false};w.hud.comic_active=false;w.hud.close()
 w.set_physics_process(false);w.player.set_physics_process(false)
 for npc in w.npcs.values():npc.set_physics_process(false)
 if is_instance_valid(w.combat):w.combat.enabled=false;w.combat.set_physics_process(false)
func gait_alpha_hash(image:Image)->String:
 image.convert(Image.FORMAT_RGBA8)
 var rgba=image.get_data();var alpha=PackedByteArray();alpha.resize(image.get_width()*image.get_height())
 for i in alpha.size():alpha[i]=rgba[i*4+3]
 var context=HashingContext.new();context.start(HashingContext.HASH_SHA256);context.update(alpha)
 return context.finish().hex_encode()
func opposite_stride_tests():
 # Foot screen-left/right alone does not identify its anatomical leg in a
 # rear three-quarter view. Freeze the actual approved silhouettes instead.
 var accepted:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/ivan_approved_gait_v20.json"))
 var m:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/characters/atlas.json"))
 for id in ["ivan"]: # Exact approved normal art remains frozen; equipment uses complete AI figures.
  var texture:Texture2D=load("res://assets/characters/"+id+".png");var image=texture.get_image()
  if image.is_compressed():image.decompress()
  var width:int=m[id].cell[0]
  for poses in ([[3,4],[5,6]] if id.ends_with("combat") else [[1,2]]):
   for angle in 8:
    var hashes=[]
    for pose in poses:
     var region=image.get_region(Rect2i(angle*width+(width-280)/2,pose*352+250,280,102));hashes.append(gait_alpha_hash(region))
    check(hashes[0]==accepted.alpha_sha256[angle][1] and hashes[1]==accepted.alpha_sha256[angle][2] and hashes[0]!=hashes[1],"both actual strides retain the approved independent foot silhouettes: "+id+str(poses)+str(angle))
func run():
 opposite_stride_tests()
 var w=load("res://scenes/waterworks.tscn").instantiate();root.add_child(w);current_scene=w;await frames();freeze(w)
 w.story.give("revolver");w.story.equip_weapon("revolver")
 for art in ["ivan","ivan_masked"]:
  var a=preload("res://scripts/actor.gd").new();a.art_id=art;w.add_child(a);a.setup(w.kit,true);a.set_physics_process(false)
  var p=a.visual.get_node("Painter");p.set_process(false)
  for mode in ["walk","armed","reload"]:
   w.story.flags.weapon_drawn=mode!="walk";w.combat.reload_time=1 if mode=="reload" else 0
   for angle in 8:
    var side=w.camera.global_basis.x;var depth=w.camera.global_basis.z;depth.y=0;depth=depth.normalized()
    var direction=side*sin(angle*PI/4)+depth*cos(angle*PI/4)
    a.visual.rotation.y=atan2(-direction.x,-direction.z);a.velocity=direction*2.65;p.direction_ready=false
    var seen=[];var sizes=[]
    for phase in [0,.25,.5,.75]:
     p.cycle=phase;p._process(0);seen.append(p.current_pose);sizes.append(p.sprite.mesh.size)
     check(p.current_column==angle and p.source_count==8,"actual eight-view source selected: "+art+mode+str(angle))
     check(not p.material.get_shader_parameter("mirror"),"walking never flips Ivan's head/equipment")
     check(is_equal_approx(p.material.get_shader_parameter("frame_origin").x,float(angle)/8.0),"GPU samples the correct independent column")
    check(seen==([1,0,2,0] if p.pose_count==3 else ([5,2,6,2] if mode=="reload" else [3,0,4,0])),"both diagonals include the contact frame twice per cycle")
    check(sizes.all(func(s):return s==sizes[0]),"world dimensions stay fixed throughout a stride")
    var texture:Texture2D=p.material.get_shader_parameter("painted_map");var image=texture.get_image()
    if image.is_compressed():image.decompress()
    var width:int=p.manifest[p.atlas_id].cell[0]
    var samples=[]
    for pose in [seen[0],seen[1],seen[2]]:samples.append(image.get_region(Rect2i(angle*width,pose*352,width,352)))
    check(samples[0].get_data()!=samples[1].get_data() and samples[2].get_data()!=samples[1].get_data(),"contact is distinct actual artwork, not just a pose number")
    var head_counts=[]
    for sample in samples:
     var count=0
     for yy in range(18,71):
      for xx in range(width/2-44,width/2+44):
       if sample.get_pixel(xx,yy).a>.5:count+=1
     head_counts.append(count)
    check(float(head_counts.max()-head_counts.min())/maxi(1,head_counts.max())<.18,"standing and both complete strides retain comparable head scale: "+art+mode+str(angle))
   # Actual slow rendering must still show a contact image between strides.
   for delta in [1.0/60,1.0/15,.30]:
    p.cycle=0;var previous=-1;var safe=true;var contacts=0;var center=2 if mode=="reload" and p.pose_count>=7 else 0
    for i in 40:
     p._process(delta)
     if p.current_pose==center:contacts+=1
     if previous>=0 and previous!=p.current_pose and previous!=center and p.current_pose!=center:safe=false
     previous=p.current_pose
    check(safe and contacts>0,"render time spikes cannot skip all contact frames")
  a.queue_free();await frames(1)
 w.queue_free();await frames()
 for floor in ["life","commune","sech"]:
  w=load("res://scenes/"+("d6" if floor=="life" else floor)+".tscn").instantiate();root.add_child(w);current_scene=w;await frames();freeze(w)
  for id in w.npcs:
   var npc=w.npcs[id]
   check(npc.navigation!=null,"every singleton, including late-created residents, has navigation: "+floor+id)
   for destination in npc.patrol:check(destination.distance_to(npc.home_anchor)<npc.roam_radius+.15 and npc.work_area.has_point(Vector2(destination.x,destination.z)),"local patrol stays at its workplace: "+id)
   var painter=npc.visual.get_node("Painter");painter.set_process(false)
   if painter.pose_count==1:
    npc.velocity=Vector3(.72,0,0);painter.cycle=0;painter._process(0)
    check(absf(float(painter.material.get_shader_parameter("puppet_stride")))>.9,"a single-illustration resident has a real independent-leg rig: "+id)
    painter.cycle=.25;painter._process(0)
    check(is_zero_approx(float(painter.material.get_shader_parameter("puppet_stride"))),"resident's rig includes planted transition: "+id)
    painter.cycle=.125;painter._process(0)
    check(float(painter.material.get_shader_parameter("puppet_stride"))>.6 and float(painter.material.get_shader_parameter("puppet_stride"))<.8,"single-pose leg motion has a smooth intermediate position: "+id)
    painter.cycle=.375;painter._process(0)
    check(float(painter.material.get_shader_parameter("puppet_stride"))<-.6,"the opposite leg advances on the next half-cycle: "+id)
    npc.velocity=Vector3.ZERO
  var chosen="supply" if floor=="life" else ("commune_printer" if floor=="commune" else "sech_quartermaster")
  var npc=w.npcs[chosen];var home=npc.home_anchor;var candidates=[]
  for point_id in w.navigation.points:
   var q:Vector2=w.navigation.points[point_id];var distance=q.distance_to(Vector2(home.x,home.z))
   if distance>1.7 and distance<2.3 and npc.work_area.has_point(q):candidates.append(Vector3(q.x,.04,q.y))
  check(not candidates.is_empty(),"return-to-work probe has a physically navigable start")
  if not candidates.is_empty():
   for a in w.npcs.values():a.collision_layer=0
   npc.position=candidates[0];npc.velocity=Vector3.ZERO;npc.purposeful=false;npc.stationary=false;npc.patrol.clear();npc.rest_time=999;npc.path_points.clear();npc.goal=Vector3.INF;npc.reached_anchor=true
   w.player.position=home+Vector3(8,.04,8);npc.set_physics_process(true)
   var previous=npc.position;var no_teleport=true
   for i in 480:
    await physics_frame
    if npc.position.distance_to(previous)>.10:no_teleport=false
    previous=npc.position
   check(npc.position.distance_to(home)<.65 and npc.home_anchor==home,"displaced worker returns to the original station: "+floor)
   check(no_teleport,"return uses actual walking/physics, never teleportation")
   npc.set_physics_process(false)
  if floor=="life":
   w.player.position=w.targets.radio.pos+Vector3(0,.04,1.1)
   var flags=w.story.flags.duplicate(true);w.interact("radio");w.hud.finish_typing()
   check(w.story.view("radio").options.any(func(o):return o.key=="room_radio_music" and o.enabled),"bedroom story radio offers music")
   w.perform("room_radio_music","radio");var radio=w.public_radio;radio.play_track();radio.update_mix(1)
   check(w.hud.radio_open and radio.local_origin==w.targets.radio.pos and radio.audible>.9,"bedroom radio really plays from the bedroom receiver")
   check(not w.story.has("frequency") and w.story.flags==flags,"music cannot reveal Star City or autoaccept its task")
   w.hud.show_dialogue("semyon");radio.update_mix(1)
   check(not radio.suppressed and not radio.audio.stream_paused,"music continues through ordinary NPC dialogue")
   w.hud.close();w.player.position=w.targets.radio.pos+Vector3(30,.04,0);radio.update_mix(1)
   check(radio.audible==0,"bedroom receiver does not become a free portable radio")
   radio.stop()
  if floor=="commune":
   for group in w.get_children():
    if not String(group.name).begins_with("ResidentGroup_"):continue
    var origin=group.position;var old=group.material.get_shader_parameter("idle_time");group._process(.8)
    check(group.position==origin and group.material.get_shader_parameter("idle_time")!=old,"crowds breathe in place without sliding")
    var members=0.0
    for ink in group.member_materials:members+=float(ink.get_shader_parameter("idle_members"))
    check(members==float(group.get_meta("resident_count")),"crowd members have independent idle phases")
   check(w.get_node("ResidentGroup_queue").position==Vector3(8,0,3.2),"queue leaves the corner and waits at the allocation counter")
   check(w.get_node("ResidentGroup_readers").position==Vector3(16,0,-8.4),"readers stand by archive furnishings")
  w.queue_free();await frames()
 print("MOTION_V18_RESULT checks=",checks," failures=",failures);quit(0 if failures==0 else 1)
