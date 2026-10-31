extends RefCounted
## A persistent transcript above a separate, pinned reply list.
static func portrait(h,id:String)->String:
 var art={"armory":"queue","main_gate":"commander","d6_return_desk":"commander","coal_gate_entry":"queue","front_veteran":"veteran_masked","c1_lidiya":"coal_medic"}.get(id,id)
 if id=="ivan" and h.world.player.art_id!="":art=h.world.player.art_id
 if h.world.npcs.has(id) and h.world.npcs[id].art_id!="":art=h.world.npcs[id].art_id
 return "res://assets/portraits/"+art+".png"
static func gutter(row:HBoxContainer):
 var space=Control.new();space.custom_minimum_size.x=24;row.add_child(space)
static func render(h,id:String,first_new:int):
 load("res://scripts/ui_workbench.gd").dialogue(h,id,first_new)
