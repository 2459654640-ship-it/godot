extends RefCounted
## Display changes are previewed in memory; only explicit confirmation persists them.
const DEFAULTS={"mode":0,"width":1440,"height":900,"fill":false,"quality":2,"vsync":true,"fps":60}
const RESOLUTIONS=[Vector2i(1280,720),Vector2i(1366,768),Vector2i(1440,900),Vector2i(1600,1000),Vector2i(1920,1080),Vector2i(2560,1440),Vector2i(3840,2160)]
static func sanitize(value:Dictionary)->Dictionary:
	var v=DEFAULTS.duplicate();v.merge(value,true)
	v.mode=clampi(int(v.mode),0,2);v.quality=clampi(int(v.quality),0,3)
	v.width=clampi(int(v.width),960,7680);v.height=clampi(int(v.height),600,4320)
	v.fill=bool(v.fill);v.vsync=bool(v.vsync)
	v.fps=int(v.fps) if int(v.fps) in [0,30,60,120,144] else 60
	return v
static func apply(session):
	var v:Dictionary=session.video
	var window=session.get_tree().root
	window.content_scale_size=Vector2i(1600,1000)
	window.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	window.content_scale_aspect=Window.CONTENT_SCALE_ASPECT_IGNORE if v.fill else Window.CONTENT_SCALE_ASPECT_KEEP
	Engine.max_fps=v.fps
	window.msaa_3d=[Viewport.MSAA_DISABLED,Viewport.MSAA_2X,Viewport.MSAA_4X,Viewport.MSAA_8X][v.quality]
	window.scaling_3d_scale=[.70,.85,1.0,1.0][v.quality]
	if DisplayServer.get_name()!="headless":
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if v.vsync else DisplayServer.VSYNC_DISABLED)
		# Window owns viewport sizing and input transforms. Direct DisplayServer
		# resizing can leave its cached size / UI scale at the old resolution.
		window.mode=Window.MODE_WINDOWED if v.mode==0 else (Window.MODE_MAXIMIZED if v.mode==1 else Window.MODE_FULLSCREEN)
		if v.mode==0:
			var screen=DisplayServer.window_get_current_screen()
			var usable=DisplayServer.screen_get_usable_rect(screen)
			var size=Vector2i(mini(v.width,usable.size.x),mini(v.height,usable.size.y))
			window.size=size
			window.position=usable.position+(usable.size-size)/2
	apply_lights(session.get_tree().root,v.quality)
static func apply_lights(node:Node,quality:int):
	if node is Light3D:
		if not node.has_meta("authored_shadow"):node.set_meta("authored_shadow",node.shadow_enabled)
		node.shadow_enabled=bool(node.get_meta("authored_shadow")) and (quality>=2 or (quality==1 and node is DirectionalLight3D))
	if node is WorldEnvironment and node.environment:
		var env:Environment=node.environment
		var advanced=RenderingServer.get_current_rendering_method()=="forward_plus"
		env.ssao_enabled=advanced and quality>=2
		env.ssao_radius=1.35;env.ssao_intensity=1.15;env.ssao_power=1.2
		env.ssil_enabled=advanced and quality>=3
		env.ssil_radius=3.0;env.ssil_intensity=.5
		env.glow_enabled=advanced and quality>=1
		env.glow_intensity=.25;env.glow_bloom=0.0
	for child in node.get_children():apply_lights(child,quality)
