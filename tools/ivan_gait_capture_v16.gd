extends "res://tools/actor_audit_v14.gd"
func run():
 var folder="res://docs/characters";DirAccess.make_dir_recursive_absolute(folder)
 stage=Stage.new();root.add_child(stage);stage.kit=preload("res://scripts/kit.gd").new(stage)
 var environment=WorldEnvironment.new();var setting=Environment.new();setting.background_mode=Environment.BG_COLOR;setting.background_color=Color("60685f");environment.environment=setting;stage.add_child(environment)
 camera=Camera3D.new();stage.add_child(camera);camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=9.5;camera.position=Vector3(23,30,27);camera.look_at(Vector3.ZERO);camera.current=true
 for id in ["ivan","ivan_masked"]:
  for row in 3:
   for angle in 8:build_actor(id,angle,row,false)
  await settle(5);root.get_texture().get_image().save_png(folder+"/"+id+"-eight-directions.png");print("CAPTURE ",id," eight directions");await clear_figures()
 stage.queue_free();await settle(3);quit()
