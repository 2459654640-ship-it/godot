extends SceneTree
const Story=preload("res://scripts/story.gd")
const Narrative=preload("res://scripts/narrative.gd")
var checks=0
var failures:Array[String]=[]
func check(ok:bool,message:String):
	checks+=1
	if not ok:failures.append(message);push_error(message)
func _initialize():
	var fixture=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/story-v2-contract.json"))
	for path in fixture.paths:
		var s=Story.new()
		s.flags.nina_safety=true
		s.context.hatch_clear=true # Legacy fixture compares costs after the new physical prerequisite.
		var sequence=fixture.paths[path]
		for index in sequence.states.size():
			if index>0:
				var key=sequence.actions[index-1]
				var reply=s.act(key)
				if not key in ["leave_official","leave_east"]:check(not reply.is_empty(),"actual interaction result has authored text: "+key)
			var expected=sequence.states[index]
			var actual=JSON.parse_string(JSON.stringify(s.serialize()))
			actual.erase("intel")
			for added in ["economy","conversations","last_greetings","checkpoint","read_topics"]:actual.erase(added)
			for added in ["social_seed","nina_safety","briefed","intro_done"]:actual.flags.erase(added)
			actual.intel_count=float(s.intel.size())
			check(actual==expected.state,"quest state/reward/cost unchanged: %s step %d" % [path,index])
			for id in expected.options:
				var options={}
				for o in s.view(id).options:
					if expected.options[id].has(o.key):options[o.key]=o.enabled
				var expected_options=expected.options[id].duplicate()
				if id=="supply":expected_options.erase("get_kit")
				if id=="lift":expected_options.erase("leave_official")
				if id=="hatch" and s.f("hatch"):
					for key in expected_options:expected_options[key]=false
				for key in expected_options:
					if s.once_topic(key) and key in s.read_topics:expected_options[key]=false
				check(options==expected_options,"all original action gates unchanged: %s/%d/%s" % [path,index,id])
		# Conversations should never grant items, persist flags or change routes.
		var before=s.serialize().duplicate(true)
		for key in Narrative.CHAT:
			var reply=s.act(key)
			var after=s.serialize().duplicate(true);after.erase("read_topics")
			var original=before.duplicate(true);original.erase("read_topics")
			check(reply==Narrative.CHAT[key][2] and after==original,"small talk preserves quests and rewards: "+key)
			s.act(key);check(not s.last_action_valid,"read topic cannot be clicked again: "+key)
	for id in Narrative.BODIES:
		var s=Story.new()
		for stage in range(2):
			if stage==1:s.restore({"version":1,"flags":{"searched":true,"cache":true,"relay":true,"valve":true,"soup_claimed":true,"accepted":true,"kit":true,"gate":true,"hatch":true,"fuse_taken":true,"shift":true,"side_crossed":true},"items":["permit","frequency"],"intel":[],"route":"permit","ending":false})
			var body=s.view(id).body
			check(not body.is_empty(),"authored body present: "+id)
			for banned in ["原型","测试","本次新增","不赠送","作为补偿","开发"]:check(not banned in body,"no development instructions in scene prose: "+id)
	var characters={"semyon":0,"nina":0,"mikhail":0,"cook":0,"supply":0,"commander":0,"igor":0}
	for key in Narrative.CHAT:characters[Narrative.CHAT[key][0]]+=1
	for id in characters:check(characters[id]>=3,"at least three personal conversations: "+id)
	print("NARRATIVE_CONTRACT_RESULT checks=",checks," failures=",failures.size())
	quit(0 if failures.is_empty() else 1)
