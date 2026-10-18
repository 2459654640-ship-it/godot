extends RefCounted
## Persist only text actually encountered by the player, never hidden choices.
static func split_text(text:String,speaker:String)->Array:
	var parts=[]
	var regex=RegEx.new()
	regex.compile("「[^」]*」")
	var offset=0
	for quote in regex.search_all(text):
		var narration=text.substr(offset,quote.get_start()-offset).strip_edges()
		var named=RegEx.new();named.compile("(?:^|\\n)([^\\n：:]{1,18})[：:]$")
		var attribution=named.search(narration)
		var voice=speaker;var label=""
		if attribution:
			label=attribution.get_string(1);voice="voice_"+label
			narration=narration.substr(0,attribution.get_start()).strip_edges()
		if narration!="":parts.append({"speaker":"narrator","text":narration})
		var part={"speaker":voice,"text":quote.get_string().trim_prefix("「").trim_suffix("」")}
		if label!="":part.name=label
		parts.append(part)
		offset=quote.get_end()
	var rest=text.substr(offset).strip_edges()
	if rest!="":parts.append({"speaker":"narrator","text":rest})
	return parts
static func append(s,id:String,text:String,speaker:String)->int:
	if not s.conversations.has(id):s.conversations[id]=[]
	var first=s.conversations[id].size()
	# split_text already separates narration from quoted speech. Keep the NPC
	# identity for quotes, including authored campaign dialogue and introductions.
	for part in split_text(text,speaker):s.conversations[id].append(part)
	return first
static func visit(s,id:String,body:String)->int:
	var first=s.conversations.get(id,[]).size()
	if s.last_greetings.get(id,"")!=body:
		append(s,id,body,id)
		s.last_greetings[id]=body
	return first
static func reply(s,id:String,choice:String,text:String)->int:
	if not s.conversations.has(id):s.conversations[id]=[]
	var first=s.conversations[id].size()
	if choice!="":
		var spoken=choice.begins_with("「")
		s.conversations[id].append({"speaker":"ivan" if spoken else "narrator","text":choice.trim_prefix("「").trim_suffix("」") if spoken else "你"+choice})
	append(s,id,text,id)
	return first
