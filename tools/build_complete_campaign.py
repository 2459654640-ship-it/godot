from pathlib import Path
import json
ROOT=Path(__file__).resolve().parents[1]
d={k:{} for k in ['actions','interactions','panels','jobs','endings']};d['quests']=[]
def A(key,text,reply='',all=(),not_=(),floor=None,flags=None,once=True,**kw):
 req={'all':list(all),'not':list(not_)}
 if floor:req['floor']=[floor] if isinstance(floor,str) else floor
 d['actions'][key]={'text':text,'reply':reply,'once':once,'req':req,'flags':{key:True}|(flags or {}),**kw};return key
def I(key,floor,name,body,options,role='现场',spoken=False,after=()):d['interactions'][key]=dict(facility=floor,name=name,role=role,body=body,options=options,spoken=spoken,after=list(after))
def P(key,title,art,lines=(),next=None,end=None,choices=None,music='shift_below',**kw):
 p=dict(title=title,art=art,same_moment=True,music=music,**kw)
 if isinstance(lines,str):p['body']=lines
 else:p['lines']=[dict(speaker=x[0],text=x[1],**({'when':x[2]} if len(x)>2 else {})) for x in lines]
 if next:p['next']=next
 if end:p['end']=end
 if choices:p['choices']=choices
 d['panels'][key]=p

def stage(target,place,step,*flags):return dict(when={'all':list(flags)},target=target,place=place,step=step)
def job(id,faction,name,prereq,floor,brief):
 home={'commune':'commune','sech':'sech','d6':'labor'}[faction];person={'commune':'commune_guard','sech':'sech_elder','d6':'d6_return_desk'}[faction]
 accepted=f'late_{id}_started';done=f'late_{id}_done';key=f'field_{id}_accept' if faction!='d6' else f'late_{id}_accept'
 flags={accepted:True,'late_active_job':id,'late_story_enabled':True}
 if faction!='d6':flags[f'field_{id}_accepted']=True
 A(key,'「我愿意接这趟工作。先说说情况。」',brief,all=prereq,not_=[done],floor=home,flags=flags,give=['revolver'])
 d['jobs'][id]=dict(faction=faction,home=home,person=person,name=name,floor=floor,accept=key,accepted=accepted,done=done)
 return accepted,done,home,person

def J(id,suffix,text,reply='',all=(),floor=None,**kw):return A('late_'+id+'_'+suffix,text,reply,all=['late_'+id+'_started',*all],not_=['late_'+id+'_done'],floor=floor,**kw)
def Q(id,name,background,stages,actions=()):
 j=d['jobs'][id];d['quests'].append(dict(id='late_'+id,name=name,kind='主线',facility=j['home'],accepted=j['accepted'],done=j['done'],background=background,lead='',stages=stages,actions=[j['accept'],*actions]))
def report(id,requirements,reply,travel=None):
 j=d['jobs'][id];flags={j['done']:True};
 if id[0] in 'cs':flags['field_'+id+'_done']=True
 return J(id,'report','「事情办完了。我把经过说清楚。」',reply,all=requirements,floor=j['home'],flags=flags,reward={'handmade':24,'military':8},**({'travel':travel} if travel else {}))
# C2: a person is evacuated before the letters are delivered.
job('c2','commune','被截住的回信',['commune_member','field_c1_done'],'junction','亚历山德拉：「运输员尤里没有按约回来，家属只听见有人说他叛逃了。巴拉诺娃一直替住户收信，你先问她最后一班车去了哪里。别先替我们写一个结论。」')
J('c2','family','「那一班车上，有你认识的人吗？」','巴拉诺娃：「尤里替我们带信。那天他还问，信封上能不能只写收件人的名字，住址等到了再问。我把邮袋交给他，约好下个休息班来取回执。他没有来。我想知道他平不平安，也想请你把信交到本人手里。」',floor='commune',flags={'late_c2_route_known':True})
J('c2','depart','登记出站，沿地表前往货场换乘线。',all=['late_c2_route_known'],floor='commune',once=False,travel='late_c2_road')
J('c2','find','「我从公社来。你是尤里吗？」','尤里：「是我。轮轴坏了以后，我留下看车。封锁队来过，把盖着住址的那张名册收走了。信藏在工具夹层里，没让他们拿走。我的腿还能走，先离开这里吧。」',floor='junction',flags={'late_c2_found':True},give=['late_mailbag'])
J('c2','consent','「信交给收件人，接应人的姓名和住址不公开。你愿意让我这样转告吗？」','尤里：「愿意。还有，告诉巴拉诺娃，我答应帮她找的那个人，回执还没查到。别因为我回来了，就说每个人都有消息了。」',all=['late_c2_found'],floor='junction',flags={'late_c2_escort':True})
J('c2','letters','逐一核对收件人，再请巴拉诺娃私下转交。','巴拉诺娃把信封一只只排开，遇到不认识的名字就单独放在一边。\n「有两封得继续打听，我不会把它们扔了。尤里在厨房喝水，我先去看看他。谢谢你把人也带回来。」',all=['late_c2_evacuated'],floor='commune',take=['late_mailbag'])
report('c2',['late_c2_letters'],'亚历山德拉：「我撤下那张失踪通知，只写尤里已经平安回来。没有找到的人继续找。有人问名单为什么不全公开，我会把理由当面说明。」',travel='late_c2_home')
Q('c2','被截住的回信','找到运输员本人，护送他离开换乘线，再按本人意愿交还书信。',[
 stage('commune_baranova','commune','先问巴拉诺娃运输员和邮袋最后的去向。'),stage('commune_leave','commune','备好装备，从公社出站。沿地图去北线货场换乘口。','late_c2_route_known'),stage('junction_yuri','junction','到西北检修间找尤里；中部有兽群，也能从西侧维修廊绕行。','late_c2_depart'),stage('junction_yuri','junction','与尤里商量书信的处理，再陪他到南侧接送口。','late_c2_found'),stage('junction_yuri','junction','陪尤里走到南口；距离太远时他会等你。','late_c2_escort'),stage('junction_exit','junction','尤里已到接送处，从南口一起返回公社。','late_c2_evacuated'),stage('commune_baranova','commune','把邮袋交给巴拉诺娃，按收件人分别转交。','late_c2_home_arrived'),stage('commune_guard','commune','把找到的人、尚未查到的消息和名单安排向守备班说明。','late_c2_letters')])
# C3: heat is physically restored; a resident relocates while it is off.
job('c3','commune','暖气恢复以后',['commune_member','late_c2_done'],'commune','亚历山德拉：「锅炉修好了，议事厅准备宣布恢复供暖。可巴拉诺娃说客铺仍然很冷。你先去摸摸回水管，再查总表。别让住户拿着我们的通知，等一整夜热水。」')
J('c3','cold','检查家属房的回水温度，与住户核对。','回水管几乎和墙一样冷。巴拉诺娃拿来一条补过的毯子。\n「通知说已经修好了，我就让老人们别再搬床。是我听得太急了吗？」\n你请她先到食堂靠近炉子的地方休息，再去核对管线。',floor='commune',flags={'late_c3_cold_confirmed':True})
J('c3','diagram','对照锅炉房的阀位和回水记录。','你沿管线找到临时改管：为保住温室的夜间供热，上一班关闭了家属区的支路。锅炉已经能运转，两处末端却不能同时达到原来的温度。记录上没有写这一点。先把卡住的调节阀修好，才有分时供暖的条件。',all=['late_c3_cold_confirmed'],floor='commune')
J('c3','parts','在机修间核对规格，领取阀芯和密封垫。','机修员把配套零件留给你，提醒你先断开家属区支路。\n「这个型号还能修。别把整座锅炉停了，医务室那边正在换药。」',all=['late_c3_diagram'],floor='commune',give=['late_valve_parts'])
J('c3','isolate','关闭家属区支路，打开泄压口。','你先关小上游阀，确认压力回落，再打开检修口。其它支路仍在供热。',all=['late_c3_parts'],floor='commune')
J('c3','repair','更换阀芯，缓慢恢复回水。','管道里先传来断续的水声，随后回水温度开始上升。你检查接头，没有继续渗水。温室与家属区可以按班次轮换供热，医务室保持优先；这套安排还需要当面告知受影响的人。',all=['late_c3_isolate'],floor='commune',take=['late_valve_parts'],flags={'late_c3_heat_restored':True})
J('c3','meeting','参加居民议事，说明原通知遗漏的停暖情况。','你把测温记录与改管经过放在桌上。有人担心温室减热会少收作物，家属房的住户则请委员说清楚每班到底能开多久。\n议事会最终同意先试行轮换供热，将每班测温交给住户核对。旧的成功通知撤下，补贴实际受影响的房间。',all=['late_c3_heat_restored'],floor='commune',flags={'late_c3_public_record':True})
report('c3',['late_c3_meeting'],'亚历山德拉：「以后交接既写已经恢复的部分，也写还没有恢复的部分。星城那个观测台的事，我愿意让你去核对。但介绍信只说明你为什么去，门是他们自己开的。」',travel='late_c3_home')
Q('c3','暖气恢复以后','供热通知与住户实际感受不符。查明管线，修复调节阀，再公开安排供热。',[
 stage('commune_radiator','commune','先检查家属房暖气，与巴拉诺娃核实停暖。'),stage('commune_boiler','commune','到锅炉房核对支路、阀位和回水记录。','late_c3_cold_confirmed'),stage('commune_salvage','commune','到机修间领取对应阀芯与密封垫。','late_c3_diagram'),stage('commune_boiler','commune','在锅炉房隔离家属支路，泄压后维修，再恢复回水。','late_c3_parts'),stage('commune_hall','commune','到人民议事厅座席区说明停暖、维修与轮换方案。','late_c3_heat_restored'),stage('commune_guard','commune','交接实际测温记录与居民议事决定。','late_c3_public_record')])
# Sech's opening job is engineering rather than a renamed document raid.
job('s1','sech','空车也要回家',['sech_member'],'junction','长老：「北线那辆检修车刹死在换乘口，司机怕空着手回来挨骂，留在那里修了两班。彼得要的是人平安，车能修就修。到现场先卸掉制动压力，再查旁线，别把人逼着守一辆铁壳。」')
J('s1','inspect','检查检修车制动与车轮。','手制动已经松开，制动管里仍有残压。车轮后垫着木楔，司机没有冒险把车推上坡道。西侧检修柜有放气接头，先接管再泄压。',floor='junction')
J('s1','spare','在检修柜领取放气接头与旧制动软管。','接头型号相符，软管还能用于低压试车。你将坏管留在柜边，挂上停用标记。',all=['late_s1_inspect'],floor='junction',give=['late_brake_kit'])
J('s1','brake','接好软管，放掉残压，再取走轮挡。','压力表回到零位，车轮终于能转动。你先让司机缓慢试车，确认制动重新有效，才收起轮挡。',all=['late_s1_spare'],floor='junction',take=['late_brake_kit'])
J('s1','switch','检查岔尖贴合，锁好通往南口的旁线。','你清掉轨槽里的碎石，将道岔锁到旁线。司机复述了手势，车缓慢滑到南口等待。',all=['late_s1_brake'],floor='junction',flags={'late_s1_ready':True})
report('s1',['late_s1_ready'],'长老：「修车的人回来了，车也回来了。彼得已经替司机补上了休息班。下一趟不是空车：有个替我们跑运输的人被灰狗扣住，先让谢尔盖把情况说清楚。」',travel='late_s1_home')
Q('s1','空车也要回家','修好滞留检修车的制动和旁线，让司机安全返站。',[
 stage('sech_leave','sech','备好装备，从谢契出站，沿地表去北线货场换乘口。'),stage('junction_car','junction','先检查检修车的制动残压和轮挡。','late_s1_depart'),stage('junction_tools','junction','到西南检修间领取放气接头。','late_s1_inspect'),stage('junction_car','junction','返回检修车，更换软管、泄压并测试制动。','late_s1_spare'),stage('junction_switch','junction','到南侧道岔检查岔尖并锁定旁线。','late_s1_brake'),stage('junction_exit','junction','从南口随检修车返回谢契。','late_s1_ready'),stage('sech_elder','sech','向长老与彼得交代人、车和线路状况。','late_s1_home_arrived')])
# S2 uses the actual bandit hideout and the existing stealth system.
job('s2','sech','没有旗子的车队',['sech_member','late_s1_done'],'grey_shelter','长老：「运输员阿尔乔姆被灰狗扣在货场下的避难所。谢尔盖见过他，先问清位置。能绕过守卫就绕，必须动枪时也别忘了里面还有被扣住的人。拿回货不是这趟最要紧的事。」')
J('s2','brief','「阿尔乔姆被关在哪里？灰狗有多少人？」','谢尔盖：「货场营地有持枪守卫，地下入口在棚屋旁。阿尔乔姆被留在住户铺位那间，看管的人会回厨房。你可以从货场围栏的缺口绕进去，轻步走，别在他们面前翻箱子。真打起来就先找掩体。」',floor='sech')
J('s2','depart','出站前往灰狗货场营地。',all=['late_s2_brief'],floor='sech',once=False,travel='late_s2_road')
J('s2','release','「谢尔盖让我来接你。你还能走吗？」','阿尔乔姆：「能。我记得外面的路。车上有几袋粮食，灰狗说是买的，可我没有签收，也没有收钱。你先带我出去，到了谢契，我当面把话说清楚。」',floor='grey_shelter',flags={'late_s2_escort':True},give=['late_driver_statement'])
J('s2','account','请阿尔乔姆当面说明失踪与被扣货物的经过。','阿尔乔姆将自己的工牌放在桌上，逐项说明没有收到的款项与被拿走的粮食。谢尔盖没有替他回答。彼得先让他去吃饭，将争议货物另列，暂缓派出报复队。',all=['late_s2_evacuated'],floor='sech',take=['late_driver_statement'])
report('s2',['late_s2_account'],'长老：「被扣的人已经回来，货还可以继续追。接下来要安排一趟家属和粮食同行的车，别让出过事的人立刻再去冒险。」',travel='late_s2_home')
Q('s2','没有旗子的车队','从灰狗避难所接出被扣的运输员。可以利用守卫视线潜入，也可以正面交战。',[
 stage('sech_sergey','sech','先请谢尔盖说明入口、守卫和运输员的位置。'),stage('sech_leave','sech','备好装备后出站，寻找灰狗货场地下入口。','late_s2_brief'),stage('late_captive','grey_shelter','在避难所住户铺位找到阿尔乔姆，确认他能够同行。','late_s2_depart'),stage('late_captive','grey_shelter','陪阿尔乔姆到地下出口，他会等你靠近后继续。','late_s2_escort'),stage('grey_shelter_exit','grey_shelter','阿尔乔姆已到出口；回地表后从谢契入口返站。','late_s2_evacuated'),stage('sech_sergey','sech','让阿尔乔姆当面说明经过，再与长老交接。','late_s2_home_arrived'),stage('sech_elder','sech','交接运输员的说明和后续安排。','late_s2_account')])
job('s3','sech','末班车的空位',['sech_member','late_s2_done'],'junction','长老：「这趟要接四名外来伤病者，还要带回过冬粮食。一辆车不能都装下。你可以先修另一辆拖车；实在修不了，就把先后安排说清楚，第二班由我们负责，别让等车的人以为被丢下了。」')
J('s3','manifest','当面核对人数、担架位置和货物重量。','司机划出了担架需要的位置。旁边停着一辆缺联接销的拖车，车轴仍完好。修好拖车就能两辆同行；否则必须先送伤病者，或先运粮食，并为另一班留下值守人员。',floor='junction')
J('s3','coupling','在检修柜检查并领取匹配的联接销。','你量过销孔，找到带防脱孔的联接销。司机提醒你装好后还要插入保险件，空推一次。',all=['late_s3_manifest'],floor='junction',give=['late_coupling'])
J('s3','repair','联接拖车，锁好保险并进行空车制动测试。','两辆车先后缓慢停住。联接销没有窜动，拖车可以一起走，担架与粮食不用再争同一块位置。',all=['late_s3_coupling'],floor='junction',take=['late_coupling'],flags={'late_s3_capacity':True})
J('s3','people','「这一班先接伤病者；粮食留人看守，下一班回来运。」','司机将第二班时间告诉留下的人，请一位轮值者签下接应安排。有人担心粮食会被偷走，彼得的联络员答应留在这里，不让他们独自等。',all=['late_s3_manifest'],floor='junction',flags={'late_s3_depart_ready':True,'late_s3_people_first':True})
J('s3','both','核对两车分载和担架固定，通知所有人上车。','伤病者上了有挡风板的前车，粮袋与工具放在拖车。你把名单交给司机，确认站台上已经没有被漏掉的人。',all=['late_s3_capacity'],floor='junction',flags={'late_s3_depart_ready':True,'late_s3_all_carried':True})
report('s3',['late_s3_evacuated'],'长老：「接应的值守和空床已经排上。星城外围答应接收线路检修申请，彼得会给你一封说明来意的信。里面的人不了解我们，信只能让他们知道该问谁，不能代替他们的核查。」',travel='late_s3_home')
Q('s3','末班车的空位','落实运力、乘员与接应。修复第二辆车可以避免把人和粮食分成两班。',[
 stage('sech_leave','sech','从谢契出站，前往北线货场换乘口。'),stage('junction_manifest','junction','先在候车处核对名单和载重。','late_s3_depart'),stage('junction_tools','junction','可到检修间找联接销修好拖车；也可明确安排先接伤病者。','late_s3_manifest'),stage('junction_car','junction','装好联接销与保险，测试拖车制动。','late_s3_coupling'),stage('junction_manifest','junction','确认两车分载与担架固定，通知上车。','late_s3_capacity'),stage('junction_family','junction','陪候车的人走到南口；确认到齐后出发。','late_s3_depart_ready'),stage('junction_exit','junction','人已到齐，从南口随车返回谢契。','late_s3_evacuated'),stage('sech_elder','sech','交接乘员、货物与下一班安排。','late_s3_home_arrived')])
# D-6 has its own continuing line after the first pump expedition.
job('d1','d6','谁先通过',['d6_patrol_done','d6_cargo_returned'],'junction','科瓦廖夫：「伤员车和燃料车都等在北线单行段。你先查南侧道岔，能把旁线修通就分流。医护要求伤员先走，供暖班也说再不来煤就要停炉。把你能确认的情况带回来，别只照着表格签字。」')
J('d1','inspect','检查旁线岔尖、电源和手动锁闭。','岔尖被碎石卡住，电机保护座也烧坏了。旁线没有塌陷，换掉保护座并清理轨槽后可以恢复。西南检修间保存着同型号备件。',floor='junction')
J('d1','parts','领取旁线保护座与手动锁闭销。','你核对规格，在领用簿写下用途。值班医护过来问伤员什么时候能走，你把查到的情况如实告诉她，没有先许诺时间。',all=['late_d1_inspect'],floor='junction',give=['late_track_parts'])
J('d1','repair','断开道岔电机，清理岔槽后更换保护座。','岔尖贴合，试车没有异响。你锁好旁线，将试验结果交给司机复核。两班车可以分流，燃料车晚一段进站，伤员不必再留在风口。',all=['late_d1_parts'],floor='junction',take=['late_track_parts'],flags={'late_d1_bypass':True})
J('d1','civilian','先让伤员车通过，在现场登记燃料车延误。','医护先把最怕冷的伤员扶进车厢。你将燃料车预计延误写在交接单上，请司机复述下一班安排。',all=['late_d1_inspect'],floor='junction',flags={'late_d1_dispatched':True,'late_d1_medical_first':True})
J('d1','both','确认旁线锁定，安排伤员与燃料车分流。','两位司机分别复述了进路。伤员车先通过，燃料车沿旁线等候；你直到尾灯越过道岔，才向控制间交回手动锁闭钥匙。',all=['late_d1_bypass'],floor='junction',flags={'late_d1_dispatched':True})
report('d1',['late_d1_dispatched'],'科瓦廖夫逐项看完延误和分流记录。\n「我会把实际到站时间写进去。伤员交医务间，供暖班的延误也要有人处理。下一个问题在我们自己的管线上：报告说恢复供水的地方，仍有人接不到水。」',travel='late_d1_home')
Q('d1','谁先通过','解决单线运输冲突，让伤员抵站，记录燃料调度的真实代价。',[
 stage('d6_surface_gate','labor','准备好防护和武器，从 D-6 正门登记出站，前往货场换乘口。'),stage('junction_switch','junction','先检查南侧道岔，确认旁线能否恢复。','late_d1_depart'),stage('junction_tools','junction','可领取备件修通旁线，或者在调度处安排伤员优先。','late_d1_inspect'),stage('junction_switch','junction','更换保护座，清理轨槽并测试锁闭。','late_d1_parts'),stage('junction_manifest','junction','向司机明确分流或伤员优先安排。','late_d1_bypass'),stage('junction_exit','junction','从南口返站，交接伤员与延误记录。','late_d1_dispatched'),stage('d6_return_desk','labor','向中尉交接实际运输记录。','late_d1_home_arrived')])
job('d2','d6','没有送到的水',['late_d1_done'],'labor','科瓦廖夫：「供水表已经填了恢复，可生活层还在排队。你去下层净水阀组测压力，再找妮娜核对支路。谁填错的先放一边，先让人有水用。」')
J('d2','meter','读取净水间出口压力与住区支路流量。','总管压力正常，生活层支路的流量却接近零。报告中的数字是总管读数，不能说明每个住区已经恢复。你记下时间，再去找妮娜核对支路。',floor='labor')
J('d2','nina','「总管有压力，住区支路却没有流量。能一起查查吗？」','妮娜：「临时旁通还没拆，上层那段冻裂管子已经隔离，当然送不过去。先把公共取水点接上，再安排换管。接头我留着了，你去下层备用柜拿，不用另买。」',all=['late_d2_meter'],floor='life',give=['late_water_joint'])
J('d2','repair','关闭临时旁通，连接公共取水支路并检查漏水。','水先裹着气泡流出，随后稳定下来。你让值班员接满一只水桶，再量一次流量，确认这次读数来自住户实际能用的出水口。',all=['late_d2_nina'],floor='labor',take=['late_water_joint'],flags={'late_d2_supply':True})
J('d2','truth','「总管恢复了，住区尚未全通。我按实际情况重写报告。」','科瓦廖夫：「把两个数字都留着，别再混成一个。对外报表我来签，维修和临时取水也要写进去。」\n他停了一会儿，又说：「上面会问为什么前一份填得太早，我也得回答。」',all=['late_d2_supply'],floor='labor',flags={'late_d2_reported':True,'late_d2_truthful':True})
report('d2',['late_d2_reported'],'中尉收起修正后的报告，给测量班留出下一班外勤名额。\n「地表那段旧沉降带近来不稳，带着仪器去核对。你已经知道一个总数能漏掉什么，这回把地点和时间都记清楚。」',travel='late_d2_home')
Q('d2','没有送到的水','区分总管读数与住户供水，落实公共取水，再修正报告。',[
 stage('late_d6_meter','labor','到净水阀组读取出口压力与支路流量。'),stage('nina','life','上生活层，和妮娜核对冻裂管段与临时旁通。','late_d2_meter'),stage('late_d6_meter','labor','返回净水阀组接通公共取水支路，并现场复测。','late_d2_nina'),stage('d6_return_desk','labor','向中尉说明真实供水情况，再正式交回修正报告。','late_d2_supply')])
job('d3','d6','读数的出处',['late_d2_done'],'east_district','科瓦廖夫：「测量仪已经校准。先在工人街背风处记一组，再去北侧废弃中继站核对另一组。灰狗活动区可以绕开，带回有时间和地点的原始读数。星城愿意接收技术询问，进不进得去由他们核验。」')
J('d3','street','在工人街诊所外记录背风点读数。','你将仪器放稳，记下风向、时间与地表状态。背风处数值相对平缓，不能据此代替旧沉降带。原始纸带收进保护袋，下一处测量需要单独记时间。',floor='east_district',give=['late_readings'])
J('d3','relay','在废弃中继站外侧核对暴露区读数。','同一台仪器在裸露尘土上得到更高的读数。你检查计时与校准标记，重新测了一次；结果相近，但仍需专业人员结合风向判断。',all=['late_d3_street'],floor='relay')
report('d3',['late_d3_relay'],'科瓦廖夫：「我签技术联络委派，星城只会按他们自己的流程接待。把两处原始记录都交给他们，别只报一个最吓人的数字。若他们确认风险，民用线路也必须收到通知。」',travel='late_d3_home')
Q('d3','读数的出处','取得有来源的独立测量，获得赴星城外围技术联络的资格。',[
 stage('d6_surface_gate','labor','携仪器从 D-6 正门出站，先去工人街诊所外侧。'),stage('late_street_probe','east_district','在诊所外的背风测点记录第一组读数。','late_d3_depart'),stage('east_north_entry','east_district','沿北线接送路到星城外围，再从外侧检修口进入中继站。','late_d3_street'),stage('relay_probe','relay','在中继站暴露区核对第二组读数。','late_d3_entered'),stage('d6_return_desk','labor','沿来路返站，交回两组读数与原始纸带。','late_d3_relay')])
# Shared travel and physical map interactions.
for id,j in d['jobs'].items():
 if id not in ['c2','s2']:
  J(id,'depart','登记出发，前往本次任务地点。',floor=j['home'],once=False,travel='late_'+id+'_road')
 report_key='late_'+id+'_report'
 d['actions'][report_key]['req']['not'].append('late_'+id+'_awaiting_return')
 art='junction_transfer' if j['floor']=='junction' else ('east_district_arrival' if j['floor'] in ['east_district','grey_shelter'] else 'commune_threshold')
 P('late_'+id+'_road',j['name']+' / 出发',art,[('旁白','你核对防护和返程入口，将这趟任务的记录单放进内袋。聚落值守记下你的去向，提醒你回程先到原来的接送处报到。')],end='map:east_district' if j['floor'] not in ['commune','labor'] else 'map:'+j['home'])
 P('late_'+id+'_home',j['name']+' / 交接以后','d6_ward' if j['faction']=='d6' else ('medical_home32' if j['faction']=='commune' else 'sech_threshold'),[('旁白',{'commune':'登记不再只剩一个完成标记。回来的居民有了位置，仍没有回信的人继续留在查找簿上。你把记录收好，回到有人叫你名字的走廊。','sech':'站台值守把这一班的车和人分别登记。厨房还留着热水，下一班的安排写在门边。你可以先歇一会儿，再去见他们。','d6':'记录交回以后，实际到站和仍未恢复的部分分栏留下。有人先去医务间，也有人继续等维修。中尉没有宣布一切已经解决。'}[j['faction']])],end='resume:'+j['person'])
A('late_junction_enter','沿货场检修阶梯进入换乘线。',once=False,floor='east_district',travel='late_junction_arrive')
P('late_junction_arrive','北线货场 / 换乘口','junction_transfer',[('旁白','货场的检修阶梯通到地下。站台两侧分开停着货车和维修车，候车的人躲在有挡风墙的地方。南口是回程接送点，西侧廊道通往检修间，中央轨道上能听见兽爪擦过枕木。')],end='map:junction')
A('late_junction_return','从南口按本班安排返站。',once=False,floor='junction',travel='late_junction_home_commune')
A('late_junction_bypass','清理西侧维修廊的落物，固定通往南口的检修门。','你将落物移到墙边，固定门扇，确认廊道能够通人。中央轨道上的兽群仍在那里，走这条路可以避开它们。',floor='junction')
I('junction_yuri','junction','尤里 / 失联运输员','男人坐在工具箱边，腿上缠着旧布。听到脚步，他先问来的是哪一班。',['late_c2_find','late_c2_consent'],'运输员',True)
I('junction_car','junction','检修车与拖车','车辆分别停在各自轨道上，轮挡、软管和联接处都可以检查。',['late_s1_inspect','late_s1_brake','late_s3_repair'],'运输设备')
I('junction_tools','junction','西南检修柜','零件按规格分开放置，不能靠外形相似就随意更换。',['late_s1_spare','late_s3_coupling','late_d1_parts'])
I('junction_switch','junction','南口道岔 / 旁线锁闭','这里的道岔将一股轨道分向两条线路。岔尖必须贴合，锁闭以后才能让车通过。',['late_s1_switch','late_d1_inspect','late_d1_repair'])
I('junction_manifest','junction','候车处 / 司机交接','名单、担架尺寸与载重表摆在司机面前。先核对实际情况，再决定这一班怎么走。',['late_s3_manifest','late_s3_people','late_s3_both','late_d1_civilian','late_d1_both'])
I('junction_family','junction','候车住户','住户已经收好行李，等司机确认上车。',[],'候车住户',True)
I('junction_exit','junction','南口接送处','离开前确认同行者已经到齐。未完成的工作可以退回准备，下次再来。',['late_junction_return'])
I('junction_bypass','junction','西侧维修廊','检修门被旧构件卡住，清理后能通到南口。',['late_junction_bypass'])
I('late_captive','grey_shelter','阿尔乔姆 / 被扣运输员','男人听到有人靠近，先看门口的守卫，再压低声音问你从哪里来。',['late_s2_release'],'运输员',True)
I('late_street_probe','east_district','诊所外 / 背风测点','这处低矮墙角能遮住部分吹来的尘土。读数需要记明位置和时间。',['late_d3_street'])
I('late_d6_meter','labor','净水阀组 / 住区支路','压力表与支路流量表并排，出口通向生活层公共取水管。',['late_d2_meter','late_d2_repair'])
# Star City admission: work is verified independently; family evidence never opens the gate.
A('late_star_request','「我来核对线路异常，想申请外线检修交接。」','值守：「这里只接收技术交接，人员询问另行核查。先修外侧中继：断开馈线、检查连接，再用我们的校验序列回传。我们会用另一套接收机复核。做完回来仍需去污与登记，不能直接过门。」',all=['north_story_ready'],floor='starcity',flags={'late_relay_assigned':True,'late_story_enabled':True},give=['late_calibrator'],travel='late_star_brief')
A('late_relay_depart','沿外侧检修路进入地表中继站。',once=False,floor='starcity',travel='late_relay_arrive')
A('late_relay_return','沿检修路返回星城外围。',once=False,floor='relay',travel='late_relay_back')
A('late_relay_isolate','断开馈线电源，确认无电后检查接头。','你先断开电源，测量端子电压。损坏接头在低压段，备用件已经随校验仪配给，不需要冒险拆开高压柜。',all=['late_relay_assigned'],floor='relay')
A('late_relay_cable','替换受潮接头，检查接地与馈线连续性。','端子重新锁紧，馈线连续性恢复。你合上防水护套，将检修时间写在柜门内侧。',all=['late_relay_isolate'],floor='relay')
A('late_relay_calibrate','接入校验仪，按值守序列完成收发测试。','耳机里依次返回三组校验音。星城值守用独立接收机核对编号，确认外线恢复。你保留仪器原始记录，不把一次成功测试当成整条网络都已可靠。',all=['late_relay_cable'],floor='relay',flags={'late_relay_verified':True})
A('late_relay_wind','记录暴露区的风向、时间与沉降读数。','风卷起废墟里的细尘，读数随阵风变化。你标出采样高度和时间，保存两次测量。仪器只说明这个点的情况，需要与背风点和旧记录一起比较。',all=['late_relay_assigned'],floor='relay',flags={'late_exposed_reading':True},give=['late_readings'])
A('late_star_decontam','接受外衣去污，登记携带装备并办理临时工作证。','值守先核验外线测试回执，再检查防护。武器交保管柜，逐件登记；离开工作区时按清单原样领回。临时证只允许进入接待和外线维修区，家庭身份不会代替门禁手续。',all=['late_relay_verified'],floor='starcity',flags={'late_star_admitted':True},travel='late_star_admit')
A('late_star_enter','出示临时工作证，进入接待工作区。',all=['late_star_admitted'],floor='starcity',once=False,travel='late_star_admit')
A('late_star_exit','交回当班临时证，领回保管武器并返回外围。',floor='star_interior',once=False,travel='late_star_leave')
A('late_identity','核对姓名、母亲信息和谢苗诺夫的联系记录。','萨文逐项复述母亲的姓名与 D-6 登记年份，又请你讲谢苗诺夫的工作和住处。旧人员簿中有能相互印证的记录。\n「我可以安排你们在交接间见面。技术权限仍按工作安排办理，别把两件事混在一起。」',all=['late_star_admitted'],floor='star_interior',flags={'late_identity_checked':True})
A('late_father_meet','「我是伊万。母亲带我进了 D-6，老爹把我带大。」',all=['late_identity_checked'],floor='star_interior',travel='late_father_first')
A('late_father_photo','把母亲的照片放在桌上，给父亲看背面的字。','父亲用指尖停在照片边缘，没有拿走。\n「那天她怕你哭，拍完就抱着你出去透气了。背面这几行字，是后来写的。」\n他将照片推回你面前。「你留着。我想听你说她，但不用今天就说完。」',all=['late_father_first_seen'],floor='star_interior',flags={'late_photo_seen':True})
A('late_work_brief','「先把这班工作做好。需要我做什么？」','父亲：「先隔离校准台低压电源，再按端子号检查参考回路。你不会的地方叫我，我们一起确认。不能为了赶进度，把不确定的读数填成正常。」',all=['late_father_first_seen'],floor='star_interior',flags={'late_work_assigned':True},give=['late_calibrator'])
A('late_lab_isolate','按端子号隔离校准台低压电源。','你将端子号抄在纸上，确认仪表归零。父亲扶住松动的接头，让你有地方下手。',all=['late_work_assigned'],floor='star_interior')
A('late_lab_reference','接入参考回路，交叉核对两组读数。','校准结果稳定。父亲看着你手边的编号纸，说他认得谢苗诺夫这个习惯。你告诉他，老爹教你的远比这一件多。',all=['late_lab_isolate'],floor='star_interior',flags={'late_lab_ready':True},travel='late_father_work')
A('late_archive','查阅经过准许调阅的私人通信延后记录。','记录没有把全部责任推给一道口令。几封家信被列为延后转交，旁边有父亲的设备操作签认。后来路线恢复过，他仍未追查每一封是否送达。你可以当面问他，技术工作照常进行，不需要先原谅任何人。',all=['late_lab_ready'],floor='star_interior',flags={'late_archive_read':True})
A('late_father_truth','「我看过签认记录了。后来有机会的时候，你为什么没有再找我们？」',all=['late_archive_read'],floor='star_interior',travel='late_father_truth_scene')
A('late_notify_semyon','给谢苗诺夫留一封亲笔平安信，请可信的联络员转交。','你先写自己平安，再写已经见到父亲，没有替两个人解释关系。联络员核对了老爹的姓名与住处，使用旧有私人投递线，不把你的消息当作 D-6 通行凭证。',all=['late_father_first_seen'],floor='star_interior',flags={'late_semyon_notified':True})
A('late_weather_review','与列夫核对风向、独立测点和旧沉降记录。','列夫：「背风点与裸露尘土不是同一种环境，不能平均掉。外海那组英语报码也只有气象资料，有时延，我们拿来复核，不当作命令。现在能确认的是：风转后，东郊装卸路与几处通风口会更危险。我们要把来源、时间和还不知道的部分一起报出去。」',all=['late_lab_ready','late_exposed_reading','late_sheltered_reading'],floor='star_interior',flags={'late_risk_confirmed':True})
A('late_network_plan','「需要哪些人接收？我们有哪些真正能执行的办法？」',all=['late_risk_confirmed','late_father_truth_seen'],floor='star_interior',travel='late_four_plans')
# A free mainline measurement point remains available to every faction.
A('late_sheltered_probe','用已校准的仪器测诊所背风处，保存时间与来源。','你使用同一台仪器记下这处背风环境。与暴露区分别保存，不把不同地点合成一个失去出处的数。',all=['late_relay_assigned'],floor='east_district',flags={'late_sheltered_reading':True},give=['late_readings'])
I('relay_power','relay','中继站 / 馈线隔离柜','柜内标明低压检修边界，备用接头与校验仪型号相配。',['late_relay_isolate','late_relay_cable'])
I('relay_mast','relay','中继天线 / 收发校验台','馈线通向天线，独立接收编号由星城值守复核。',['late_relay_calibrate'])
I('relay_probe','relay','裸露沉降区 / 测量点','风吹起细尘，测量需要记录高度、风向与时间。',['late_relay_wind','late_d3_relay'])
I('relay_exit','relay','返回外围的检修路','沿原来的检修路返回星城外围，未完成的工作会保留。',['late_relay_return'])
I('late_star_guard','star_interior','萨文 / 接待值守','值守先核对临时证，再问你要办理技术交接还是家庭询问。两份登记分开放着。',['late_identity','late_star_exit'],'星城接待',True)
I('late_father','star_interior','父亲 / 测控技术员','老人把手上的接头放回盒里，等你走到桌边。他没有催你坐下。',['late_father_meet','late_father_photo','late_work_brief','late_father_truth','late_notify_semyon'],'测控技术员',True)
I('late_lab','star_interior','标定间 / 参考回路','端子、隔离开关和参考信号各自编号，操作次序写在工作卡上。',['late_lab_isolate','late_lab_reference'])
I('late_archive','star_interior','交接档案 / 私人通信记录','准许调阅的纸页保留原日期和签认，缺页明确标出，不能凭空补写。',['late_archive'])
I('late_lev','star_interior','列夫 / 通信与观测','列夫先对过纸带时间，才抬头和你说话。',['late_weather_review','late_network_plan'],'观测通信',True)
I('late_star_exit','star_interior','接待气闸 / 武器交还','离开前按入站清单领回武器。返回外围不解除原有身份限制。',['late_star_exit'])
# Four finals. Each has three spatially separate actions and a visible readiness list.
plans={
'shared':('共享预警','把有来源的警告送到多个独立接收点，公开风险区域，保护人员名单。',['late_shared_packet','late_shared_receiver','late_shared_evac']),
'central':('中央调度','接通中央运力，同时落实明确的民用警报与撤离席位。',['late_central_agreement','late_central_train','late_central_alarm']),
'distributed':('分散保全','先发紧急预警，将可搬设备和记录分交给会维护的人。',['late_distributed_copy','late_distributed_modules','late_distributed_handover']),
'watch':('留守观测','修复持续供电，安排外部接收人与交班，留下完成下一轮播发。',['late_watch_power','late_watch_shift','late_watch_broadcast'])}
for mode,(name,desc,steps) in plans.items():
 A('late_plan_'+mode,'选择方案：'+name,desc+'\n这一步只选择准备方向。确认最终行动前，你仍可自由探索、做支线或改换方案。',all=['late_four_plans_seen'],not_=['late_final_started'],floor='star_interior',flags={'late_final_mode':mode},once=False)
A('late_final_confirm','准备好了，确认开始最终行动。',all=['late_four_plans_seen'],not_=['late_final_started'],floor='star_interior',flags={'late_final_started':True},travel='late_final_depart')
A('late_plan_review','核对当前方案与实际完成的准备。',all=['late_four_plans_seen'],floor='star_interior',once=False)
A('late_shared_packet','标明来源、时间和误差，封存人员名单后制作预警副本。','列夫核对每份副本的原始编号。危险区域可以公开，名单只交给负责接应的人。消息包括仍未知的部分，不把预测写成必然结果。',all=['late_final_started'],floor='star_interior')
A('late_shared_receiver','在换乘站接通独立接收机，请值守复述完整预警。','值守逐项复述时间、区域和备用路线，并签下回执。公开的是危险与改道办法，接应人员没有在广播里报姓名。',all=['late_shared_packet'],floor='junction',give=['late_acknowledgements'])
A('late_shared_evac','陪改道的住户走到中继站南侧接应点。','你确认接应的人已到，才请住户动身。没有人被要求跑过交火区，队伍沿西侧挡风墙移动。',all=['late_shared_receiver'],floor='relay',flags={'late_final_escort':True})
A('late_central_agreement','把民用警报、撤离席位与发布时刻写进中央接收单。','中尉通过星城联络线复述安排：军运不得占用已经确认的民用席位，地方警报按本地读数独立发布。你将这两项留在双方都持有的副本上。临时防灾联络不会取消逃亡者原来的通缉记录。',all=['late_final_started'],floor='star_interior',give=['late_civilian_schedule'])
A('late_central_train','在换乘站核对民用席位，锁定撤离列车的先行进路。','司机逐项对过担架位置和乘员名单。你把进路锁到民用车这一侧，等到尾灯越过信号才交回控制权。中央的运力在这里实际承担了撤离，留下可核查的班次。',all=['late_central_agreement'],floor='junction')
A('late_central_alarm','在中继站打开本地独立警报，并取得民用列车回执。','地方值守没有等待另一道宣传口令，按已经核验的读数发出警报。列车回执到达时，你记录下实际发布时间；承诺与执行第一次能放在同一页核对。',all=['late_central_train'],floor='relay',flags={'late_final_execution_done':True},give=['late_acknowledgements'])
A('late_distributed_copy','先发本轮紧急预警，再制作校准记录与维修说明的副本。','紧急预警先发出去，设备转移不耽误这一轮通知。列夫将标定方法、备件规格与故障记录一起抄出，避免只搬走会亮的机箱。',all=['late_final_started'],floor='star_interior',give=['late_network_manual'])
A('late_distributed_modules','隔离中继站备用回路，拆下两只可搬接收模块。','你按编号隔离备用回路，主测量仍在运行。两只模块装进防潮箱，拆除后覆盖会暂时缩小，这一项也写在预警副本上。',all=['late_distributed_copy'],floor='relay',give=['late_receiver_modules'])
A('late_distributed_handover','在换乘站交接模块，请接收人员完成一次独立校验。','一只模块留给运输值守，另一只随受训人员转往独立接收点。你直到两边都能复述测试序列，才签下交接；维修说明与校准记录各留一套。',all=['late_distributed_modules'],floor='junction',take=['late_receiver_modules'],flags={'late_final_execution_done':True},give=['late_acknowledgements'])
A('late_watch_power','在中继站检修备用供电，测试失电切换。','你清理接线端，检查燃料与蓄电池，再请值守切断主电源测试。备用回路接上，仪表没有重启。观测仍需要轮班的人，不能只靠一台备用机。',all=['late_final_started'],floor='relay')
A('late_watch_shift','在换乘站安排外部接收人与撤离交班。','值守留下按时接收与复核的班次，把不适合继续留在外线的人送上车。你说明自己将返回观测岗位，安排有谁接下一轮消息。',all=['late_watch_power'],floor='junction')
A('late_watch_broadcast','回测控台完成下一轮测量，与外部值守交叉核对后播发。','父亲先报出自己的读数，你独立核对时间与标定。外部接收人复述了警告，工作不再只由封闭设施单方面宣布。你自愿留下这一班，今后的生活也需要自己安排。',all=['late_watch_shift'],floor='star_interior',flags={'late_final_execution_done':True},give=['late_acknowledgements'])
A('late_finish','回测控通信台，核对回执并结束本轮行动。',all=['late_final_execution_done'],floor='star_interior',travel='late_final_result')
I('late_planning','star_interior','联络会议 / 最终行动','先核对事实，再决定怎样组织预警与撤离。准备阶段没有后台倒计时，确认前可以继续其它工作。',[*['late_plan_'+x for x in plans],'late_plan_review','late_final_confirm','late_shared_packet','late_central_agreement','late_distributed_copy','late_finish'])
I('late_watchdesk','star_interior','测控台 / 轮值记录','读数、时间、标定与外部回执需要彼此对应。',['late_watch_broadcast'])
I('junction_final_receiver','junction','换乘站 / 独立接收与调度','接收人、司机与维护人员都在现场，交接要由他们实际确认。',['late_shared_receiver','late_central_train','late_distributed_handover','late_watch_shift'])
I('relay_generator','relay','中继站 / 备用供电与模块','备用电源与便携接收回路分别编号，操作前先确认主测量不断电。',['late_central_alarm','late_distributed_modules','late_watch_power','late_shared_evac'])
# Permanent travel after admission.
A('late_final_to_junction','从外围检修路前往换乘站。',all=['late_star_admitted'],floor=['starcity','relay'],once=False,travel='late_junction_arrive')
A('late_junction_to_star','沿已确认的外线检修路返回星城外围。',all=['late_star_admitted'],floor='junction',once=False,travel='late_relay_back')
d['interactions']['junction_exit']['options'].append('late_junction_to_star');d['interactions']['relay_exit']['options'].append('late_final_to_junction')
# Endgame quests have precise, stage-specific targets.
d['quests'].append(dict(id='late_star_access',name='门内的工作',kind='主线',facility='starcity',accepted='late_relay_assigned',done='late_star_admitted',background='介绍信只能说明来意。先让星城独立核验外线维修，再办理有限准入。',lead='',actions=['late_star_request'],stages=[stage('late_perimeter_relay','starcity','从外围检修口进入中继站，先断电检查馈线。'),stage('relay_power','relay','替换接头并检查接地与连续性。','late_relay_isolate'),stage('relay_mast','relay','在天线校验台用配给仪器完成收发测试。','late_relay_cable'),stage('star_perimeter_call','starcity','返回外围，去污并登记装备；值守独立核验后办理临时证。','late_relay_verified')]))
d['quests'].append(dict(id='late_family',name='交接间',kind='主线',facility='star_interior',accepted='late_star_admitted',done='late_father_truth_seen',background='先核实家庭身份，再与父亲见面。重逢不要求立即原谅，也不替代公共责任。',lead='',actions=['late_identity'],stages=[stage('late_star_guard','star_interior','在接待处核对家庭登记。'),stage('late_father','star_interior','到交接间与父亲见面，可展示照片，也可以暂时不谈。','late_identity_checked'),stage('late_father','star_interior','见面后领取这一班的标定工作。','late_father_first_seen'),stage('late_lab','star_interior','隔离低压电源，核对参考回路。','late_work_assigned'),stage('late_archive','star_interior','工作完成后，查阅获准调阅的私人通信记录。','late_lab_ready'),stage('late_father','star_interior','带着看过的具体记录，再与父亲交谈。','late_archive_read')]))
d['quests'].append(dict(id='late_warning',name='风变之前',kind='主线',facility='star_interior',accepted='late_work_assigned',done='late_campaign_complete',background='取得独立读数，核实预警，在四种实际方案中作出选择并执行。准备期间可继续探索与支线。',lead='',actions=['late_weather_review'],stages=[stage('late_street_probe','east_district','记录诊所背风点；中继站裸露区也要取得一组有时间的读数。'),stage('relay_probe','relay','在中继站记录暴露区风向、时间与沉降读数。','late_sheltered_reading'),stage('late_lev','star_interior','将两处读数交列夫复核，再讨论可执行的方案。','late_exposed_reading'),stage('late_planning','star_interior','核对四种方案，完成准备后再确认最终行动。','late_four_plans_seen')]))
# The deliberate personal scenes: choices shape the relationship, not the public ending lock.
P('late_star_brief','隔离线外的答复','starcity',[('值守','外线检修申请可以接收。你带来的原始数据会另存，家人的事也会另查。先去检修，回来我们再核对。'),('旁白','你在临时登记单上写下姓名。厚门仍然关着，右侧检修路的指示灯却亮了。')],end='resume:star_perimeter_call')
P('late_relay_arrive','北线中继站','north_relay',[('旁白','积雪掩住了旧道路的大部分颜色，裂开的沥青还露在车辙里。天线的拉索越过倒塌的墙，落在还能使用的混凝土基座上。西侧控制屋里有一盏灯，馈线沿有盖的沟槽通向北边。'),('旁白','检修牌标出了返程：沿西南侧检修路回到星城外围。这里没有聚落，补给要自己带好；主线所需的校验仪与接头已经配给。')],end='map:relay',music='dawn_theme')
P('late_relay_back','沿检修路回来','north_relay',[('旁白','你将仪器装回防潮袋，沿已经记过的检修路返回。外线修复与测量各有自己的记录，完成了哪一项，就交哪一项，没有结果的部分仍空着。')],end='map:starcity')
P('late_star_admit','门内的第一班','star_reunion',[('旁白','去污间的门先在身后关上。值守逐件登记武器，让你看过保管清单，才打开通往接待区的内门。'),('萨文','临时工作区、测控交接间和标定室可以去。其它门仍受控。有家庭询问先找我登记，别自己去敲宿舍。')],end='map:star_interior')
P('late_star_leave','领回自己的东西','star_reunion',[('旁白','值守按清单归还武器，临时证记下离站时间。你的技术交接没有被撤销；再回来仍需检查，但不用重新证明已经做过的工作。')],end='map:starcity')
P('late_father_first','桌子两边','star_reunion',[('旁白','父亲将螺丝刀放平，像是担心一抬手会碰落什么。他看了一会儿你的脸，问起母亲。'),('父亲','她后来一直住在 D-6 吗？'),('伊万','她带我进去以后，就没再出来。后来她病死了。照顾我的一直是谢苗诺夫。'),('父亲','我写过信。最早的两封没有送出去，后来我也没有再查到底。我知道，这不能算尽过力。')],choices=[dict(text='「我想问的很多。今天先把工作办完。」',next='late_father_first_end',flag='late_family_time'),dict(text='「我现在不想听解释。工作上的事照常说。」',next='late_father_first_end',flag='late_family_distance')],music='home_lamp')
P('late_father_first_end','留出一点时间','star_reunion',[('旁白','父亲点头，把另一把椅子留在桌边，没有再让你坐下。你们约好这班交接以后可以再谈；没有一句话能把缺席的二十年补齐。')],end='resume:late_father',finish_flags=['late_father_first_seen'],music='home_lamp')
P('late_father_work','编号纸','star_reunion',[('父亲','你先写端子号，是谁教的？'),('伊万','老爹。他说修到一半停电，靠记性容易接错。'),('父亲','他以前也常提醒我。'),('伊万','我记得的是后来。他教了我很多年。'),('旁白','父亲没有再接话，转身把你们都核对过的读数签进工作卡。')],end='resume:late_lab',music='shift_below')
P('late_father_truth_scene','签认的名字','star_reunion',[('父亲','最初我担心线路被追踪，入口会暴露。我按命令延后私人通信，也签过操作确认。'),('父亲','后来我有机会再找，却害怕知道你们已经不在了。我留在这里做事，慢慢把没有消息当成了不用再问。你说我逃避，是对的。'),('伊万','母亲没有等到解释。老爹也没因为没有消息，就不再照顾我。')],choices=[dict(text='「我愿意以后再谈，但你欠我们的不会因此消失。」',next='late_father_truth_end',flag='late_family_open'),dict(text='「我会和你共事。家里的事，先到这里。」',next='late_father_truth_end',flag='late_family_closed'),dict(text='「现在我还决定不了。先把能救人的消息发出去。」',next='late_father_truth_end',flag='late_family_later')],music='home_lamp')
P('late_father_truth_end','这一班还要继续','star_reunion',[('父亲','我会把你问过的记录留下，也会回答。你不用替我把话说得好听。'),('旁白','你收好自己的东西，留下了下一次工作的时间。无论以后怎样相处，这一班该做的事仍然在桌上。')],end='resume:late_father',finish_flags=['late_father_truth_seen'],music='home_lamp')
P('late_four_plans','消息要送到哪里','star_reunion',[('列夫','共享预警，需要几个能独立复核的接收人。中央调度能调用较多车辆，但民用警报和席位必须落实。分散设备可以减少一处失守的风险，覆盖却会暂时下降。留下观测也需要外面有人接，不是关起门来守一台机器。'),('列夫','我们有可完成的基础方案，必要设备都能配给。你可以先看准备清单，继续做未完的事；只有你确认最终行动，才开始这一轮调度。')],end='resume:late_planning',finish_flags=['late_four_plans_seen'])
P('late_final_depart','最后一轮调度之前','north_relay',[('旁白','你将实际采用的方案留给每个负责接应的人。最终行动前的存档已经单独保存，手动档位没有被覆盖。这一轮工作需要按计划完成，支线与闲逛没有消耗过一个隐藏的倒计时。')],end='resume:late_planning')
P('late_final_result','回执到达','star_reunion',[('旁白','第一批回执到达时，房间里没有欢呼。列夫先核对来源与时间，再把已经收到和仍未确认的站点分开。你们用实际完成的工作，替一部分人争取了改道和撤离的机会。')],next='late_epilogue_people',music='c1_return_theme')
P('late_epilogue_people','后来的人','medical_home32',[('旁白','战争没有因为一轮预警结束。人们仍要修管道、照顾病人、准备下一班的饭。有人记得广播，有人只记得那天有人敲门，告诉他们换一条路走。')],next='late_epilogue_family',music='c1_return_theme')
P('late_epilogue_family','写给老爹','star_reunion',[('旁白','你在给谢苗诺夫的信里写了这一趟经过。开头仍旧是报平安，后面才是你决定怎样生活。把你养大的人，会先想知道你有没有好好吃饭。')],end='complete:campaign',music='home_lamp')
for mode,(name,desc,steps) in plans.items():d['endings']['warning_'+mode]=dict(title=name,body=desc,art={'shared':'warning_shared','central':'junction_transfer','distributed':'warning_distributed','watch':'warning_watch'}[mode],steps=steps)
# The first two post-start preparation actions remain in the interior; other actions require the chosen mode.
for mode,(_,_,steps) in plans.items():
 for key in steps:d['actions'][key]['mode']=mode
# Metadata and physical target extension, separate from static pre-existing object lists.
d['extensions']={
 'commune_guard':['field_c2_accept','late_c2_report','field_c3_accept','late_c3_report'],
 'commune_baranova':['late_c2_family','late_c2_letters'],
 'commune_leave':['late_c2_depart','late_c3_depart'],
 'commune_radiator':['late_c3_cold'], 'commune_boiler':['late_c3_diagram','late_c3_isolate','late_c3_repair'], 'commune_salvage':['late_c3_parts'], 'commune_hall':['late_c3_meeting'],
 'sech_elder':['field_s1_accept','late_s1_report','field_s2_accept','late_s2_report','field_s3_accept','late_s3_report'],
 'sech_sergey':['late_s2_brief','late_s2_account'], 'sech_leave':['late_s1_depart','late_s2_depart','late_s3_depart'],
 'd6_return_desk':['late_d1_accept','late_d1_report','late_d2_accept','late_d2_truth','late_d2_report','late_d3_accept','late_d3_report'],
 'd6_surface_gate':['late_d1_depart','late_d3_depart'], 'nina':['late_d2_nina'],
 'star_perimeter_call':['late_star_request','late_star_decontam','late_star_enter'],
 'late_street_probe':['late_sheltered_probe']}
# Physical northern contact can be learned late; it never assumes the opening radio was heard.
A('late_north_contact','「接下来的外勤，需要我先去哪里了解情况？」','联络值守打开收音机，让你听了一遍收到的呼叫。东方-7 只说需要核验外线，不能据此知道里面的名册。你的阵营负责人留下技术经历与回信方式；这份说明不授予星城准入。',all=[],floor=['commune','sech','labor'],flags={'north_story_ready':True,'north_inquiry_ready':True,'star_known':True,'signal_identified':True,'late_north_contacted':True},give=['late_faction_letter'],travel='late_north_signal')
A('late_star_return_home','沿原路回到地表城区，再返回所属聚落。',floor='starcity',once=False,travel='east_return_starcity')
I('late_perimeter_relay','starcity','外侧检修路','路标指向旧中继站；只通往外部设施，不绕过隔离门。',['late_relay_depart','late_final_to_junction'])
for npc in ['commune_guard','sech_elder','d6_return_desk']:d['extensions'][npc].append('late_north_contact')
d['extensions']['star_perimeter_call'].append('late_star_return_home')
P('late_north_signal','听到呼号以后','frontline_station',[('东方-7 值守','外线校验窗口已经开放。到外围声讯柱提交检修申请，未经核验不得越过隔离线。'),('旁白','值守在地图上指出北线接送路尽头的外围设施。你第一次得到可以自己核对的去向，仍不知道父亲是否在那里。')],end='resume:late_route_dispatch')
d['quests'].append(dict(id='late_perimeter',name='呼号之后的路',kind='主线',facility='starcity',accepted='late_north_contacted',done='late_relay_assigned',background='阵营负责人说明了东方-7 的呼叫和外围位置。介绍信说明来意，准入仍由星城决定。',lead='',actions=['late_north_contact'],stages=[stage('east_north_entry','east_district','从所属聚落出站，沿北线接送路到星城外围；在外侧声讯柱申请外线交接。')]))
I('late_route_dispatch','commune','联络值守','这次呼叫与外围位置已经记入手记。',[])
# Every interactive point is a named, reachable object; early withdrawal does not move missing people.
I('late_junction_entry','east_district','货场检修阶梯 / 换乘线','一座带扶手的检修阶梯通到地下，门边的灯还亮着。',['late_junction_enter'])
for id in ['c2','s1','s3','d1']:
 for home in ['commune','sech','labor']:
  P('late_junction_home_'+home,'南口接送以后','junction_transfer',[('旁白','你按原来的安排返回聚落，将已经到达的同行者交给接应值守。还没有完成的部分留在这一班的记录里，需要的时候仍可返回现场。')],end='map:'+home)
d['actions']['late_s1_report']['req']['all'].append('late_s1_driver_arrived')
d['actions']['late_d1_report']['req']['all'].append('late_d1_evacuated')
d['panels']['late_c2_home']['art']='letters_home'
d['panels']['late_final_depart']['lines']=[{'speaker':'旁白','text':'你把预警副本交到值守手中，让他把目的地和接收人重新念一遍。门外有人清点担架和行李，司机已经上车。你最后看了眼留在桌上的轮值表，转身去做分给自己的那一段。'}]
A('late_take_north_foot','沿北线检修路步行到星城外围。','接送车还不能使用。你核对了路标和回程位置，沿检修路步行前往外围；不经过封闭的内部线路。',all=['star_known'],floor='east_district',once=False,travel='late_north_walk')
d['extensions']['east_north_entry']=['late_take_north_foot']
P('late_north_walk','北线尽头的门','north_relay',[('旁白','你沿检修路走过几处废弃的接送站，顺着尚能辨认的线缆标记向北。最后一段路背着风，厚重的隔离门和外围等候棚出现在坡下。'),('旁白','你停在声讯柱前，先检查自己的面罩，再按下呼叫键。介绍信在内袋里，里面的人仍需要亲自核对你的来意。')],end='map:starcity',music='dawn_theme')
I('junction_patients','junction','候车医护与伤员','医护已经把需要担架的重伤员安置进车厢。留下的两位还能自行走动，需要有人陪他们走到南口。',[],'医护接送')
I('late_driver','junction','安东 / 检修车司机','司机放下工具，先报了自己的名字。\n安东：「我在这里跑了十几年。车坏了我得看着，可彼得说人比车要紧，这话我记着了。」',[],'检修车司机',True)
I('relay_evac_group','relay','改道住户 / 外线接应','住户带着自己的行李，在控制屋前等你一起去南侧接应点。',[],'改道住户')
A('late_c2_public','「先问收件人，再公开愿意署名的收信名单。地址与接应人不写。」','尤里：「可以。有人盼着知道亲人平安，也有人不愿让别人知道自己在这里。让他们各自说，别替整袋信作一个决定。我陪你去说明。」',all=['late_c2_started','late_c2_found'],not_=['late_c2_done'],floor='junction',flags={'late_c2_escort':True,'late_c2_public_consent':True})
d['actions']['late_c2_consent']['flags']['late_c2_private_records']=True
d['interactions']['junction_yuri']['options'].append('late_c2_public')
A('late_d1_fuel','先让燃料车通过，由医护照看等候的伤员并登记延误。','医护让两位伤员再加一层毯子，问司机预计还要多久。你把延误写进交接单，确认燃料卸下后能保住住区与医务间的供暖；受寒的风险不会因为这个理由就消失。',all=['late_d1_started','late_d1_inspect'],not_=['late_d1_done'],floor='junction',flags={'late_d1_dispatched':True,'late_d1_fuel_first':True})
d['interactions']['junction_manifest']['options'].append('late_d1_fuel')
A('late_d2_polish','「先按恢复写总表，把支路问题留在维修附注。」','中尉看了一眼你放在旁边的流量纸，问你是否确定。总表仍然写成恢复供水，维修附注留下了住区尚未全通的事实。两张纸以后会一起留档，不能靠把其中一张收起来，让等水的人也消失。',all=['late_d2_started','late_d2_supply'],not_=['late_d2_reported'],floor='labor',flags={'late_d2_reported':True,'late_d2_polished':True})
d['extensions']['d6_return_desk'].insert(-1,'late_d2_polish')
d['actions']['field_s3_accept']['reply']='长老：「这趟要接四名外来伤病者，还要带回过冬粮食。一辆车不能都装下。你可以先修另一辆拖车；实在修不了，就先送伤病者，粮食由值守看着，下一班再运。把安排说清楚，别让等车的人以为被丢下了。」'
P('late_c2_home','信交到谁手里','letters_home',[('旁白','巴拉诺娃把已经核对过的信封装进不同的布袋，留在桌上的还有两封。尤里坐在门边，热水已经喝掉一半。'),('巴拉诺娃','收件人找到了才交。没有找到的人，我会继续问。'),('尤里','我被扣住那天，一直怕你们以为我拿着粮食跑了。后来又想，等我回去，是不是所有人都会围着问消息。'),('伊万','你知道的说清楚。不知道的，我们再找。')],end='resume:commune_guard',music='c1_return_theme')
for id in d['jobs']:
 q=next(q for q in d['quests'] if q['id']=='late_'+id)
 q['actions']=[key for key in d['actions'] if key.startswith('late_'+id+'_') or key==d['jobs'][id]['accept']]
for key,panel in d['panels'].items():
 if key.endswith('_road'):panel['same_moment']=False
# Private rescue is a prepared internal contact, never an enemy faction's pass.
A('late_mine_cover_help','「安娜准备来接哥哥。请你确认这一班的接应和退路。」','瓦西里：「她得跟矿区的工友走搬运支线，你还是从旧检修巷进来，别一起去矿口报名字。我能替她安排带路的人，但报班铃的接头坏了，下一班会错过换岗。你把它修好，或者留下两份维修料让工友修，我们再定会合。」',all=['anna_warning_seen','east_mine_prepared','brother_found'],floor='coal',not_=['late_mine_cover_ready'])
A('late_mine_bell_inspect','检查报班铃的低压接头。','你先断开低压支路，再检查铃线。受潮接头的氧化层已经松动，清理后重新压接即可。清洁和绝缘用的材料在洗护准备桌。',all=['late_mine_cover_help'],floor='coal',not_=['late_mine_cover_ready'])
A('late_mine_bell_clean','在准备桌清理拆下的接头，补好绝缘。','你擦去氧化层，重新压紧线鼻，包好已经开裂的绝缘层。接头收进干燥的工具布里，还要带回报班铃旁接好并试响。',all=['late_mine_bell_inspect'],floor='coal',not_=['late_mine_cover_ready'])
A('late_mine_bell_fix','装回修好的接头，接通低压支路并试响报班铃。','铃声在支巷里传开，工友按约回了一声。瓦西里过来核对班次，说明安娜由谁带路、伊万从哪里进、撤离时在哪个出口会合。安排只限煤运外围，通缉记录没有撤销。',all=['late_mine_bell_clean'],floor='coal',flags={'late_mine_cover_ready':True})
A('late_mine_materials','交两份废金属维修料，请当班工友修好报班接头。','瓦西里把材料交给当班维修工，让你留在门边等试铃。试响通过以后，他逐项确认带路人、伊万的检修入口和撤离出口。这份私人安排没有变成 D-6 通行许可。',all=['late_mine_cover_help'],floor='coal',not_=['late_mine_cover_ready'],flags={'late_mine_cover_ready':True},goods={'scrap_metal':-2})
d['actions']['late_mine_materials']['req']['goods']={'scrap_metal':2}
d['extensions']['coal_clerk']=['late_mine_cover_help','late_mine_materials']
I('late_mine_bell','coal','报班铃 / 低压接线盒','报班铃挂在支巷西墙，线缆通向旁边的低压接线盒。',['late_mine_bell_inspect','late_mine_bell_fix'],'矿区报班铃')
d['extensions']['coal_wash']=['late_mine_bell_clean']
P('anna_private_depart','约好的两个入口','east_mine_service',[('旁白','瓦西里确认了这一班的带路人。安娜跟矿区工友走地下搬运支线，医护和行李同路；你独自沿已侦察的检修路接近煤运外围。你们会在休养间会合，谁也不去正门报上公社的名义。'),('安娜','我把孩子们这几天的课交给别人了。哥哥愿意走，我们就按准备好的办法接他；如果条件还不够，就先补齐。到了那里，你别只顾着催车，也问问他怕什么。')],end='map:east_district',music='letters_theme')
d['quests'].append(dict(id='late_mine_cover',name='这一班的接应',kind='支线',facility='coal',accepted='late_mine_cover_help',done='late_mine_cover_ready',background='安娜救援前确认矿区内部带路、检修入口和退路。私人接应不解除伊万的通缉。',lead='',actions=['late_mine_cover_help','late_mine_bell_inspect','late_mine_bell_clean','late_mine_bell_fix','late_mine_materials'],stages=[stage('late_mine_bell','coal','检查支巷西墙的报班铃接头；也可请瓦西里安排工友维修，需要两份废金属。'),stage('coal_wash','coal','到洗护准备桌清理拆下的接头，补好绝缘。','late_mine_bell_inspect'),stage('late_mine_bell','coal','带修好的接头回支巷西墙，装回并试响报班铃。','late_mine_bell_clean')]))
A('late_veteran_route','「你在这边看到了什么？我们该留意哪里？」','',all=['sided_veteran'],floor=['junction','relay','starcity'],once=False)
A('late_veteran_family','「我见到父亲了。现在还有些话，不知道该怎么说。」','老兵：「不用赶着把二十年的事说完。他是你父亲，老谢也还是把你养大的人。先想清楚自己要问什么，愿意说多少，自己定。要出去做事，叫我一声就行。」',all=['sided_veteran','late_father_first_seen'],floor=['junction','relay','starcity'],once=False)

P('arrive_junction','北线货场换乘线','junction_transfer',[('旁白','你从货场检修阶梯下到换乘线。中间是两股旧轨，维修廊绕到西侧，候车室和调度间在东侧。先确认这一班要接的人，再决定从哪条路带他们离开。')],end='map:junction')
P('arrive_relay','北线地表中继站','north_relay',[('旁白','风从坍塌的楼间穿过，地上的线缆一直通向北侧天线。西面的控制屋还亮着一盏灯，南侧检修路连着回程入口。你检查面罩，先在墙后停住，听了一会儿外面的动静。')],end='map:relay')
P('arrive_star_interior','星城测控设施','star_reunion',[('旁白','去污间的外门合拢后，值守才打开第二道门。电机声很轻，墙上贴着已经改过多次的轮值表。接待员指给你登记桌的位置，提醒你按许可范围活动。')],end='map:star_interior')


# Scene-specific aftermath: each return changes a person's life, not only a ledger.
P('late_c3_home','夜班的温度','commune_threshold',[
 ('旁白','巴拉诺娃从食堂搬回了自己的铺位。她先摸了摸床头的回水管，又把毯子折成两层，留在床尾。暖气还达不到战前的温度，好在这一次，贴在门边的通知写清了什么时候会停。'),
 ('巴拉诺娃','明晚我替老人们记温度。你要是再听到有人说全修好了，先叫他过来住一夜。'),
 ('伊万','温室那边也要轮换，可能还得改。'),
 ('巴拉诺娃','那就改。早点告诉我们，别等床都搬完了才说。')],end='resume:commune_guard',music='c1_return_theme')
P('late_s1_home','司机的休息班','sech_threshold',[
 ('旁白','安东交出车辆钥匙时，彼得又递给他一张写着下一班时间的纸。他看了一眼，才发现名字被往后移了两行。'),
 ('安东','我其实还能跑一趟。'),('彼得','先去吃饭，睡够了再来。今晚有人替你。'),
 ('旁白','安东把纸折好，没有再争。他走进厨房以后，彼得才问你那段软管还能撑多久。车仍要修，人也终于可以歇一班。')],end='resume:sech_elder',music='c1_return_theme')
P('late_s2_home','讲完以后','sech_threshold',[
 ('旁白','阿尔乔姆吃到一半，忽然问自己还能不能继续跑运输。谢尔盖把装着运输凭据的袋子从桌边移开，给他的碗腾出地方。'),
 ('谢尔盖','车队还需要你。先把这几天缺的觉补上，货的事明天再说。'),
 ('阿尔乔姆','我怕你们觉得，是我把东西卖了。'),
 ('谢尔盖','你已经把经过说清楚了。还有疑问，我们找在场的人问。你不用整夜坐在这里等着别人审。')],end='resume:sech_elder',music='letters_theme')
P('late_s3_home','等下一班的人','sech_threshold',[
 ('旁白','厨房先给回来的住户分了热水。有人找空床，有人核对粮袋，彼得挨个问清还有没有人落在换乘口。你把最后一张乘员单交给他，手指上还留着联接销的油。'),
 ('长老','修过的拖车要留一份检修记录。下一趟接人的时候，别再等他们站到车边才算位置。'),
 ('旁白','住户们开始争论哪张床更靠近暖气。声音有些吵，你听了一会儿，才觉得这一趟真的结束了。')],end='resume:sech_elder',music='c1_return_theme')
P('late_d1_home','抵站以后','d6_ward',[
 ('旁白','广播仍在播报前线捷报。医务间门外，两名伤员扶着墙慢慢走，值班员腾出一条通往床位的路。中尉在门口停了一会儿，先让医护把人接进去。'),
 ('科瓦廖夫','燃料车的延误我会签认。你把现场的时间写准，不用替我的报告凑齐。'),
 ('伊万','广播里没有说过有这么多伤员。'),
 ('科瓦廖夫','我知道。先把他们安置好。这些名字要留在交接单上。')],end='resume:d6_return_desk',music='letters_theme')
P('late_d2_home','第一桶水','d6_ward',[
 ('旁白','公共取水口前已经有人排队。妮娜让第一位取水的住户把桶放稳，自己蹲下去检查接头。桶满以后，她才直起身，在墙上写下下一次检查的时间。'),
 ('妮娜','还有两段住区没通，别把人都叫过来。先告诉他们这里可以接水，坏管子我们接着修。'),
 ('旁白','你听见身后有人问今晚还会不会停水。这次有了能回答的人，也有了写在墙上的具体时刻。')],end='resume:d6_return_desk',music='shift_below')
P('late_d3_home','交出去的纸带','d6_ward',[
 ('科瓦廖夫','技术委派已经签了。读数交给星城，原始记录你自己留一份。'),
 ('伊万','如果他们确认的情况，和我们广播里说的不一样呢？'),
 ('科瓦廖夫','把可以核实的部分送回来。至于怎么向上面解释，那是我签字的时候就该想的事。'),
 ('旁白','他把副本推给你，另一份收进自己的文件夹。门外又传来担架轮子的声音，你们都停下来，等医护先过去。')],end='resume:d6_return_desk',music='letters_theme')
# The north is not a miraculous secret or an unrestricted doorway.
d['actions']['late_c3_report']['reply']='亚历山德拉：「住户会接着记温度，锅炉班也要把每次调整写清楚。北边的星城愿意听取线路检修申请，我们可以介绍你去核对情况。但他们与外界很少往来，信只能说明来意，能否进去仍由他们核查。」'
d['actions']['late_s3_manifest']['reply']='司机划出了担架需要的位置。旁边停着一辆缺联接销的拖车，车轴仍完好。修好拖车就能两辆同行；如果这一班修不好，就先送伤病者，粮食由值守看管，下一班再运。'
d['actions']['late_s1_switch']['reply']='你清掉轨槽里的碎石，将道岔锁到旁线。司机复述了试车手势，确认南口的值守会接车。正式发车前，你还得陪他走到接送处核对这一班的安排。'
d['actions']['late_d1_both']['reply']='两位司机分别复述进路。伤员车先行，燃料车在旁线等候；调度员锁住进路后收回手动钥匙。重伤员由担架队安置，你还需要接候车室里两位能自行走动的伤员到南口，确认人员齐备后随车返站。'
d['actions']['late_central_train']['reply']='司机逐项对过担架位置和乘员名单。你把进路锁到民用车这一侧，取得调度员的发车确认；列车回执会送往中继站。中央提供了这趟运力，地方值守也留下可以核对的班次与席位，不能再拿一份总数代替。'
d['actions']['late_notify_semyon']['reply']='你先写自己平安，再告诉老爹已经见到父亲，问他工坊和腿伤近来怎么样。联络员核对了谢苗诺夫的姓名与住处，答应沿旧运输线转交。信件没有回执以前，你还不能确定它已经到手。'
d['interactions']['late_planning']['body']='桌上分放原始纸带、线路图和各站尚能提供的车次。列夫请你先核对测量结果，再讨论由谁接收警告、哪些人需要撤离。'
d['panels']['late_four_plans']['lines']=[
 {'speaker':'列夫','text':'东郊装卸路和几处通风口都在受污染尘土可能经过的方向。各站得先收到能核对来源的消息，再安排改道。我们无法通知每一个人，没收到回执的站点还要继续呼叫。'},
 {'speaker':'列夫','text':'你可以把警告交给多个独立接收点。这样有人迟迟不发布，别处仍能收到消息。但各站运力有限，路线和名单都要分别协调；公开危险区域时，也要保护接应人的身份。'},
 {'speaker':'列夫','text':'中央能调用更多车辆，可以承担集中撤离。代价是调度权会更集中。民用警报什么时候发、给居民留多少席位，都要现在写明，再核对他们到底有没有执行。'},
 {'speaker':'列夫','text':'也可以先发这次紧急预警，再把备用模块和维修资料交给受训值守。以后少依赖一个设施，可设备拆走后，这里的覆盖会缩小。每个接收点都得有人会修，也得继续供应备件。'},
 {'speaker':'列夫','text':'最后一条办法，是你留下完成下一轮观测。外面仍要有人接收、复核并安排撤离，我们也得修好备用电源。你留下这一班，不代表从此不能再有自己的生活。先想清楚愿意承担哪一部分。'}]
# Do not put saving-system explanations into characters' dialogue.
for id in d['jobs']:
 if id in ['c3','d2']:continue
 d['panels']['late_'+id+'_road']['lines']=[{'speaker':'旁白','text':{
 'c2':'巴拉诺娃把一只干燥的布袋交给你，叮嘱找到信以后装在里面。你向值守报过去向，沿地表检修路前往北线货场。尤里最后一班停靠的换乘口在轨道西侧，那里还有一条避开中央轨道的维修廊。',
 's1':'彼得递给你检修车的编号，另外夹了一张写着司机姓名的纸。你把纸收好，沿旧货运路走向换乘口。安东已经在那里多守了两班，到了以后先让他知道有人来接，再检查车辆。',
 's2':'谢尔盖在地图上圈出货场棚屋，提醒你地下入口在院子里。你沿旧路接近营地，远处有人在避风处抽烟，枪背在肩上。绕行和交战都能到达入口，先看清守卫的视线与掩体位置。',
 's3':'彼得反复确认了接应时刻，将空床和当班医护都安排妥当。到了换乘口，你还要与司机核对四名住户和粮食的载重；如果要分两班，就得明确告诉留下的人下一班由谁来。',
 'd1':'医护带着担架先下到货场换乘线，你随后从检修阶梯进入。两班司机等在南口，一边要赶回医务间，一边担心燃料误点。先去看道岔和旁线的实际情况，再决定怎样让车通过。',
 'd3':'你将校准仪装进防潮袋，出站时让值守核对封条。第一处测点在工人街诊所外的背风角，第二处在北线中继站。测量之间隔着一段废路，每一组都需要另记地点与时刻。'}[id]}]


for key in ['late_father_first','late_father_first_end','late_father_truth_scene','late_father_truth_end','late_epilogue_family']:d['panels'][key]['music']='reunion_theme'
for key in ['late_final_depart','late_final_result','late_epilogue_people']:d['panels'][key]['music']='warning_theme'

(ROOT/'data/complete_campaign.json').write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n')
print('actions',len(d['actions']),'quests',len(d['quests']),'panels',len(d['panels']))
