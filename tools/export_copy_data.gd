extends SceneTree
## Resolve engine-side constants and comic overrides for the editorial export.
func clean(value):
	if value is Object:return null
	if value is Dictionary:
		var result={}
		for key in value:
			var item=clean(value[key])
			if item!=null:result[str(key)]=item
		return result
	if value is Array:
		var result=[]
		for item in value:result.append(clean(item))
		return result
	if typeof(value) in [TYPE_NIL,TYPE_BOOL,TYPE_INT,TYPE_FLOAT,TYPE_STRING]:return value
	return str(value)
func _initialize():
	var result={"constants":{},"panels":{},"source_hashes":{}}
	for folder in ["scripts","data"]:
		for name in DirAccess.get_files_at("res://"+folder):
			if name.ends_with(".gd") or name.ends_with(".json"):
				var path=folder+"/"+name
				result.source_hashes[path]=FileAccess.get_sha256("res://"+path)
	for file in ["story","narrative","resident_dialogue","d6_chapter","progression","journal","economy","comic"]:
		var script=load("res://scripts/"+file+".gd")
		result.constants[file]=clean(script.get_script_constant_map())
	var Story=load("res://scripts/story.gd")
	var s=Story.new()
	var keys={}
	for source in [s.Comic.PANELS,s.Campaign.data().panels,s.Comic.authored()]:
		for key in source:keys[key]=true
	for key in keys:
		s.flags.comic={"active":true,"sequence":"editorial","node":key,"visited":[]}
		result.panels[key]=s.Comic.panel(s)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/copy"))
	var output=ProjectSettings.globalize_path("res://docs/copy/runtime-v13.json")
	var file=FileAccess.open(output,FileAccess.WRITE)
	if not file:push_error("Cannot write editorial runtime export");quit(1);return
	file.store_string(JSON.stringify(result,"  ",false))
	print("EDITORIAL_EXPORT panels=",result.panels.size()," path=",output)
	quit()
