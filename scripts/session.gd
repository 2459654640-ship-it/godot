extends Node
## Carries the same story across floors; no autosave overwrites user files.
var pending:Dictionary={}
var departure_snapshot:Dictionary={}
func clear():
	pending={}
	departure_snapshot={}
func enter(data:Dictionary,floor:String,position:Vector3):
	pending={"story":data.duplicate(true),"floor":floor,"position":position}
	get_tree().change_scene_to_file("res://scenes/labor.tscn" if floor=="labor" else "res://scenes/d6.tscn")
