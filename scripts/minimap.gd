extends Control
## A surveyed axonometric plan. It is a view of existing zones, not navigation.
var world
var expanded=false
var display_floor=""
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
	var floor=display_floor if display_floor!="" else world.floor_id
	var same=floor==world.floor_id
	var zones=world.facility_zones(floor)
	var bounds=Rect2()
	var first=true
	for zone in zones:
		for corner in [zone.rect.position,Vector2(zone.rect.end.x,zone.rect.position.y),zone.rect.end,Vector2(zone.rect.position.x,zone.rect.end.y)]:
			var flat=Vector2((corner.x-corner.y)*.86,(corner.x+corner.y)*.45)
			if first:bounds=Rect2(flat,Vector2.ZERO);first=false
			else:bounds=bounds.expand(flat)
	drawing_scale=minf((size.x-32)/bounds.size.x,(size.y-(80 if expanded else 24))/bounds.size.y)
	origin=Vector2(size.x*.5,size.y*.5)-bounds.get_center()*drawing_scale
	var focused=world.hud.Journal.active(world.story)
	var focus_point=Vector2.INF
	if not focused.is_empty():
		if same and world.targets.has(focused.target):
			var target:Vector3=world.targets[focused.target].pos;focus_point=Vector2(target.x,target.z)
		elif world.CampaignMaps.LAYOUTS.has(floor):
			for entry in world.CampaignMaps.LAYOUTS[floor].objects:
				if entry[0]==focused.target:focus_point=Vector2(entry[1],entry[2])
	var drawing_zones=zones.duplicate()
	if floor in ["surface","starcity","railfront"]:drawing_zones.sort_custom(func(a,b):return a.code=="00" and b.code!="00")
	for zone in drawing_zones:
		var r:Rect2=zone.rect
		var points=polygon(r.grow(-0.14))
		var shadow=points.duplicate()
		for i in shadow.size():shadow[i]+=Vector2(0,3 if expanded else 2)
		draw_colored_polygon(shadow,Color("060c0c"))
		draw_colored_polygon(points,Color("364239") if zone.code=="00" else Color("26302b"))
		draw_polyline(PackedVector2Array([points[0],points[1],points[2],points[3],points[0]]),Color("65705e"),1.2,true)
		if not focused.is_empty() and focused.place==floor and (focused.area==zone.name or (focus_point.is_finite() and r.has_point(focus_point))):
			draw_colored_polygon(points,Color(.72,.56,.29,.19))
			draw_polyline(PackedVector2Array([points[0],points[1],points[2],points[3],points[0]]),gold,2,true)
			if expanded:draw_string(world.kit.font,project(r.get_center())+Vector2(-22,-15),"这一带",HORIZONTAL_ALIGNMENT_LEFT,-1,13,gold)
		if zone.code=="01" and floor=="life":draw_line(project(Vector2(-11.95,-9)),project(Vector2(-11.95,-2.8)),gold,1.2,true)
		if zone.code!="00" and not (floor=="life" and zone.code in ["09","10"]):
			draw_string(world.kit.font,project(r.get_center())+Vector2(-6,4),zone.code,HORIZONTAL_ALIGNMENT_LEFT,-1,14 if expanded else 10,Color("c5bea2"))
	if floor=="labor":
		var stair=Rect2(-13.8,4.1,3.2,5.3)
		draw_colored_polygon(polygon(stair.grow(-.1)),Color("555444"))
		for i in 10:draw_line(project(Vector2(-10.95-i*.25,6.65)),project(Vector2(-10.95-i*.25,8.95)),gold,1,true)
		if expanded:draw_string(world.kit.font,project(stair.get_center())+Vector2(-6,-10),"LS",HORIZONTAL_ALIGNMENT_LEFT,-1,14,gold)
	for p in world.facility_doors(floor):
		var center=project(p)
		draw_line(center-Vector2(3,1.5),center+Vector2(3,1.5),gold,2,true)
	# A meeting is an area objective, not an invisible dot at the lectern.
	if not focused.is_empty() and world.InteractionRegions.active(world.story,focused.target):
		var spec:Dictionary=world.InteractionRegions.REGIONS[focused.target]
		if spec.floor==floor:
			var region=polygon(spec.rect)
			draw_colored_polygon(region,Color(.78,.63,.33,.22))
			draw_polyline(PackedVector2Array([region[0],region[1],region[2],region[3],region[0]]),gold,2,true)
			if expanded:draw_string(world.kit.font,project(spec.rect.get_center())+Vector2(-36,18),"进入此区按 E",HORIZONTAL_ALIGNMENT_LEFT,-1,13,gold)
	elif expanded and not focused.is_empty() and focused.place==floor and focus_point.is_finite():
		var point=project(focus_point)
		draw_arc(point,6,0,TAU,20,gold,2,true)
		draw_circle(point,2,gold)
		draw_string(world.kit.font,point+Vector2(9,-7),"当前目标",HORIZONTAL_ALIGNMENT_LEFT,-1,13,gold)
	for id in ["lift","gate","side","hatch","main_gate","stairs_up","coal_door"]:
		if not same or not world.targets.has(id):continue
		var t=world.targets[id]
		var pos=project(Vector2(t.pos.x,t.pos.z))
		var color=Color("80ac91") if (id=="gate" and world.story.f("gate")) or (id=="side" and world.story.f("side_crossed")) else gold
		draw_rect(Rect2(pos-Vector2(2.5,2.5),Vector2(5,5)),color,false,1.3)
	if expanded and same:
		for id in world.npcs:
			var a=world.npcs[id]
			draw_circle(project(Vector2(a.position.x,a.position.z)),2.7,Color("79a8a0"))
	if same:
		var p=project(Vector2(world.player.position.x,world.player.position.z))
		var forward=world.player.visual.global_basis.z
		var direction=(project(Vector2(world.player.position.x-forward.x,world.player.position.z-forward.z))-p).normalized()
		var right=Vector2(-direction.y,direction.x)
		draw_colored_polygon(PackedVector2Array([p+direction*6,p-direction*4+right*3.5,p-direction*4-right*3.5]),Color("e0c48b"))
		draw_arc(p,9,0,TAU,28,Color(0.88,0.77,0.54,0.30),1,true)
	if expanded:
		draw_string(world.kit.font,Vector2(12,24),{"life":"D–6 / 生活层","labor":"D–6 / 作业层"}.get(floor,world.story.Campaign.NAMES.get(floor,"设施")),HORIZONTAL_ALIGNMENT_LEFT,-1,16,gold)
		var n=Vector2(size.x-30,35)
		draw_line(n,n+Vector2(0,28),ink,1.2,true)
		draw_colored_polygon(PackedVector2Array([n,n+Vector2(-4,12),n+Vector2(4,12)]),gold)
		draw_string(world.kit.font,n+Vector2(-5,-7),"N",HORIZONTAL_ALIGNMENT_LEFT,-1,13,ink)
		draw_line(Vector2(16,size.y-20),Vector2(16+drawing_scale*2,size.y-20),gold,2)
		draw_string(world.kit.font,Vector2(16,size.y-28),"2 m",HORIZONTAL_ALIGNMENT_LEFT,-1,12,ink)
