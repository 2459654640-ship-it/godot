extends Node3D
## A self-contained comparison room. No Session transfer, game save or story writes.
const Surface=preload("res://scripts/ui_surface.gd")
const Kit=preload("res://scripts/kit.gd")
const Actor=preload("res://scripts/actor.gd")
const Pilot=preload("res://scripts/prerendered_ivan.gd")
var originals:Array=[]
var pilot
var camera:Camera3D
var kit
var lamps:Array=[]
var environment:Environment
var automatic=true
var moving=true
var time=0.0
var lighting=0
var caption:Label
var route_origin=Vector3.ZERO
func _ready():
 kit=Kit.new(self)
 kit.box("TestFloor",Vector3(0,-.12,0),Vector3(15,.24,12),"tile",true)
 for x in [-7.5,7.5]:kit.wall("LabWall",Vector2(x,-6),Vector2(x,6),true)
 kit.wall("LabBack",Vector2(-7.5,-6),Vector2(7.5,-6),true)
 kit.wall("LabFront",Vector2(-7.5,6),Vector2(7.5,6),true);kit.finish_walls()
 for x in [-4,4]:
  kit.bench(Vector3(x,0,-4),2.6,true,PI)
  kit.locker(Vector3(x,0,-5.5))
 kit.pipe(Vector3(-7,2,-5.7),Vector3(7,2,-5.7),.075,"rust")
 for x in [-2,2]:
  kit.lamp(Vector3(x,2.5,2.2),true,2.8,6)
  kit.pipe(Vector3(x,0,2.1),Vector3(x,2.5,2.1),.035,"metal")
  kit.box("InspectionLampBase",Vector3(x,.06,2.1),Vector3(.5,.12,.45),"metal")
 # Find the actual lamp nodes; protective cage meshes are added after each lamp.
 lamps=find_children("*","OmniLight3D",false,false)
 var world=WorldEnvironment.new();environment=Environment.new();environment.background_mode=Environment.BG_COLOR;environment.background_color=Color("111b1b");environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;environment.ambient_light_color=Color("a7aca0");environment.ambient_light_energy=.20;world.environment=environment;add_child(world)
 camera=Camera3D.new();add_child(camera);camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=9.0;camera.position=Vector3(10,14.462,13);camera.look_at(Vector3(0,.7,0));camera.current=true
 for i in range(2):
  var actor=Actor.new();actor.name="IvanOriginal" if i==0 else "IvanPilot";add_child(actor);actor.setup(kit,true);actor.camera=camera
  actor.position=Vector3(-2 if i==0 else 2,.04,0);actor.use_override=true;originals.append(actor)
 pilot=Pilot.new();originals[1].visual.add_child(pilot);pilot.setup(originals[1])
 var old=originals[1].visual.get_node("Painter");old.hide();old.set_process(false)
 # Keep the approximate caster safely inside the reconstructed body surface.
 for mesh in originals[1].get_children():
  if mesh is MeshInstance3D and mesh.cast_shadow==GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY:mesh.scale=Vector3(.6,1,.6)

 for pair in [["move_left",KEY_A],["move_right",KEY_D],["move_up",KEY_W],["move_down",KEY_S]]:
  if not InputMap.has_action(pair[0]):InputMap.add_action(pair[0])
  var key=InputEventKey.new();key.physical_keycode=pair[1]
  if not InputMap.action_has_event(pair[0],key):InputMap.action_add_event(pair[0],key)
 ui();set_lighting(0)
func ui():
 var layer=CanvasLayer.new();add_child(layer);var canvas=Control.new();canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);canvas.mouse_filter=Control.MOUSE_FILTER_IGNORE;layer.add_child(canvas)
 var theme=Theme.new();theme.default_font=load("res://assets/fonts/MetroSans.otf");theme.default_font_size=20;canvas.theme=theme
 var panel=PanelContainer.new();panel.position=Vector2(42,32);panel.size=Vector2(1516,130);canvas.add_child(panel)
 var style=StyleBoxFlat.new();style.bg_color=Color("17221f");style.border_color=Color("89744f");style.set_border_width_all(1);style.content_margin_left=22;style.content_margin_top=15;style.content_margin_bottom=15;panel.add_theme_stylebox_override("panel",style);Surface.attach(panel)
 var box=VBoxContainer.new();panel.add_child(box)
 var title=Label.new();title.text="伊万 · 角色样片";title.add_theme_font_override("font",load("res://assets/fonts/MetroSerif.otf"));title.add_theme_font_size_override("font_size",30);box.add_child(title)
 caption=Label.new();box.add_child(caption)
 var note=Label.new();note.text="左：现有角色　　右：同一模型生成的八方向动画　　WASD 手动移动 / Esc 退出试验";note.add_theme_font_size_override("font_size",18);box.add_child(note)
 var controls=HBoxContainer.new();controls.position=Vector2(42,900);controls.add_theme_constant_override("separation",14);canvas.add_child(controls)
 button(controls,"自动 / 手动",func():automatic=not automatic;time=0)
 button(controls,"站立 / 行走",func():moving=not moving)
 button(controls,"切换照明",func():set_lighting((lighting+1)%3))
 button(controls,"复位",reset)
 button(controls,"退出试验",leave)
func button(parent,text:String,action:Callable):
 var b=Button.new();b.text=text;b.custom_minimum_size=Vector2(190,55);b.add_theme_color_override("font_color",Color("e4d2aa"));parent.add_child(b);Surface.attach(b,"button");b.pressed.connect(action)
func set_lighting(mode:int):
 lighting=mode
 for lamp in lamps:
  lamp.light_color=Color("ffc283") if mode==0 else Color("8cb6d2")
  lamp.light_energy=2.4 if mode==0 else (1.7 if mode==1 else .05)
  lamp.shadow_enabled=true
  lamp.position.z=1.8
 environment.ambient_light_energy=.28 if mode<2 else .045
 caption.text=["暖灯：观察衣服、脸和背包的受光","冷灯：观察相同动作在冷光中的颜色","暗处：人物应随房间变暗，仍保留轮廓"][mode]
func reset():
 time=0
 for i in range(2):originals[i].position=Vector3(-2 if i==0 else 2,.04,0);originals[i].velocity=Vector3.ZERO
func leave():get_tree().quit()
func _physics_process(delta):
 time+=delta
 var input=Input.get_vector("move_left","move_right","move_up","move_down")
 if input.length()>.1:automatic=false
 for actor in originals:
  actor.motion_override=input if moving else Vector2.ZERO
  if automatic:
   var direction=floori(time/2.5)%8
   actor.motion_override=Vector2(cos(direction*PI/4),sin(direction*PI/4))*.5 if moving and fmod(time,2.5)<1.2 else Vector2.ZERO
 if automatic and fmod(time,20)<delta:reset()
func _unhandled_input(event):
 if event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:leave()
