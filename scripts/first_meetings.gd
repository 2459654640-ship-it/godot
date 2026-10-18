extends RefCounted
## Social introductions start only on an actual conversation, never a journal lookup.
static var _data:Dictionary={}
static func data()->Dictionary:
	if _data.is_empty():_data=JSON.parse_string(FileAccess.get_file_as_string("res://data/first_meetings.json"))
	return _data
static func state_key(id:String)->String:return "first_meeting_"+id
static func begin(s,id:String):
	if not data().has(id) or s.flags.has(state_key(id)):return
	var known=not s.conversations.get(id,[]).is_empty() or s.last_greetings.has(id)
	# Legacy saves can have quest progress without a retained transcript.
	for action in s.Campaign.data().interactions[id].options:
		if s.f("c_done_"+action):known=true
	s.flags[state_key(id)]=2 if known else 0
static func decorate(v:Dictionary,s)->Dictionary:
	if not data().has(v.id):return v
	var stage=int(s.flags.get(state_key(v.id),2))
	if stage>=2:return v
	var d:Dictionary=data()[v.id]
	var here=s.context.get("floor","")==s.Campaign.data().interactions[v.id].facility
	v.body=d.greeting if stage==0 else d.named
	v.options=[]
	if stage==0:
		v.options.append(s.opt("meet_"+v.id+"_name",d.name_choice,here))
	else:
		for i in d.topics.size():v.options.append(s.opt("meet_"+v.id+"_topic"+str(i),d.topics[i].text,here))
	return v
static func act(s,key:String)->String:
	for id in data():
		if not key.begins_with("meet_"+id+"_"):continue
		var stage=int(s.flags.get(state_key(id),2))
		var d:Dictionary=data()[id]
		if stage==0 and key=="meet_"+id+"_name":
			s.flags[state_key(id)]=1
			# Reopening at this stage must not repeat the reply as a fresh greeting.
			s.last_greetings[id]=d.named
			return d.named
		if stage==1:
			for i in d.topics.size():
				if key=="meet_"+id+"_topic"+str(i):
					s.flags[state_key(id)]=2
					return d.topics[i].reply
	return "这句话已经说过了。"
