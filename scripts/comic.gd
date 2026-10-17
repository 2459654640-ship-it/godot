extends RefCounted
## Approved scope: departure to waterworks exterior, or first meeting with Sergey.
const Campaign=preload("res://scripts/campaign.gd")
static var _authored:Dictionary={}
static func authored()->Dictionary:
	if _authored.is_empty():_authored=JSON.parse_string(FileAccess.get_file_as_string("res://data/story_panels.json"))
	return _authored
const PANELS={
"intro_wake":{"art":"wake","title":"醒来 / 16 XI 1982","body":"通风机的低鸣先于闹铃把你叫醒。墙里流过一阵水声，很快又停了。\n二十年前，战争把莫斯科的人赶进地下。你在这里长大，直到现在，晨光对你仍只是一个词。\n你叫伊万，是 D-6 武装小队的一员。老爹谢苗诺夫在门边敲了两下。","next":"intro_semyon"},
"intro_semyon":{"art":"wake","title":"门边的老爹","body":"「醒了就把衣服穿好。管理处昨晚把征召名单送下来了，有你。」\n老爹把声音放低。\n「净水设施停了，存水最多撑两周。明早派人去东郊水处理厂，找战前封存的零件。你先去找科瓦廖夫报到，路线和装备都问清楚。」","choices":[{"text":"「我知道了。还有什么要带的？」","next":"intro_errand"},{"text":"「两周……一点办法也没有了？」","next":"intro_water","flag":"asked_water"}]},
"intro_water":{"art":"wake","title":"两周的水","body":"「能拆的旧件都拆过了，妮娜他们一夜没睡。」\n老爹替你拢了拢衣领。\n「不是催你逞英雄。出去前把面具试好，名单有什么不清楚，直接问中尉。别自己闷着。」","next":"intro_errand"},
"intro_errand":{"art":"wake","title":"出门之前","body":"「先去第七供应点，领今天的维生素 D。别又忘了。」\n老爹指了指楼梯的方向。\n「领完再下作业层找中尉。我在隔壁，有事回来叫我。」\n你穿上外套，检查子弹袋：18 发制式弹，12 发土制弹。地板很冷，走廊里已经有人端着空饭盒经过。","end":"intro"},
"official_gate":{"art":"gate","title":"D-6 正门 / 次日清晨","body":"点名结束，卫兵对过中尉的名单，绞盘慢慢转动。厚钢门退开一道缝，轨道终于通向看不见的远处。\n你们登上电瓶轨道车。有人挪了挪背包，给你留出座位。","next":"official_train"},
"official_train":{"art":"trolley","title":"黑暗里的车声","body":"老兵坐在你对面，左脸有一道旧疤。车轮每越过一道接缝，灯罩就轻轻晃一下。\n「老谢送你来的？」\n你点头。他打量了一会儿你的脸。\n「你小时候我见过。现在都能跟着出任务了。」","choices":[{"text":"「他把我带大的。您也认识我父亲？」","next":"official_father","flag":"asked_veteran_father"},{"text":"「先说说上面吧，我第一次出去。」","next":"official_surface","flag":"asked_surface"}]},
"official_father":{"art":"trolley","title":"一句没说完的话","body":"「认识。1962 年……」\n轨道车猛地颠了一下，中尉提醒大家检查滤罐。老兵伸手扶住你的背包，等车稳下来才接着说。\n「那时候帮过我的人，不少。等这趟平安回来，有时间慢慢说。」\n他没有许诺一个答案。你把这句话记在心里。","next":"official_surface"},
"official_surface":{"art":"surface","title":"第一次看见天空","body":"终点站的台阶上结着薄霜。灰白的光从门缝里涌进来，你隔着面罩抬起头，几乎分不清那是天还是尘。\n「别摘面具。跟紧，脚下看清。」\n中尉指向工业区。老兵站在你身后，替一个年轻士兵拉紧松掉的背带。","choices":[{"text":"帮年轻士兵检查背带，再跟上队伍。","next":"official_plant","flag":"helped_young_soldier"},{"text":"记住回程的入口，确认方位后跟上。","next":"official_plant","flag":"marked_surface_exit"}]},
"official_plant":{"art":"surface","title":"东郊水处理厂 / 外围","body":"沿着废路走了很久，沉淀池和锈蚀的管桥终于出现在眼前。仓库方向被倒下的构件挡住了，里面没有灯。\n中尉让队伍停在围墙外，先清点人和装备。\n老兵朝你摆了摆手。\n「到地方了。先看，别急着进。」","end":"waterworks_exterior"},
"solo_descent":{"art":"descent","title":"灯光的尽头","body":"你沿木板坡道慢慢往下。铁皮在冷风里轻响，身后生活层的说话声一层层被机器声盖住。\n再下去，只有废弃轨道和黑暗。没人替你报数，也没有人催你回头。","next":"solo_tunnel"},
"solo_tunnel":{"art":"descent","title":"独自走进隧道","body":"你沿轨道旁的窄路往前。遇到岔口时停了一会儿，听见远处有轻轻的金属碰撞声。\n一团很小的火光藏在旧维修龛里。火旁的人先看见了你。\n「别再靠近。手让我看见。」","choices":[{"text":"停下，把双手举到他能看见的位置。","next":"solo_sergey","flag":"sergey_cautious"},{"text":"「我只是经过。你是谁？」","next":"solo_sergey","flag":"sergey_direct"}]},
"solo_sergey":{"art":"sergey","title":"火光边的陌生人","body":"那人没有举枪，只把手停在背带上。他的外套很旧，帽檐下有一双没什么睡意的眼睛。\n「谢尔盖·切尔卡索夫。有人叫我灰鹰。」\n他扫过你的衣领和背包。\n「你从哪个地下出来的？」","choices":[{"text":"「D-6。我自己出来的。」","next":"solo_honest","flag":"sergey_honest"},{"text":"「地铁里。别的暂时不想说。」","next":"solo_reserved","flag":"sergey_reserved"}]},
"solo_honest":{"art":"sergey","title":"先换一段路","body":"「D-6……那你认得这边的地铁。」\n谢尔盖把火堆拨小了一点，往旁边挪出些位置。\n「我在找一条通旧军列的路。你熟悉地下，我熟悉上面。先坐一会儿，想清楚愿不愿意同行。」\n你仍没放下背包，但在火光外停住了脚。","end":"sergey_meeting"},
"solo_reserved":{"art":"sergey","title":"各留一点余地","body":"「行。不想说的先留着。」\n谢尔盖没有继续追问，朝火边的空地方偏了偏头。\n「隧道里别只顾着看前头，头顶也听着点。我找旧军列，你要找路，也许能互相省点事。」\n你站在离火几步远的地方。下一段路，还没有决定。","end":"sergey_meeting"}}
static func start(s,sequence:String):
	s.ending=false
	# An illustrated conversation remains in the same moment and facility.
	if not authored().get(sequence,{}).get("same_moment",false) and not Campaign.data().panels.get(sequence,{}).get("end","").begins_with("resume:"):
		s.flags.story_day=17 if sequence=="official" else (16 if sequence in ["solo","intro"] else int(s.flags.get("story_day",17))+1)
		s.flags.story_time="05:40" if sequence=="official" else ("08:10" if sequence=="solo" else "07:42")
	if sequence=="solo" and (not s.has("mask") or not s.has("filter")) and not s.f("unprotected_departure"):
		s.flags.unprotected_departure=true
		s.economy.health=maxi(1,s.economy.health-8)
		s.economy.radiation=mini(100,s.economy.radiation+12)
	s.flags.comic={"active":true,"sequence":sequence,"node":{"intro":"history_war","official":"official_gate","solo":"solo_descent"}.get(sequence,sequence),"visited":[]}
static func panel(s)->Dictionary:
	var node=s.flags.get("comic",{}).get("node","")
	var p:Dictionary=PANELS.get(node,Campaign.data().panels.get(node,{})).duplicate(true)
	p.merge(authored().get(node,{}),true)
	if p.has("lines"):
		var paragraphs:Array[String]=[]
		for line in p.lines:paragraphs.append(line.text if line.speaker=="旁白" else line.speaker+"：「"+line.text+"」")
		p.body="\n".join(paragraphs)
	if not p.is_empty() and s.flags.get("comic",{}).get("sequence","")=="solo" and (not s.has("mask") or not s.has("filter")):
		if p.art in ["descent","sergey"]:p.art+="_unmasked"
		if s.flags.comic.node=="solo_descent":p.body+="\n你没有完整防护。灰尘呛进喉咙，你用围巾捂住口鼻，咳得胸口发疼。必须尽快离开这段积尘的通道。"
	return p
static func choose(s,index:int=-1):
	var state:Dictionary=s.flags.comic
	var p:Dictionary=panel(s)
	if not state.active or p.is_empty():return
	if p.has("choices") and (index<0 or index>=p.choices.size()):return
	if not state.node in state.visited:
		state.visited.append(state.node)
		var records:Array=s.flags.get("comic_records",[])
		records.append({"title":p.title,"body":p.body,"choice":p.choices[index].text if p.has("choices") else ""})
		s.flags.comic_records=records
	if p.has("end"):
		state.active=false
		if p.end=="intro":
			s.flags.intro_done=true
			if not s.f("rations_issued"):
				s.flags.rations_issued=true
				s.economy.goods.bread=int(s.economy.goods.get("bread",0))+2
		elif p.end.begins_with("resume:"):
			s.flags.resume_dialogue=p.end.substr(7)
		elif p.end.begins_with("map:"):
			s.flags.next_facility=p.end.substr(4)
			s.ending=false
		elif p.end.begins_with("ending:"):Campaign.finish(s,p.end.substr(7))
		else:s.flags.chapter_endpoint=p.end;s.ending=true
	elif p.has("choices"):
		if index<0 or index>=p.choices.size():return
		var choice:Dictionary=p.choices[index]
		if choice.has("flag"):s.flags[choice.flag]=true
		state.node=choice.next
	else:state.node=p.next
	if state.node in ["official_surface","official_plant"]:s.flags.story_time="07:25"
	s.flags.comic=state
	s.changed.emit()
