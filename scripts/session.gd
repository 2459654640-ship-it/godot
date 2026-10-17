extends Node
## Carries the same story across floors; no autosave overwrites user files.
var pending:Dictionary={}
var departure_snapshot:Dictionary={}
func clear():
	pending={}
	departure_snapshot={}
func enter(data:Dictionary,floor:String,position:Vector3):
	pending={"story":data.duplicate(true),"floor":floor,"position":position}
	var scene={"life":"d6","labor":"labor"}.get(floor,floor)
	get_tree().change_scene_to_file("res://scenes/"+scene+".tscn")

var effect_players:Array[AudioStreamPlayer]=[]
var settings=ConfigFile.new()
func _ready():
	settings.load("user://metro_settings.cfg")
	for bus_name in ["Music","Effects"]:
		if AudioServer.get_bus_index(bus_name)<0:
			AudioServer.add_bus();AudioServer.set_bus_name(AudioServer.bus_count-1,bus_name)
	for pair in [["Master",.8],["Music",.35],["Effects",.85]]:
		set_volume(pair[0],float(settings.get_value("audio",pair[0],pair[1])),false)
	for i in 4:
		var p=AudioStreamPlayer.new();p.bus="Effects";add_child(p);effect_players.append(p)
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
