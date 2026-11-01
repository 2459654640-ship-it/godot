extends Node
## Native distribution can use multiple content packs; source/editor play is unchanged.
func _ready():
 var base=OS.get_executable_path().get_base_dir()
 var path=base.path_join("content/manifest.json")
 if not OS.has_feature("editor") and FileAccess.file_exists(path):
  var manifest=JSON.parse_string(FileAccess.get_file_as_string(path))
  if not manifest is Dictionary or not manifest.get("packs",[]) is Array:failure("The content manifest is damaged.");return
  for entry in manifest.packs:
   if not entry is Dictionary or String(entry.get("file","")).get_file()!=entry.get("file",""):failure("The content manifest is invalid.");return
   var pack=base.path_join("content").path_join(entry.file)
   var file=FileAccess.open(pack,FileAccess.READ)
   if not file or file.get_length()!=int(entry.get("bytes",0)):failure("Missing or damaged file: "+entry.file);return
   file.close()
   if not ProjectSettings.load_resource_pack(pack):failure("Cannot load game content: "+entry.file);return
 elif FileAccess.file_exists("res://content_mode.json"):
  failure("Missing content/manifest.json. Please extract every file before starting.");return
 get_tree().call_deferred("change_scene_to_file","res://scenes/main_menu.tscn")
func failure(reason:String):
 push_error(reason)
 if DisplayServer.get_name()!="headless":OS.alert(reason+"\n\n请完整解压游戏文件后，再启动地铁1982。","地铁1982")
 get_tree().quit(1)
