extends RefCounted
## Versioned local saves. A failed write never replaces the previous readable copy.
const QUICK="user://d6_save.json"
const FLOORS=["life","labor","waterworks","commune","sech","coal","starcity","surface"]
static func paths()->Array:
	return [QUICK,"user://saves/manual_1.json","user://saves/manual_2.json","user://saves/manual_3.json","user://saves/auto_0.json","user://saves/auto_1.json","user://saves/auto_2.json"]
static func valid(d:Variant)->bool:
	if not d is Dictionary or int(d.get("version",0))!=1:return false
	if d.get("floor","life") not in FLOORS:return false
	for key in ["flags","economy","conversations"]:
		if d.has(key) and not d[key] is Dictionary:return false
	for key in ["items","intel","read_topics"]:
		if d.has(key) and not d[key] is Array:return false
	for key in ["items","intel","read_topics"]:
		for entry in d.get(key,[]):
			if not entry is String:return false
	var economy:Dictionary=d.get("economy",{})
	for key in ["goods","stock"]:
		if economy.has(key) and not economy[key] is Dictionary:return false
	for key in ["health","food","radiation","military","handmade"]:
		if economy.has(key) and not (economy[key] is int or economy[key] is float):return false
	var p=d.get("position",[0,.04,0])
	if not p is Array or p.size()!=3:return false
	for n in p:
		if not (n is float or n is int) or not is_finite(float(n)) or absf(float(n))>10000:return false
	if d.has("checksum"):
		var payload=d.duplicate(true);var checksum=payload.checksum;payload.erase("checksum")
		if JSON.stringify(payload).sha256_text()!=checksum:return false
	return true
static func read(path:String)->Dictionary:
	for source in [path,path+".bak"]:
		if not FileAccess.file_exists(source):continue
		var parser=JSON.new()
		if parser.parse(FileAccess.get_file_as_string(source))!=OK:continue
		var d=parser.data
		if valid(d):
			d=d.duplicate(true);d.erase("checksum")
			if source.ends_with(".bak"):d.recovered_backup=true
			return d
	return {}
static func parsed(path:String)->Variant:
	if not FileAccess.file_exists(path):return null
	var parser=JSON.new()
	return parser.data if parser.parse(FileAccess.get_file_as_string(path))==OK else null
static func write(path:String,data:Dictionary,kind:String="manual")->Error:
	if not valid(data):return ERR_INVALID_DATA
	var payload=data.duplicate(true);payload.erase("checksum");payload.erase("recovered_backup")
	payload.saved_at=Time.get_unix_time_from_system();payload.save_kind=kind
	# JSON restores all numeric fields as doubles. Hash the same normalized
	# representation on both sides (rather than int-vs-float in live state).
	payload=JSON.parse_string(JSON.stringify(payload))
	payload.checksum=JSON.stringify(payload).sha256_text()
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var file=FileAccess.open(path+".tmp",FileAccess.WRITE)
	if not file:return FileAccess.get_open_error()
	file.store_string(JSON.stringify(payload,"\t"));file.flush();file.close()
	if not valid(parsed(path+".tmp")):return ERR_FILE_CORRUPT
	if FileAccess.file_exists(path) and valid(parsed(path)):
		var copied=DirAccess.copy_absolute(path,path+".bak")
		if copied!=OK:return copied
	return DirAccess.rename_absolute(path+".tmp",path)
static func newest()->Dictionary:
	var latest={};var stamp=-1.0
	for path in paths():
		var data=read(path)
		if data.is_empty():continue
		var time=float(data.get("saved_at",FileAccess.get_modified_time(path)))
		if time>stamp:latest={"path":path,"data":data};stamp=time
	return latest
static func auto_path()->String:
	var oldest="user://saves/auto_0.json";var stamp=INF
	for i in 3:
		var path="user://saves/auto_%d.json"%i;var d=read(path)
		if d.is_empty():return path
		if float(d.get("saved_at",0))<stamp:oldest=path;stamp=float(d.get("saved_at",0))
	return oldest
static func summary(d:Dictionary)->String:
	if d.is_empty():return "空存档位"
	var names={"life":"D-6 · 生活层","labor":"D-6 · 作业层","waterworks":"东郊水处理厂","commune":"莫斯科公社","sech":"废土谢契","coal":"煤运休养区","starcity":"星城外围","surface":"地表旧泵站"}
	var date=Time.get_datetime_string_from_unix_time(int(d.get("saved_at",0))).replace("T"," ") if d.has("saved_at") else "旧版手记"
	return names.get(d.get("floor","life"),"D-6")+"  ·  "+date+" UTC"+("  ·  已恢复备份" if d.get("recovered_backup",false) else "")
