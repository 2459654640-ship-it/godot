extends SceneTree
var checks=0
var failures=0
var samples={}
func _initialize():call_deferred("run")
func check(ok:bool,why:String):
 checks+=1
 if not ok:failures+=1;push_error(why)
func frames(n:int=4):
 for i in n:await process_frame
 await RenderingServer.frame_post_draw
func sample(lab,index:int)->Color:
 var p=lab.camera.unproject_position(lab.originals[index].global_position+Vector3(0,1.05,0))
 var img=root.get_texture().get_image();var sum=Color(0,0,0,0)
 for x in range(-3,4):
  for y in range(-3,4):sum+=img.get_pixel(clampi(roundi(p.x)+x,0,img.get_width()-1),clampi(roundi(p.y)+y,0,img.get_height()-1))
 return sum/49
func run():
 var menu=load("res://scenes/main_menu.tscn").instantiate();menu.save_path="user://pilot_test_missing.json";root.add_child(menu);current_scene=menu;await frames()
 var found=false
 for b in menu.find_children("*","Button",true,false):
  if b.text=="伊万角色样片":b.pressed.emit();found=true;break
 await frames(6)
 var lab=current_scene
 check(found and lab.scene_file_path.ends_with("ivan_pilot.tscn"),"actual main-menu button opens the isolated character comparison")
 lab.automatic=false;lab.moving=false;lab.set_physics_process(false);lab.reset()
 for actor in lab.originals:
  actor.set_physics_process(false);actor.visual.rotation.y=atan2(-lab.camera.global_basis.z.x,-lab.camera.global_basis.z.z)
 await frames()
 lab.pilot.set_process(false)
 for actor in lab.originals:actor.visual.get_node("Painter").set_process(false)
 for mode in range(3):
  lab.set_lighting(mode);await frames()
  samples[str(mode)]=[sample(lab,0),sample(lab,1)]
 var warm:Color=samples["0"][1];var cold:Color=samples["1"][1];var dark:Color=samples["2"][1]
 var old_warm:Color=samples["0"][0];var old_dark:Color=samples["2"][0]
 check(warm.get_luminance()>dark.get_luminance()*1.7,"pilot actually darkens with the room")
 check(Vector3(old_warm.r,old_warm.g,old_warm.b).distance_to(Vector3(old_dark.r,old_dark.g,old_dark.b))<.02,"original comparison retains its fixed brightness")
 check(warm.r/maxf(warm.b,.001)>cold.r/maxf(cold.b,.001),"warm and cold lights actually recolour the pilot")
 check(warm.get_luminance()>.08,"lit pilot stays readable at native gameplay scale")
 # Shadowed scene illumination should respond to a real obstruction.
 lab.set_lighting(0);await frames();var before=sample(lab,1)
 var p:Vector3=lab.originals[1].position
 var blocker=lab.kit.box("LightingOccluder",p+Vector3(0,1.2,.85),Vector3(.35,2.4,.15),"metal")
 await frames();var after=sample(lab,1)
 check(after.get_luminance()<before.get_luminance()*.9,"actual geometry can shade the pilot")
 # A blue unshaded floor makes missing toes observable, rather than merely
 # checking a shader flag. These pixels project below the root floor line.
 blocker.queue_free();await frames()
 var blue=StandardMaterial3D.new();blue.albedo_color=Color(.04,.12,.95);blue.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
 lab.get_node("TestFloor").material_override=blue;await frames()
 var pixels=root.get_texture().get_image()
 var texture:Texture2D=lab.pilot.material.get_shader_parameter("color_atlas")
 var source=texture.get_image().get_region(Rect2i(0,0,192,288))
 var centre:Vector3=lab.pilot.sprite.global_position
 var visible_toes=0;var tested_toes=0
 for x in range(192):
  for y in range(223,250):
   if source.get_pixel(x,y).a<.98:continue
   var point=centre+lab.camera.global_basis.x*((float(x)+.5)/192-.5)*2.2*192/288+lab.camera.global_basis.y*(.5-(float(y)+.5)/288)*2.2
   var screen=lab.camera.unproject_position(point)
   var pixel=pixels.get_pixel(clampi(roundi(screen.x),0,pixels.get_width()-1),clampi(roundi(screen.y),0,pixels.get_height()-1))
   tested_toes+=1
   if not (pixel.b>.6 and pixel.b>pixel.r*2):visible_toes+=1
 check(tested_toes>5,"source contains opaque toe pixels below the floor pivot")
 check(tested_toes>0 and float(visible_toes)/tested_toes>.85,"actual foot pixels survive ground depth testing")
 var data={"checks":checks,"failures":failures,"warm":[warm.r,warm.g,warm.b],"cold":[cold.r,cold.g,cold.b],"dark":[dark.r,dark.g,dark.b],"original_warm":[old_warm.r,old_warm.g,old_warm.b],"original_dark":[old_dark.r,old_dark.g,old_dark.b],"occluded":[after.r,after.g,after.b],"toe_pixels":tested_toes,"visible_toes":visible_toes}
 print("IVAN_LIGHTING_SAMPLES ",JSON.stringify(data))
 lab.queue_free();await frames();print("IVAN_LIGHTING_RESULT checks=",checks," failures=",failures);quit(0 if failures==0 else 1)
