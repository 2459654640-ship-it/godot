extends SceneTree
const Campaign=preload("res://scripts/campaign.gd")
const Story=preload("res://scripts/story.gd")
var checks=0
var failures=0
func _initialize():call_deferred("run")
func check(ok:bool,message:String):
 checks+=1
 if not ok:failures+=1;push_error(message)
func frames(n:int):
 for i in n:await physics_frame
func run():
 var w=load("res://scenes/commune.tscn").instantiate();root.add_child(w);await frames(8)
 w.set_physics_process(false);w.player.set_physics_process(false);w.hud.close()
 for actor in w.npcs.values():actor.set_physics_process(false)
 check(w.find_children("RoomSkirting*","MeshInstance3D",true,false).is_empty(),"no continuous skirting bars across commune openings")
 check(w.find_children("ThresholdPatch*","MeshInstance3D",true,false).is_empty(),"no stray finish patches at arbitrary room edges")
 check(w.find_children("HallStructuralBeam*","MeshInstance3D",true,false).is_empty(),"no floating column beam")
 for solid in w.kit.solids:
  if solid.name=="PilasterCollision":
   check(absf(solid.rect.get_center().x+11)<.3 or absf(solid.rect.get_center().x-12)<.3,"pilaster stays against public hall wall")
 var finishes={}
 for floor in w.find_children("Floor_*","MeshInstance3D",true,false):
  finishes[floor.get_meta("floor_finish")]=true
  var code=floor.get_meta("room_code")
  var matches=w.zones.filter(func(r):return r.code==code and Vector2(floor.position.x,floor.position.z).is_equal_approx(r.rect.get_center()))
  check(matches.size()==1,"floor seam follows room footprint: "+code)
 check(finishes.size()>=5,"different functional rooms use visibly different floor surfaces")
 for mesh in w.find_children("*","MeshInstance3D",true,false):
  if mesh.get_meta("design_id","")=="BenchSeat" and mesh.position.x<2 and mesh.position.z>7 and mesh.position.z<15:
   var table_z=9.0 if mesh.position.z<11 else 13.0
   check(mesh.get_meta("seat_forward").dot(Vector3(0,0,table_z-mesh.position.z))>0,"dining benches face their own table")
 var canopy=w.get_node("FungusShade")
 check(canopy.mesh.size.y<.1 and canopy.position.y>2.3,"shade is horizontal and above head height")
 w.story.flags.grow_fixed=true;w.on_story_changed()
 check(canopy.position.y>2 and canopy.mesh.size.z>2,"adjusted canopy stays over shelf rather than across aisle")
 var ray=PhysicsRayQueryParameters3D.create(Vector3(-6,1,21.5),Vector3(-4.6,1,21.5),1)
 var hit=w.get_world_3d().direct_space_state.intersect_ray(ray)
 check(not hit.is_empty() and hit.collider.get_parent().get_meta("design_id",hit.collider.get_parent().name)=="MedicalPrivacyHull","medical screen has real body collision")
 var groups=w.find_children("ResidentGroup_*","Node3D",false,false)
 check(groups.size()==6,"six distinct fixed resident groups")
 var people=0
 for group in groups:
  people+=group.get_meta("resident_count")
  var old=group.position;await frames(3)
  check(group.position==old and group.get_meta("stationary"),"group never wanders: "+group.name)
  var query=PhysicsRayQueryParameters3D.create(old+Vector3(0,1,2),old+Vector3(0,1,-2),1)
  var result=w.get_world_3d().direct_space_state.intersect_ray(query)
  check(not result.is_empty(),"resident group blocks passage through figures: "+group.name)
 check(people==17,"seventeen extra background residents")
 var lit_group=groups[0];var lamp=OmniLight3D.new();w.add_child(lamp);lamp.position=lit_group.position+Vector3(0,2.4,.8);lamp.omni_range=6;lamp.light_energy=5
 lit_group.lamps=[lamp];lit_group._process(1);var bright:Vector3=lit_group.material.get_shader_parameter("light_tint")
 lamp.light_energy=0;lit_group._process(1);var dark:Vector3=lit_group.material.get_shader_parameter("light_tint")
 check(bright.length()>dark.length()*1.15,"painted resident groups respond to actual local lamp strength")
 lamp.queue_free()
 var door=w.get_children().filter(func(n):return n.get_script()==load("res://scripts/assembly_door.gd"))[0]
 w.player.position=Vector3(25,.04,2);await frames(160)
 check(door.leaves.all(func(l):return absf(l.rotation.y)<.01),"unoccupied assembly doors close fully")
 ray=PhysicsRayQueryParameters3D.create(Vector3(.1,1,-2),Vector3(.1,1,-6),1)
 check(not w.get_world_3d().direct_space_state.intersect_ray(ray).is_empty(),"closed door physically blocks opening")
 door.set_physics_process(false);w.player.position=Vector3(.5,.04,-2)
 for i in 90:
  await physics_frame
  w.player.velocity=Vector3(0,-.5,-2);w.player.move_and_slide()
 check(w.player.position.z> -3.7,"closed door stops the player capsule, including the central seam")
 door.set_physics_process(true)
 w.player.position=Vector3(.5,.04,-1.7);await frames(12)
 check(absf(door.leaves[0].rotation.y)>.01 and absf(door.leaves[0].rotation.y)<1.45,"opening passes through visible intermediate angles")
 await frames(45)
 check(door.leaves.all(func(l):return absf(l.rotation.y)>1.45),"approach opens both leaves")
 for direction in [-1,1]:
  for i in 130:
   await physics_frame
   w.player.velocity=Vector3(0,-.5,direction*2);w.player.move_and_slide()
  check(w.player.position.z< -5.7 if direction==-1 else w.player.position.z> -2,"player crosses door with physics in direction "+str(direction))
 var painter=w.player.visual.get_node("Painter");painter.set_process(false)
 check(painter.get_children().filter(func(n):return n is MeshInstance3D).size()==1,"walking uses one entire painted figure")
 w.player.velocity=Vector3(1,0,1)
 var poses=[]
 for phase in [0.0,.25,.5,.75]:
  painter.cycle=phase;painter._process(0);poses.append(painter.current_pose)
 check(poses==[1,0,2,0],"walk uses opposite authored stride poses separated by neutral stance")
 w.story.flags.first_meeting_commune_anna=2;w.hud.show_dialogue("commune_anna");w.hud.finish_typing()
 for i in 8:await process_frame
 var spoken=w.hud.modal.find_children("*","RichTextLabel",true,false).filter(func(n):return n.get_parsed_text().contains("安娜把几本练习册"))
 check(spoken.size()==1 and spoken[0].size.x>390,"long natural dialogue uses the available transcript width")
 w.hud.close()
 var data=Campaign.data();var story=Story.new();story.context.floor="waterworks"
 var reply=story.act("c_veteran_road")
 check(reply.contains("家属") and reply.contains("工牌") and not reply.contains("按住 E"),"question about family receives an answer about family rather than controls")
 check(data.interactions.plant_diagram.body.contains("主泵继续隔离") and not data.interactions.plant_diagram.body.contains("恢复泵电"),"diagram guidance agrees with isolated main pump")
 check(str(data.interactions.commune_anna.after).contains("阿列克谢") and not str(data.interactions.commune_anna).contains("敌方工牌"),"Anna clearly identifies missing brother and request")
 for q in data.quests:check(not q.background.contains("写成宏大计划"),"quest description stays within world: "+q.id)
 w.queue_free();await frames(3)
 print("VISUAL_FIXES_V11_1_RESULT checks=",checks," failures=",failures);quit(0 if failures==0 else 1)
