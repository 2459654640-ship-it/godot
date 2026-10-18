extends SceneTree
## All eight runtime directions and full poses, with one fixed camera/light.
class CombatState extends RefCounted:
	var enabled=false
	var reload_time=0.0
	var veteran_reload=0.0
	var veteran_health=100
class Stage extends Node3D:
	var story=preload("res://scripts/story.gd").new()
	var combat=CombatState.new()
	var floor_id="life"
	var kit
var stage
var camera
var objects:Array=[]
const OUT="res://docs/screenshots/visual-v14"
func _initialize():call_deferred("run")
func settle(n:int=4):
	for i in n:await process_frame
	await RenderingServer.frame_post_draw
func build_actor(id:String,angle:int,row:int,reloading:bool):
	var a=preload("res://scripts/actor.gd").new();a.art_id=id;stage.add_child(a)
	var side=camera.global_basis.x;var depth=camera.global_basis.z;depth.y=0;depth=depth.normalized()
	a.position=side*((angle-3.5)*1.9)+depth*((row-1)*4.0+.7)
	a.setup(stage.kit,id in ["ivan","ivan_masked"])
	a.set_physics_process(false);a.set_process(false);objects.append(a)
	var direction=side*sin(angle*PI/4)+depth*cos(angle*PI/4)
	a.visual.rotation.y=atan2(-direction.x,-direction.z)
	a.velocity=Vector3.ZERO if row==0 else direction*1.5
	var p=a.visual.get_node("Painter");p.set_process(false);p.cycle=0 if row<2 else .5
	p._process(0)
	var spec=p.manifest[p.atlas_id]
	var exposures:Array=spec.get("exposure",[])
	var gain=1.0 if exposures.is_empty() else float(exposures[p.current_pose][mini(angle,8-angle)])
	p.material.set_shader_parameter("light_tint",Vector3(.87,.86,.83)*gain)
	var label=Label3D.new();label.text=str(angle*45)+"° / "+str(p.current_pose);label.font_size=24;label.pixel_size=.005;label.no_depth_test=true;label.billboard=BaseMaterial3D.BILLBOARD_ENABLED;label.position=a.position-Vector3.UP*.20;stage.add_child(label);objects.append(label)
func clear_figures():
	for object in objects:object.queue_free()
	objects.clear();await settle(2)
func run():
	DirAccess.make_dir_recursive_absolute(OUT)
	stage=Stage.new();root.add_child(stage);stage.kit=preload("res://scripts/kit.gd").new(stage)
	var environment=WorldEnvironment.new();var setting=Environment.new();setting.background_mode=Environment.BG_COLOR;setting.background_color=Color("60685f");environment.environment=setting;stage.add_child(environment)
	camera=Camera3D.new();stage.add_child(camera);camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=9.5;camera.position=Vector3(23,30,27);camera.look_at(Vector3.ZERO);camera.current=true
	stage.story.give("revolver")
	for set_id in ["ivan","ivan_masked","commander","commander_masked","ivan_combat","ivan_masked_combat","veteran_masked_combat"]:
		var armed=set_id.ends_with("_combat");var id=set_id.trim_suffix("_combat")
		stage.story.flags.weapon_drawn=armed;stage.combat.enabled=armed
		for mode in ([false,true] if armed else [false]):
			stage.combat.reload_time=1.5 if mode else 0.0;stage.combat.veteran_reload=stage.combat.reload_time
			for row in 3:
				for angle in 8:build_actor(id,angle,row,mode)
			await settle(6)
			var tag=set_id+("-reload" if mode else "-walk")
			root.get_texture().get_image().save_png(OUT+"/"+tag+".png");print("CAPTURE ",tag)
			await clear_figures()
	stage.queue_free();await settle(3);quit()
