extends RefCounted
## Story phases gate offers, never the main route. World arrivals are physical, saved facts.
static var _data:Dictionary={}
static func data()->Dictionary:
 if _data.is_empty():_data=JSON.parse_string(FileAccess.get_file_as_string("res://data/living_story.json"))
 return _data
static func extend(c:Dictionary):
 for section in ["actions","interactions"]:c[section].merge(data()[section].duplicate(true),true)
 c.quests.append_array(data().quests.duplicate(true))
 for q in c.quests:
  if q.id=="moro_band":
   q.stages.insert(q.stages.size()-1,{"when":{"all":["moro_ready"]},"target":"commune_moro","step":"到议事厅和莫罗会合，参加试演，再商量正式演出的方式。"})
   q.actions.append("moro_rehearse")
static func busy(s,except:String)->bool:
 for pair in [["anna_request","anna_first_news"],["moro_job","moro_done"],["memory_job","memory_done"]]:
  if pair[0]!=except and s.f(pair[0]) and not s.f(pair[1]):return true
 return false
static func allowed(s,key:String)->bool:
 var offer={"anna_accept":"anna_request","moro_accept":"moro_job","memory_accept":"memory_job"}.get(key,"")
 if offer!="" and not s.f(offer) and busy(s,offer):return false
 # A second chapter is offered after actual field experience, not in the same talk.
 if key=="anna_warning" and not s.f("chapter_first_field"):return false
 if key=="veteran_defense_accept" and s.Campaign.Update.mission(s)=="":return false
 return true
static func act(s,key:String):
 if key in ["anna_walk_invite","moro_accept","veteran_defense_accept"]:
  s.flags.tracked_quest={"anna_walk_invite":"anna_evening","moro_accept":"moro_band","veteran_defense_accept":"veteran_passage"}[key]
static func decorate(v:Dictionary,s)->Dictionary:
 # Keep already accepted tasks visible. Future long chapters do not clutter conversations.
 var staged=["anna_accept","anna_walk_invite","anna_walk_later","anna_walk_talk","anna_visit_class","moro_accept","moro_permission","moro_rehearse","moro_public","moro_private","memory_accept","veteran_defense_accept","veteran_defense_finish"]
 v.options=v.options.filter(func(o):return o.key.trim_prefix("c_") not in staged or o.enabled)
 if v.id=="commune_anna":
  if s.f("anna_walk_started") and not s.f("anna_conversation_ready"):
   v.body="安娜拿着饭盒，正沿医务室西门去食堂。\n安娜：「我走慢一点。你有事先忙，我会在食堂等你。」" if not s.f("anna_walk_arrived") else "安娜在食堂收好借来的课本，把饭盒放在桌边。\n安娜：「总算能吃口热的了。你也坐一会儿吧。」"
  elif s.f("moro_job") and not s.f("moro_done") and not s.f("anna_request"):
   v.body="安娜正在批孩子们的练习册。\n安娜：「听莫罗说，你们要办演出。去忙吧，课本我自己收拾，晚些再聊。」"
 if v.id=="commune_class" and s.f("anna_rescue_started") and not s.f("anna_outcome_done"):
  v.body="课本已经交给代课人。安娜随医护交换队去了 D-6 矿区，会在休养间外与你会合。";v.options=[]
 if v.id=="commune_moro" and s.f("moro_job"):
  if not s.f("moro_parts_found"):v.body="莫罗正带着工具去北侧机修间。\n莫罗：「我在报废架旁等你，咱们一起拆开看看。」"
  elif not s.f("moro_amp_fixed"):v.body="莫罗提着工具，在锅炉房和机修间之间核对线路。\n莫罗：「得把电和接头都查清，再给住户试音。」"
  elif not s.f("moro_schedule"):v.body="莫罗带着试音记录去南侧守备班。\n莫罗：「跟我一起去。场地和时段，我得当面跟他们说。」"
  elif s.f("moro_ready") and not s.f("moro_played"):v.body="莫罗把吉他带到了议事厅，正在给靠门的椅子留出过道。\n莫罗：「先试一遍，愿意帮忙的人都到了。」"
  elif s.f("moro_played"):v.body="莫罗留在演出场地，听住户说刚才哪一段听不清。\n莫罗：「我把这些记下来。以后还能再演，明早的锅炉班也不能误。」"
 return v
static func objective(s)->String:
 if s.context.get("floor","")=="commune" and s.f("anna_walk_started") and not s.f("anna_conversation_ready"):return "陪安娜从医务室西门走到食堂 · 她会在食堂等你"
 if s.context.get("floor","")=="railfront" and s.f("veteran_defense_started") and not s.f("veteran_defense_safe"):return "守住西侧交叉口 · 已接应 %d / 3 人"%int(s.flags.get("veteran_evac_count",0))
 return ""
static func migrate(s,revision:int):
 if revision>=24:return
 if s.f("anna_request"):s.flags.anna_conversation_ready=true
 if s.f("moro_schedule"):s.flags.moro_terms_agreed=true
 if s.f("moro_booked") or s.f("moro_played"):s.flags.moro_rehearsed=true
static func task_stage(s,q:Dictionary,current:Dictionary)->Dictionary:
 var v=current.duplicate()
 if q.id=="moro_band" and s.f("moro_job") and not s.f("moro_done"):
  if s.f("moro_ready") and not s.f("moro_rehearsed"):v.target="commune_moro";v.step="去议事厅参加试演。莫罗会先到场准备，地图显示他的当前位置。"
  elif s.f("moro_amp_fixed") and not s.f("moro_schedule"):v.step="和莫罗一起去南侧守备班，当面商量住户的休息、演出时段与用电。"
  elif not s.f("moro_parts_found"):v.step="跟莫罗到北侧机修间，等他到报废架旁一起拆检音箱。"
 return v
