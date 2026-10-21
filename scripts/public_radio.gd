extends Node3D
## A quiet, opt-in receiver. Distance follows Ivan, not the overhead camera.
const UI=preload("res://scripts/ui_public_radio.gd")
const SITES={
 "railfront":{"p":Vector3(19.6,0,19.8),"heading":PI,"place":"南控制间等候角"},
 "life":{"p":Vector3(1.6,0,-1.8),"heading":PI/2,"place":"公共食堂西侧"},
 "labor":{"p":Vector3(-22.8,0,4.65),"heading":0.0,"place":"工人歇脚棚西北角"},
 "waterworks":{"p":Vector3(17.6,0,4.6),"heading":0.0,"place":"入口气闸东北侧值班休息角"},
 "commune":{"p":Vector3(-10.25,0,.2),"heading":PI/2,"place":"公共厅西侧"},
 "sech":{"p":Vector3(-3.3,0,6.2),"heading":PI/2,"place":"检修库公共厅西侧"},
 "coal":{"p":Vector3(-16.9,0,8.1),"heading":PI/2,"place":"探访登记等候区西侧"},
 "starcity":{"p":Vector3(-11.3,0,7.1),"heading":PI/2,"place":"外围等候棚西侧"},
 "surface":{"p":Vector3(-19.9,0,15.8),"heading":PI/2,"place":"背风装卸台"}}
var world
var catalog:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/radio.json"))
var audio:AudioStreamPlayer
var station=0
var track=0
var enabled=false
var portable=false
var local_origin=Vector3.INF
var paused=false
var suppressed=false
var audible=0.0
var status_label:Label
var clock=0.0

func setup(w):
 world=w;name="PublicRadioController"
 catalog=with_optional_channels(catalog,func(file):return ResourceLoader.exists("res://assets/audio/radio/"+file))
 var saved=world.get_node("/root/Session").settings.get_value("radio",world.floor_id,{})
 if saved is Dictionary:
  station=clampi(int(saved.get("station",0)),0,catalog.stations.size()-1)
  track=clampi(int(saved.get("track",0)),0,current_station().tracks.size()-1)
 build_receiver()
 audio=AudioStreamPlayer.new();audio.name="PublicRadioMusic";audio.bus="Radio";audio.volume_db=-80;add_child(audio)
 audio.finished.connect(advance.bind(1))
 var session=world.get_node("/root/Session")
 if not session.radio_transfer.is_empty():
  var saved_portable=session.radio_transfer.duplicate(true);session.radio_transfer={}
  call_deferred("restore_portable",saved_portable)

static func with_optional_channels(source:Dictionary,exists:Callable)->Dictionary:
 var result=source.duplicate(true)
 for station in source.get("optional_stations",[]):
  var complete=true
  for id in station.tracks:
   var song:Dictionary=source.get("optional_tracks",{}).get(id,{})
   if song.is_empty() or not exists.call(song.get("file","")):complete=false
  if not complete:continue
  if not result.stations.any(func(s):return s.id==station.id):result.stations.append(station.duplicate(true))
  for id in station.tracks:result.tracks[id]=source.optional_tracks[id].duplicate(true)
 return result

func current_station()->Dictionary:return catalog.stations[station]
func current_track()->Dictionary:return catalog.tracks[current_station().tracks[track]]
func remember():
 var session=world.get_node("/root/Session")
 session.settings.set_value("radio",world.floor_id,{"station":station,"track":track})
 session.settings.save("user://metro_settings.cfg")
func select_station(index:int):
 if index<0 or index>=catalog.stations.size():return
 station=index;track=0;play_track()
func select_track(index:int):
 if index<0 or index>=current_station().tracks.size():return
 track=index;play_track()
func play_track(offset:float=0.0):
 audio.stop();audio.stream=load("res://assets/audio/radio/"+current_track().file)
 enabled=true;paused=false;audio.stream_paused=false
 # Set initial attenuation before playback, avoiding a loud first frame.
 update_mix(1.0)
 audio.play(clampf(offset,0,maxf(0,audio.stream.get_length()-.05)));audio.stream_paused=suppressed
 remember();refresh_ui()
func toggle():
 if not enabled:play_track();return
 paused=not paused;audio.stream_paused=paused or suppressed;refresh_ui()
func stop():
 enabled=false;paused=false;audio.stop();audio.stream=null;refresh_ui()
func advance(direction:int):
 track=posmod(track+direction,current_station().tracks.size());play_track()
func refresh_ui():
 if is_instance_valid(world.hud) and world.hud.radio_open:UI.render(world.hud)
func owns_portable()->bool:return int(world.story.economy.goods.get("portable_radio",0))>0
func open_controls(use_portable:bool=false,receiver_position:Vector3=Vector3.INF):
 if use_portable and not owns_portable():world.hud.toast("先在第七供应点购买随身收音机。",4);return
 portable=use_portable;local_origin=receiver_position;UI.render(world.hud)
func restore_portable(saved:Dictionary):
 if not owns_portable():return
 station=clampi(int(saved.get("station",0)),0,catalog.stations.size()-1)
 track=clampi(int(saved.get("track",0)),0,current_station().tracks.size()-1)
 portable=true;play_track(float(saved.get("position",0)))
 paused=bool(saved.get("paused",false));update_mix(1)

func _process(delta:float):
 if not is_instance_valid(world) or not world.initialized:return
 update_mix(delta)
 clock+=delta
 if clock>=.25:
  clock=0
  if is_instance_valid(status_label) and world.hud.radio_open:status_label.text=status()
func update_mix(delta:float):
 if not is_instance_valid(audio):return
 if portable and not owns_portable():stop();portable=false
 var narrative=is_instance_valid(world.hud) and world.hud.comic_active
 var battle=is_instance_valid(world.combat) and world.combat.active
 suppressed=narrative or battle or world.event_music_id!=""
 audio.stream_paused=paused or suppressed
 var origin=local_origin if local_origin.is_finite() else global_position
 var distance=Vector2(world.player.position.x-origin.x,world.player.position.z-origin.z).length() if is_instance_valid(world.player) else 0.0
 audible=(1.0 if portable else 1.0-smoothstep(3.0,18.0,distance)) if enabled and not paused and not suppressed else 0.0
 audio.volume_db=linear_to_db(maxf(.0001,audible*.60))
 if is_instance_valid(world.ambience):world.ambience.volume_db=lerpf(world.ambience.volume_db,-8.0-13.0*audible,1.0-exp(-delta*6.0))
func status()->String:
 if not enabled:return "电源关闭 · 选择频道或歌曲开始收听"
 var state="过场 / 战斗期间暂时停播" if suppressed else ("已暂停" if paused else "正在播放")
 var elapsed=audio.get_playback_position();var duration=audio.stream.get_length() if audio.stream else 0.0
 return "%s    %02d:%02d / %02d:%02d"%[state,int(elapsed)/60,int(elapsed)%60,int(duration)/60,int(duration)%60]
func _exit_tree():
 var session=get_node_or_null("/root/Session")
 if is_instance_valid(session) and portable and enabled and owns_portable():
  session.radio_transfer={"station":station,"track":track,"position":audio.get_playback_position(),"paused":paused}
 if is_instance_valid(audio):audio.stop();audio.stream=null

func build_receiver():
 var site:Dictionary=SITES[world.floor_id];var p:Vector3=site.p;var heading:float=site.heading
 position=p
 var k=world.kit;var facing=Basis(Vector3.UP,heading)
 var top_size=Vector3(.66,.08,1.24) if absf(heading)>1 else Vector3(1.24,.08,.66)
 k.box("PublicRadioTable",p+Vector3(0,.75,0),top_size,"wood",true)
 # One low hull covers the legs, retaining the intended navigation footprint.
 k.box("PublicRadioTableHull",p+Vector3(0,.36,0),Vector3(top_size.x,.72,top_size.z),"dark",true).visible=false
 for x in [-.51,.51]:
  for z in [-.23,.23]:k.box("PublicRadioTableLeg",p+facing*Vector3(x,.36,z),Vector3(.06,.72,.06),"dark")
 var receiver=Node3D.new();receiver.name="public_radio";world.add_child(receiver);receiver.position=p+Vector3(0,.79,0);receiver.rotation.y=heading
 receiver.set_meta("radio_front",facing*Vector3.BACK)
 for x in [-.26,.26]:k.box("RadioRubberFoot",Vector3(x,.015,0),Vector3(.09,.03,.20),"boot",false,receiver)
 k.box("RadioWalnutCabinet",Vector3(0,.23,0),Vector3(.76,.40,.28),"wood",false,receiver)
 k.box("RadioBrassBezel",Vector3(0,.23,.146),Vector3(.70,.34,.018),"brass",false,receiver)
 k.box("RadioSpeakerCloth",Vector3(-.17,.24,.159),Vector3(.28,.27,.010),"cloth",false,receiver)
 for x in range(8):k.box("RadioSpeakerGrille",Vector3(-.296+x*.035,.24,.168),Vector3(.008,.26,.01),"dark",false,receiver)
 k.box("RadioTuningGlass",Vector3(.16,.29,.16),Vector3(.29,.10,.016),"green",false,receiver)
 for x in range(9):k.box("RadioFrequencyTick",Vector3(.04+x*.029,.3,.171),Vector3(.003,.025 if x%2 else .043,.004),"paper",false,receiver)
 k.box("RadioDialNeedle",Vector3(.12,.29,.175),Vector3(.007,.083,.004),"red",false,receiver)
 for x in [.08,.26]:
  var knob=k.cyl("RadioTuningKnob",Vector3(x,.15,.18),.038,.035,"dark",receiver);knob.rotation.x=PI/2
  k.box("RadioKnobIndex",Vector3(x,.17,.201),Vector3(.004,.018,.004),"paper",false,receiver)
 # A short folded aerial stays below the wall fixtures, above the cabinet.
 var aerial=k.box("RadioFoldedAerial",Vector3(-.20,.46,-.07),Vector3(.42,.012,.012),"metal",false,receiver);aerial.rotation.z=.10
 world.target("public_radio",p,"公共收音机 · "+site.place,"radio")
