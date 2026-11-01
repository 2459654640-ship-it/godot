extends SceneTree
var checks=0
var failures=0
var w
func _initialize():call_deferred("run")
func check(ok:bool,why:String):
 checks+=1
 if not ok:failures+=1;push_error(why)
func frames(n:int=4):
 for i in n:await physics_frame
func open(floor:String):
 var s=load("res://scripts/story.gd").new();s.flags.intro_done=true;s.flags.late_star_admitted=true;s.give("mask");s.give("filter");s.give("revolver")
 root.get_node("Session").pending={"story":s.serialize(),"floor":floor,"position":Vector3.INF}
 w=load("res://scenes/"+floor+".tscn").instantiate();root.add_child(w);current_scene=w;await frames()
 w.set_physics_process(false);w.player.set_physics_process(false);w.combat.set_physics_process(false);w.hud.close()
func run():
 await open("waterworks");var c=w.combat
 c.update_cursor();check(not c.reticle.visible and Input.mouse_mode==Input.MOUSE_MODE_VISIBLE,"holstered exploration uses system pointer")
 w.toggle_weapon();c.update_cursor();check(c.reticle.visible and (DisplayServer.get_name()=="headless" or Input.mouse_mode==Input.MOUSE_MODE_HIDDEN),"manual draw shows only game reticle, even before encounter")
 check(not c.cursor_allowed(false,true) and not c.cursor_allowed(true,false),"unfocused window and pointer outside viewport cannot retain reticle")
 w.hud.show_inventory();check(not c.reticle.visible and Input.mouse_mode==Input.MOUSE_MODE_VISIBLE,"opening inventory immediately restores pointer")
 w.hud.close();check(c.reticle.visible and (DisplayServer.get_name()=="headless" or Input.mouse_mode==Input.MOUSE_MODE_HIDDEN),"closing inventory immediately restores aim")
 w.hud.show_dialogue("plant_guide");c.update_cursor();check(not c.reticle.visible and Input.mouse_mode==Input.MOUSE_MODE_VISIBLE,"dialogue uses pointer without second reticle")
 w.hud.close();w.departure_animating=true;c.update_cursor();check(not c.reticle.visible and Input.mouse_mode==Input.MOUSE_MODE_VISIBLE,"departure transition restores pointer")
 w.departure_animating=false;c.defeated=true;c.update_cursor();check(not c.reticle.visible and Input.mouse_mode==Input.MOUSE_MODE_VISIBLE,"defeat hides aiming before retry panel")
 c.defeated=false;w.toggle_weapon();c.update_cursor();check(not c.reticle.visible and Input.mouse_mode==Input.MOUSE_MODE_VISIBLE,"holstering cannot leave hidden pointer")
 check(w.find_children("*","MeshInstance3D",true,false).filter(func(n):return n.get_meta("design_id","")=="HorizontalPumpMotor").size()==2,"both old vertical drum pumps are replaced by horizontal motor sets")
 check(w.find_children("PumpHousing*","MeshInstance3D",true,false).is_empty(),"obsolete pump geometry is removed rather than covered")
 check(w.find_children("*","MeshInstance3D",true,false).filter(func(n):return n.get_meta("design_id","")=="AnalogueGaugeFace").size()==2,"one mechanically connected gauge per pump")
 for id in ["plant_diagram","plant_bleed","plant_fuse","plant_power","plant_archive"]:
  if not w.targets.has(id):continue
  var goal:Vector3=w.targets[id].pos;var route=w.navigation.path(w.player.position,goal)
  check(not route.is_empty() and route[-1].distance_to(goal)<1.7,"machinery leaves task access clear "+id)
 w.queue_free();await frames();check(Input.mouse_mode==Input.MOUSE_MODE_VISIBLE,"leaving combat world restores pointer")
 await open("star_interior")
 var hall=w.find_children("Floor_*","MeshInstance3D",true,false).filter(func(n):return n.get_meta("room_code","")=="02")[0]
 check(hall.mesh is ArrayMesh and hall.mesh.get_aabb().size.x>23,"hall uses triangulated cut-corner floor")
 check(w.find_children("*","MeshInstance3D",true,false).filter(func(n):return n.get_meta("design_id","")=="ResearchCornerMasonry").size()==4,"four diagonal hall corners are actual masonry")
 check(w.find_children("FinishFloor_02*","MeshInstance3D",true,false).is_empty(),"rectangular finishing floor cannot fill cut corners")
 check(w.kit.wall_finish_theme=="starcity","research rooms use their own palette, not factory finishes")
 var profiles=w.kit.wall_room_profiles.map(func(p):return p.style);check(profiles.has(21) and profiles.has(22) and profiles.has(23),"laboratory, entrance and residential wall profiles differ")
 for d in preload("res://scripts/late_layouts.gd").PLANS.star_interior.doors:
  var p=Vector2(d[0],d[1]);check(not w.kit.solids.any(func(s):return s.top>.5 and s.bottom<1.7 and s.rect.has_point(p)),"portal centre remains physically clear "+str(d))
 for id in w.targets:
  var point:Vector3=w.targets[id].pos;var path=w.navigation.path(w.player.position,point)
  check(w.player.position.distance_to(point)<1.7 or (not path.is_empty() and path[-1].distance_to(point)<1.7),"research target remains reachable "+id)
 w.queue_free();await frames();print("SCENE_HANDOFF_V34_RESULT checks=",checks," failures=",failures);quit(1 if failures else 0)
