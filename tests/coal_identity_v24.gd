extends SceneTree
const Story=preload("res://scripts/story.gd")
var checks=0
var failures=0
func _initialize():call_deferred("run")
func check(ok:bool,why:String):
 checks+=1
 if not ok:failures+=1;push_error(why)
func frames(n:int=4):
 for i in n:await physics_frame
func run():
 var s=Story.new();s.flags.intro_done=true;s.flags.coal_access=true;s.flags.anna_request=true
 root.get_node("Session").pending={"story":s.serialize(),"floor":"coal","position":Vector3(-12,.04,9)}
 var w=load("res://scenes/coal.tscn").instantiate();root.add_child(w);current_scene=w;await frames();w.hud.close();w.set_physics_process(false)
 check(not w.npcs.has("coal_brother") and not w.targets.has("coal_brother"),"initial arrival cannot reveal the patient's identity or location")
 check(w.npcs.size()>=11,"mine has miners, guard, registration and medical staff rather than only quest givers")
 for id in w.npcs:
  if not String(id).begins_with("resident_"):continue
  var a=w.npcs[id];var point=w.navigation.graph.get_closest_point(Vector2(a.position.x,a.position.z));var near=w.navigation.graph.get_point_position(point)
  check(near.distance_to(Vector2(a.position.x,a.position.z))<.8,"background resident occupies actual clear walkable space: "+id)
  check(a.stationary,"workers remain at their assigned places: "+id)
  var capsule=CapsuleShape3D.new();capsule.radius=.30;capsule.height=1.72
  var query=PhysicsShapeQueryParameters3D.new();query.shape=capsule;query.transform=Transform3D(Basis.IDENTITY,a.position+Vector3.UP*.93);query.collision_mask=1
  check(w.get_world_3d().direct_space_state.intersect_shape(query).is_empty(),"resident capsule does not overlap furniture or a wall: "+id)
 for action in ["coal_register","coal_archive"]:
  w.story.act("c_"+action);check(w.story.last_action_valid,"investigation phase "+action)
 check(not w.npcs.has("coal_brother"),"record lookup alone does not summon the patient")
 w.story.act("c_coal_medic");check(w.story.last_action_valid and w.npcs.has("coal_brother") and w.targets.has("coal_brother"),"medical arrangement reveals the correct patient and interaction together")
 w.story.act("c_coal_brother");check(w.story.last_action_valid and w.story.f("brother_found"),"existing informed visit still completes")
 w.story.flags.anna_outcome_done=true;w.story.changed.emit();await frames()
 check(not w.npcs.has("coal_brother") and not w.targets.has("coal_brother"),"evacuated patient cannot remain in the mine")
 w.queue_free();await frames()
 # Formal return and limited visits must not share the same blanket restriction.
 for route in ["official","hatch","permit"]:
  var t=Story.new();t.context.floor="labor";t.route=route;t.flags.d6_returned=true;t.flags.departure_official=route=="official"
  check(not t.Chapter.home_access(t),"return paperwork must precede unrestricted home access: "+route)
  t.flags.d6_cargo_returned=true
  check(t.Chapter.home_access(t)==(route=="official"),"only actual formal cargo return restores resident access: "+route)
  t.act("travel_up");check(t.last_action_valid==(route=="official"),"travel action enforces the same access rule: "+route)
  t.flags.sided_veteran=true;check(not t.Chapter.home_access(t),"leaving with the veteran does not acquire full D-6 access")
 for floor in ["d6","labor"]:
  w=load("res://scenes/"+floor+".tscn").instantiate();root.add_child(w);current_scene=w;await frames();w.hud.close();w.set_physics_process(false)
  check(w.floor_name() in ["D-6生活层","D-6作业层"],"fully qualified D-6 location title")
  w.hud.show_journal("map")
  var labels=w.hud.modal.find_children("*","Button",true,false).map(func(b):return b.text)
  check("D-6生活层" in labels and "D-6作业层" in labels and "生活层" not in labels and "作业层" not in labels,"map tabs identify both D-6 floors")
  w.hud.comic_active=false;w.story.flags.comic={"active":false};w.hud.close();w.queue_free();await frames()
 print("COAL_IDENTITY_V24_RESULT checks=",checks," failures=",failures);quit(0 if failures==0 else 1)
