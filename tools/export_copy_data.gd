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
	var result={"constants":{},"panels":{},"source_hashes":{},"campaign":{},"d6_views":[]}
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
	result.campaign=clean(s.Campaign.data())
	# Read-only examples of the final decorated view help an editor read D-6
	# dialogue without mistaking an overridden constant for the on-screen line.
	var situations=[
		{"name":"初到生活层／尚未接任务","floor":"life","flags":{},"items":[],"route":""},
		{"name":"已经接取厨房与维修任务、手中有扳手和备用保险芯","floor":"life","flags":{"cook_job":true,"nina_job":true,"heat_job":true},"items":["wrench","fuse","rag"],"route":""},
		{"name":"生活维修已完成，准备领取答谢与记录","floor":"life","flags":{"cook_job":true,"nina_job":true,"heat_job":true,"valve":true,"relay":true,"heating_fixed":true,"vitamins_taken":true},"items":["wrench"],"route":""},
		{"name":"已拿检修许可、暖气记录与换班情报，尚未离站","floor":"life","flags":{"shift":true,"vitamins_taken":true,"father":true,"signal_heard":true},"items":["permit","report","map","mask","filter","frequency","photo"],"route":"permit"},
		{"name":"伊戈尔发现侧门被动过，索要补偿","floor":"life","flags":{"igor_suspicious":true,"igor_debt_known":true},"items":[],"route":"shift"},
		{"name":"已替伊戈尔清理岗灯，等待验收","floor":"life","flags":{"igor_suspicious":true,"igor_debt_known":true,"igor_chore":true,"igor_lamp_clean":true},"items":[],"route":"shift"},
		{"name":"初到作业层、尚未登记征召","floor":"labor","flags":{},"items":[],"route":""},
		{"name":"已登记征召、持中尉登记单，尚未领装备","floor":"labor","flags":{"accepted":true},"items":["order"],"route":"official"},
		{"name":"已领完整离站装备，可以随队出发","floor":"labor","flags":{"accepted":true,"kit":true},"items":["order","mask","filter"],"route":"official"},
		{"name":"从公社持探访安排返回D-6，尚未完成身份审核","floor":"labor","flags":{"d6_returned":true,"anna_request":true,"anna_records":true},"items":["transit_pass","anna_note"],"route":"hatch"},
		{"name":"返站审核与煤矿访问均已批准","floor":"labor","flags":{"d6_returned":true,"return_reviewed":true,"coal_access":true,"anna_request":true,"anna_records":true},"items":["transit_pass","anna_note"],"route":"official"}]
	for situation in situations:
		var sample=Story.new();sample.context.floor=situation.floor;sample.context.hatch_clear=false
		sample.flags.merge(situation.flags,true);sample.route=situation.route
		for item in situation.items:sample.items.append(item)
		var ids=["box","radio","notice","chalk","semyon","mikhail","cook","valve","nina","cabinet","relay","supply","igor","side","hatch","lift","exit"]+sample.Life.IDS if situation.floor=="life" else ["commander","armory","medical","coal_door","main_gate","labor_notice","stairs_up"]
		for id in ids:
			var v=sample.view(id)
			result.d6_views.append({"scenario":situation,"id":id,"view":clean(v)})
	var keys={}
	for source in [s.Comic.PANELS,s.Campaign.data().panels,s.Comic.authored()]:
		for key in source:keys[key]=true
	for key in keys:
		# Keep every conditional line and choice, rather than filtering against
		# an empty save and silently losing branches in an editorial document.
		var panel:Dictionary=s.Comic.PANELS.get(key,s.Campaign.data().panels.get(key,{})).duplicate(true)
		var override:Dictionary=s.Comic.authored().get(key,{})
		if override.has("next") or override.has("choices"):panel.erase("end")
		panel.merge(override,true)
		result.panels[key]=clean(panel)
	var args=OS.get_cmdline_user_args()
	var output=args[0] if not args.is_empty() else "/tmp/metro1982-copy/runtime-v24.json"
	DirAccess.make_dir_recursive_absolute(output.get_base_dir())
	var file=FileAccess.open(output,FileAccess.WRITE)
	if not file:push_error("Cannot write editorial runtime export");quit(1);return
	file.store_string(JSON.stringify(result,"  ",false))
	print("EDITORIAL_EXPORT panels=",result.panels.size()," path=",output)
	quit()
