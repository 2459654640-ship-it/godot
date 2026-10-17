extends Control
## A surveyed axonometric plan. It is a view of existing zones, not navigation.
var world
var expanded=false
var drawing_scale=1.0
var origin=Vector2.ZERO
var ink=Color("7e8a7a")
var gold=Color("c7aa70")

func project(p:Vector2) -> Vector2:
	return origin+Vector2((p.x-p.y)*0.86,(p.x+p.y)*0.45)*drawing_scale

func polygon(r:Rect2) -> PackedVector2Array:
	return PackedVector2Array([project(r.position),project(Vector2(r.end.x,r.position.y)),project(r.end),project(Vector2(r.position.x,r.end.y))])

func _draw():
	if not world:return
	var bounds=Rect2()
	var first=true
	for zone in world.zones:
		for corner in [zone.rect.position,Vector2(zone.rect.end.x,zone.rect.position.y),zone.rect.end,Vector2(zone.rect.position.x,zone.rect.end.y)]:
			var flat=Vector2((corner.x-corner.y)*.86,(corner.x+corner.y)*.45)
			if first:bounds=Rect2(flat,Vector2.ZERO);first=false
			else:bounds=bounds.expand(flat)
	drawing_scale=minf((size.x-32)/bounds.size.x,(size.y-(80 if expanded else 24))/bounds.size.y)
	origin=Vector2(size.x*.5,size.y*.5)-bounds.get_center()*drawing_scale
	for zone in world.zones:
		var r:Rect2=zone.rect
		var points=polygon(r.grow(-0.14))
		var shadow=points.duplicate()
		for i in shadow.size():shadow[i]+=Vector2(0,3 if expanded else 2)
		draw_colored_polygon(shadow,Color("060c0c"))
		draw_colored_polygon(points,Color("364239") if zone.code=="00" else Color("26302b"))
		draw_polyline(PackedVector2Array([points[0],points[1],points[2],points[3],points[0]]),Color("65705e"),1.2,true)
		if zone.code=="01":draw_line(project(Vector2(-11.95,-9)),project(Vector2(-11.95,-2.8)),gold,1.2,true)
		if zone.code not in ["00","09","10"]:
			draw_string(world.kit.font,project(r.get_center())+Vector2(-6,4),zone.code,HORIZONTAL_ALIGNMENT_LEFT,-1,14 if expanded else 10,Color("c5bea2"))
	for p in [Vector2(-10.5,0),Vector2(-3.5,0),Vector2(5.2,0),Vector2(12.3,0),Vector2(-11,3.2),Vector2(-3.4,3.2),Vector2(5.6,3.2)]+world.Wing.DOORS:
		var center=project(p)
		draw_line(center-Vector2(3,1.5),center+Vector2(3,1.5),gold,2,true)
	for id in ["lift","gate","side","hatch"]:
		var t=world.targets[id]
		var pos=project(Vector2(t.pos.x,t.pos.z))
		var color=Color("80ac91") if (id=="gate" and world.story.f("gate")) or (id=="side" and world.story.f("side_crossed")) else gold
		draw_rect(Rect2(pos-Vector2(2.5,2.5),Vector2(5,5)),color,false,1.3)
	if expanded:
		for id in world.npcs:
			var a=world.npcs[id]
			draw_circle(project(Vector2(a.position.x,a.position.z)),2.7,Color("79a8a0"))
	var p=project(Vector2(world.player.position.x,world.player.position.z))
	var forward=world.player.visual.global_basis.z
	var direction=(project(Vector2(world.player.position.x-forward.x,world.player.position.z-forward.z))-p).normalized()
	var right=Vector2(-direction.y,direction.x)
	draw_colored_polygon(PackedVector2Array([p+direction*6,p-direction*4+right*3.5,p-direction*4-right*3.5]),Color("e0c48b"))
	draw_arc(p,9,0,TAU,28,Color(0.88,0.77,0.54,0.30),1,true)
	if expanded:
		draw_string(world.kit.font,Vector2(12,24),"Д–6 / ЖИЛОЙ УРОВЕНЬ",HORIZONTAL_ALIGNMENT_LEFT,-1,16,gold)
		var n=Vector2(size.x-30,35)
		draw_line(n,n+Vector2(0,28),ink,1.2,true)
		draw_colored_polygon(PackedVector2Array([n,n+Vector2(-4,12),n+Vector2(4,12)]),gold)
		draw_string(world.kit.font,n+Vector2(-5,-7),"N",HORIZONTAL_ALIGNMENT_LEFT,-1,13,ink)
		draw_line(Vector2(16,size.y-20),Vector2(16+drawing_scale*2,size.y-20),gold,2)
		draw_string(world.kit.font,Vector2(16,size.y-28),"2 m",HORIZONTAL_ALIGNMENT_LEFT,-1,12,ink)
