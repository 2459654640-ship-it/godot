extends SceneTree
func _initialize():
	var source=Image.load_from_file("res://art-source/v7-cast.png")
	var manifest=JSON.parse_string(FileAccess.get_file_as_string("res://assets/characters/atlas.json"))
	for row in 2:
		var id="anna" if row==0 else "father"
		var top=row*source.get_height()/2;var bottom=(row+1)*source.get_height()/2
		var runs=[];var start=-1
		for x in source.get_width():
			var count=0
			for y in range(top,bottom):
				if source.get_pixel(x,y).a>.5:count+=1
			if count>2 and start<0:start=x
			if count<=2 and start>=0:runs.append(Vector2i(start,x));start=-1
		if start>=0:runs.append(Vector2i(start,source.get_width()))
		# Ignore isolated antialias flecks; only full figures span a substantial width.
		runs=runs.filter(func(r):return r.y-r.x>40)
		assert(runs.size()==5,"five full figures per character")
		var atlas=Image.create(1200,352,false,Image.FORMAT_RGBA8)
		for c in 5:
			var crop=source.get_region(Rect2i(runs[c].x,top,runs[c].y-runs[c].x,bottom-top))
			var bounds=crop.get_used_rect();crop=crop.get_region(bounds)
			crop.resize(roundi(float(crop.get_width())*324/crop.get_height()),324,Image.INTERPOLATE_LANCZOS)
			assert(crop.get_width()<230,"normalized body width")
			atlas.blit_rect(crop,Rect2i(Vector2i.ZERO,crop.get_size()),Vector2i(c*240+(240-crop.get_width())/2,18))
			if c==0:
				var face=crop.get_region(Rect2i(0,0,crop.get_width(),140));face.resize(roundi(face.get_width()*1.7),238,Image.INTERPOLATE_LANCZOS)
				var portrait=Image.create(240,280,false,Image.FORMAT_RGBA8);portrait.blit_rect(face,Rect2i(Vector2i.ZERO,face.get_size()),Vector2i((240-face.get_width())/2,280-face.get_height()))
				portrait.save_png("res://assets/portraits/"+id+".png")
		atlas.save_png("res://assets/characters/"+id+".png")
		manifest[id]={"file":id+".png","directions":8,"source_angles":5,"poses":1,"cell":[240,352],"baseline":342,"body_pixels":324,"rear_diagonal_normalized":true,"clips":["idle"]}
	FileAccess.open("res://assets/characters/atlas.json",FileAccess.WRITE).store_string(JSON.stringify(manifest,"  ",false)+"\n")
	quit()
