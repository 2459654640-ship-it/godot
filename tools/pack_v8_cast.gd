extends SceneTree
## Normalize generated source sheets into the established five-view atlas contract.
var manifest:Dictionary
func _initialize():
	manifest=JSON.parse_string(FileAccess.get_file_as_string("res://assets/characters/atlas.json"))
	var sources=JSON.parse_string(FileAccess.get_file_as_string("res://art-source/v8/sources.json"))
	for source in sources:pack(source)
	FileAccess.open("res://assets/characters/atlas.json",FileAccess.WRITE).store_string(JSON.stringify(manifest,"  ",false)+"\n")
	quit()
func bands(image:Image,horizontal:bool)->Array:
	var out=[];var start=-1
	var length=image.get_height() if horizontal else image.get_width()
	var cross=image.get_width() if horizontal else image.get_height()
	for i in length:
		var count=0
		for j in cross:
			if image.get_pixel(j,i).a>.4 if horizontal else image.get_pixel(i,j).a>.4:count+=1
		var used=count>3
		if used and start<0:start=i
		if not used and start>=0:
			if i-start>20:out.append(Vector2i(start,i))
			start=-1
	if start>=0:out.append(Vector2i(start,length))
	return out
func pack(source:Dictionary):
	var image=Image.load_from_file("res://art-source/v8/"+source.file)
	var rows=bands(image,true)
	assert(rows.size()==source.rows,"authored row count: "+source.file)
	var by_id={}
	for row in rows.size():
		var id:String=source.ids[mini(row,source.ids.size()-1)]
		if not by_id.has(id):by_id[id]=[]
		var strip=image.get_region(Rect2i(0,rows[row].x,image.get_width(),rows[row].y-rows[row].x))
		var columns=bands(strip,false)
		assert(columns.size()==5,"five separate directions: "+source.file+" row "+str(row))
		var cells=[]
		for c in 5:
			var cell=strip.get_region(Rect2i(columns[c].x,0,columns[c].y-columns[c].x,strip.get_height()))
			cell=cell.get_region(cell.get_used_rect())
			cell.resize(roundi(float(cell.get_width())*324/cell.get_height()),324,Image.INTERPOLATE_LANCZOS)
			assert(cell.get_width()<238,"body fits original cell: "+id)
			cells.append(cell)
		by_id[id].append(cells)
	for id in by_id:
		var poses:int=by_id[id].size()
		var atlas=Image.create(1200,352*poses,false,Image.FORMAT_RGBA8)
		for row in poses:
			for c in 5:
				var cell:Image=by_id[id][row][c]
				atlas.blit_rect(cell,Rect2i(Vector2i.ZERO,cell.get_size()),Vector2i(c*240+(240-cell.get_width())/2,row*352+18))
		atlas.save_png("res://assets/characters/"+id+".png")
		var front:Image=by_id[id][0][0]
		var portrait=Image.create(240,280,false,Image.FORMAT_RGBA8)
		var face=front.get_region(Rect2i(0,0,front.get_width(),140));face.resize(roundi(face.get_width()*1.7),238,Image.INTERPOLATE_LANCZOS)
		portrait.blit_rect(face,Rect2i(Vector2i.ZERO,face.get_size()),Vector2i((240-face.get_width())/2,42));portrait.save_png("res://assets/portraits/"+id+".png")
		manifest[id]={"file":id+".png","directions":8,"source_angles":5,"poses":poses,"cell":[240,352],"baseline":342,"body_pixels":324,"rear_diagonal_normalized":true,"clips":["idle","left_stride","right_stride"] if poses==3 else ["idle"]}
