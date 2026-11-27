extends Control
const Atlas=preload("res://scripts/district_atlas.gd")
signal point_chosen(id:String)
## The expanded paper chart and the nearby view read the same floor geometry.
var world
var expanded=false
var display_floor=""
var drawing_scale=1.0
var origin=Vector2.ZERO
var gold=Color("c7aa70")
var flat_projection=false
var map_zoom=1.0
var map_pan=Vector2.ZERO
var map_points:Dictionary={}
var map_selected=""
var map_hover=""
var reviewed_task:Dictionary={}
var preview_only=false

func map_task()->Dictionary:
	return reviewed_task if preview_only else world.hud.Journal.active(world.story)

func reset_view():
	map_zoom=1;map_pan=Vector2.ZERO;queue_redraw()

func center_on(id:String):
	var points=Atlas.features(world,map_task())
	if not points.has(id):return
	var plot=Atlas.frame(self)
	map_zoom=maxf(map_zoom,1.55)
	var scale=minf(plot.size.x/Atlas.BOUNDS.size.x,plot.size.y/Atlas.BOUNDS.size.y)*map_zoom
	map_pan=-Vector2(points[id].p)*scale
	select_point(id)

func select_point(id:String):
	map_selected=id;point_chosen.emit(id);queue_redraw()

func pick(pos:Vector2)->String:
	if not Atlas.frame(self).grow(8).has_point(pos):return ""
	var best=14.0
	var selected=""
	var order=map_points.keys();order.reverse()
	for id in order:
		var d=project(map_points[id].p).distance_to(pos)
		if d<best:best=d;selected=id
	return selected

func zoom_at(at:Vector2,factor:float):
	var next=clampf(map_zoom*factor,1,3)
	if is_equal_approx(map_zoom,next):return
	map_pan=at-Atlas.frame(self).get_center()-(at-origin)*(next/map_zoom)
	map_zoom=next;clamp_pan();queue_redraw()

func clamp_pan():
	var plot=Atlas.frame(self)
	var boundary=plot.size*(.20+.38*map_zoom)
	map_pan=map_pan.clamp(-boundary,boundary)

func project(p:Vector2) -> Vector2:
	if flat_projection:return origin+p*drawing_scale
	return origin+Vector2((p.x-p.y)*0.86,(p.x+p.y)*0.45)*drawing_scale

func _gui_input(event):
	var floor=display_floor if display_floor!="" else world.floor_id
	if not expanded or floor!="east_district":return
	if event is InputEventMouseMotion:
		if event.button_mask&MOUSE_BUTTON_MASK_MIDDLE:
			map_pan+=event.relative;clamp_pan();queue_redraw();accept_event();return
		var hit=pick(event.position)
		if hit!=map_hover:map_hover=hit;queue_redraw()
		tooltip_text=map_points[hit].name+" · "+map_points[hit].status if hit!="" else "左键点空白处标记方位 · 右键清除"
	if event is InputEventMouseButton and event.pressed:
		if event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
			zoom_at(event.position,1.2 if event.button_index==MOUSE_BUTTON_WHEEL_UP else 1.0/1.2);accept_event();return
		if event.button_index==MOUSE_BUTTON_LEFT:
			var hit=pick(event.position)
			if hit!="":select_point(hit);accept_event();return
			if not Atlas.frame(self).grow(8).has_point(event.position):return
			var p=(event.position-origin)/drawing_scale
			if not Atlas.BOUNDS.has_point(p):return
			pin(p)
		elif event.button_index==MOUSE_BUTTON_RIGHT:
			world.story.flags.erase("city_waypoint")
			if map_selected=="waypoint":select_point("")
		else:return
		queue_redraw();accept_event();world.autosave()

func pin(p:Vector2):
	world.story.flags.city_waypoint=[p.x,p.y];queue_redraw()

func polygon(r:Rect2) -> PackedVector2Array:
	return PackedVector2Array([project(r.position),project(Vector2(r.end.x,r.position.y)),project(r.end),project(Vector2(r.position.x,r.end.y))])

func _draw():
	if not world:return
	var floor=display_floor if display_floor!="" else world.floor_id
	flat_projection=expanded
	if floor=="east_district":
		if expanded:Atlas.draw(self)
		else:preload("res://scripts/city_survey.gd").draw_map(self)
		return
	var same=floor==world.floor_id
	var zones=world.facility_zones(floor)
	var bounds=Rect2()
	var first=true
	for zone in zones:
		for corner in [zone.rect.position,Vector2(zone.rect.end.x,zone.rect.position.y),zone.rect.end,Vector2(zone.rect.position.x,zone.rect.end.y)]:
			var flat=corner if flat_projection else Vector2((corner.x-corner.y)*.86,(corner.x+corner.y)*.45)
			if first:bounds=Rect2(flat,Vector2.ZERO);first=false
			else:bounds=bounds.expand(flat)
	var plot=Atlas.frame(self) if expanded else Rect2(Vector2(16,12),size-Vector2(32,24))
	if not bounds.has_area():return
	drawing_scale=minf(plot.size.x/bounds.size.x,plot.size.y/bounds.size.y)
	origin=plot.get_center()-bounds.get_center()*drawing_scale
	if expanded:Atlas.paper(self,{"life":"D-6 生活层","labor":"D-6 作业层"}.get(floor,world.story.Campaign.NAMES.get(floor,"设施")),"ПЛАН ПОМЕЩЕНИЙ  /  站内平面图")
	var focused=map_task()
	var focus_point=Vector2.INF
	if not focused.is_empty():
		if same and world.targets.has(focused.target):
			var target:Vector3=world.targets[focused.target].pos;focus_point=Vector2(target.x,target.z)
		elif world.CampaignMaps.LAYOUTS.has(floor):
			for entry in world.CampaignMaps.LAYOUTS[floor].objects:
				if entry[0]==focused.target:focus_point=Vector2(entry[1],entry[2])
	var drawing_zones=zones.duplicate()
	drawing_zones.sort_custom(func(a,b):return a.code=="00" and b.code!="00")
	for zone in drawing_zones:
		var r:Rect2=zone.rect
		var points=polygon(r.grow(-0.14))
		var plan:Dictionary=preload("res://scripts/late_layouts.gd").PLANS.get(floor,{})
		if plan.get("polygons",{}).has(zone.code):
			points=PackedVector2Array()
			for p in plan.polygons[zone.code]:points.append(project(p))
		elif floor=="starcity" and preload("res://scripts/starcity_v17.gd").POLYGONS.has(zone.code):
			points=PackedVector2Array()
			for p in preload("res://scripts/starcity_v17.gd").POLYGONS[zone.code]:points.append(project(p))
		var shadow=points.duplicate()
		for i in shadow.size():shadow[i]+=Vector2(0,3 if expanded else 2)
		draw_colored_polygon(shadow,Color("b0a58c") if expanded else Color("060c0c"))
		draw_colored_polygon(points,(Color("c6c7ad") if zone.code=="00" else Color("ede2c5")) if expanded else (Color("364239") if zone.code=="00" else Color("26302b")))
		var outline=points.duplicate();outline.append(points[0])
		draw_polyline(outline,Color("748071") if expanded else Color("65705e"),1.2,true)
		if not focused.is_empty() and focused.place==floor and (focused.area==zone.name or (focus_point.is_finite() and r.has_point(focus_point))):
			draw_colored_polygon(points,Color(.72,.56,.29,.19))
			draw_polyline(outline,Atlas.TASK if expanded else gold,2,true)
		if zone.code=="01" and floor=="life":draw_line(project(Vector2(-11.95,-9)),project(Vector2(-11.95,-2.8)),gold,1.2,true)
		if zone.code!="00" and not (floor=="life" and zone.code in ["09","10"]):
			var pen=project(r.get_center())
			var title:String=zone.name
			var width=world.kit.font.get_string_size(title,HORIZONTAL_ALIGNMENT_LEFT,-1,13).x
			if expanded and width+12<r.size.x*drawing_scale and r.size.y*drawing_scale>30:
				draw_string(world.kit.font,pen+Vector2(-width/2,5),title,HORIZONTAL_ALIGNMENT_LEFT,-1,13,Atlas.INK)
			else:draw_string(world.kit.font,pen+Vector2(-6,4),zone.code,HORIZONTAL_ALIGNMENT_LEFT,-1,13 if expanded else 10,Atlas.FAINT if expanded else Color("c5bea2"))
	if floor=="labor":
		var stair=Rect2(-13.8,4.1,3.2,5.3)
		draw_colored_polygon(polygon(stair.grow(-.1)),Color("bbb9a0") if expanded else Color("555444"))
		for i in 10:draw_line(project(Vector2(-10.95-i*.25,6.65)),project(Vector2(-10.95-i*.25,8.95)),Atlas.FAINT if expanded else gold,1,true)
		if expanded:draw_string(world.kit.font,project(stair.get_center())+Vector2(-12,-10),"楼梯",HORIZONTAL_ALIGNMENT_LEFT,-1,13,Atlas.INK)
	for p in world.facility_doors(floor):
		var center=project(p)
		draw_line(center-Vector2(3,1.5),center+Vector2(3,1.5),Atlas.TRAVEL if expanded else gold,2,true)
	if expanded and same and floor=="coal" and focused.get("id","")=="anna_rescue":draw_mine_journey()
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
		Atlas.marker(self,point,"task",false)
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
	if same and expanded:Atlas.marker(self,project(Vector2(world.player.position.x,world.player.position.z)),"player",false)
	elif same:
		var p=project(Vector2(world.player.position.x,world.player.position.z))
		var forward=world.player.visual.global_basis.z
		var direction=(project(Vector2(world.player.position.x-forward.x,world.player.position.z-forward.z))-p).normalized()
		var right=Vector2(-direction.y,direction.x)
		draw_colored_polygon(PackedVector2Array([p+direction*6,p-direction*4+right*3.5,p-direction*4-right*3.5]),Color("e0c48b"))
		draw_arc(p,9,0,TAU,28,Color(0.88,0.77,0.54,0.30),1,true)
	if expanded:
		Atlas.compass(self,Vector2(size.x-42,40))
		Atlas.scale(self,Vector2(25,size.y-20),5)

func draw_mine_journey():
	var destination=world.story.Campaign.Rescue.map_destination(world.story)
	if not destination.is_finite():return
	var path:PackedVector3Array=world.navigation.path(world.player.position,destination)
	if path.is_empty():return
	var points=PackedVector2Array()
	for p in path:points.append(project(Vector2(p.x,p.z)))
	if points.size()>1:draw_polyline(points,Color("c4a36c"),1.6,true)
	draw_string(world.kit.font,Vector2(16,49),"金线 · 本次同行路线",HORIZONTAL_ALIGNMENT_LEFT,-1,13,gold)
