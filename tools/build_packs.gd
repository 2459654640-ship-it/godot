extends SceneTree
## Called by package_native.py after extracting the authoritative Godot export.
func _initialize():
 var args=OS.get_cmdline_user_args()
 if args.size()!=1:quit(2);return
 var spec=JSON.parse_string(FileAccess.get_file_as_string(args[0]))
 for job in spec.jobs:
  var pack=PCKPacker.new()
  if pack.pck_start(job.output)!=OK:quit(3);return
  for entry in job.entries:
   if pack.add_file("res://"+entry.path,entry.file)!=OK:quit(4);return
  if pack.flush()!=OK:quit(5);return
  print("PACK_READY ",job.output)
 quit()
