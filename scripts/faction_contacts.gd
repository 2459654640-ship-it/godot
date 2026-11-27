extends RefCounted
## What Ivan knows, where he can go, and which work he represents are separate.
const GATES={"commune":"east_commune_entry","sech":"east_sech_entry","labor":"east_d6_entry"}
const NAMES={"commune":"莫斯科公社","sech":"废土谢契","labor":"D-6"}
const OFFICERS={"commune":"亚历山德拉","sech":"彼得","labor":"科瓦廖夫"}
const DESKS={"commune":"commune_guard","sech":"sech_quartermaster","labor":"d6_return_desk"}
const PLACES={"commune":"电车站以南 · 红漆管线气闸","sech":"铁路以东 · 旧军列检修库","labor":"南侧 D-6 联络口"}
const APPROACHES={"commune":"在旧电车站的乘客名簿后面找近期的领水记录，也可以去看看站台南侧的红漆管线。","sech":"看看工人街交通维修间的运件登记，或者沿铁路去东侧检修库找轮值牌。"}
const SITE_CLUES={"commune":["city_passenger_roll"],"sech":["east_spares","east_transfer_entry"]}
const LOCAL_COMMITMENTS=["commune_join","commune_stay","anna_home","ending_workers","sech_join","sech_stay","ending_train","ending_caravan","surface_accept","surface_depart","surface_turnin","north_inquiry","north_verify","late_north_contact"]

static func home(s)->String:
 if s.f("commune_member"):return "commune"
 if s.f("sech_member"):return "sech"
 if s.f("d6_cargo_returned") and s.Campaign.Access.public_entry(s):return "labor"
 return String(s.flags.get("faction_home",s.flags.get("east_home",s.context.get("floor",""))))

static func located(s,id:String)->bool:
 return s.f("faction_mapped_"+id) or s.f("visited_"+id) or s.context.get("floor","")==id or s.flags.get("east_home","")==id

static func heard(s,id:String)->bool:
 if id=="labor" or located(s,id) or s.f("faction_heard_"+id):return true
 if id=="commune":return s.f("sergey_explained_commune") or s.f("solo_commune") or s.f("sided_veteran") or s.f("commune_joined")
 return s.f("sergey_explained_sech") or s.f("with_sergey") or s.f("sech_joined")

static func foreign(s,id:String)->bool:
 var base=home(s)
 return NAMES.has(base) and id in ["commune","sech"] and id!=base

static func established(s,id:String)->bool:
 return foreign(s,id) and s.flags.get("faction_visit_"+id,"")==home(s)

static func sponsored(s,id:String)->bool:
 return foreign(s,id) and (s.flags.get("faction_sponsor_"+id,"")==home(s) or (home(s) in ["commune","sech"] and s.f("cross_contact_ready")))

static func can_enter(s,id:String)->bool:
 if id=="labor":return s.Campaign.Access.public_entry(s)
 if home(s)==id:return true
 return foreign(s,id) and (established(s,id) or sponsored(s,id))

static func trusted(s)->bool:
 match home(s):
  "commune":return s.f("commune_trusted") or s.f("field_c1_done") or s.f("chapter_first_field")
  "sech":return s.f("sech_trusted") or s.f("late_s1_done") or s.f("chapter_first_field")
  "labor":return s.f("d6_patrol_done") and s.Campaign.Access.public_entry(s)
 return false

static func sponsor_open(s,id:String)->bool:
 return foreign(s,id) and not (home(s)=="labor" and id=="commune") and trusted(s) and located(s,id) and not can_enter(s,id)

static func status(s,id:String)->Dictionary:
 var base=home(s)
 if id=="labor" and not s.Campaign.Access.public_entry(s):
  return {"state":"公开返站受限","detail":"外侧岗哨查验中央苏维埃的随队与返站记录。矿区的私人接应另行安排。"}
 if id==base or id=="labor":return {"state":"归队入口","detail":"沿这条联络线可以回到你落脚的聚落。备战、交付和寄存都在站内办理。"}
 if base=="labor" and id=="commune":
  return {"state":"敌对 · 不接待公访","detail":"公社不会给现役 D-6 人员办理公访。可以调查地表留下的交流记录。"}
 if established(s,id):return {"state":"已登记 · 可往返","detail":"守门人已有你的访问登记。可从联络口进站、歇脚和交易，所属路线及任务交付地点照旧。"}
 if sponsored(s,id):return {"state":"首次访问已担保","detail":"到地表联络口报接应人姓名；值守核对封签后会登记。这份担保仅适用于这里。"}
 if not located(s,id):return {"state":"听闻 · 入口待查","detail":APPROACHES.get(id,"要在地表找到外侧岗哨。")}
 if sponsor_open(s,id):return {"state":"入口已记 · 可问担保","detail":"回去找%s，把地表路标和找到的入口告诉对方，商量一次具名访问。"%OFFICERS.get(base,"联络人")}
 return {"state":"入口已记 · 缺担保","detail":"你已经知道怎么到岗哨。先完成一项本方外勤、取得接应人的信任，再找联络人。"}

static func record_gate(s,target:String)->bool:
 var id=GATES.find_key(target)
 if id==null or located(s,id):return false
 s.flags["faction_mapped_"+id]=true
 return true

static func enter(s,id:String):
 if not foreign(s,id):return
 var first=not established(s,id)
 s.flags.faction_crossing={"from":home(s),"to":id}
 s.flags.erase("faction_sponsor_"+id)
 s.flags.cross_contact_ready=false
 s.flags.cross_contact_trips=int(s.flags.get("cross_contact_trips",0))+1
 if first:s.flags.next_sequence="faction_arrive_"+id

static func arrive(s,id:String,from:String)->bool:
 var check_in:Dictionary=s.flags.get("faction_crossing",{})
 if from=="east_district" and foreign(s,id):
  var comic:Dictionary=s.flags.get("comic",{})
  var legacy=String(comic.get("sequence",""))=="east_enter_"+id and not comic.get("active",true) and s.f("cross_contact_trips")
  if check_in.get("to","")!=id or check_in.get("from","")!=home(s):
   if not legacy:return false
  s.flags["faction_visit_"+id]=home(s)
  s.flags["arrival_v8_"+id]=true
  s.flags.erase("faction_crossing")
 if id in ["commune","sech"]:
  s.flags["faction_mapped_"+id]=true
  if not NAMES.has(home(s)):s.flags.faction_home=id
 return true

static func leads(s)->Array:
 var out=[]
 var base=home(s)
 for id in ["commune","sech"]:
  if not heard(s,id) or not foreign(s,id) or (base=="labor" and id=="commune") or established(s,id):continue
  var record=status(s,id)
  out.append(NAMES[id]+" · "+record.detail)
 return out

static func allowed(s,key:String)->bool:
 var floor:String=s.context.get("floor","")
 if foreign(s,floor) and (key in LOCAL_COMMITMENTS or key.begins_with("field_")):return false
 if key.begins_with("faction_sponsor_"):return floor==home(s) and sponsor_open(s,key.trim_prefix("faction_sponsor_"))
 if key.begins_with("faction_ask_"):return floor==home(s) and not heard(s,key.trim_prefix("faction_ask_"))
 if key.begins_with("faction_read_"):return not located(s,key.trim_prefix("faction_read_"))
 return true

static func extend(c:Dictionary):
 for id in ["commune","sech"]:
  var origins=["sech" if id=="commune" else "commune","labor"]
  var clue="领水名簿后夹着一张最近的便条。送水的人留了名字，约在电车站以南、三根红漆管线旁交接，落款是莫斯科公社的联络班。你把气闸的位置抄进地图。" if id=="commune" else "运件簿上有几笔新账。收货人签在旧军列检修库一栏，盖的是谢契轮值班的印。旁边还标着铁路以东的入口和台阶。你把它抄进地图。"
  var topic="「听说旧电车站南边还有人运水。他们是哪儿的？」" if id=="commune" else "「听说旧军列那边还有人在巡轨。他们是哪儿的？」"
  var answer="「那是莫斯科公社的人。他们和中央开过火，送水却还走旧电车站。想弄清气闸在哪，去看看站台上的乘客名簿；有人在上头补了最近的领水记录。」" if id=="commune" else "「东边是谢契。住旧军列的那群人管着几段货运线，修车和运货都靠他们自己。工人街的交通维修间留有他们的收货单，那里应该写了库门怎么走。」"
  c.actions["faction_ask_"+id]={"text":topic,"reply":answer,"req":{"floor":origins},"flags":{"faction_heard_"+id:true}}
  c.actions["faction_read_"+id]={"text":"查看夹在旧登记簿里的新记录。","reply":clue,"req":{"floor":["east_district"]},"flags":{"faction_mapped_"+id:true}}
  c.actions["faction_sponsor_"+id]={"text":"「我找到"+NAMES[id]+"的地表联络口了。能安排我去一趟吗？」","reply":"","once":false,"req":{"floor":origins}}
  for origin in origins:
   c.interactions[DESKS[origin]].options.append_array(["faction_ask_"+id,"faction_sponsor_"+id])
  for site in SITE_CLUES[id]:c.interactions[site].options.append("faction_read_"+id)
  var greeting="守备员验过彼得签名的封签，又叫你顺着来路说一遍。听见三根红漆管线，她在访问簿里补上换班号，让等在后面的送水工先过去。\n「以后还走这个口，进来先报名字。有事去联络室说。」" if id=="commune" else "轮值员检查封签，把交接号码抄在自己的本子上。你顺着楼梯向下，听见检修车里有人敲打冻住的水龙头。\n轮值员：「下回还走这个口。把枪收好，进屋等彼得吧，外面风大。」"
  c.panels["faction_arrive_"+id]={"title":"联络簿上的名字","art":id+"_threshold","body":greeting,"end":"map:"+id,"same_moment":true}
  c.interactions[DESKS[id]].options.erase("cross_contact")
  c.interactions[id+"_leave"].options.erase("commune_sech" if id=="commune" else "sech_commune")

static func act(s,key:String)->String:
 if not key.begins_with("faction_sponsor_"):return ""
 var id=key.trim_prefix("faction_sponsor_")
 s.flags["faction_sponsor_"+id]=home(s)
 return OFFICERS[home(s)]+"在封签上签了名。\n「交给联络口值守，他会核对班次。第一次登记以后，下一趟可以照这条路走。你还是从我们这里接活，那边有事要办可以当面问他们。」\n你把担保封签夹进手记，访问安排已记在 M 地图。"
