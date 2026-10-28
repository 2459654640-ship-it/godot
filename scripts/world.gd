extends Node3D
const SaveStore=preload("res://scripts/save_store.gd")
const Publications=preload("res://scripts/publications.gd")
const PublicationPlaces=preload("res://scripts/publication_places.gd")
const PublicRadio=preload("res://scripts/public_radio.gd")
const InteractionRegions=preload("res://scripts/interaction_regions.gd")
var public_radio
var interaction_candidates:Array[String]=[]
var chosen_interaction=""
var played_seconds=0.0
var arrival_data:Dictionary={}
var combat
var grey_camp
const ArtDirection=preload("res://scripts/art_direction.gd")
const Kit = preload("res://scripts/kit.gd")
const Actor = preload("res://scripts/actor.gd")
const Story = preload("res://scripts/story.gd")
const HUD = preload("res://scripts/hud.gd")
const CampaignMaps=preload("res://scripts/campaign_maps.gd")
var campaign_gate:MeshInstance3D
var campaign_gate_flag="star_access"
var campaign_gate_state=-1
var gate_tween:Tween
var factory_exit_leaves:Array[Node3D]=[]
var departure_animating=false
const Labor=preload("res://scripts/labor_floor.gd")
@export var floor_id="life"
const Wing=preload("res://scripts/residential_wing.gd")
var kit
var story
var player
var camera: Camera3D
var hud
var targets: Dictionary = {}
var npcs: Dictionary = {}
var nearest = ""
var gate_mesh: MeshInstance3D
var side_mesh: MeshInstance3D
var gate_body: CollisionShape3D
var side_body: CollisionShape3D
var phase = 0.0
var step_clock=0.0
var step_variant=0
var step_samples:Array[AudioStream]=[]
var step_audio:AudioStreamPlayer
var ambience:AudioStreamPlayer
var event_music:AudioStreamPlayer
var event_music_id=""
var event_music_tween:Tween
var waiting_shift = false
var pending_route=""
var previous_position=Vector3.ZERO
var overview = false
var camera_size = 17.0
var living
var initialized = false
var save_path="user://d6_save.json"
var debug_camera_target=Vector3.ZERO
var capture_mode=false
var room_name="伊万的卧室"
var wall_veil
var navigation
var guard_away_time=0.0
const LIFE_ZONES=[
 {"name":"伊万的卧室","rect":Rect2(-15,-9,7,9),"code":"01"},
 {"name":"维修工坊","rect":Rect2(-8,-9,9,9),"code":"02"},
 {"name":"公共食堂","rect":Rect2(1,-9,9,9),"code":"03"},
 {"name":"第 7 供应点","rect":Rect2(10,-9,5,9),"code":"04"},
 {"name":"洗漱 / 储物区","rect":Rect2(-15,3.2,7,6.8),"code":"05"},
 {"name":"值班休息区","rect":Rect2(-8,3.2,10,6.8),"code":"06"},
 {"name":"东侧维修岗","rect":Rect2(2,3.2,7,6.8),"code":"07"},
 {"name":"东侧维修坡道","rect":Rect2(9,3.2,6,6.8),"code":"08"},
 {"name":"生活层主通道","rect":Rect2(-15,0,30,3.2),"code":"00"}]
var zones=LIFE_ZONES.duplicate(true)

func _ready():
	inputs()
	story=Story.new()
	var transfer=get_node_or_null("/root/Session")
	var arrival=Vector3.INF
	if transfer and not transfer.pending.is_empty():
		arrival_data=transfer.pending.story.duplicate(true)
		if arrival_data.get("save_slot","") in SaveStore.manual_paths():save_path=arrival_data.save_slot
		story.restore(transfer.pending.story)
		played_seconds=float(transfer.pending.story.get("played_seconds",0))
		camera_size=clampf(float(transfer.pending.story.get("camera_size",17)),12,19)
		arrival=transfer.pending.position
		if ((floor_id=="commune" and transfer.pending.story.get("layout_revision",0)<12) or (floor_id=="sech" and transfer.pending.story.get("layout_revision",0)<11) or (floor_id=="starcity" and transfer.pending.story.get("layout_revision",0)<19) or (floor_id not in ["life","labor","sech"] and transfer.pending.story.get("layout_revision",0)<8)):arrival=CampaignMaps.LAYOUTS[floor_id].spawn
		transfer.pending={}
	story.Campaign.District.prepare(self)
	kit=Kit.new(self)
	build_environment()
	if floor_id=="life":
		zones.append_array(Wing.ZONES)
		build_structure()
		Wing.structure(self)
		kit.finish_walls()
		build_residence()
		build_workshop()
		build_mess()
		build_supply()
		build_south()
		build_corridor()
		build_dressing()
		Wing.furnish(self)
		build_implied_life()
	elif floor_id=="labor":
		zones=Labor.ZONES.duplicate(true)
		Labor.build(self)
	else:
		zones=CampaignMaps.rooms(floor_id)
		CampaignMaps.build(self)
	preload("res://scripts/environment_details.gd").build(self)
	PublicationPlaces.build(self)
	public_radio=PublicRadio.new();add_child(public_radio);public_radio.setup(self)
	ArtDirection.refine(self)
	kit.batch_static()
	get_node("/root/Session").Video.apply_lights(self,int(get_node("/root/Session").video.quality))
	build_people() if floor_id=="life" else build_labor_people()
	navigation=preload("res://scripts/route_grid.gd").new()
	if floor_id=="life":
		build_targets()
		Wing.targets(self)
		target("pipe_exit",Vector3(10.8,0,8.6),"检修管线出口")
		target("other_life",Vector3(17.04,0,1.6),"其它生活区")
	elif floor_id=="labor":
		Labor.targets(self)
		target("d6_return_desk",npcs.commander.position,"返站审核 / 科瓦廖夫","talk")
		target("coal_gate_entry",targets.coal_door.pos,"煤矿限区检票")
	else:CampaignMaps.targets(self)
	if floor_id not in ["life","labor"]:CampaignMaps.residents(self)
	preload("res://scripts/supply_storage.gd").setup(self)
	preload("res://scripts/raid_loot.gd").setup(self)
	navigation.setup(self)
	setup_daily_routines()
	preload("res://scripts/npc_workplace.gd").configure(self)
	if arrival.is_finite():player.position=clear_arrival(arrival)
	if not arrival_data.is_empty():restore_placement(arrival_data)
	story.context.floor=floor_id
	if floor_id=="starcity":
		story.ending=false
		# Old interior saves retain their history, but cannot resume an internal
		# reunion/cutscene or bypass the current exterior-only chapter.
		var sequence:String=story.flags.get("comic",{}).get("sequence","")
		if story.flags.get("comic",{}).get("active",false) and sequence not in ["star_road","arrive_starcity","star_back_commune","star_back_sech"]:story.flags.comic={"active":false}
		story.flags.erase("resume_dialogue")
		story.flags.erase("next_sequence")
	if floor_id=="waterworks" and story.route=="official":story.flags.plant_briefed=true
	kit.prepare_highlights()
	camera=Camera3D.new()
	add_child(camera)
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	camera.size=camera_size
	camera.near=0.4
	camera.far=260 if floor_id=="east_district" else 90
	camera.current=true
	player.camera=camera
	var c=CanvasLayer.new()
	add_child(c)
	hud=HUD.new()
	c.add_child(hud)
	hud.setup(self)
	story.changed.connect(on_story_changed)
	ambience=AudioStreamPlayer.new()
	add_child(ambience)
	ambience.stream=load("res://assets/audio/shelter_theme.wav")
	ambience.bus="Music"
	var score=preload("res://scripts/scene_score.gd").new();add_child(score);score.setup(self)
	if DisplayServer.get_name()!="headless":ambience.play()
	step_audio=AudioStreamPlayer.new()
	add_child(step_audio)
	step_audio.stream=load("res://assets/audio/step.wav")
	step_audio.volume_db=-12
	step_audio.bus="Footsteps"
	for file in ["step","step_b","step_c","step_d"]:step_samples.append(load("res://assets/audio/"+file+".wav"))
	on_story_changed()
	set_camera(0,true)
	combat=preload("res://scripts/combat.gd").new();add_child(combat);combat.setup(self)
	living=preload("res://scripts/living_world.gd").new();add_child(living);living.setup(self)
	combat.restore_state(arrival_data.get("combat_state",{}))
	story.Campaign.District.restore_combat(self)
	if floor_id in ["east_district","grey_shelter"]:
		grey_camp=preload("res://scripts/greyhound_camp.gd").new();add_child(grey_camp);grey_camp.setup(self)
		if floor_id=="east_district":
			var survey=preload("res://scripts/city_survey.gd").new();add_child(survey);survey.setup(self)
	initialized=true
	call_deferred("autosave")
	wall_veil=preload("res://scripts/wall_veil.gd").new()
	add_child(wall_veil)
	wall_veil.setup(self)
	previous_position=player.position
	if story.flags.get("comic",{}).get("active",false):hud.call_deferred("show_comic")
	elif story.ending:hud.call_deferred("show_chapter_end")
	elif DisplayServer.get_name()!="headless" and floor_id=="labor" and story.f("intro_done") and not story.f("lower_war_seen"):hud.call_deferred("show_comic","lower_ward")
	elif DisplayServer.get_name()!="headless" and "--skip-intro" not in OS.get_cmdline_user_args() and floor_id=="life" and not story.f("intro_done"):hud.call_deferred("show_comic","intro")
	if "--capture" in OS.get_cmdline_user_args():
		capture_mode=true
		capture_later()

func inputs():
	var actions={"move_left":[KEY_A,KEY_LEFT],"move_right":[KEY_D,KEY_RIGHT],"move_up":[KEY_W,KEY_UP],"move_down":[KEY_S,KEY_DOWN],"interact":[KEY_E],"inventory":[KEY_I],"journal":[KEY_J],"map":[KEY_M],"overview":[KEY_TAB],"save":[KEY_F5],"load":[KEY_F9],"reload":[KEY_R],"draw_weapon":[KEY_1],"sneak":[KEY_CTRL]}
	for action in actions:
		if not InputMap.has_action(action):InputMap.add_action(action)
		for key in actions[action]:
			var ev=InputEventKey.new()
			ev.physical_keycode=key
			InputMap.action_add_event(action,ev)

	if not InputMap.has_action("shoot"):
		InputMap.add_action("shoot");var mouse=InputEventMouseButton.new();mouse.button_index=MOUSE_BUTTON_LEFT;InputMap.action_add_event("shoot",mouse)
func build_environment():
	var we=WorldEnvironment.new()
	var e=Environment.new()
	e.background_mode=Environment.BG_COLOR
	e.background_color=Color("a8bac4") if floor_id in ["surface","starcity","east_district"] else Color("090b0b")
	e.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color=Color("9bada6")
	e.ambient_light_energy=0.29
	if floor_id not in ["life","labor"]:
		var atmosphere:Dictionary=CampaignMaps.LAYOUTS[floor_id]
		e.ambient_light_color=Color(atmosphere.ambient)
		e.ambient_light_energy=.45 if floor_id in ["surface","starcity","east_district"] else atmosphere.energy
		if floor_id in ["surface","starcity","east_district"]:e.fog_enabled=true;e.fog_density=.0008;e.fog_light_color=Color("bac8cf")
	e.tonemap_mode=Environment.TONE_MAPPER_FILMIC
	we.environment=e
	add_child(we)
	var light=DirectionalLight3D.new()
	add_child(light)
	light.rotation_degrees=Vector3(-65,-28,0)
	light.light_color=Color("9caaa5")
	light.light_energy=0.32
	if floor_id not in ["life","labor"]:
		light.light_color=Color("b9ccd2") if floor_id=="waterworks" else Color("8d9fa8")
		light.light_energy=.45 if floor_id in ["surface","starcity","east_district"] else (.21 if floor_id=="waterworks" else .12)
	light.shadow_enabled=true
	light.directional_shadow_max_distance=65
	light.shadow_bias=0.04
	ArtDirection.environment(self,e,light)
	kit.box("UndergroundVoid",Vector3(0,-1.4 if floor_id=="sech" else -.65,0),Vector3(200,0.5,200),"black")

func build_structure():
	kit.box("Foundation",Vector3(0,-0.30,0.5),Vector3(30.5,0.5,19.5),"concrete")
	kit.box("FloorCollision",Vector3(0,-0.10,0.5),Vector3(30,0.20,19),"tile",true).visible=false
	for zone in zones:
		var r:Rect2=zone.rect
		var m=kit.box("Floor_"+zone.code,Vector3(r.get_center().x,0.006,r.get_center().y),Vector3(r.size.x-0.04,0.012,r.size.y-0.04),"wood" if zone.code=="08" else ("tile" if zone.code not in ["02","07"] else "concrete"))
		m.material_override=m.material_override.duplicate()
		m.material_override.uv1_scale=Vector3.ONE/2.4
		if zone.code=="01":m.material_override.albedo_color=Color("b7a88a")
		if zone.code=="08":m.material_override.albedo_color=Color("677b7b")
	kit.wall("North",Vector2(-15,-9),Vector2(15,-9))
	kit.wall("WestNorth",Vector2(-15,-9),Vector2(-15,.74))
	kit.wall("WestSouth",Vector2(-15,2.46),Vector2(-15,10))
	kit.wall("SouthCut",Vector2(-15,10),Vector2(9,10),true)
	kit.box("RampSouthRail",Vector3(12,.5,9.9),Vector3(6,.9,.18),"wood",true)
	kit.wall("EastCut",Vector2(15,-9),Vector2(15,0),true)
	zones.append({"name":"其他生活区门前","rect":Rect2(15,0,2.2,3.2),"code":"00"})
	kit.box("RampEdgeStop",Vector3(14.9,1.3,6.6),Vector3(.22,2.6,6.8),"dark",true).visible=false
	# North rooms: independent spaces linked by a 3.2m main circulation spine.
	for x in [-8,1,10]:kit.wall("NorthPartition",Vector2(x,-9),Vector2(x,0),true)
	# Two homes, one unchanged common foyer. Existing NPC/target coordinates stay
	# in place. This is the only new collision partition (explicitly requested).
	kit.wall("SemyonRoomRear",Vector2(-11.95,-9),Vector2(-11.95,-7.7))
	kit.wall("SemyonRoomDivider",Vector2(-11.95,-7.7),Vector2(-11.95,-4.76),true)
	kit.wall("SemyonRoomJamb",Vector2(-11.95,-3.04),Vector2(-11.95,-2.80),true)
	kit.doorway(-11.95,-3.90,true)
	var door_x=[-10.5,-3.5,5.2,12.3]
	var start=-15.0
	for x in door_x:
		kit.wall("NorthCorridorWall",Vector2(start,0),Vector2(x-0.86,0),true)
		kit.doorway(x,0)
		start=x+0.86
	kit.wall("NorthCorridorEnd",Vector2(start,0),Vector2(15,0),true)
	start=-15
	for x in [-11.0,-3.4,5.6]:
		kit.wall("SouthCorridorWall",Vector2(start,3.2),Vector2(x-0.86,3.2),true)
		kit.doorway(x,3.2)
		start=x+0.86
	kit.wall("SouthCorridorEnd",Vector2(start,3.2),Vector2(15,3.2),true)
	for x in [-8,2]:kit.wall("SouthPartition",Vector2(x,3.2),Vector2(x,10),true)
	# Guard-to-tunnel partition with two actual, separately locked openings.
	for segment in [[3.2,3.7],[5.3,5.9],[7.5,10.0]]:
		kit.wall("GatePartition",Vector2(9,segment[0]),Vector2(9,segment[1]),true)
	kit.doorway(9,4.5,true)
	kit.doorway(9,6.7,true)
	gate_mesh=kit.box("LockedMainGate",Vector3(9,1.02,6.7),Vector3(0.15,2.04,1.45),"metal",true)
	gate_body=gate_mesh.get_child(0).get_child(0)
	side_mesh=kit.box("LockedSideDoor",Vector3(9,1.02,4.5),Vector3(0.12,2.04,1.45),"rust",true)
	side_body=side_mesh.get_child(0).get_child(0)
	kit.box("InnerLatch",Vector3(9.25,1,5.27),Vector3(.15,.4,.12),"brass")
	for x in [-14,-7,0,7,14]:
		kit.box("PillarFoot",Vector3(x,0.1,-8.65),Vector3(0.4,0.2,0.5),"dark")
		kit.box("Pillar",Vector3(x,1.4,-8.72),Vector3(0.24,2.8,0.34),"concrete")
	# Floor-level guide lines never create collision snags.
	for x in range(-14,15):kit.box("CorridorGuide",Vector3(x,0.02,1.60),Vector3(0.48,0.02,0.035),"brass")
	for x in [-13,-6,1,8,14]:kit.lamp(Vector3(x,2.4,-0.14),x<0,1.45,5.0)

func build_residence():
	kit.bed(Vector3(-13.1,0,-6.2),"cloth")
	kit.bed(Vector3(-9.2,0,-6.2))
	kit.box("WovenRug",Vector3(-10.2,0.024,-4.6),Vector3(2.2,0.025,2.8),"red")
	var rug=MeshInstance3D.new()
	rug.name="WornMedallionCarpet"
	var rug_plane=PlaneMesh.new()
	rug_plane.size=Vector2(2.2,2.8)
	rug.mesh=rug_plane
	var rug_material=StandardMaterial3D.new()
	rug_material.albedo_texture=load("res://assets/visual/rug.png")
	rug_material.roughness=0.98
	rug_material.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	rug.material_override=rug_material
	rug.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(rug)
	rug.position=Vector3(-10.2,0.041,-4.6)
	for z in [-5.8,-5.5,-3.7,-3.4]:kit.box("RugWeave",Vector3(-10.2,0.04,z),Vector3(2,0.01,0.025),"cloth")
	kit.box("BedsideCabinet",Vector3(-11.2,0.4,-7.7),Vector3(1,0.8,0.55),"wood",true)
	kit.box("Radio",Vector3(-11.2,0.98,-7.65),Vector3(0.68,0.38,0.32),"wood")
	kit.box("RadioDial",Vector3(-11.1,1.02,-7.47),Vector3(0.32,0.11,0.02),"cream")
	for x in [-11.4,-10.95]:kit.cyl("RadioKnob",Vector3(x,0.91,-7.46),0.035,0.035,"brass").rotation.x=PI/2
	for x in [-11.45,-11.38,-11.31]:kit.box("RadioSpeaker",Vector3(x,1.06,-7.47),Vector3(0.025,0.16,0.02),"dark")
	kit.pipe(Vector3(-11.4,1.1,-7.7),Vector3(-11.5,1.9,-7.7),0.01,"dark")
	kit.cyl("ReadingLampBase",Vector3(-10.82,0.85,-7.9),0.10,0.04,"brass")
	kit.pipe(Vector3(-10.82,0.87,-7.9),Vector3(-10.82,1.19,-7.9),0.018,"brass")
	kit.cyl("ReadingLampShade",Vector3(-10.82,1.23,-7.9),0.18,0.18,"green",null,0.075)
	var reading_light=OmniLight3D.new()
	add_child(reading_light)
	reading_light.position=Vector3(-10.82,1.16,-7.9)
	reading_light.light_color=Color("ffbc74")
	reading_light.light_energy=0.8
	reading_light.omni_range=2.5
	kit.crate(Vector3(-12.2,0,-4.8),Vector3(0.65,0.35,0.45))
	kit.locker(Vector3(-14.2,0,-2.0))
	kit.locker(Vector3(-14.2,0,-2.65))
	kit.bench(Vector3(-11.8,0,-1.4),1.1,true,PI)
	kit.poster(Vector3(-12.7,1.65,-8.87),"МОСКВА · 1962",false)
	kit.signboard("01 / ЖИЛОЙ ОТСЕК",Vector3(-10.4,2.1,-8.83),3.0)
	kit.signboard("СЕМЁНОВ",Vector3(-13.45,2.22,-8.82),2.1)
	kit.label("谢苗诺夫",Vector3(-13.45,1.85,-8.78),22,Color("bcb28f"))
	kit.label("ИВАН / 伊万",Vector3(-9.6,1.72,-8.78),24,Color("bcb28f"))
	kit.lamp(Vector3(-13.4,2.2,-8.7),true,2.2,7)
	kit.box("CoatOnWall",Vector3(-14.83,1.3,-4.0),Vector3(0.12,0.7,0.4),"cloth")
	# Heating pipes hug the wall above walking headroom or stay in fixture footprints.
	for y in [0.35,0.52]:kit.pipe(Vector3(-14.75,y,-8.4),Vector3(-14.75,y,-0.6),0.05)

func build_workshop():
	kit.box("Workbench",Vector3(-3.8,0.75,-7.6),Vector3(4.3,0.12,1.0),"wood",true)
	kit.box("WorkbenchBase",Vector3(-3.8,0.35,-7.6),Vector3(4.0,0.7,0.8),"metal",true)
	kit.box("ToolBoard",Vector3(-3.8,1.6,-8.78),Vector3(4.4,1.25,0.09),"wood")
	for x in [-5.5,-4.8,-4.1,-3.4,-2.7,-2.0]:
		kit.box("HangingTool",Vector3(x,1.75,-8.69),Vector3(0.045,0.43,0.025),"metal")
		kit.box("ToolHandle",Vector3(x,1.5,-8.67),Vector3(0.08,0.18,0.05),"red")
	kit.box("Vise",Vector3(-5.2,0.92,-7.2),Vector3(0.45,0.23,0.35),"blue")
	kit.cyl("Motor",Vector3(-3.2,1.05,-7.55),0.24,0.55,"metal").rotation.z=PI/2
	kit.box("Manual",Vector3(-2.1,0.84,-7.4),Vector3(0.44,0.04,0.30),"paper").rotation.y=0.2
	for x in [-6.8,-5.9]:kit.crate(Vector3(x,0,-5.3))
	kit.locker(Vector3(-0.3,0,-7.9))
	kit.locker(Vector3(-0.3,0,-7.15))
	kit.box("SparePipeRack",Vector3(-7.5,0.5,-6.4),Vector3(0.55,1,2.4),"dark",true)
	for y in [0.4,0.7,1.0]:kit.pipe(Vector3(-7.4,y,-7.5),Vector3(-7.4,y,-5.3),0.09,"rust")
	kit.bench(Vector3(-1.2,0,-2.0),1.8,true,PI)
	kit.signboard("02 / МАСТЕРСКАЯ",Vector3(-3.6,2.45,-8.83),3.6)
	kit.lamp(Vector3(-4.5,2.3,-8.7),true,2.5,7)
	kit.lamp(Vector3(-0.8,2.3,-4.1),false,1.4,4)

func build_mess():
	# 0.75m tables with clear circulation aisles >=1.8m.
	for p in [Vector3(3.2,0,-4.3),Vector3(7.0,0,-4.3)]:
		kit.table(p)
		kit.bench(p+Vector3(0,0,0.95),2.1,false)
		kit.bench(p+Vector3(0,0,-1.0),2.1,true)
	kit.box("KitchenCounter",Vector3(5.1,0.48,-7.9),Vector3(6.4,0.96,1.05),"metal",true)
	var counter=kit.box("CounterTop",Vector3(5.1,1.0,-7.9),Vector3(6.5,0.08,1.12),"metal")
	counter.material_override=counter.material_override.duplicate()
	counter.material_override.albedo_color=Color("b4b9ac")
	counter.material_override.roughness=0.72
	for x in [3.5,4.5]:
		kit.cyl("SoupPot",Vector3(x,1.25,-7.9),0.30,0.46,"metal")
		kit.cyl("PotLid",Vector3(x,1.49,-7.9),0.32,0.04,"dark")
		kit.cyl("PotHandle",Vector3(x,1.54,-7.9),0.07,0.06,"boot")
		for side in [-1,1]:kit.box("PotGrip",Vector3(x+side*0.35,1.38,-7.9),Vector3(0.15,0.04,0.09),"dark")
	kit.box("Sink",Vector3(6.5,1.07,-7.85),Vector3(0.80,0.08,0.60),"dark")
	kit.pipe(Vector3(6.5,1.0,-8.1),Vector3(6.5,1.48,-8.1),0.025,"metal")
	kit.pipe(Vector3(6.5,1.48,-8.1),Vector3(6.5,1.48,-7.85),0.025,"metal")
	kit.box("KitchenShelf",Vector3(5.0,1.8,-8.7),Vector3(5.8,0.09,0.4),"wood")
	for x in [2.5,2.8,3.1,4.3,4.6,5.5,5.8,6.7,7.0]:kit.cyl("FoodTin",Vector3(x,1.96,-8.68),0.10,0.24,"cream" if x<5 else "red")
	kit.pipe(Vector3(8.8,0.3,-8.5),Vector3(8.8,1.6,-8.5),0.06)
	kit.pipe(Vector3(8.8,1.6,-8.5),Vector3(8.8,1.6,-6.4),0.06)
	kit.cyl("ValveWheel",Vector3(8.8,1.25,-6.5),0.22,0.04,"red").rotation.x=PI/2
	kit.cyl("CatchBucket",Vector3(8.8,0.20,-6.5),0.23,0.4,"metal")
	kit.poster(Vector3(1.8,1.9,-8.85),"ХЛЕБ И ТРУД")
	kit.signboard("03 / ОБЩАЯ СТОЛОВАЯ",Vector3(5.5,2.5,-8.83),4.4)
	kit.lamp(Vector3(4,2.2,-6.5),true,3.0,7)
	kit.lamp(Vector3(8.1,2.2,-8.65),true,1.7,5)
	# Carefully constrained steam geometry, not a giant fog plane.
	for i in range(5):
		var m=kit.cyl("Steam",Vector3(3.5+sin(i)*0.07,1.65+i*0.12,-7.9),0.06+i*0.015,0.11,"cream")
		var mat=StandardMaterial3D.new()
		mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_color=Color(0.7,0.75,0.68,0.075)
		m.material_override=mat

func build_supply():
	kit.box("RationCounter",Vector3(12.5,0.50,-5.5),Vector3(3.1,1,0.65),"wood",true)
	kit.box("RationCounterTop",Vector3(12.5,1.03,-5.5),Vector3(3.2,0.10,0.75),"metal")
	for x in [11.4,12.3,13.2,14.1]:kit.crate(Vector3(x,0,-8.1),Vector3(0.7,0.8,0.7))
	for y in [1.1,1.7]:
		kit.box("SupplyShelf",Vector3(12.6,y,-8.3),Vector3(3.4,0.08,0.5),"wood")
		for x in [11.4,11.8,12.2,13.2,13.6,14.0]:kit.box("RationPacket",Vector3(x,y+0.17,-8.3),Vector3(0.27,0.30,0.23),"paper")
	kit.box("RationScale",Vector3(11.5,1.18,-5.5),Vector3(0.38,0.20,0.32),"metal")
	kit.box("Ledger",Vector3(13.3,1.1,-5.45),Vector3(0.50,0.035,0.35),"paper")
	kit.signboard("07 / СНАБЖЕНИЕ",Vector3(12.5,2.3,-8.8),3.1)
	kit.lamp(Vector3(12.2,2.3,-8.6),false,2.4,7)
	kit.poster(Vector3(10.14,1.45,-2.2),"НОРМА / 1982",false,PI/2)

func build_south():
	# Washroom: sinks and heater are wall fixtures with unified collision hulls.
	kit.box("SinkBank",Vector3(-13.8,0.85,6.5),Vector3(0.9,0.25,2.7),"cream",true)
	kit.box("SinkBase",Vector3(-13.8,0.34,6.5),Vector3(0.85,0.68,2.5),"metal",true)
	for z in [5.6,6.5,7.4]:
		kit.box("SinkBasin",Vector3(-13.6,.986,z),Vector3(0.55,.012,0.55),"dark")
		kit.pipe(Vector3(-14,0.9,z),Vector3(-14,1.28,z),0.025,"metal")
		kit.pipe(Vector3(-14,1.28,z),Vector3(-13.8,1.28,z),0.025,"metal")
	kit.box("FuseCabinet",Vector3(-9.0,1.1,8.9),Vector3(0.8,1.5,0.35),"metal",true)
	kit.box("FuseHazard",Vector3(-9,1.3,8.70),Vector3(0.25,0.28,0.025),"cream")
	kit.label("⚡",Vector3(-9,1.3,8.67),30,Color("27332d")).rotation.y=PI
	kit.bench(Vector3(-11.3,0,8.8),2,true,PI)
	kit.lamp(Vector3(-12,2.4,4.0),false,2.3,6)
	# Assembly bay is a pause space, not a second combat level.
	kit.bench(Vector3(-6.4,0,4.3),2.1)
	kit.bench(Vector3(-6.4,0,8.7),2.1,true,PI)
	kit.box("BriefingDesk",Vector3(-0.2,0.75,6.5),Vector3(1.45,0.12,0.9),"wood",true)
	kit.box("BriefingDeskBase",Vector3(-0.2,0.35,6.5),Vector3(1.3,0.7,0.75),"dark",true)
	kit.box("FoldedMap",Vector3(-0.3,0.83,6.5),Vector3(0.9,0.02,0.6),"paper")
	kit.box("AirlockFrame",Vector3(-3.3,1.15,9.55),Vector3(2.25,2.3,0.45),"dark",true)
	kit.box("AirlockDoor",Vector3(-3.3,1.1,9.28),Vector3(1.6,2.15,0.15),"metal")
	kit.cyl("AirlockWheel",Vector3(-3.3,1.05,9.15),0.25,0.08,"brass").rotation.x=PI/2
	kit.signboard("ЛЕСТНИЦА / ВНИЗ",Vector3(-3.3,2.5,9.2),2.8)
	for x in [-7,1.2]:kit.locker(Vector3(x,0,6.8))
	kit.lamp(Vector3(-4,2.5,4),true,2.1,6)
	# Guard station and relay.
	kit.box("GuardDesk",Vector3(4.4,0.75,7.8),Vector3(2,0.12,0.85),"wood",true)
	kit.box("GuardDeskBase",Vector3(4.4,0.35,7.8),Vector3(1.9,0.7,0.8),"metal",true)
	kit.box("GuardBook",Vector3(4.2,0.84,7.7),Vector3(0.43,0.035,0.31),"paper")
	kit.cyl("GuardCup",Vector3(4.8,0.92,7.7),0.09,0.17,"cream")
	kit.bench(Vector3(3.1,0,9.1),1.1,true,PI)
	kit.box("RelayBox",Vector3(7.7,1.0,3.8),Vector3(0.9,1.3,0.45),"metal",true)
	kit.box("GuardLampCloth",Vector3(7.1,.93,3.9),Vector3(.2,.04,.16),"cloth")
	kit.lamp(Vector3(7,1.9,3.85),true,.65,3)
	kit.box("RelayScreen",Vector3(7.7,1.25,4.04),Vector3(0.55,0.28,0.02),"cold_light")
	kit.cyl("PressureGauge",Vector3(8.6,1.4,5.5),0.18,0.09,"cream").rotation.x=PI/2
	kit.pipe(Vector3(8.6,0.1,5.5),Vector3(8.6,1.3,5.5),0.04)
	kit.box("HatchFrame",Vector3(7.8,0.025,8.9),Vector3(1.2,0.05,1.2),"dark")
	kit.box("HatchCover",Vector3(7.8,0.07,8.9),Vector3(0.9,0.07,0.9),"rust")
	for z in [8.6,8.75,8.9,9.05,9.2]:kit.box("HatchGrille",Vector3(7.8,0.12,z),Vector3(0.65,0.015,0.035),"dark")
	kit.lamp(Vector3(4.5,2.3,3.7),true,2.0,6)
	kit.lamp(Vector3(8.6,2.3,8.8),false,1.3,5)
	# Open maintenance ramp, visually descending beyond a safe interaction edge.
	for z in [5.5,7.7]:
		var beam=kit.box("RampStringer",Vector3(16.8,-.58,z),Vector3(4.2,.22,.18),"metal")
		beam.rotation.z=-atan(.16/.45)
	kit.box("RampVoid",Vector3(18,-1.0,6.6),Vector3(7,.4,5),"black")
	for i in 9:
		kit.box("RampStep",Vector3(15.0+i*.45,-.05-i*.16,6.6),Vector3(.5,.12,2.6),"wood")
	for z in [5.1,8.1]:
		kit.box("ScrapRampRail",Vector3(16.8,-.14,z),Vector3(4,.8,.12),"rust").rotation.z=-atan(.16/.45)
		for x in [15,16.5,18]:kit.box("RampPost",Vector3(x,.50-maxf(x-15,0)*.16/.45,z),Vector3(.08,1.3,.08),"wood")
	kit.lamp(Vector3(14.4,2.2,4.2),false,1.5,5)
	kit.signboard("ТЕХНИЧЕСКИЙ СПУСК",Vector3(12,2.3,3.36),3)

func build_corridor():
	# Dense wall dressing is decorative and kept above 2m or out of circulation.
	for z in [0.5,2.8]:kit.pipe(Vector3(-14.7,2.9,z),Vector3(14.7,2.9,z),0.075)
	for x in [-12,-6,0,6,12]:
		kit.pipe(Vector3(x,2.95,0.4),Vector3(x,2.95,2.85),0.045,"dark")
		kit.box("CableClip",Vector3(x,2.88,0.5),Vector3(0.12,0.22,0.20),"metal")
	# Posters are readable props, not baked scene images.
	kit.poster(Vector3(-5.5,1.45,-8.85),"ТРУД / ДИСЦИПЛИНА")
	kit.box("NoticeBoard",Vector3(11,1.5,-0.2),Vector3(1.15,1.25,0.1),"wood")
	kit.box("CallUpNotice",Vector3(11,1.5,-0.13),Vector3(0.86,1.0,0.025),"paper")
	kit.label("ПРИКАЗ\nD–6\n16 / XI / 82",Vector3(11,1.53,-0.10),24,Color("333a31"))
	kit.label("★ — ◯",Vector3(-7.6,1.0,-0.13),35,Color("d1cdb4"))
	kit.signboard("D–6  /  ЖИЛОЙ УРОВЕНЬ",Vector3(0,2.35,-0.15),5.1)
	kit.box("HeatingManifold",Vector3(2.8,1.25,.18),Vector3(.65,.75,.18),"metal")
	kit.cyl("ManifoldGauge",Vector3(2.8,1.48,.30),.14,.065,"metal").rotation.x=PI/2
	kit.cyl("ManifoldDial",Vector3(2.8,1.48,.34),.115,.01,"paper").rotation.x=PI/2
	kit.box("ManifoldNeedle",Vector3(2.83,1.51,.352),Vector3(.012,.11,.012),"dark").rotation.z=-.7
	kit.label("ОТОПЛЕНИЕ / 12",Vector3(2.8,1.08,.30),17)

func person(id: String,p: Vector3,coat: String="green",hat: bool=false,art:String=""):
	var a=Actor.new()
	a.name=id
	a.art_id=art
	add_child(a)
	a.position=p
	a.setup(kit,false,coat,hat)
	a.visual.rotation.y={"igor":-1.9,"cook":2.7,"nina":-2.4,"supply":-2.7,"mikhail":-2.1,"commander":-2.5}.get(id,PI)
	npcs[id]=a

func build_people():
	player=Actor.new()
	player.name="Ivan"
	add_child(player)
	player.position=Vector3(-10.5,0.04,-3.4)
	player.add_to_group("player")
	player.setup(kit,true,"green")
	player.visual.rotation.y=-2.4
	person("semyon",Vector3(-12.1,0,-2.2),"wood",true)
	person("nina",Vector3(-3.8,0,-6.1),"blue")
	person("mikhail",Vector3(1.65,0,-3.25),"wood",true)
	person("cook",Vector3(5.5,0,-6.6),"cream")
	person("supply",Vector3(12.4,0,-6.5),"blue")
	person("igor",Vector3(6.3,0,6.6),"green",true)
	person("resident",Vector3(-25.0,0,-5.1),"cloth",true)
	person("diner",Vector3(-25.0,0,-1.6),"blue")
	person("queue",Vector3(13.6,0,-3.2),"wood")

func setup_daily_routines():
	if floor_id not in ["life","labor"]:CampaignMaps.routines(self);return
	if floor_id=="labor":Labor.routines(self);return
	# Quiet local activity: one nearby station within the NPC's own room.
	var offsets={"nina":Vector3(.9,0,.4),"cook":Vector3(-.8,0,.4),"supply":Vector3(0,0,.8),"mikhail":Vector3(.7,0,.2),"resident":Vector3(.6,0,0),"diner":Vector3(.6,0,0)}
	for id in npcs:
		var actor=npcs[id];actor.navigation=navigation;actor.rest_time=20+float(id.hash()%100)/10
		if offsets.has(id):
			var destination=actor.anchor+offsets[id]
			var path=navigation.path(actor.anchor,destination)
			if not path.is_empty() and path[-1].distance_to(destination)<.55:actor.patrol.assign([actor.anchor,path[-1]])

func target(id: String,p: Vector3,label: String,kind: String="inspect"):
	# Keep target data and interaction coordinates stable; no ground ring or
	# floating geometry is needed for the new screen-space proximity cue.
	var ring=Node3D.new()
	add_child(ring)
	ring.visible=false
	var marker=Node3D.new()
	add_child(marker)
	marker.visible=false
	targets[id]={"pos":p,"label":label,"kind":kind,"ring":ring,"marker":marker}

func build_targets():
	for pair in [["semyon","谢苗诺夫"],["nina","妮娜"],["mikhail","米哈伊尔"],["cook","加琳娜"],["supply","柳德米拉"],["igor","老伊戈尔"]]:target(pair[0],npcs[pair[0]].position,pair[1],"talk")
	target("box",Vector3(-12.1,0,-4.5),"老爹的木箱")
	target("radio",Vector3(-11.2,0,-6.9),"旧收音机")
	target("notice",Vector3(11,0,0.65),"征召令")
	target("chalk",Vector3(-7.5,0,0.7),"粉笔记号")
	target("valve",Vector3(8.6,0,-6.0),"回水阀")
	target("cabinet",Vector3(-9,0,8.1),"断电配电柜")
	target("relay",Vector3(7.7,0,4.5),"压力监测箱")
	target("gate",Vector3(8.2,0,6.7),"维修门")
	target("side",Vector3(8.2,0,4.5),"检修侧门")
	target("inner_latch",Vector3(9.8,0,4.5),"内侧安全闩")
	target("hatch",Vector3(7.7,0,8.7),"检修盖板")
	target("lift",Vector3(-3.3,0,8.3),"楼梯 / 作业层")
	target("exit",Vector3(13.4,0,6.6),"维修坡道出口")

func _physics_process(delta):
	if not initialized:return
	if not hud.modal_visible():played_seconds+=delta
	phase=fmod(phase+delta,12.0)
	var moved=Vector2(player.position.x-previous_position.x,player.position.z-previous_position.z).length()
	var active=not departure_animating and not hud.modal_visible() and not waiting_shift and not story.flags.get("comic",{}).get("active",false)
	var walking=active and moved>.001 and moved<1.5
	story.Economy.advance(story,delta,walking)
	if walking:
		step_clock+=moved
		if step_clock>=1.05:
			step_clock=fmod(step_clock,1.05)
			step_variant=(step_variant+1)%step_samples.size()
			step_audio.stream=step_samples[step_variant]
			step_audio.volume_db=-23 if player.sneaking else -12
			step_audio.pitch_scale=[.98,1.02,1.0,.97][step_variant]
			if DisplayServer.get_name()!="headless":step_audio.play()
	else:step_clock=0
	if floor_id=="life":
		if waiting_shift:
			if phase>=8.0 and story.guard_clear():
				waiting_shift=false
				story.route="shift"
				story.flags.side_pass=true
				hud.toast("黄灯已亮 · 侧门开启，穿过侧门进入东段")
				story.changed.emit()
			else:hud.prompt.text="确认伊戈尔已离开 · 等候黄灯 / Esc 取消"
		if story.f("side_pass") and player.position.x>9.45:story.flags.side_crossed=true
		update_guard(delta)
		if player.position.x>9.4 and previous_position.x<=9.4:
			if absf(player.position.z-6.7)<0.9 and story.f("gate"):
				story.route=story.flags.get("gate_route","permit")
				story.changed.emit()
			elif absf(player.position.z-4.5)<0.9 and story.f("side_pass"):
				story.route="shift"
				story.changed.emit()
	previous_position=player.position
	if is_instance_valid(living):living.tick(delta)
	set_camera(delta)
	if floor_id!="waterworks" and story.weapon_drawn() and not hud.modal_visible():
		var cursor=get_viewport().get_mouse_position()
		var aim_point=Plane(Vector3.UP,.62).intersects_ray(camera.project_ray_origin(cursor),camera.project_ray_normal(cursor))
		if aim_point!=null:player.aim_direction=aim_point-player.position
	find_nearest()
	player.blocked=hud.modal_visible() or waiting_shift or departure_animating or (is_instance_valid(combat) and combat.defeated)
	for zone in zones:
		if zone.rect.has_point(Vector2(player.position.x,player.position.z)):
			room_name=zone.name
			if zone.code=="01" and player.position.x < -11.95 and player.position.z < -2.8:room_name="谢苗诺夫的卧室"
			break
	if floor_id=="labor" and Rect2(-13.8,4.1,3.2,5.3).has_point(Vector2(player.position.x,player.position.z)):room_name="生活层楼梯间"
	hud.tick(delta)

func target_actor(id:String):
	return npcs.get({"armory":"armorer","main_gate":"main_guard","d6_return_desk":"commander","front_veteran":"plant_veteran"}.get(id,id))

func find_nearest():
	story.context.east_side=player.position.x>24.5 if floor_id=="east_district" else false
	nearest=""
	interaction_candidates.clear()
	var distances:Dictionary={}
	for id in targets:
		if id in ["d6_return_desk","coal_gate_entry"] and not story.f("d6_returned"):continue
		var t=targets[id]
		var actor=target_actor(id)
		if actor:t.pos=actor.global_position
		var d=Vector2(player.position.x-t.pos.x,player.position.z-t.pos.z).length()
		if InteractionRegions.contains(story,id,player.position):
			# Room activity is available anywhere inside its authored participation
			# area. Nearby people/books still win selection and wheel cycling works.
			interaction_candidates.append(id)
			distances[id]=1.69
			continue
		var reachable=true
		if d<1.75:
			var q=PhysicsRayQueryParameters3D.create(player.position+Vector3(0,1.2,0),t.pos+Vector3(0,1.2,0),1)
			var hit=get_world_3d().direct_space_state.intersect_ray(q)
			reachable=hit.is_empty() or hit.position.distance_to(t.pos+Vector3(0,1.2,0))<0.48
		if d<1.7 and reachable:
			interaction_candidates.append(id)
			distances[id]=d
	interaction_candidates.sort_custom(func(a,b):return distances[a]<distances[b] if not is_equal_approx(distances[a],distances[b]) else a<b)
	if chosen_interaction not in interaction_candidates:chosen_interaction=""
	if not interaction_candidates.is_empty():nearest=chosen_interaction if chosen_interaction!="" else interaction_candidates[0]
	var cue=nearest if not hud.modal_visible() else ""
	if cue=="gate" and story.f("gate"):cue=""
	if cue=="side" and (story.f("side_crossed") or story.f("side_pass")):cue=""
	kit.highlight({"armory":"armorer","main_gate":"main_guard","front_veteran":"plant_veteran"}.get(cue,cue),npcs)
	if not waiting_shift:hud.set_prompt(nearest)

func cycle_interaction(direction:int)->bool:
	find_nearest()
	if interaction_candidates.size()<2:return false
	var index=interaction_candidates.find(nearest)
	chosen_interaction=interaction_candidates[posmod(index+direction,interaction_candidates.size())]
	find_nearest()
	return true

func update_guard(delta:float):
	if not npcs.has("igor"):return
	var guard=npcs.igor
	var inspection=Vector3(2.8,0,1.4)
	if story.f("side_inside_release") and player.position.x<8.2:story.flags.side_inside_release=false
	if story.f("guard_task"):
		if guard.anchor!=inspection:
			guard.purposeful=true;guard.yield_time=0;guard.path_points.clear();guard.goal=Vector3.INF;guard.reached_anchor=false
			guard.anchor=inspection;guard.travel_to(inspection)
		if Vector2(guard.position.x-inspection.x,guard.position.z-inspection.z).length()<.65:
			if guard_away_time==0.0:guard_away_time=45.0
			if not hud.modal_visible():guard_away_time=maxf(.001,guard_away_time-delta)
			if guard_away_time<=.001:
				story.flags.guard_task=false
				guard_away_time=0.0
				hud.toast("伊戈尔查完总表，正往岗哨走。维修记录仍可用。")
	else:
		guard_away_time=0.0
		var home=Vector3(6.3,0,6.6)
		if guard.anchor!=home:
			guard.yield_time=0;guard.goal=Vector3.INF;guard.reached_anchor=false;guard.anchor=home;guard.travel_to(home)
		guard.purposeful=guard.position.distance_to(home)>.6
		if story.f("side_pass") and not story.f("side_inside_release") and guard.position.distance_to(guard.anchor)<1.2 and absf(player.position.x-9)>.8:
			story.flags.side_pass=false;story.flags.igor_suspicious=true
			hud.toast("伊戈尔发现侧门开着，正在把门关上。",6)
			story.changed.emit()
	refresh_guard_context()

func refresh_guard_context():
	if is_instance_valid(grey_camp):story.context.camp_loot_safe=grey_camp.can_loot()
	if not npcs.has("igor"):
		story.context.hatch_clear=false
		return
	var clear=false
	if story.f("guard_task"):
		var guard=npcs.igor
		# A promise to leave is insufficient: the guard must physically reach
		# the corridor, where the room's opaque wall blocks his sight line.
		if guard.position.z<2.6:
			var end=targets.hatch.pos+Vector3(0,1.2,0)
			var ray=PhysicsRayQueryParameters3D.create(guard.position+Vector3(0,1.5,0),end,1)
			clear=not get_world_3d().direct_space_state.intersect_ray(ray).is_empty()
	var previous=story.guard_clear()
	story.context.hatch_clear=clear
	if previous!=clear and hud:hud.refresh_status()

func set_camera(delta: float, instant: bool = false):
	if not capture_mode:
		overview=false
		camera_size=clampf(camera_size,12,19)
	var focus=(Vector3(-6,0,-1.5) if floor_id=="life" else Vector3(1,0,.5)) if overview else Vector3(player.position.x*.90,.4,player.position.z*.85)
	if floor_id=="east_district":focus=Vector3.ZERO if overview else player.position+Vector3.UP*.4
	if capture_mode:focus=debug_camera_target
	var desired=focus+Vector3(23,30,27)
	if instant:camera.position=desired
	else:camera.position=camera.position.lerp(desired,1-exp(-delta*3.5))
	camera.look_at(camera.position-Vector3(23,30,27),Vector3.UP)
	var desired_size=(39.0 if floor_id=="life" else 44.0) if overview else camera_size
	if is_instance_valid(wall_veil) and wall_veil.interior_active and not capture_mode:desired_size=minf(camera_size,15.0)
	if floor_id=="east_district" and overview:desired_size=175.0
	camera.size=lerpf(camera.size,desired_size,1-exp(-delta*5)) if not instant else desired_size

func _unhandled_input(event):
	if not initialized or departure_animating:return
	if event.is_action_pressed("ui_cancel"):
		if hud.comic_active:
			hud.show_comic_pause()
			get_viewport().set_input_as_handled()
			return
		if waiting_shift:
			waiting_shift=false
			player.blocked=false
		elif hud.modal_visible():hud.close()
		else:hud.show_pause()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("save"):hud.show_saves(true);return
	if event.is_action_pressed("load"):hud.show_saves(false);return
	if hud.modal_visible():return
	if event.is_action_pressed("draw_weapon"):
		if not (event is InputEventKey and event.echo):toggle_weapon()
		return
	if event.is_action_pressed("interact") and nearest!="" and not waiting_shift:
		interact(nearest)
	if event.is_action_pressed("inventory"):hud.show_inventory()
	if event.is_action_pressed("journal"):hud.show_journal()
	if event.is_action_pressed("map"):hud.show_map()
	if event.is_action_pressed("overview"):hud.show_map()
	if event is InputEventMouseButton and event.pressed:
		if event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN] and cycle_interaction(-1 if event.button_index==MOUSE_BUTTON_WHEEL_UP else 1):
			get_viewport().set_input_as_handled();return
		if event.button_index==MOUSE_BUTTON_WHEEL_UP:camera_size=clampf(camera_size-1,12,19)
		if event.button_index==MOUSE_BUTTON_WHEEL_DOWN:camera_size=clampf(camera_size+1,12,19)

func interact(id: String):
	refresh_guard_context()
	if is_instance_valid(combat) and combat.active and not (floor_id=="surface" and id=="surface_exit") and not story.Campaign.District.can_retreat(self,id) and not story.Campaign.District.safe_interaction(self,id):
		var warning="先离开眼前的交火，或清理威胁后再操作。"
		if is_instance_valid(combat.veteran):warning+="老兵倒地时靠近并按住 E 救援。"
		hud.toast(warning,3);return
	if id=="grey_shelter_entry":preload("res://scripts/grey_shelter.gd").enter(self);return
	if id=="grey_shelter_exit":preload("res://scripts/grey_shelter.gd").leave(self);return
	if id.begins_with("raid_container_"):preload("res://scripts/raid_loot.gd").open(self,id);return
	if id.begins_with("surface_loot_"):preload("res://scripts/surface_site.gd").collect(self,id);return
	if id.begins_with("east_loot_"):story.Campaign.District.collect(self,id);return
	if id=="common_blocks":hud.show_blocks();return
	if id=="public_radio":public_radio.open_controls();return
	if id=="personal_storage":preload("res://scripts/supply_storage.gd").render(hud);return
	if id.begins_with("pub_"):
		if not targets.has(id):return
		if Publications.acquire(story,id):
			PublicationPlaces.refresh(self)
			hud.toast("刊物已收入手记。按 J，在“收集品”里翻阅。",5)
			autosave()
		return
	refresh_guard_context()
	if id=="commander" and story.f("d6_returned"):hud.show_dialogue("d6_return_desk");return
	if id=="main_gate" and story.f("d6_returned"):hud.show_dialogue("d6_surface_gate" if story.Campaign.Access.public_entry(story) else "coal_gate_entry");return
	if id=="coal_door" and story.f("d6_returned"):hud.show_dialogue("coal_gate_entry");return
	if id=="stairs_up" and not story.Chapter.home_access(story):
		hud.toast("返站通行仅限作业层与煤矿。先在审核窗口办理手续。",5);return
	if id=="igor" and story.f("igor_suspicious") and not story.f("igor_debt_known"):
		story.flags.igor_debt_known=true;story.changed.emit()
	if id=="side" and story.f("side") and not story.f("side_pass"):
		if not story.guard_clear():hud.toast("伊戈尔仍看得到门口，先设法让他去走廊查表。",5);return
		waiting_shift=true
		hud.toast("已开始等候黄灯 · Esc 取消")
		return
	hud.show_dialogue(id)

func perform(key: String, id: String):
	refresh_guard_context()
	if is_instance_valid(combat) and combat.active and not key.begins_with("c_surface_back_") and not story.Campaign.District.can_retreat(self,id) and not story.Campaign.District.safe_interaction(self,id):return
	if departure_animating:return
	refresh_guard_context()
	var reply=story.act(key)
	if not story.last_action_valid:
		hud.show_reply(id,reply)
		return
	if key=="c_surface_trade":hud.shop_actor=id;hud.show_shop();return
	if key.begins_with("c_"):
		get_node("/root/Session").sound("interact")
		if story.flags.has("next_sequence"):
			var sequence:String=story.flags.next_sequence
			if reply!="":story.Conversation.reply(story,id,hud.last_choice,reply);hud.last_choice=""
			story.flags.erase("next_sequence")
			if key=="c_plant_leave" and not factory_exit_leaves.is_empty():
				departure_animating=true
				hud.close();player.blocked=true
				hud.toast("厂区铁门缓缓打开",1.5)
				var opening=create_tween().set_parallel(true)
				for leaf in factory_exit_leaves:opening.tween_property(leaf,"rotation:y",leaf.get_meta("opening_angle"),.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
				await opening.finished
				departure_animating=false
			hud.show_comic(sequence)
		elif story.ending:hud.show_chapter_end()
		else:hud.show_reply(id,reply)
		return
	get_node("/root/Session").sound("interact")
	if key=="room_radio_music":
		story.Conversation.reply(story,id,hud.last_choice,reply);hud.last_choice=""
		public_radio.open_controls(false,targets.radio.pos)
		return
	if key in ["travel_down","travel_up"]:
		travel_floor("labor" if key=="travel_down" else "life")
		return
	if key=="shop":
		story.Conversation.reply(story,id,hud.last_choice,reply)
		hud.last_choice=""
		hud.shop_actor="supply";hud.show_shop()
		return
	if npcs.has(id):
		var painter=npcs[id].visual.get_node("Painter")
		painter.react(story.last_outcome.get("kind","success"))
	if key in ["leave_official","leave_east"]:
		if (key=="leave_official" and story.f("kit")) or (key=="leave_east" and story.route!=""):
			pending_route="official" if key=="leave_official" else story.route
			hud.show_departure(false)
		return
	if key in ["hatch_wrench","hatch_knife","hatch_pass"] and story.f("hatch"):
		player.position=Vector3(11.0,0.04,8.6)
		player.velocity=Vector3.ZERO
	if key=="return_pipe":
		player.position=Vector3(7.2,0.04,8.5)
		player.velocity=Vector3.ZERO
	hud.show_reply(id,reply)

func on_story_changed():
	if floor_id=="coal":
		var grille=get_node_or_null("MineEscapeGrille")
		if is_instance_valid(grille) and story.f("rescue_route_ready") and not grille.get_meta("opened",false):
			grille.set_meta("opened",true)
			var motion=create_tween()
			motion.tween_property(grille,"position:x",-20.2,1.0).set_trans(Tween.TRANS_SINE)
			motion.finished.connect(func():if is_instance_valid(navigation):navigation.setup(self))

	story.context.floor=floor_id
	story.Campaign.District.sync(self)
	PublicationPlaces.refresh(self)
	if floor_id=="surface":
		var water=get_node_or_null("SurfaceStandingWater")
		if water:water.visible=not story.f("surface_drain_open")
	if floor_id=="commune":
		var shade=get_node_or_null("FungusShade")
		if shade:shade.position.y=2.08 if story.f("grow_fixed") else 2.38
	if campaign_gate:
		var state=1 if story.f(campaign_gate_flag) else 0
		if state!=campaign_gate_state:
			campaign_gate_state=state
			var closed:Vector3=campaign_gate.get_meta("closed_position",campaign_gate.position)
			var destination=closed+campaign_gate.get_meta("opening_offset",Vector3(2.35,0,0))*state
			if is_instance_valid(gate_tween):gate_tween.kill()
			if not initialized:campaign_gate.position=destination
			else:
				gate_tween=create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
				gate_tween.tween_property(campaign_gate,"position",destination,1.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
				gate_tween.finished.connect(func():if is_instance_valid(navigation):navigation.setup(self))
				get_node("/root/Session").sound("interact")
	if gate_mesh:animate_d6_door(gate_mesh,story.f("gate"))
	if side_mesh:animate_d6_door(side_mesh,story.f("side_pass"))
	if is_instance_valid(living):living.sync()
	if hud:hud.refresh_status()

func animate_d6_door(mesh:MeshInstance3D,opened:bool):
	var state=1 if opened else 0
	if mesh.get_meta("state",-1)==state:return
	mesh.set_meta("state",state)
	if not mesh.has_meta("closed"):mesh.set_meta("closed",mesh.position)
	var destination:Vector3=mesh.get_meta("closed")+Vector3(0,2.3*state,0)
	var previous=mesh.get_meta("motion") if mesh.has_meta("motion") else null
	if previous is Tween and previous.is_valid():previous.kill()
	if not initialized:mesh.position=destination;return
	var motion=create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	mesh.set_meta("motion",motion)
	motion.tween_property(mesh,"position",destination,.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func clear_arrival(p:Vector3)->Vector3:
	# New decorative fixtures must not imprison an earlier saved position.
	if floor_id not in ["commune","waterworks","surface","starcity","coal","railfront","east_district","grey_shelter"]:return p
	# Legacy mine saves could place Ivan exactly on the registrar's spawn.
	if npcs.values().any(func(a):return Vector2(a.position.x-p.x,a.position.z-p.z).length()<.65):
		var best=Vector3.INF;var distance=INF
		for id in navigation.graph.get_point_ids():
			var point:Vector2=navigation.graph.get_point_position(id)
			var delta=point.distance_to(Vector2(p.x,p.z))
			if delta>=distance or npcs.values().any(func(a):return point.distance_to(Vector2(a.position.x,a.position.z))<.7):continue
			distance=delta;best=Vector3(point.x,.04,point.y)
		if best.is_finite():p=best
	for solid in kit.solids:
		if solid.name=="BasinInspectionGate" and story.f("city_basin_open"):continue
		if solid.name=="CampaignInnerGate" and story.f(campaign_gate_flag):continue
		if solid.top<=.24 and solid.top>.025 and solid.bottom<.12 and solid.rect.has_point(Vector2(p.x,p.z)):
			p.y=maxf(p.y,solid.top+.002);continue
		if solid.top>.18 and solid.bottom<1.75 and solid.rect.grow(.28).has_point(Vector2(p.x,p.z)):
			var nearest_cell=navigation.graph.get_closest_point(Vector2(p.x,p.z))
			if nearest_cell>=0:
				var clear:Vector2=navigation.graph.get_point_position(nearest_cell)
				return Vector3(clear.x,.04,clear.y)
	return p

func save_snapshot()->Dictionary:
	if is_instance_valid(living):living.capture()
	if is_instance_valid(grey_camp):grey_camp.capture()
	if is_instance_valid(combat) and combat.enabled:story.flags.weapon_clip=combat.clip
	var data=story.serialize()
	data.position=[player.position.x,player.position.y,player.position.z];data.floor=floor_id
	data.layout_revision=29;data.played_seconds=played_seconds
	data.camera_size=camera_size;data.facing=player.visual.rotation.y
	data.world_state={"phase":phase,"guard_away_time":guard_away_time,"waiting_shift":waiting_shift,"pending_route":pending_route}
	var saved_room=floor_name()
	for zone in zones:
		if zone.rect.has_point(Vector2(player.position.x,player.position.z)):saved_room=zone.name;break
	data.save_summary={"room":saved_room,"quest":preload("res://scripts/journal.gd").active(story).get("name","")}
	data.combat_state=combat.serialize_state() if is_instance_valid(combat) else {}
	data.npc_positions={}
	for id in npcs:data.npc_positions[id]={"position":[npcs[id].position.x,npcs[id].position.y,npcs[id].position.z],"facing":npcs[id].visual.rotation.y}
	return data
func save_game(path:String="")->bool:
	var destination=path if path!="" else save_path
	var data=save_snapshot();data.save_slot=destination
	var result=SaveStore.write(destination,data,"manual")
	if result==OK:
		save_path=destination;get_node("/root/Session").sound("save");hud.toast("已保存 · "+SaveStore.title(destination));return true
	hud.toast("保存失败，原存档仍保留："+error_string(result),7);return false
func autosave():
	if not initialized or story.ending:return
	var result=SaveStore.write(SaveStore.auto_path(),save_snapshot(),"auto")
	if result!=OK:push_warning("自动记录失败："+error_string(result))
func load_game(path:String=""):
	var source=path if path!="" else save_path
	var data=SaveStore.read(source)
	if data.is_empty():hud.toast("没有可读取的手记，或该存档及备份均已损坏。",6);return
	var p=data.get("position",[-10.5,.04,-3.4])
	if data.get("floor","life")!=floor_id or floor_id in ["waterworks","surface","starcity","coal","railfront","east_district"]:
		get_node("/root/Session").enter(data,data.get("floor","life"),Vector3(p[0],maxf(p[1],.04),p[2]));return
	hud.observing=false;story.restore(data)
	player.position=clear_arrival(Vector3(p[0],maxf(p[1],.04),p[2]))
	if (floor_id=="commune" and int(data.get("layout_revision",0))<12) or (floor_id=="sech" and int(data.get("layout_revision",0))<11) or (floor_id=="starcity" and int(data.get("layout_revision",0))<19):player.position=CampaignMaps.LAYOUTS[floor_id].spawn
	played_seconds=float(data.get("played_seconds",0));camera_size=clampf(float(data.get("camera_size",17)),12,19)
	waiting_shift=false;guard_away_time=0;restore_placement(data);player.velocity=Vector3.ZERO
	if is_instance_valid(living):living.reset_for_load()
	hud.comic_active=false;hud.close()
	if story.flags.get("comic",{}).get("active",false):hud.show_comic()
	elif story.ending:hud.show_chapter_end()
	hud.toast("已读取手记"+(" · 自动恢复了上一次有效备份" if data.get("recovered_backup",false) else ""))
func restore_placement(data:Dictionary):
	if data.get("floor","")==floor_id:
		var state:Dictionary=data.get("world_state",{})
		phase=float(state.get("phase",0));guard_away_time=float(state.get("guard_away_time",0));waiting_shift=bool(state.get("waiting_shift",false));pending_route=String(state.get("pending_route",""))
	player.visual.rotation.y=float(data.get("facing",player.visual.rotation.y))
	if data.get("floor","")!=floor_id or int(data.get("layout_revision",0))<(19 if floor_id=="starcity" else (12 if floor_id=="commune" else 11)):return
	for id in data.get("npc_positions",{}):
		if not npcs.has(id):continue
		var entry:Dictionary=data.npc_positions[id];var p=entry.get("position",[])
		if p.size()!=3:continue
		var actor=npcs[id];actor.position=clear_arrival(Vector3(float(p[0]),.04,float(p[2])));actor.velocity=Vector3.ZERO
		actor.visual.rotation.y=float(entry.get("facing",0));actor.path_points.clear();actor.goal=Vector3.INF;actor.reached_anchor=false

func restart():
	public_radio.stop()
	get_node("/root/Session").clear()
	get_tree().change_scene_to_file("res://scenes/d6.tscn")

func return_menu():
	public_radio.stop()
	get_node("/root/Session").clear()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _exit_tree():
	if is_instance_valid(event_music):event_music.stop();event_music.stream=null
	# Release looping audio before node teardown (also avoids Dummy-driver leaks
	# in headless visual/regression runs). No save or quest data is touched.
	if is_instance_valid(ambience):
		ambience.stop()
		ambience.stream=null
	if is_instance_valid(step_audio):
		step_audio.stop()
		step_audio.stream=null

func capture_later():
	overview=true
	debug_camera_target=Vector3(0,0,0.8)
	await get_tree().create_timer(3).timeout
	var image=get_viewport().get_texture().get_image()
	image.save_png("/tmp/d6-overview.png")
	overview=false
	debug_camera_target=Vector3(-7,0,-1.5)
	camera_size=20
	await get_tree().create_timer(2).timeout
	get_viewport().get_texture().get_image().save_png("/tmp/d6-residence.png")
	debug_camera_target=Vector3(5,0,-1.5)
	await get_tree().create_timer(2).timeout
	get_viewport().get_texture().get_image().save_png("/tmp/d6-mess.png")
	hud.show_dialogue("igor")
	await get_tree().create_timer(1).timeout
	get_viewport().get_texture().get_image().save_png("/tmp/d6-dialogue.png")
	image=null
	ambience.stop()
	step_audio.stop()
	await get_tree().process_frame
	get_tree().quit()

func build_dressing():
	# Architectural ribs and utility distribution establish a bunker, not a tiled board.
	for x in [-14.6,-7.7,1.3,10.3,14.6]:
		kit.cyl("ConcreteRib",Vector3(x,1.42,-8.62),0.18,2.84,"concrete")
		kit.box("RibCapital",Vector3(x,2.72,-8.62),Vector3(0.48,0.20,0.50),"dark")
	for x in [-14.65,-7.6,1.4,10.4]:
		kit.pipe(Vector3(x,2.55,-8.5),Vector3(x+3.5,2.55,-8.5),0.08,"metal")
	# Cast iron radiators, built from fins; one smooth hull avoids snagging toes.
	for pos in [Vector3(-14.45,0,-4.8),Vector3(-6.5,0,-8.45),Vector3(1.7,0,-8.6)]:
		var n=Node3D.new()
		add_child(n)
		n.position=pos
		for i in range(7):kit.cyl("RadiatorFin",Vector3(i*0.105,0.52,0),0.075,0.74,"metal",n)
		kit.box("RadiatorHull",pos+Vector3(0.32,0.47,0),Vector3(0.82,0.94,0.28),"metal",true).visible=false
		kit.pipe(pos+Vector3(-0.1,0.2,0),pos+Vector3(0.8,0.2,0),0.03,"rust")
	# Barrels, water drums, folded cloth and carefully kept service clutter.
	for pos in [Vector3(-0.1,0,-4.8),Vector3(14,0,-1.3),Vector3(-12.8,0,9.1)]:
		kit.cyl("WaterDrum",pos+Vector3(0,0.47,0),0.35,0.94,"metal")
		for y in [0.1,0.45,0.85]:kit.cyl("DrumHoop",pos+Vector3(0,y,0),0.365,0.035,"dark")
		kit.cyl("DrumLid",pos+Vector3(0,0.96,0),0.34,0.035,"metal")
		kit.box("DrumHull",pos+Vector3(0,0.47,0),Vector3(0.62,0.94,0.62),"dark",true).visible=false
	# Shelves with books, spools, jars and boxed electrical components.
	for p in [Vector3(-6.9,0,-2.2),Vector3(-14.1,0,-8.2)]:
		kit.box("ShelfHull",p+Vector3(0,0.85,0),Vector3(0.9,1.7,0.38),"wood",true).visible=false
		for x in [-0.44,0.44]:kit.box("ShelfUpright",p+Vector3(x,0.85,0),Vector3(0.06,1.7,0.4),"wood")
		for y in [0.12,0.62,1.12,1.62]:kit.box("Shelf",p+Vector3(0,y,0),Vector3(0.92,0.06,0.42),"wood")
		for i in range(6):
			var m=kit.box("Book",p+Vector3(-0.3+i*0.12,0.85,0),Vector3(0.07,0.37,0.25),"red" if i%3==0 else "cloth")
			m.rotation.z=(i%3-1)*0.06
		for x in [-0.25,0.05,0.3]:kit.cyl("GlassJar",p+Vector3(x,1.25,0),0.08,0.22,"cream")
	# Pinned papers and damaged paint are authored small decals, never full-room images.
	for p in [Vector3(-10.2,1.7,-8.86),Vector3(-2,1.4,-8.86),Vector3(13.3,1.5,-8.86)]:
		kit.box("PinnedPaper",p,Vector3(0.30,0.40,0.012),"paper").rotation.z=0.08
		for i in range(4):kit.box("PaperLines",p+Vector3(0,0.1-i*0.06,0.012),Vector3(0.21,0.009,0.004),"dark")
	# Thin warning stripes on the east passage threshold. Purely visual.
	for z in [6.15,6.45,6.75,7.05,7.35]:
		var stripe=kit.box("ThresholdWarning",Vector3(8.9,0.032,z),Vector3(0.22,0.02,0.13),"brass")
		stripe.rotation.y=0.35
	# Hanging pennant gives a second vertical scale cue without covering circulation.
	kit.box("Banner",Vector3(-2.4,2.1,-8.70),Vector3(0.7,1.4,0.025),"red")
	kit.label("★",Vector3(-2.4,2.3,-8.67),55,Color("d3b471"))
	kit.label("1982",Vector3(-2.4,1.8,-8.67),23,Color("d3b471"))

func build_labor_people():
	player=Actor.new()
	player.name="Ivan";add_child(player)
	player.position=Vector3(-10,.04,1.8)
	if floor_id in ["waterworks","surface","starcity","east_district"]:player.art_id="ivan_masked"
	player.add_to_group("player");player.setup(kit,true,"green")
	if floor_id=="labor":Labor.people(self)
	else:
		player.position=CampaignMaps.LAYOUTS[floor_id].spawn
		CampaignMaps.people(self)

func floor_name()->String:return {"life":"D-6生活层","labor":"D-6作业层"}.get(floor_id,story.Campaign.NAMES.get(floor_id,"设施"))

func facility_zones(id:String)->Array:
	if id=="life":return LIFE_ZONES+Wing.ZONES
	if id=="labor":return Labor.ZONES
	return CampaignMaps.rooms(id)

func facility_doors(id:String)->Array:
	if id=="life":return [Vector2(-10.5,0),Vector2(-3.5,0),Vector2(5.2,0),Vector2(12.3,0),Vector2(-11,3.2),Vector2(-3.4,3.2),Vector2(5.6,3.2)]+Wing.DOORS
	if id=="labor":return Labor.DOORS
	return CampaignMaps.doors(id)

func travel_campaign(destination:String):
	if destination=="east_district":
		story.Campaign.District.remember_combat(self)
		story.flags.erase("next_facility");story.flags.arrival_v8_east_district=true
		story.flags.campaign_location=destination;story.flags.visited_east_district=true
		get_node("/root/Session").enter(save_snapshot(),destination,story.Campaign.District.spawn(story,floor_id));return
	if floor_id=="east_district":story.Campaign.District.remember_combat(self)
	var private_mine=destination=="coal" and floor_id=="east_district" and story.Campaign.District.private_mine(story)
	if destination=="coal" and not private_mine and (not story.Campaign.Access.public_entry(story) or not story.f("coal_access")):
		story.flags.erase("next_facility")
		hud.show_comic("d6_return_blocked")
		return
	if destination=="starcity":
		if not story.f("north_inquiry_ready") and not story.f("visited_starcity"):
			story.flags.erase("next_facility");hud.toast("北线尚未具备接送与担保条件。先完成本阵营的几轮出站工作。",6);return
		if floor_id in ["commune","sech"]:story.flags.star_return_home=floor_id
		story.ending=false

	if destination in ["life","labor"]:
		if not story.Campaign.Access.public_entry(story):
			story.flags.erase("next_facility")
			hud.show_comic("d6_return_blocked")
			return
		story.ending=false;story.flags.erase("next_facility")
		story.flags.d6_returned=true;story.flags.departure_official=story.route=="official" and not story.f("sided_veteran")
		var p=Vector3(23,.04,-9) if destination=="labor" else Vector3(-3.3,.04,8)
		get_node("/root/Session").enter(save_snapshot(),destination,p);return
	if not story.f("arrival_v8_"+destination):
		story.flags["arrival_v8_"+destination]=true
		hud.show_comic("arrive_"+destination);return
	story.ending=false;story.flags.erase("next_facility")
	story.flags.campaign_location=destination;story.flags["visited_"+destination]=true
	get_node("/root/Session").enter(save_snapshot(),destination,CampaignMaps.LAYOUTS[destination].spawn)
func travel_floor(destination:String):
	var positions:Dictionary=story.flags.get("floor_positions",{}).duplicate(true)
	positions[floor_id]=[player.position.x,.04,player.position.z];story.flags.floor_positions=positions
	var fallback=[-10,.04,1.8] if destination=="labor" else [-3.3,.04,8.0]
	var p=positions.get(destination,fallback)
	get_node("/root/Session").enter(save_snapshot(),destination,Vector3(p[0],.04,p[2]))

func build_implied_life():
	# Closed doors keep these dressed continuation spaces outside navigation.
	kit.box("DistantLifeFloor",Vector3(-17.5,-.01,-1.7),Vector3(4.7,.1,3.6),"tile")
	for x in [-19.8,-15.2]:kit.box("DistantLifeSide",Vector3(x,1.3,-1.7),Vector3(.18,2.6,3.6),"rust")
	kit.box("DistantLifeBlack",Vector3(-17.5,1.2,-3.6),Vector3(4.7,2.4,.2),"black")
	kit.lamp(Vector3(-17.5,2.2,-3.4),true,.9,4)
	kit.box("EastCorridorExtension",Vector3(16.1,-.1,1.6),Vector3(2.2,.2,3.2),"tile",true)
	kit.box("EastCorridorSurface",Vector3(16.1,.006,1.6),Vector3(2.2,.012,3.16),"tile")
	for z in [0,3.2]:kit.box("EastExtensionWall",Vector3(16.1,1.3,z),Vector3(2.2,2.6,.16),"plaster",true)
	kit.box("OtherLifeDoor",Vector3(17.12,1.1,1.6),Vector3(.16,2.2,2.6),"metal",true)
	kit.label("其他生活区 / 暂闭",Vector3(17,2.4,1.6),22).rotation.y=-PI/2
	kit.lamp(Vector3(16,2.3,.25),true,.8,4)

func return_checkpoint():
	var data=story.departure_checkpoint.duplicate(true)
	if data.is_empty():return
	var p=data.get("position",[-3.3,.04,8])
	get_node("/root/Session").enter(data,data.get("floor","life"),Vector3(p[0],p[1],p[2]))

func sync_event_music(id:String):
	if id==event_music_id:return
	if is_instance_valid(event_music_tween):event_music_tween.kill()
	event_music_id=id
	if not is_instance_valid(event_music):
		event_music=AudioStreamPlayer.new();event_music.name="StoryMusic";event_music.bus="Music";event_music.volume_db=-5;add_child(event_music)
	if is_instance_valid(ambience):ambience.stream_paused=id!=""
	if id=="":
		if event_music.playing:
			event_music_tween=create_tween();event_music_tween.tween_property(event_music,"volume_db",-38.0,.65)
			event_music_tween.tween_callback(func():event_music.stop();event_music.stream=null)
		else:event_music.stop();event_music.stream=null
		return
	event_music.stop()
	if id!="":
		var score_path="res://assets/audio/"+id+".wav"
		if ResourceLoader.exists("res://assets/audio/"+id+".ogg"):score_path="res://assets/audio/"+id+".ogg"
		if id=="anna_elegy" and ResourceLoader.exists("res://assets/audio/licensed/heres_to_you.ogg"):score_path="res://assets/audio/licensed/heres_to_you.ogg"
		event_music.stream=load(score_path)
		if event_music.stream is AudioStreamOggVorbis:event_music.stream=event_music.stream.duplicate();event_music.stream.loop=true
		event_music.volume_db=-28
		event_music_tween=create_tween();event_music_tween.tween_property(event_music,"volume_db",-7.0,1.2)
		if DisplayServer.get_name()!="headless":event_music.play()
	else:event_music.stream=null

func toggle_weapon():
	if story.equipped_weapon()=="":hud.toast("武器栏为空。打开背包装备武器。",4);return
	if is_instance_valid(combat) and combat.reload_time>0:hud.toast("先完成装填，再收起武器。",3);return
	story.flags.weapon_drawn=not story.weapon_drawn();story.changed.emit()
	if not story.weapon_drawn():player.aim_direction=Vector3.ZERO
