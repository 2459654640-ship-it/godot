extends SceneTree
const Story=preload("res://scripts/story.gd")
var checks=0
var failures=0
func _initialize():call_deferred("run")
func check(ok:bool,message:String):
 checks+=1
 if not ok:failures+=1;push_error(message)
func run():
 for id in Story.FirstMeetings.data():
  for topic in [0,1]:
   var s=Story.new();s.context.floor="commune" if id.begins_with("commune") else "sech"
   var before=s.serialize().duplicate(true)
   s.view(id)
   check(s.serialize()==before,"journal metadata lookup does not start meeting: "+id)
   s.FirstMeetings.begin(s,id)
   var v=s.view(id)
   check(v.options.size()==1 and v.options[0].key=="meet_"+id+"_name","first meeting asks name before jobs: "+id)
   s.Conversation.visit(s,id,v.body)
   check(s.conversations[id].any(func(e):return e.speaker==id),"quoted greeting is spoken by the actual NPC: "+id)
   var flags=s.flags.duplicate(true);var items=s.items.duplicate();var economy=s.economy.duplicate(true)
   var reply=s.act(v.options[0].key)
   check(s.last_action_valid and not reply.is_empty(),"introduce self: "+id)
   s.Conversation.reply(s,id,v.options[0].text,reply)
   var restored=Story.new();restored.restore(JSON.parse_string(JSON.stringify(s.serialize())))
   restored.context=s.context.duplicate();s=restored
   s.FirstMeetings.begin(s,id)
   v=s.view(id)
   check(v.options.size()==2 and v.options.all(func(o):return o.key.begins_with("meet_") and o.category=="闲聊"),"save/load resumes small talk, with no quest offers: "+id)
   var count=s.conversations[id].size();s.Conversation.visit(s,id,v.body)
   check(s.conversations[id].size()==count,"reopening does not repeat name reply: "+id)
   var choice=v.options[topic];reply=s.act(choice.key)
   s.Conversation.reply(s,id,choice.text,reply)
   check(s.last_action_valid and not reply.is_empty(),"both social branches complete: "+id)
   check(s.view(id).options.any(func(o):return not o.key.begins_with("meet_")),"normal topics become available: "+id)
   flags[s.FirstMeetings.state_key(id)]=2
   check(JSON.parse_string(JSON.stringify(s.flags))==JSON.parse_string(JSON.stringify(flags)) and s.items==items and JSON.parse_string(JSON.stringify(s.economy))==JSON.parse_string(JSON.stringify(economy)),"introductions accept no quests, grant no rewards and change no faction: "+id)
   s.act(choice.key)
   check(not s.last_action_valid,"completed introduction cannot be farmed or repeated: "+id)
   var saved=Story.new();saved.restore(s.serialize());saved.context=s.context.duplicate();saved.FirstMeetings.begin(saved,id)
   check(not saved.view(id).options.any(func(o):return o.key.begins_with("meet_")),"completed meeting persists: "+id)
  var legacy=Story.new();legacy.context.floor="commune" if id.begins_with("commune") else "sech"
  legacy.conversations[id]=[{"speaker":id,"text":"以前已经聊过。"}];legacy.FirstMeetings.begin(legacy,id)
  check(int(legacy.flags[legacy.FirstMeetings.state_key(id)])==2,"legacy acquaintance retained: "+id)
  legacy=Story.new();legacy.flags["c_done_"+legacy.Campaign.data().interactions[id].options[0]]=true;legacy.FirstMeetings.begin(legacy,id)
  check(int(legacy.flags[legacy.FirstMeetings.state_key(id)])==2,"legacy quest progress retained without transcript: "+id)
 # Actual HUD callback path, including an interruption and continuing into a quest.
 var w=load("res://scenes/commune.tscn").instantiate();root.add_child(w);current_scene=w
 for i in 4:await process_frame
 w.story.flags.intro_done=true;w.hud.comic_active=false;w.story.flags.comic={"active":false};w.hud.close()
 w.interact("commune_anna");w.hud.finish_typing()
 check(w.story.view("commune_anna").options[0].key=="meet_commune_anna_name","actual interaction starts introduction")
 var option=w.story.view("commune_anna").options[0]
 for b in w.hud.modal.find_children("*","Button",true,false):
  if b.text==option.text:b.pressed.emit();break
 w.hud.finish_typing();w.hud.close();w.interact("commune_anna");w.hud.finish_typing()
 check(w.story.view("commune_anna").options.size()==2,"HUD interruption resumes at correct exchange")
 option=w.story.view("commune_anna").options[1]
 for b in w.hud.modal.find_children("*","Button",true,false):
  if b.text==option.text:b.pressed.emit();break
 w.hud.finish_typing()
 check(not w.story.f("anna_request"),"learning about brother does not autoaccept quest")
 check(w.story.view("commune_anna").options.any(func(o):return o.key=="c_anna_lesson" and o.enabled),"Anna first invites Ivan to understand the classroom")
 w.perform("c_anna_lesson","commune_anna")
 var steps=0
 while w.story.flags.get("comic",{}).get("active",false) and steps<10:
  var panel=w.story.Comic.panel(w.story);w.hud.comic_choose(0 if panel.has("choices") else -1);steps+=1
 check(w.story.f("anna_lesson_seen") and not w.story.f("anna_request"),"classroom does not silently accept the request")
 w.perform("c_anna_walk_later","commune_anna")
 w.perform("c_anna_accept","commune_anna")
 check(w.story.f("anna_request"),"original quest acceptance still works")
 w.queue_free()
 for i in 3:await process_frame
 print("FIRST_MEETINGS_V17_RESULT checks=",checks," failures=",failures)
 quit(0 if failures==0 else 1)
