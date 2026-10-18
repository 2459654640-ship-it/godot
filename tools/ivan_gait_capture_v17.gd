extends "res://tools/actor_audit_v14.gd"
func _initialize():call_deferred("run")
func run():
 var folder="/tmp/metro1982-review/v17";DirAccess.make_dir_recursive_absolute(folder)
 stage=Stage.new();root.add_child(stage);stage.kit=preload("res://scripts/kit.gd").new(stage)
 var environment=WorldEnvironment.new();var setting=Environment.new();setting.background_mode=Environment.BG_COLOR;setting.background_color=Color("60685f");environment.environment=setting;stage.add_child(environment)
 camera=Camera3D.new();stage.add_child(camera);camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=9.5;camera.position=Vector3(23,30,27);camera.look_at(Vector3.ZERO);camera.current=true
 stage.story.give("revolver")
 for id in ["ivan","ivan_masked"]:
  for armed in [false,true]:
   stage.story.flags.weapon_drawn=armed
   for row in 3:
    for angle in 8:build_actor(id,angle,row,false)
   await settle(5);root.get_texture().get_image().save_png(folder+"/"+id+("-armed" if armed else "-walk")+".png")
   # A real continuous cycle, all directions together, including the planted poses.
   for frame in 8:
    for object in objects:
     if object is CharacterBody3D:
      var painter=object.visual.get_node("Painter");painter.cycle=float(frame)/8;painter._process(0)
    await settle(1)
    root.get_texture().get_image().save_png(folder+"/"+id+("-armed" if armed else "-walk")+"-frame-%02d.png"%frame)
   await clear_figures()
 stage.queue_free();await settle(3);quit()
