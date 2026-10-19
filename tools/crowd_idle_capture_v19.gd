extends "res://tools/actor_audit_v14.gd"
func _initialize():call_deferred("run")
func run():
 var folder="/tmp/metro1982-review/v19/idle-isolated";DirAccess.make_dir_recursive_absolute(folder)
 stage=Stage.new();root.add_child(stage);stage.floor_id="commune";stage.kit=preload("res://scripts/kit.gd").new(stage)
 var env=WorldEnvironment.new();var e=Environment.new();e.background_mode=Environment.BG_COLOR;e.background_color=Color("60685f");env.environment=e;stage.add_child(env)
 camera=Camera3D.new();stage.add_child(camera);camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=4.4;camera.position=Vector3(23,30,27);camera.look_at(Vector3(0,.6,0));camera.current=true
 var group=preload("res://scripts/painted_resident_group.gd").new();group.setup(stage,"assembly",Vector3.ZERO,3,1.28);group.set_process(false)
 for frame in 18:
  group._process(.25)
  for ink in group.member_materials:ink.set_shader_parameter("light_tint",Vector3(.88,.86,.82))
  await settle(2);root.get_texture().get_image().save_png(folder+"/idle-%02d.png"%frame)
 stage.queue_free();await settle();quit()
