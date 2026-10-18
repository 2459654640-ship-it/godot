extends "res://tools/actor_audit_v14.gd"
func run():
 var folder="res://docs/characters";DirAccess.make_dir_recursive_absolute(folder)
 stage=Stage.new();root.add_child(stage);stage.kit=preload("res://scripts/kit.gd").new(stage)
 var environment=WorldEnvironment.new();var setting=Environment.new();setting.background_mode=Environment.BG_COLOR;setting.background_color=Color("60685f");environment.environment=setting;stage.add_child(environment)
 camera=Camera3D.new();stage.add_child(camera);camera.projection=Camera3D.PROJECTION_ORTHOGONAL
 camera.position=Vector3(23,30,27)+Vector3.UP*.8;camera.look_at(Vector3.UP*.8);camera.current=true
 var manifest:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/characters/atlas.json"));var ids=manifest.keys();ids.sort()
 var rows=ceili(ids.size()/10.0);camera.size=maxf(14,rows*2.0+1.3)
 var side=camera.global_basis.x;var depth=camera.global_basis.z;depth.y=0;depth=depth.normalized()
 for i in ids.size():
  var a=preload("res://scripts/actor.gd").new();a.art_id=ids[i];a.name="Gallery_"+ids[i];stage.add_child(a);a.position=side*((i%10-4.5)*1.85)+depth*((int(i/10)-(rows-1)/2.0)*3.0)
  a.setup(stage.kit,false);a.set_physics_process(false);a.visual.rotation.y=atan2(-depth.x,-depth.z)
  var p=a.visual.get_node("Painter");p.set_process(false);p._process(0);p.material.set_shader_parameter("light_tint",Vector3(.87,.86,.83))
  var label=Label3D.new();label.text="%02d  %s"%[i+1,ids[i].left(12)];label.font_size=24;label.pixel_size=.005;label.no_depth_test=true;label.billboard=BaseMaterial3D.BILLBOARD_ENABLED;label.position=a.position-Vector3.UP*.20;stage.add_child(label)
 await settle(5);root.get_texture().get_image().save_png(folder+"/all-characters.png");print("CAPTURE current character gallery: ",ids.size())
 stage.queue_free();await settle(3);quit()
