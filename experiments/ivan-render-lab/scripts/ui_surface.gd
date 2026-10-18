extends Node2D
## Tactile cloth, engraved rules and restrained corner hardware, behind a panel's text.
var host:Control
var kind="panel"
var grain:Texture2D
static func attach(control:Control,type:String="panel"):
	var surface=load("res://scripts/ui_surface.gd").new()
	surface.host=control;surface.kind=type
	control.add_child(surface,false,Node.INTERNAL_MODE_FRONT)
	control.resized.connect(surface.queue_redraw)
	return surface
func _ready():
	grain=load("res://assets/visual/interface_cloth.png") if ResourceLoader.exists("res://assets/visual/interface_cloth.png") else load("res://assets/visual/weave.png")
func _draw():
	if not is_instance_valid(host):return
	var rect=Rect2(Vector2(2,2),host.size-Vector2(4,4))
	if rect.size.x<8 or rect.size.y<8:return
	if grain:draw_texture_rect(grain,rect,true,Color(1,1,1,.20 if kind!="button" else .10))
	var gold=Color(.72,.63,.44,.7)
	var light=Color(.7,.74,.64,.12)
	draw_line(Vector2(8,5),Vector2(host.size.x-8,5),light,1)
	if kind=="button":
		draw_line(Vector2(8,host.size.y-4),Vector2(host.size.x-8,host.size.y-4),Color(.55,.6,.5,.13),1)
		return
	for p in [Vector2(8,8),Vector2(host.size.x-8,8),Vector2(8,host.size.y-8),host.size-Vector2(8,8)]:
		draw_circle(p,1.4,Color(.53,.54,.42,.7))
		draw_line(p-Vector2(1,0),p+Vector2(1,0),Color(.08,.12,.1),1)
	draw_line(Vector2(17,12),Vector2(48,12),gold,2)
	draw_line(Vector2(host.size.x-48,host.size.y-12),Vector2(host.size.x-17,host.size.y-12),gold,1)
