extends Node
## Carries the same story across floors; no autosave overwrites user files.
var pending:Dictionary={}
var departure_snapshot:Dictionary={}
var radio_transfer:Dictionary={}
func clear():
	pending={}
	departure_snapshot={}
	radio_transfer={}
func enter(data:Dictionary,floor:String,position:Vector3):
	pending={"story":data.duplicate(true),"floor":floor,"position":position}
	var scene={"life":"d6","labor":"labor"}.get(floor,floor)
	get_tree().change_scene_to_file("res://scenes/"+scene+".tscn")

var effect_players:Array[AudioStreamPlayer]=[]
var settings=ConfigFile.new()
const Video=preload("res://scripts/video_settings.gd")
signal video_changed
var video:Dictionary={}
var video_previous:Dictionary={}
var video_preview=false
var video_seconds=0.0
func _ready():
	settings.load("user://metro_settings.cfg")
	var saved={}
	for key in Video.DEFAULTS:saved[key]=settings.get_value("video",key,Video.DEFAULTS[key])
	video=Video.sanitize(saved);Video.apply(self)
	for bus_name in ["Music","Radio","Effects","Footsteps"]:
		if AudioServer.get_bus_index(bus_name)<0:
			AudioServer.add_bus();AudioServer.set_bus_name(AudioServer.bus_count-1,bus_name)
	for pair in [["Master",.8],["Music",.35],["Radio",.55],["Effects",.85],["Footsteps",.65]]:
		set_volume(pair[0],float(settings.get_value("audio",pair[0],pair[1])),false)
	for i in 4:
		var p=AudioStreamPlayer.new();p.bus="Effects";add_child(p);effect_players.append(p)
func _process(delta):
	if video_preview:
		video_seconds-=delta
		if video_seconds<=0:revert_video()
func preview_video(value:Dictionary):
	if not video_preview:video_previous=video.duplicate()
	video=Video.sanitize(value);video_preview=true;video_seconds=15.0;Video.apply(self);video_changed.emit()
func confirm_video():
	if not video_preview:return
	video_preview=false;video_previous={};video_seconds=0
	for key in Video.DEFAULTS:settings.set_value("video",key,video[key])
	settings.save("user://metro_settings.cfg");video_changed.emit()
func revert_video():
	if not video_preview:return
	video=video_previous.duplicate();video_previous={};video_preview=false;video_seconds=0
	Video.apply(self);video_changed.emit()
func volume(bus_name:String)->float:
	return AudioServer.get_bus_volume_linear(AudioServer.get_bus_index(bus_name))
func set_volume(bus_name:String,value:float,persist:bool=true):
	AudioServer.set_bus_volume_linear(AudioServer.get_bus_index(bus_name),value)
	if persist:
		settings.set_value("audio",bus_name,value);settings.save("user://metro_settings.cfg")
func sound(id:String):
	if DisplayServer.get_name()=="headless":return
	for p in effect_players:
		if not p.playing:
			p.stream=load("res://assets/audio/"+id+".wav");p.play();return
