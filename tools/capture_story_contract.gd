extends SceneTree
## Generate an immutable behavioral fixture from the previous committed script.
const IDS=["box","radio","notice","chalk","semyon","mikhail","cook","valve","nina","cabinet","relay","supply","commander","igor","gate","side","hatch","lift","exit"]
const PATHS={
"official":["read_notice","briefing","accept","get_kit","leave_official","get_kit","accept"],
"permit":["borrow_wrench","nina_job","get_fuse","fix_relay","claim_permit","use_permit","use_vodka"],
"bribe":["search_box","open_cache","use_vodka","open_cache","search_box"],
"shift":["search_box","map","trade_smoke","use_shift","trade_smoke"],
"soup":["borrow_wrench","cook_job","fix_valve","claim_soup","give_soup","use_shift","claim_soup"],
"knife":["search_box","hatch_knife","hatch_knife","hatch_wrench"],
"wrench":["borrow_wrench","hatch_wrench","hatch_knife"],
"memory":["tune","chalk","search_box","father","vitamins","give_vitamins","father"],
"early_invalid":["claim_permit","fix_relay","get_kit","use_vodka","use_shift","get_fuse","claim_soup","leave_east"]}

func _initialize():
	var old=GDScript.new()
	old.source_code=FileAccess.get_file_as_string("/tmp/d6-story-v2.txt")
	if old.reload()!=OK:quit(1);return
	var fixture={"source_commit":"c0441b48c57813b5a625e2ba14efb4ed63258241","paths":{}}
	for id in PATHS:
		var story=old.new()
		var states=[sample(story)]
		for action in PATHS[id]:
			story.act(action)
			states.append(sample(story))
		fixture.paths[id]={"actions":PATHS[id],"states":states}
	var file=FileAccess.open("res://tests/fixtures/story-v2-contract.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(fixture,"\t"))
	file.close()
	print("Saved prior-version contract for ",PATHS.size()," paths")
	quit()

func sample(story) -> Dictionary:
	var state=JSON.parse_string(JSON.stringify(story.serialize()))
	state.erase("intel")
	state.intel_count=story.intel.size()
	var options={}
	for id in IDS:
		options[id]={}
		for o in story.view(id).options:options[id][o.key]=o.enabled
	return {"state":state,"options":options}
