extends SceneTree
class Stage extends Node3D:
	var story=preload("res://scripts/story.gd").new()
	var combat
	var floor_id="life"
	var kit
var stage
var camera
var figures:Array=[]
const OUT="res://docs/screenshots/visual-v13/cast"
func _initialize():call_deferred("run")
func settle(n:int=6):
	for i in n:await process_frame
func actor(id:String,p:Vector3):
	var body=preload("res://scripts/actor.gd").new();body.art_id=id;body.name=id;stage.add_child(body);body.position=p
	body.setup(stage.kit,false);body.set_physics_process(false);body.set_process(false)
	body.visual.rotation.y=atan2(camera.global_basis.z.x,camera.global_basis.z.z)+PI
	var painter=body.visual.get_node("Painter");painter.set_process(false);painter._process(0)
	painter.material.set_shader_parameter("light_tint",Vector3(.87,.86,.83))
	figures.append(body)
	var label=Label3D.new();label.text=id;label.font_size=35;label.pixel_size=.0045;label.no_depth_test=true;label.billboard=BaseMaterial3D.BILLBOARD_ENABLED;label.position=p+Vector3(0,-.3,0);stage.add_child(label);figures.append(label)
func run():
	DirAccess.make_dir_recursive_absolute(OUT)
	stage=Stage.new();root.add_child(stage);stage.kit=preload("res://scripts/kit.gd").new(stage)
	var environment=WorldEnvironment.new();var setting=Environment.new();setting.background_mode=Environment.BG_COLOR;setting.background_color=Color("60685f");environment.environment=setting;stage.add_child(environment)
	camera=Camera3D.new();stage.add_child(camera);camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=8;camera.position=Vector3(23,30,27);camera.look_at(Vector3.ZERO);camera.current=true
	var manifest=JSON.parse_string(FileAccess.get_file_as_string("res://assets/characters/atlas.json"))
	var ids:Array=manifest.keys().filter(func(id):return not id.ends_with("_combat"))
	for page in ceili(ids.size()/10.0):
		for object in figures:object.queue_free()
		figures.clear();await settle(2)
		for i in 10:
			var index=page*10+i
			if index>=ids.size():break
			var p=camera.global_basis.x*((i%5-2)*2.2)+camera.global_basis.z*0
			var depth=camera.global_basis.z;depth.y=0;depth=depth.normalized()
			p+=depth*((i/5)*5.3-2.2)
			actor(ids[index],p)
		await settle(8);root.get_texture().get_image().save_png(OUT+"/individuals-%02d.png"%page)
	for object in figures:object.queue_free()
	figures.clear();await settle(2)
	camera.size=9
	var side=camera.global_basis.x;var towards=camera.global_basis.z;towards.y=0;towards=towards.normalized()
	for i in 6:
		var id=["workers","queue","family","readers","assembly","militia"][i]
		var p=side*((i%3-1)*4)+towards*((i/3)*6-2.5)
		var group=preload("res://scripts/painted_resident_group.gd").new()
		group.setup(stage,id,p,3,1.28 if id=="assembly" else 1.73);group.set_process(false)
		group.material.set_shader_parameter("light_tint",Vector3(.87,.86,.83))
		actor("ivan",p+side*1.65)
	await settle(8);root.get_texture().get_image().save_png(OUT+"/groups-with-ivan.png")
	stage.queue_free();await settle(3);quit()
