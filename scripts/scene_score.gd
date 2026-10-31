extends Node
## Sparse location scoring. Dialogue keeps playing; authored story cues take priority.
const TRACKS={"life":"home_lamp.ogg","labor":"shift_below.ogg","coal":"shift_below.ogg","commune":"shelter_theme.wav","sech":"shelter_theme.wav","waterworks":"shift_below.ogg","railfront":"shift_below.ogg","surface":"dawn_theme.wav","east_district":"dawn_theme.wav","starcity":"dawn_theme.wav"}
var world
var rest=0.0
func setup(w):
	world=w
	var player:AudioStreamPlayer=w.ambience
	player.set_meta("score_source",TRACKS.get(w.floor_id,"shelter_theme.wav"))
	player.stream=load("res://assets/audio/"+TRACKS.get(w.floor_id,"shelter_theme.wav")).duplicate()
	if player.stream is AudioStreamWAV:player.stream.loop_mode=AudioStreamWAV.LOOP_DISABLED
	elif player.stream is AudioStreamOggVorbis:player.stream.loop=false
	player.finished.connect(func():rest=75.0)
	player.volume_db=base_volume(w.floor_id)
static func base_volume(place:String)->float:return -17.0 if place in ["surface","starcity","east_district","waterworks"] else -12.0
func _process(delta:float):
	if not is_instance_valid(world) or not world.initialized or DisplayServer.get_name()=="headless":return
	if world.event_music_id!="" or (world.public_radio and world.public_radio.audible>.1):return
	if world.ambience.playing:return
	if world.hud.modal_visible():return
	rest-=delta
	if rest<=0:world.ambience.play()
