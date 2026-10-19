extends RefCounted
## Home never follows a patrol destination. Story-directed travel can override it.
static func configure(w):
	for id in w.npcs:
		var a=w.npcs[id]
		a.navigation=w.navigation
		a.home_anchor=a.position
		var point=Vector2(a.position.x,a.position.z)
		var smallest=INF
		for zone in w.zones:
			if zone.rect.has_point(point) and zone.rect.get_area()<smallest:
				a.work_area=zone.rect.grow(-.30);smallest=zone.rect.get_area()
		a.roam_radius=1.45 if not String(id).begins_with("resident_") else 1.7
		if id=="igor" or a.stationary or not a.patrol.is_empty():continue
		# Quiet work within arm's reach of the usual station; no corridor tours.
		var offsets=[Vector3(.7,0,.3),Vector3(-.7,0,.3),Vector3(0,0,.8),Vector3(0,0,-.8)]
		for offset in offsets:
			var destination=a.home_anchor+offset
			if not a.work_area.has_point(Vector2(destination.x,destination.z)):continue
			var path=w.navigation.path(a.home_anchor,destination)
			if path.is_empty() or path[-1].distance_to(destination)>.45:continue
			var safe=true
			for p in path:
				if Vector2(p.x,p.z).distance_to(point)>a.roam_radius or not a.work_area.has_point(Vector2(p.x,p.z)):safe=false;break
			if not safe:continue
			a.patrol.assign([a.home_anchor,path[-1]])
			a.rest_time=22.0+float(posmod(String(id).hash(),130))/10.0
			break
