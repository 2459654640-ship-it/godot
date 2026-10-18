extends RefCounted
## Collecting a publication never consumes an inventory slot or quest item.
## Save flags contain only owned IDs and read status; all prose stays in one file.
static var _data:Dictionary={}
static func data()->Dictionary:
	if _data.is_empty():_data=JSON.parse_string(FileAccess.get_file_as_string("res://data/publications.json"))
	return _data

static func entry(id:String)->Dictionary:
	for book in data().entries:
		if book.id==id:return book
	return {}

static func owned(story,id:String)->bool:
	var library=story.flags.get("publications",{})
	return library is Dictionary and library.has(id)

static func acquire(story,id:String)->bool:
	if entry(id).is_empty() or owned(story,id):return false
	var library:Dictionary=story.flags.get("publications",{}).duplicate(true)
	library[id]={"read":false}
	story.flags.publications=library
	story.changed.emit()
	return true

static func read(story,id:String)->Dictionary:
	if not owned(story,id):return {}
	var book=entry(id)
	story.flags.publications[id].read=true
	return book

static func count(story,series:String="")->int:
	var total=0
	for book in data().entries:
		if (series=="" or book.series==series) and owned(story,book.id):total+=1
	return total

static func reward(story,action:String)->Array:
	var gained=[]
	for book in data().entries:
		if book.source.kind=="reward" and book.source.action==action and acquire(story,book.id):gained.append(book)
	return gained

static func normalize(story):
	var had_library=story.flags.has("publications")
	var library=story.flags.get("publications",{})
	if not library is Dictionary:library={}
	var clean={}
	for id in library:
		if not entry(id).is_empty():
			var state=library[id]
			clean[id]={"read":bool(state.get("read",false)) if state is Dictionary else false}
	# Old saves can have completed these quests before publications existed.
	# Restore the earned copy quietly; do not re-run tasks or pay ammunition twice.
	for book in data().entries:
		if book.source.kind=="reward" and story.f("c_done_"+book.source.action) and not clean.has(book.id):clean[book.id]={"read":false}
	if had_library or not clean.is_empty():story.flags.publications=clean
	else:story.flags.erase("publications")

static func icon(book:Dictionary)->Texture2D:
	return load("res://assets/publications/cover_%02d.png"%int(book.cover))
