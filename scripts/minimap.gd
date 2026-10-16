extends Control
var world
var expanded=false
func _draw():
	if not world:return
	var pad=Vector2(18,18)
	var scale_factor=minf((size.x-36)/30.0,(size.y-36)/19.0)
	var offset=Vector2(15,9)
	for zone in world.zones:
		var r:Rect2=zone.rect
		var rect=Rect2(pad+(r.position+offset)*scale_factor,r.size*scale_factor)
		draw_rect(rect,Color("263936") if zone.code=="00" else Color("1b2b2b"))
		draw_rect(rect,Color("53635a"),false,1)
		if expanded:
			draw_string(world.kit.font,rect.position+Vector2(8,20),zone.code+"  "+zone.name,HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("c7c0a5"))
	for id in ["lift","gate","side","hatch"]:
		var t=world.targets[id]
		var pos=pad+(Vector2(t.pos.x,t.pos.z)+offset)*scale_factor
		draw_circle(pos,3.5,Color("c19b58"))
	var p=pad+(Vector2(world.player.position.x,world.player.position.z)+offset)*scale_factor
	draw_circle(p,5.5,Color("e2bd79"))
	draw_arc(p,9,0,TAU,24,Color(0.88,0.74,0.46,0.4),1.5)
	if expanded:
		for id in world.npcs:
			var a=world.npcs[id]
			draw_circle(pad+(Vector2(a.position.x,a.position.z)+offset)*scale_factor,3,Color("7bb4b5"))
