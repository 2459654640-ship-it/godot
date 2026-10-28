extends RefCounted
## Versioned local saves. A failed write never replaces the previous readable copy.
const QUICK="user://d6_save.json"
const FLOORS=["grey_shelter","east_district","life","labor","waterworks","commune","sech","coal","starcity","surface","railfront"]
const MANUAL_SLOTS=6
static func manual_paths()->Array:
	var out=[]
	for i in range(1,MANUAL_SLOTS+1):out.append("user://saves/manual_%d.json"%i)
	return out
static func automatic_paths()->Array:
	return ["user://saves/auto_0.json","user://saves/auto_1.json","user://saves/auto_2.json"]
static func paths()->Array:return manual_paths()+automatic_paths()+[QUICK]
static func title(path:String)->String:
	var index=manual_paths().find(path)
	if index>=0:return "存档位 %02d"%(index+1)
	index=automatic_paths().find(path)
	return "自动存档 %02d"%(index+1) if index>=0 else "旧版快速存档"
static func description(path:String)->String:
	var data=read(path)
	if data.is_empty() and (FileAccess.file_exists(path) or FileAccess.file_exists(path+".bak")):return "这份存档已损坏，无法读取。其它档位不受影响。"
	return summary(data)
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
	if d.has("save_summary") and not d.save_summary is Dictionary:return false
	if d.has("combat_state") and not valid_combat(d.combat_state):return false
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
	var names={"east_district":"东郊工业片区","life":"D-6 · 生活层","labor":"D-6 · 作业层","waterworks":"东郊水处理厂","commune":"莫斯科公社","sech":"废土谢契","coal":"煤运休养区","starcity":"星城外围","surface":"地表旧泵站","railfront":"旧联络线换乘站"}
	var date=Time.get_datetime_string_from_unix_time(int(d.get("saved_at",0))).replace("T"," ") if d.has("saved_at") else "旧版手记"
	var seconds=maxi(0,int(d.get("played_seconds",0)))
	var played="%02d:%02d:%02d"%[seconds/3600,(seconds/60)%60,seconds%60]
	var details:Dictionary=d.get("save_summary",{})
	var place=names.get(d.get("floor","life"),"D-6")
	if details.get("room","")!="":place+=" / "+details.room
	var task:String=details.get("quest","")
	if task=="":task="暂无跟进任务"
	var state=" · 交火中" if d.get("combat_state",{}).get("active",false) else (" · 剧情中" if d.get("flags",{}).get("comic",{}).get("active",false) else "")
	return place+"  ·  游玩 "+played+state+"\n"+task+"  ·  "+date+(" UTC" if d.has("saved_at") else "")+("  ·  已恢复备份" if d.get("recovered_backup",false) else "")

static func valid_combat(c:Variant)->bool:
	if not c is Dictionary:return false
	if c.is_empty():return true
	if not c.get("enemies",[]) is Array or not c.get("checkpoint",{}) is Dictionary:return false
	for enemy in c.get("enemies",[]):
		if not enemy is Dictionary or not enemy.get("position",[]) is Array:return false
		if enemy.position.size()!=3 or enemy.get("kind","") not in ["mutant","soldier","pouncer","spitter","greyhound","behemoth"]:return false
		for n in enemy.position:
			if not (n is int or n is float) or not is_finite(float(n)) or absf(float(n))>10000:return false
		for key in ["hp","cooldown","windup","arrival_time","move_speed","animation"]:
			if enemy.has(key) and (not (enemy[key] is int or enemy[key] is float) or not is_finite(float(enemy[key]))):return false
		var attack=enemy.get("attack",{})
		if not attack is Dictionary:return false
		if attack.get("boss_mode","charge") not in ["charge","spit","bite"]:return false
		if attack.has("direction") and not valid_vector(attack.direction):return false
		for key in ["charge","recovery","hurt"]:
			if attack.has(key) and (not (attack[key] is int or attack[key] is float) or not is_finite(float(attack[key])) or float(attack[key])<0):return false
	if not c.get("projectiles",[]) is Array:return false
	for shot in c.get("projectiles",[]):
		if not shot is Dictionary or not valid_vector(shot.get("position",[])) or not valid_vector(shot.get("direction",[])):return false
		for key in ["speed","remaining","harm"]:
			if not (shot.get(key) is int or shot.get(key) is float) or not is_finite(float(shot[key])) or float(shot[key])<0:return false
	for key in ["clip","cooldown","reload_time","veteran_health","veteran_clip","veteran_reload","veteran_cooldown","rescue"]:
		if c.has(key) and (not (c[key] is int or c[key] is float) or not is_finite(float(c[key]))):return false
	return true

static func valid_vector(v:Variant)->bool:
	if not v is Array or v.size()!=3:return false
	for n in v:
		if not (n is int or n is float) or not is_finite(float(n)) or absf(float(n))>10000:return false
	return true
