"""Export the shipped copy, branching rules and source locations to editable Word.

Run export_copy_data.gd first. No game content is changed by this tool.
The coverage index includes every Chinese/Cyrillic string outside comments in
runtime scripts and every such JSON string. Unresolved fragments remain labelled
as source templates instead of being presented as complete spoken sentences.
"""
from __future__ import annotations
import ast
import argparse
import subprocess
import bisect
import hashlib
import json
import re
from collections import defaultdict
from datetime import date
from pathlib import Path
from docx import Document
from docx.shared import Cm, Pt, RGBColor
from docx.oxml import OxmlElement
from docx.oxml.ns import qn

ROOT=Path(__file__).resolve().parents[1]
CLI=argparse.ArgumentParser(description=__doc__)
CLI.add_argument('--out',type=Path,default=Path('/tmp/metro1982-copy'))
CLI.add_argument('--runtime',type=Path)
ARGS=CLI.parse_args()
OUT=ARGS.out
RUNTIME=ARGS.runtime or OUT/'runtime-v25.json'
COMMIT=subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip()
HUMAN=re.compile(r'[\u3400-\u9fff\u0400-\u04ff]')
FLOORS={'life':'D-6生活层','labor':'D-6作业层','waterworks':'东郊水处理厂','commune':'莫斯科公社','sech':'谢契','coal':'D-6煤运休养区','starcity':'星城外围（内部暂未开放）','surface':'地表旧泵站','railfront':'旧联络线换乘站'}
FILES={p.name:json.loads(p.read_text()) for p in (ROOT/'data').glob('*.json')}
CAMPAIGN=FILES['campaign.json']
R=json.loads(RUNTIME.read_text())
CAMPAIGN=R['campaign']
for source,expected in R.get('source_hashes',{}).items():
    if hashlib.sha256((ROOT/source).read_bytes()).hexdigest()!=expected:raise RuntimeError('文案运行快照已过期，请先重新运行 tools/export_copy_data.gd：'+source)
ITEMS=R['constants']['story']['ITEMS']
GOODS=R['constants']['economy']['GOODS']
ACTORS={key:entry['name'] for key,entry in CAMPAIGN['interactions'].items()}
ACTORS.update({'semyon':'谢苗诺夫','ivan':'伊万','nina':'妮娜','cook':'加琳娜','mikhail':'米哈伊尔','igor':'伊戈尔','supply':'柳德米拉','commander':'科瓦廖夫','resident':'帕维尔','diner':'维拉'})
FLAG_LABELS={}
for quest in CAMPAIGN.get('quests',[]):
    FLAG_LABELS[quest['accepted']]='已接取“'+quest['name']+'”'
    FLAG_LABELS[quest['done']]='已完成“'+quest['name']+'”'
FLAG_LABELS.update({'accepted':'伊万已登记接受征召','kit':'已领取离站装备','father':'已向谢苗诺夫询问父亲','signal_heard':'已经听到东方-7信号','plant_diagram':'已查阅水厂值班图','plant_bled':'水厂旁通已经卸压','plant_fuse':'已找到仓门回路保险件','plant_power':'水厂仓门回路供电已恢复','water_secured':'已取得并装稳两箱净水滤芯','sided_veteran':'支持老兵离队，一同前往公社','commune_joined':'已选择加入公社','sech_joined':'已选择留在谢契','radio_fixed':'已恢复谢契短波电台','anna_reunited':'旧版探视完成记录；不是新版救援结果','father_met':'旧版曾与父亲见面；v25内部不开放','surface_job':'已接受旧泵站污染与兽群调查','surface_notes':'已阅读排水记录','surface_drain_open':'已打开泄水阀并排水','surface_sample_sealed':'已取得封存样本','anna_rescue_started':'已开始矿区救援准备','anna_outcome_done':'安娜救援结果已经确定','anna_alive':'安娜在救援后生还','anna_dead':'安娜在撤离中牺牲','rescue_medic_ready':'医护安排已落实','rescue_transport_ready':'矿口接送已落实','rescue_route_ready':'备用撤离通路已落实','signal_identified':'已辨认广播来源线索','signal_source_verified':'已到星城外围提交询问','commune_member':'已正式加入公社','sech_member':'已正式加入谢契'})
FLAG_LABELS.update({'anna_walk_started':'已明确答应陪安娜去食堂','anna_walk_arrived':'安娜已经实际走到食堂','anna_conversation_ready':'已完成食堂交谈，或选择先听她说明来意','anna_new_lesson_seen':'生还后已谈过下一次课堂','moro_at_workshop':'莫罗已实际到达机修间','moro_at_boiler':'莫罗已实际到达锅炉房','moro_at_guard':'莫罗已实际到达守备班','moro_at_stage':'莫罗已实际到达试演场地','moro_terms_agreed':'已完成住户和守备班的场地协商','moro_acoustic_terms':'协商选择饭后短时原声演出','moro_late_terms':'协商选择交班后的低音量演出','moro_rehearsed':'已经完成试演和住户反馈','moro_song_everyday':'试演后决定将居民亲历写进歌词','moro_song_uncertain':'试演后保留愿望，并写出前途的不确定','veteran_defense_started':'已明确接受协助老兵接应居民','veteran_defense_deployed':'老兵已实际就位西侧接应口','evac_first_safe':'第一名转移者已抵达候车区','evac_second_safe':'第二名转移者已抵达候车区','evac_third_safe':'第三名转移者已抵达候车区','battle_living_passage':'接应防守第一轮来袭已清除','battle_living_passage_rear':'接应防守第二轮来袭已清除','battle_living_passage_last':'接应防守最后一轮来袭已清除','veteran_defense_safe':'三人已抵达且三轮威胁均已清除','veteran_defense_done':'已与老兵核对人数并完成收尾'})
def flag_name(key):return key+('【'+FLAG_LABELS[key]+'】' if key in FLAG_LABELS else '')
def source_for(section,key):
    filename=next((name for name in ['journey_update.json','living_story.json','chapter_update.json'] if key in FILES.get(name,{}).get(section,{})), 'campaign.json')
    return 'data/'+filename+' · '+section+'.'+key

def dump(value):return json.dumps(value,ensure_ascii=False,sort_keys=True)
def literals(source):
    """Lex actual strings, skipping # comments and honoring escaped quotes."""
    i=0
    while i<len(source):
        if source[i]=='#':
            end=source.find('\n',i);i=len(source) if end<0 else end+1;continue
        if source[i] not in '\"\'':i+=1;continue
        start=i;q=source[i];triple=source.startswith(q*3,i);delimiter=q*(3 if triple else 1);i+=len(delimiter)
        while i<len(source):
            if source[i]=='\\':i+=2;continue
            if source.startswith(delimiter,i):i+=len(delimiter);break
            i+=1
        token=source[start:i]
        try:value=ast.literal_eval(token)
        except (SyntaxError,ValueError):value=token[len(delimiter):-len(delimiter)]
        yield start,value,token

def visible_ascii(prefix):
    """Also retain player-visible N, D-6, ?, × and numeric plaque labels."""
    masked=list(prefix)
    for offset,value,token in literals(prefix):masked[offset:offset+len(token)]=' '*len(token)
    masked=''.join(masked);stack=[]
    for i,char in enumerate(masked):
        if char=='(':
            name=re.search(r'(\w+)\s*$',masked[:i]);stack.append([name[1] if name else '',0])
        elif char==')':
            if stack:stack.pop()
        elif char==',' and stack:stack[-1][1]+=1
    if stack:
        name,arg=stack[-1]
        if name in ['Color','load','preload']:return False
        if name in ['label','button','body','prose','toast','receipt'] and arg==0:return True
        if name=='draw_string' and arg==2:return True
        if name=='text' and arg==1:return True
    return bool(re.search(r'\.(?:text|body|title|tooltip_text|placeholder_text)\s*\+?=',masked))

def scan():
    records=[]
    for path in sorted((ROOT/'scripts').glob('*.gd')):
        source=path.read_text();lines=source.splitlines();starts=[0]+[m.end() for m in re.finditer('\n',source)]
        contexts=[];stack=[];function='全局';constant=''
        for line in lines:
            stripped=line.lstrip();indent=len(line)-len(stripped)
            if stripped and not stripped.startswith('#'):
                while stack and indent<=stack[-1][0]:stack.pop()
                match=re.match(r'(?:static )?func (\w+)',stripped)
                if match:function=match.group(1);constant=''
                match=re.match(r'const (\w+)',stripped)
                if match:constant=match.group(1);function='常量 '+constant
                contexts.append((function,[x[1] for x in stack]))
                if stripped.endswith(':'):stack.append((indent,stripped[:-1]))
            else:contexts.append((function,[x[1] for x in stack]))
        for offset,value,token in literals(source):
            if not isinstance(value,str) or not value.strip():continue
            n=bisect.bisect_right(starts,offset)-1;function,controls=contexts[n]
            prefix=lines[n][:offset-starts[n]]
            if not HUMAN.search(value) and not visible_ascii(prefix):continue
            inline=prefix.split(':',1)[0] if re.match(r'\s*(?:if|elif) ',prefix) and ':' in prefix else ''
            if inline:controls=controls+[inline.strip()]
            records.append({'id':f'{path.stem}:{n+1}:{offset-starts[n]+1}','source':str(path.relative_to(ROOT)),'line':n+1,'text':value,'function':function,'conditions':controls,'expression':lines[n].strip()})
    def walk(value,path,file):
        if isinstance(value,dict):
            for k,v in value.items():walk(v,path+[str(k)],file)
        elif isinstance(value,list):
            for i,v in enumerate(value):walk(v,path+[str(i)],file)
        elif isinstance(value,str) and (HUMAN.search(value) or (path and path[-1] in ['name','text','body','title','role','detail','hint','description','author','date','reward_reply','background','step','location','original','zh','ru','en','frequency'])):records.append({'id':file+':'+'.'.join(path),'source':'data/'+file,'path':'.'.join(path),'text':value})
    for name,data in FILES.items():walk(data,[],name)
    for path in [ROOT/'project.godot',*sorted((ROOT/'scenes').glob('*.tscn'))]:
        for n,line in enumerate(path.read_text().splitlines(),1):
            if not re.match(r'\s*(?:config/name|config/description|text|tooltip_text|placeholder_text|title)\s*=',line):continue
            for offset,value,token in literals(line):
                if value:records.append({'id':str(path.relative_to(ROOT))+':'+str(n),'source':str(path.relative_to(ROOT)),'line':n,'text':value})
    return records

class Exporter:
    def __init__(self):
        self.doc=Document();self.records=scan();self.printed_text=set();self.rendered_actions=set()
        section=self.doc.sections[0];section.top_margin=Cm(1.8);section.bottom_margin=Cm(1.8);section.left_margin=Cm(2.1);section.right_margin=Cm(2.1)
        for name in ['Normal','Body Text','List Bullet','List Number']:
            style=self.doc.styles[name];style.font.name='Microsoft YaHei';style.font.size=Pt(10)
            style.element.get_or_add_rPr().rFonts.set(qn('w:eastAsia'),'微软雅黑')
            style.paragraph_format.space_after=Pt(5)
        for name,size in [('Title',29),('Heading 1',19),('Heading 2',14),('Heading 3',11)]:
            style=self.doc.styles[name];style.font.name='Microsoft YaHei';style.font.size=Pt(size);style.font.color.rgb=RGBColor.from_string('37574A')
            style.element.get_or_add_rPr().rFonts.set(qn('w:eastAsia'),'微软雅黑')
        self.doc.core_properties.title='地铁1982 v25 · 全文案与分支校订本'
        self.doc.core_properties.subject='实际工程文案、触发条件、选项与后果、源码索引'
        self.doc.core_properties.author='地铁1982项目'
        footer=section.footer.paragraphs[0];footer.alignment=2;footer.add_run('地铁1982 · 文案校订本　|　')
        field=OxmlElement('w:fldSimple');field.set(qn('w:instr'),'PAGE');footer._p.append(field)
        update=OxmlElement('w:updateFields');update.set(qn('w:val'),'true');self.doc.settings.element.append(update)
    def p(self,text='',style=None):
        text=str(text);self.printed_text.add(text);return self.doc.add_paragraph(text,style)
    def h(self,text,level=1):self.doc.add_heading(text,level)
    def meta(self,label,value):
        p=self.doc.add_paragraph();p.add_run(label+'：').bold=True;p.add_run(str(value))
    def prose(self,text):
        self.printed_text.add(text)
        for paragraph in str(text).split('\n'):self.doc.add_paragraph(paragraph)
    def source(self,text):
        p=self.p(text);p.paragraph_format.space_after=Pt(3)
        for run in p.runs:run.font.size=Pt(8);run.font.color.rgb=RGBColor.from_string('6E746B')
    def condition(self,req):
        if not req:return '没有额外前置条件'
        if isinstance(req,str):return '状态 '+flag_name(req)+' 为真'
        parts=[]
        for key,value in req.items():
            if key=='floor':parts.append('所在场景为 '+'／'.join(FLOORS.get(x,x) for x in value))
            elif key=='all':parts.extend('已满足 '+flag_name(x) for x in value)
            elif key=='any':parts.append('至少满足一项：'+'、'.join(flag_name(x) for x in value))
            elif key=='not_all':parts.append('以下条件不能全部成立：'+'、'.join(flag_name(x) for x in value))
            elif key=='not':parts.extend('尚未满足 '+flag_name(x) for x in value)
            elif key=='items':parts.append('持有 '+'、'.join(ITEMS.get(x,[x])[0] for x in value))
            elif key=='goods':parts.extend('持有 '+GOODS.get(x,{'name':x})['name']+' ≥ '+str(n) for x,n in value.items())
            else:parts.append(key+'='+dump(value))
        return '；'.join(parts)
    def title_page(self):
        self.doc.add_heading('地铁1982',0);self.h('v25 全文案与分支校订本',1)
        self.p('导出日期：'+date.today().isoformat());self.meta('工程版本','v25 / '+COMMIT);self.meta('版本依据','metro-v25-journeys-ui；仅导出文字，未修改游戏内容')
        self.p('本文件从当前工程数据与运行脚本导出，供逐项校正文字。章节中的稳定ID和文件路径用于把修改对应回游戏。')
        self.p('重要：这是校订资料，不是游戏攻略。当前开放到星城外围；内区、与父亲重逢及旧结局虽然仍保存在工程中，不能据此理解为本版可触发。标注“保留／暂未开放”的段落可修改，但不会在本版正常流程中出现。')
        self.p('本版剧情以 journey_update.json、living_story.json、chapter_update.json 依次覆盖 campaign.json 的结果为准；journey_update.gd 另有运行时改写。同名过场由 journey_panels.json 最后覆盖。文档保留全部条件行与选项，不会只导出某一个存档当时能看到的文字。')
        self.p('建议开启 Word 的“视图 → 导航窗格”，按章节、NPC、任务或ID定位。可用修订模式修改原文，或在其下添加批注；只修改本文档不会自动改变游戏。')
        self.h('怎样阅读触发条件',2)
        self.p('对话先显示对应交互对象的开场，再按条件替换为状态变化后的开场。替换规则按列出顺序执行，后满足的规则可以覆盖先前规则。只有有效条件下的选项能够执行。')
        self.p('all 表示全部状态成立，any 表示至少一项成立，not 表示这些状态尚未成立；items 表示背包条件，goods 表示数量条件。状态ID保留原名，附录中的状态索引说明其由哪些选择设置。')
        self.p('条件性台词逐段标注：满足条件才出现，不代表所有段落会在一次游玩中连续说出。任务阶段按数据顺序检查，最后一个满足条件的阶段覆盖前面的阶段；动态目标还可能由脚本改写，相关规则在任务章单列。')
        self.p('限次动作执行后会记录 c_done_动作ID，已完成选项不能重复领取奖励。已失败支线的动作不再允许执行。主线改道、已完成、支线失败分别显示，未接取的支线不进入任务列表。')
        self.p('旁白与台词：带「」的部分由当前NPC说出；带姓名前缀的台词使用该姓名。其余部分按旁白显示。图文过场有单独的说话者字段。动态数字和物品名以模板保留，文档不会虚构一次具体游玩的数值。')
        self.p('D-6及NPC的文本依次经过 Story → Narrative → ResidentDialogue → D6Chapter → Campaign（含 ChapterUpdate）→ Economy → Progression → FirstMeetings；后层可改写前层。首次自我介绍尚未结束时，正式任务选项会被替换。第五章保留脚本条件与原始拼接语句；例如米哈伊尔赠送维生素D的旧选项虽在底层存在，最终已被过滤。')
        self.p('覆盖范围：data 内全部JSON文字（包括当前覆盖稿与保留稿）；scripts 内除注释外的中文／西里尔文字符串及可识别的界面英文、符号、数字标签；场景文本与工程标题；广播中英俄歌名。图像内没有字符串资源的装饰印刷，另列示例图与素材位置供人工校对，不把图中的不可读装饰字当成正式设定。外部参考文档、测试断言、工具日志不混入文案。动态拼接片段保留原始语句，不伪装成一条独立台词。')
        self.h('故事路线定位',2)
        for route,nodes in [('征召离站','D-6登记与领取装备 → 地表行军与减员 → 水厂解谜、战斗及取滤芯 → 归途岔路选择'),('独自离站','取得防护装备 → 检修许可／侧门／管线等离站方式 → 结识谢尔盖 → 选择公社或谢契路线'),('D-6归队','支持中尉或和平归队 → 交回滤芯 → 回家交谈 → 医务说明与领补给 → 地表旧泵站解谜、战斗、采样 → 返站汇报 → 根据报告重点领取医护或路线后续；尚未完成长期D-6阵营主线'),('公社','抵达自我介绍 → 加入后完成三轮联络线任务 → 再安排星城外围；安娜线由课堂、寻亲进入矿区救援，含生还和悲剧两种后续'),('谢契','抵达并认识居民 → 加入后完成三轮联络线任务 → 通过担保接触公社和安娜 → 后期可去星城外围；地表旧泵站为可重复出站任务'),('星城','完成阵营三轮主线并核实广播 → 获得担保 → 抵达外围提交询问信 → 返回聚落；内部与父亲重逢保留文案未开放')]:self.meta(route,nodes)
        self.p(f'索引共 {len(self.records)} 个文字来源；全部来源同时保存在 copy-index-v25.json，便于后续自动核对。')
        self.doc.add_page_break();self.h('目录',1)
        p=self.doc.add_paragraph();field=OxmlElement('w:fldSimple');field.set(qn('w:instr'),'TOC \\o "1-2" \\h \\z \\u');p._p.append(field)
        self.p('Word打开后可右键目录选择“更新域”。导航窗格无需更新目录即可使用。')
    def panels(self):
        self.h('一、图文过场与剧情分支')
        incoming=defaultdict(list)
        for key,panel in R['panels'].items():
            if 'next' in panel:incoming[panel['next']].append(key+' → 下一页')
            for index,choice in enumerate(panel.get('choices',[])):incoming[choice['next']].append(key+' → 选项'+str(index+1))
        triggers={'history_war':['新存档：intro'],'official_gate':['确认随征召小队离站：official'],'solo_descent':['确认独自离开D-6：solo']}
        for key,a in CAMPAIGN['actions'].items():
            if a.get('travel'):incoming[a['travel']].append('交互动作 '+key+'：'+a['text'])
        for path in (ROOT/'scripts').glob('*.gd'):
            for n,line in enumerate(path.read_text().splitlines(),1):
                for match in re.finditer(r'(?:show_comic|\.start)\([^\n]*?["\']([a-z_0-9]+)["\']',line):
                    if match[1] in R['panels']:incoming[match[1]].append(f'{path.name}:{n}')
        for key,panel in R['panels'].items():
            self.h(panel.get('title',key)+' 〔'+key+'〕',2)
            origin='data/journey_panels.json' if key in FILES.get('journey_panels.json',{}) else 'data/living_panels.json' if key in FILES.get('living_panels.json',{}) else 'data/chapter_panels.json' if key in FILES.get('chapter_panels.json',{}) else ('data/story_panels.json' if key in FILES.get('story_panels.json',{}) else ('data/campaign.json · panels' if key in FILES['campaign.json'].get('panels',{}) else 'scripts/comic.gd · PANELS'))
            self.source('当前节点来源：'+origin+' · '+key)
            self.source('最终运行文本：Comic.panel；基础 Comic.PANELS / campaign.panels；覆盖 data/story_panels.json 与 data/chapter_panels.json')
            self.meta('到达方式','；'.join(triggers.get(key,[])+incoming[key]) or '未发现静态入口；可能由参数调用进入，或属于保留版本。可按该ID全文检索核对。')
            if panel.get('location'):self.meta('地点',panel['location']);self.printed_text.add(panel['location'])
            if panel.get('art'):self.meta('配图素材','assets/cinematics/'+panel['art']+'.png')
            if 'lines' in panel:
                for i,line in enumerate(panel['lines'],1):
                    self.meta('段落 '+str(i)+' 的出现条件',self.condition(line.get('when',{})))
                    self.p(('旁白：' if line['speaker']=='旁白' else line['speaker']+'：')+line['text']);self.printed_text.add(line['text'])
            else:self.prose(panel.get('body',''))
            if panel.get('choices'):
                for i,choice in enumerate(panel['choices'],1):
                    self.p(f'选项{i}：'+choice['text']);self.printed_text.add(choice['text'])
                    self.meta('选中后','进入 '+choice['next']+('；设置 '+choice['flag']+'=true' if choice.get('flag') else ''))
                    self.meta('选项出现条件',self.condition(choice.get('when',{}))+('；已满足 '+flag_name(choice['requires']) if choice.get('requires') else '')+('；'+flag_name(choice['hide_if'])+' 成立后隐藏' if choice.get('hide_if') else ''))
                    extra={k:v for k,v in choice.items() if k not in ['text','next','flag']}
                    if extra:self.meta('其它条件或影响',dump(extra))
            elif panel.get('next'):self.meta('继续后','进入 '+panel['next'])
            if panel.get('end'):self.meta('本段结束','返回／前往 '+panel['end'])
            if panel.get('finish_flags'):self.meta('结束后设置',dump(panel['finish_flags']))
            if panel.get('same_moment'):self.meta('时间','发生于同一时刻，不推进故事日')
            if panel.get('music'):self.meta('背景音乐提示',panel['music'])
        self.h('结局与收束文本',2)
        for key,ending in CAMPAIGN['endings'].items():
            self.h(ending.get('title',key)+' 〔'+key+'〕',3)
            self.meta('本版状态','旧结局保留稿；加入公社／谢契已改为继续探索，不凭此表判断结局可达性。以实际允许动作和当前过场连接为准。')
            linked=[k for k,a in CAMPAIGN['actions'].items() if a.get('ending')==key]
            linked+=['过场 '+k for k,p in R['panels'].items() if p.get('end')=='ending:'+key]
            self.meta('触发','；'.join(linked) or '未发现当前动作或过场直接连接；作为已有保留文案列出，不保证目前可达。')
            for field,value in ending.items():
                if isinstance(value,str):self.meta(field,value);self.printed_text.add(value)
    def action(self,key):
        a=CAMPAIGN['actions'][key]
        if key in self.rendered_actions:
            self.meta('共用选项',a['text']+' 〔c_'+key+'〕；完整前置条件、回复与后果见首次出现的同ID条目。');return
        self.rendered_actions.add(key)
        self.h(a['text']+' 〔c_'+key+'〕',3);self.printed_text.add(a['text'])
        self.source(source_for('actions',key))
        if key in CAMPAIGN.get('unreleased_star_actions',[]):self.meta('本版状态','暂未开放：被 unreleased_star_actions 明确禁止，即使旧存档有前置状态也不能执行。')
        self.meta('可执行条件',self.condition(a.get('req',{})))
        self.meta('重复限制','完成一次后停用' if a.get('once',True) else '可重复；仍受当前状态限制')
        self.meta('附加逻辑','还受 scripts/living_story.gd · allowed 与 scripts/chapter_update.gd · allowed、scripts/campaign.gd · available 和支线失败记录限制；脚本逐条件文本在第五章保留。')
        if a.get('offer_for'):
            self.meta('首次提出任务','尚未设置 '+a['offer_for']+' 时，还需 '+self.condition(a.get('offer_unlock',{})))
            if a.get('offer_busy'):self.meta('暂缓提出的情况','；'.join('已接 '+x[0]+' 且未完成 '+x[1] for x in a['offer_busy']))
        self.meta('执行回复','基础动作回复如下；front_* 等动态回复还可能由本轮任务和 chapter_update.act 替换，见主线任务与第五章。')
        self.prose(a.get('reply',''))
        for field,label in [('flags','写入状态'),('give','获得任务物品'),('take','交出物品'),('goods','普通物资变化'),('reward','子弹报酬'),('travel','接续过场'),('ending','触发结局')]:
            if a.get(field):self.meta(label,dump(a[field]))
        rewards=[b for b in FILES['publications.json']['entries'] if b['source'].get('action')==key]
        for book in rewards:self.meta('新增刊物答谢',book.get('reward_reply','')+book['title'])
    def interactions(self):
        self.h('二、设施NPC、场景交互与选项')
        self.h('D-6：最终显示文本的状态示例',2)
        self.p('以下通过 Story.view 读取最终叠加后的对话，只读、不执行动作。每组标出假设的任务状态、物品与路线，再列开场和选项。它们是用于辨别覆盖关系的状态组合示例，不是要求玩家按此顺序经历的新增剧情；没有覆盖到的条件分支仍完整保存在第五章源码条件索引。')
        grouped=defaultdict(list)
        for entry in R.get('d6_views',[]):grouped[entry['id']].append(entry)
        for key,entries in grouped.items():
            self.h(entries[0]['view']['name']+' 〔'+key+'〕',3)
            variants={}
            for entry in entries:
                signature=dump(entry['view'])
                if signature not in variants:variants[signature]=[entry,[]]
                variants[signature][1].append(entry['scenario']['name'])
            for entry,names in variants.values():
                v=entry['view'];state=entry['scenario']
                self.meta('示例场合','；'.join(names))
                self.meta('场景／路线',FLOORS[state['floor']]+'；'+(state['route'] or '尚未确定'))
                self.meta('假设状态／持有物品',dump(state['flags'])+'；'+dump(state['items']))
                self.prose(v.get('body',''))
                for option in v.get('options',[]):
                    self.meta('选项 '+option['key'],option['text']+' 【'+('可选' if option['enabled'] else '不可选')+'】'+(('；'+option['reason']) if option.get('reason') else ''))
                self.source('scripts/story.gd · view，叠加其余规则后的结果；动作回复见D-6集中回复与第五章条件索引。')
        done=set()
        for floor in ['life','labor','waterworks','commune','sech','coal','surface','railfront','starcity']:
            entries=[(k,v) for k,v in CAMPAIGN['interactions'].items() if v.get('facility')==floor]
            if not entries:continue
            self.h(FLOORS[floor],2)
            for key,v in entries:
                self.h(v['name']+' 〔'+key+'〕',2);self.printed_text.add(v['name']);self.printed_text.add(v.get('role',''))
                self.source(source_for('interactions',key))
                if key in FILES.get('first_meetings.json',{}):self.meta('首次见面','先走“首次自我介绍”章的问名与话题，结束后才进入这里的任务选项。')
                if floor=='starcity' and key!='star_perimeter_call':self.meta('本版状态','内部保留交互，不在当前外围地图中生成。')
                if key=='commune_anna':self.meta('场景变化','安娜死亡后替换为她留下的课桌；不再生成活着的安娜，也不再提供其生前选项。')
                self.meta('身份／交互类别',v.get('role',''))
                self.meta('出现方式','在 '+FLOORS[floor]+' 靠近交互点按 E；只在该设施允许执行选项。')
                self.meta('最初开场','以下为默认开场；后续状态满足时按顺序替换。')
                self.prose(v.get('body',''))
                for i,variant in enumerate(v.get('after',[]),1):
                    self.meta('开场变化 '+str(i),self.condition(variant[0]));self.prose(variant[1])
                for option in v.get('options',[]):
                    if option in CAMPAIGN['actions']:self.action(option);done.add(option)
        left=set(CAMPAIGN['actions'])-done
        if left:
            self.h('其它流程动作与事件',2)
            for key in sorted(left):self.action(key)
    def quests(self):
        self.h('三、任务描述、阶段与失败规则')
        self.p('接取新任务、任务更新、完成和失败会有通知。手记只列已接取任务；未接取的委托以“留意的事”中的轻度线索提示。支线因不可逆离场或旅程结束而无法交付时记录失败；不会仅因暂时走开而失败。')
        for q in CAMPAIGN.get('quests',[]):
            self.h(q['name']+' 〔'+q['id']+'〕',2);self.printed_text.add(q['name'])
            self.meta('场景与类型',FLOORS.get(q.get('facility'),q.get('facility'))+' / '+q.get('kind','支线'))
            self.meta('接取／完成状态',q['accepted']+' / '+q['done'])
            self.prose(q.get('background',''))
            self.meta('相关动作','、'.join(q.get('actions',[])))
            for i,stage in enumerate(q.get('stages',[]),1):
                self.meta('阶段 '+str(i),self.condition(stage.get('when',{})))
                self.prose(stage.get('step',''))
                target=stage.get('target','');self.meta('跟进地点',FLOORS.get(stage.get('place',q.get('facility')),stage.get('place',q.get('facility')))+' / '+ACTORS.get(target,target)+' 〔'+target+'〕')
            for k,v in q.items():
                if k not in ['id','name','facility','kind','accepted','done','background','actions','stages']:self.meta(k,dump(v))
        self.h('D-6基础任务、主线跟进与轻度提醒',2)
        self.p('这些任务由 scripts/journal.gd 和 scripts/progression.gd 按状态生成。第五章按函数逐条列出标题、描述、目标和分支条件；状态名称均保留，便于核对。')
        self.h('v25 任务目标的运行时改写',2)
        self.p('旧泵站：surface_depart 出发时自动追踪 surface_survey。在地表已封存样本后，目标为 surface_exit（检修梯），返回聚落后再指向 commune_guard 或 sech_quartermaster。人在公社／谢契时可直接向当地收件人交付。广播线索的地点固定为实际可调查的收音机／联络点，不能把旧泵站标成广播调查现场。原始阶段中的回城目标不能覆盖这条运行规则。')
        self.source('scripts/campaign.gd · side_tasks / act；scripts/journal.gd · tasks / active / track')
        self.h('阵营六轮主线：调查物、现场描述与回报',2)
        for key,m in FILES.get('chapter_update.json',{}).get('missions',{}).items():
            self.h(m['name']+' 〔'+key+'〕',3)
            self.source('data/chapter_update.json · missions.'+key)
            self.meta('所属阵营',FLOORS.get(m['faction'],m['faction']))
            for field,label in [('title','派工标题'),('summary','委托简介'),('object','现场调查对象'),('evidence','检查证据时的描述'),('report','带回证据后的汇报描写')]:
                self.meta(label+' / '+field,m[field]);self.printed_text.add(m[field])
            self.meta('动态使用条件','field_mission='+key+'；现场调查由 front_take_evidence 读取本轮 evidence，相关回复还受已完成战斗与现场过场状态限制。')
            self.meta('过场连接','开场节点 '+m.get('intro','')+'；返程节点 '+m.get('after','')+'；选项与条件见第一章相应ID。')
    def introductions(self):
        self.h('二·补充、首次见面与问名流程')
        self.p('只有真正开始和NPC交谈时，才建立 first_meeting_NPC 状态。0=尚未报上姓名，1=已介绍姓名但尚未聊完一个话题，2=可以进入正式选项。已有聊天记录／任务经历的旧存档会视为已经认识；单纯查手记不会提前跳过问名。')
        for key,v in FILES.get('first_meetings.json',{}).items():
            self.h(ACTORS.get(key,key)+' 〔'+key+'〕',2)
            self.source('data/first_meetings.json · '+key+'；scripts/first_meetings.gd · begin / decorate / act')
            for field,label in [('greeting','状态0：首次开场'),('name_choice','状态0：玩家介绍姓名的选项'),('named','选中后回复／状态1再交谈的开场')]:
                self.meta(label,v[field]);self.printed_text.add(v[field])
            for i,topic in enumerate(v.get('topics',[]),1):
                self.meta('状态1 话题 '+str(i),topic['text']);self.printed_text.add(topic['text'])
                self.prose(topic['reply']);self.printed_text.add(topic['reply'])
                self.meta('选中后','设置 first_meeting_'+key+'=2；结束本轮初识，可再次交谈查看正式任务与闲聊。')
    def radio(self):
        self.h('四·补充、收音机频道、歌名与小游戏界面')
        radio=FILES.get('radio.json',{})
        for optional,key in [(False,'stations'),(True,'optional_stations')]:
            for station in radio.get(key,[]):
                self.h(station['name']+' 〔'+station['id']+'〕',2)
                self.meta('出现条件','待启用：必须两首新增MP3均存在且导入，当前音频未齐全，不会显示空频道。' if optional else '与公共收音机互动后选择音乐，或使用已购买的随身收音机。')
                self.source('data/radio.json · '+key+' · '+station['id'])
                for field in ['name','frequency','ru','en','description']:
                    if field in station:self.meta(field,station[field]);self.printed_text.add(station[field])
                for track in station.get('tracks',[]):
                    song=radio.get('optional_tracks' if optional else 'tracks',{}).get(track,{})
                    self.meta('歌曲ID',track)
                    for field in ['zh','ru','original']:
                        if field in song:self.meta(field,song[field]);self.printed_text.add(song[field])
        self.p('小游戏的规则、得分、开始／暂停／结束按钮及错误提示，按第五章 scripts/arcade.gd 和相关 UI 文件列出；数字为运行时变量，保留模板与拼接来源。')
    def items_books(self):
        self.h('四、物品、商店物资与刊物正文')
        self.h('任务物品、装备与纪念物',2)
        for key,v in ITEMS.items():
            self.h(v[0]+' 〔'+key+'〕',3);self.meta('类别',v[2]);self.prose(v[1]);self.printed_text.update(v)
        self.h('可购买／出售／使用的普通物资',2)
        for key,v in GOODS.items():
            self.h(v['name']+' 〔'+key+'〕',3);self.printed_text.add(v['name']);self.prose(v['detail'])
            self.meta('机制','售价 '+str(v['price'])+' 制式弹；库存 '+str(v['stock'])+'；效果 '+str(v.get('effect',''))+' '+str(v.get('amount',0)))
        self.h('可收集刊物：'+str(len(FILES['publications.json']['series']))+'系列、'+str(len(FILES['publications.json']['entries']))+'册',2)
        pubs=FILES['publications.json']
        for series in pubs['series']:
            self.h(series['name']+' 〔'+series['id']+'〕',2);self.printed_text.add(series['name']);self.prose(series['description'])
            for book in [x for x in pubs['entries'] if x['series']==series['id']]:
                self.h(book['title']+' 〔'+book['id']+'〕',3);self.printed_text.add(book['title']);self.meta('作者／年代',book['author']+' / '+book['date']);self.printed_text.update([book['author'],book['date']])
                source=book['source'];self.meta('取得方式',FLOORS[source['floor']]+'：'+source.get('place',''))
                self.meta('触发ID',source['target'] if source['kind']=='pickup' else '完成动作 '+source['action']+' 后答谢赠送，限一册')
                self.meta('未收录时的悬停提示',book['hint']);self.printed_text.add(book['hint'])
                if book.get('reward_reply'):self.meta('NPC赠书补充句',book['reward_reply']);self.printed_text.add(book['reward_reply'])
                cover=ROOT/'assets/publications'/f"cover_{book['cover']:02d}.png"
                if cover.exists():self.source('封面：'+str(cover.relative_to(ROOT)))
                self.prose(book['body'])
    def d6_constants(self):
        self.h('五、D-6对话、任务与系统文案的条件索引')
        self.p('本章既保留有效的状态变化文案，也保留被后续层覆盖的默认模板，并标注所在函数和分支。实际显示先后遵循第一章说明的规则顺序。条件中的“match”或字符串分支表示对应交互对象／动作；if/elif/else 表示状态分支。')
        for file in ['narrative','resident_dialogue']:
            constants=R['constants'][file]
            self.h(('D-6主要人物' if file=='narrative' else 'D-6居民与生活区')+'：集中编写的文本',2)
            for table in ['BODIES','OPTIONS','REPLIES','CHAT']:
                if table not in constants:continue
                self.h({'BODIES':'交互开场','OPTIONS':'选项文本替换','REPLIES':'动作回复','CHAT':'可选择的闲聊'}[table],3)
                for key,value in constants[table].items():
                    self.meta('ID',key)
                    self.source('scripts/'+file+'.gd · '+table+'.'+key)
                    hosts=sorted({entry['view']['name'] for entry in R.get('d6_views',[]) if any(o['key']==key for o in entry['view'].get('options',[]))})
                    if hosts:self.meta('对话／交互对象','、'.join(hosts))
                    if table=='CHAT':
                        self.meta('交谈对象',ACTORS.get(value[0],value[0]));self.meta('玩家选项',value[1]);self.prose(value[2]);self.printed_text.update(value[1:])
                    else:self.prose(value)
        self.h('按文件、函数和条件排列的其余文字',2)
        ordered=['story','narrative','resident_dialogue','d6_chapter','progression','journal','economy','comic','conversation','hud','ui_dialogue','ui_comic','main_menu','save_store','combat','world']
        rest=sorted({Path(r['source']).stem for r in self.records if r['source'].startswith('scripts/')}-set(ordered))
        for stem in ordered+rest:
            rows=[r for r in self.records if r['source']==f'scripts/{stem}.gd' and r['text'] not in self.printed_text]
            if not rows:continue
            self.h('scripts/'+stem+'.gd',2)
            purpose={'story':'角色基础交互、动作验证、装备与道具；底层选项可能被后续规则替换。','narrative':'D-6人物开场、状态变化与回复覆盖。','resident_dialogue':'生活层居民、生活支线与闲聊。','d6_chapter':'D-6下层、征召、病房、离站与返回。','progression':'主支线状态、任务失败、伊戈尔旧账及防护限制。','journal':'手记中的标题、任务阶段、线索提醒与百科；包含随状态生成的目标。','campaign':'设施交互、任务阶段、剧情动作与返回地点的运行时改写。','chapter_update':'阵营主线、安娜救援及后续状态覆盖；本版的重要剧情逻辑。','hud':'背包、任务、提示弹窗、记录与系统操作文字。','economy':'购买、出售、使用、补给与生命／食物／辐射等反馈。','comic':'过场框架、分支结算与旧版基础稿。','main_menu':'主菜单、设置与新游戏提示。','save_store':'存档元数据、读档验证及错误提示。','world':'场景交互名称、抵达流程及探索反馈。','combat':'即时战斗、换弹、救援、辐射与重试提示。','public_radio':'公共／随身收音机交互、播放提示及频道启用。','ui_public_radio':'收音机播放界面。','first_meetings':'初识、问名与话题结束后的解锁规则。','arcade':'场内小游戏的规则、按钮、得分及结束提示。'}.get(stem,'该模块的玩家可见文字或辅助配置模板；原始语句说明它如何被调用和拼接。')
            self.meta('文案用途',purpose)
            grouped=defaultdict(list)
            for r in rows:grouped[(r['function'],tuple(r['conditions']))].append(r)
            for (function,conditions),group in grouped.items():
                self.h(function,3)
                self.meta('出现分支',' → '.join(conditions) or '该函数的通用文本；具体调用时显示')
                seen=set()
                for r in group:
                    if r['text'] in seen:continue
                    seen.add(r['text'])
                    self.source(f"{r['source']}:{r['line']} 〔{r['id']}〕")
                    if r['expression'].count('"')>2 or '+' in r['expression']:self.meta('文本类型','源码模板／可能是拼接片段；请结合下方完整语句修改，不代表单独显示的一句台词。')
                    self.prose(r['text'])
                    self.meta('原始语句／动态拼接',r['expression'])
    def remaining_json(self):
        rows=[r for r in self.records if not r['source'].startswith('scripts/') and r['text'] not in self.printed_text]
        if not rows:return
        self.h('六、其余JSON文案与被覆盖的基础文本')
        self.p('这里列出尚未在正文出现的JSON文字及场景／工程标题。相同ID按 chapter_panels → story_panels → campaign.panels / Comic.PANELS 的优先级确定最终稿；交互与动作按 chapter_update 覆盖 campaign。这里可能有被覆盖的旧稿、辅助配置或动态字段，务必结合来源位置判断，不是额外可接取的任务。')
        for r in rows:self.source(r['source']+' · '+r.get('path',str(r.get('line',''))));self.prose(r['text'])
    def printed_art(self):
        self.h('附录、场景图内告示与印刷装饰')
        self.p('下列素材中的印刷、图表与装饰字直接画在图片里。这里保留出现位置和素材路径，方便另行查看并圈画；它们不是可直接修改的字符串，不把无法可靠识读的AI装饰字臆造为台词。书刊封面路径已在刊物章节逐册列出。')
        references=[('commune_poster_0','公社人民议事厅墙面：革命宣传画'),('commune_poster_1','公社食堂入口北墙：生产与生活宣传画'),('plant_pump_chart','水厂西侧泵房北墙：泵组检修图'),('plant_roster_chart','水厂交接档案室北墙：旧值班表'),('plant_safety_chart','水厂档案室与入口气闸：安全告示'),('plant_tool_board','水厂工具修配间北墙：工具板'),('plant_electric_warning','水厂送电控制柜正面：高压警告'),('plant_filter_label','水厂封存仓库木箱正面：滤芯装箱标签')]
        for asset,place in references:
            path=ROOT/'assets/visual'/(asset+'.png')
            if not path.exists():continue
            self.h(place,3);self.meta('显示条件','进入相应场景即可看到；固定场景装饰，不需接任务')
            self.source(str(path.relative_to(ROOT)))
    def states(self):
        self.h('附录、分支状态设置索引')
        flags=defaultdict(list)
        for key,a in CAMPAIGN['actions'].items():
            for flag,value in a.get('flags',{}).items():flags[flag].append('动作 '+key+' → '+str(value))
        for key,p in R['panels'].items():
            for i,c in enumerate(p.get('choices',[]),1):
                if c.get('flag'):flags[c['flag']].append('过场 '+key+' 选项'+str(i)+' → true')
            for flag in p.get('finish_flags',[]):flags[flag].append('过场 '+key+' 结束 → true')
        for flag,sources in sorted(flags.items()):self.meta(flag,'；'.join(sources))
    def repeated_sources(self):
        self.h('附录、重复句子的其它出现位置')
        self.p('相同文字在正文中可合并阅读。这里补列重复出现的各处条件，避免把同一句话的不同触发方式遗漏。动态拼接仍需结合原始语句核对。')
        grouped=defaultdict(list)
        for row in self.records:grouped[row['text']].append(row)
        for text,rows in grouped.items():
            if len(rows)<2:continue
            self.prose(text)
            for r in rows:
                location=r['source']+':'+str(r.get('line',r.get('path','')))
                if r.get('function'):location+=' · '+r['function']+' · '+(' → '.join(r.get('conditions',[])) or '通用分支')
                self.source(location)
    def finish(self):
        OUT.mkdir(parents=True,exist_ok=True)
        self.title_page();self.panels();self.interactions();self.introductions();self.quests();self.items_books();self.radio();self.d6_constants();self.remaining_json();self.printed_art();self.states();self.repeated_sources()
        # Exact source coverage, independent of how duplicate sentences are laid out.
        missing=[r for r in self.records if r['text'] not in self.printed_text]
        assert not missing,[(r['id'],r['text'][:50]) for r in missing]
        document=OUT/'地铁1982-v25-全文案与分支校订本.docx';self.doc.save(document)
        index={'version':23,'game_commit':COMMIT,'source_files':{},'records':self.records,'coverage':{'total':len(self.records),'missing':len(missing)}}
        for source in sorted({r['source'] for r in self.records}):index['source_files'][source]=hashlib.sha256((ROOT/source).read_bytes()).hexdigest()
        (OUT/'copy-index-v25.json').write_text(json.dumps(index,ensure_ascii=False,indent=2)+'\n')
        print(json.dumps({'document':str(document),'bytes':document.stat().st_size,'source_records':len(self.records),'missing':0,'paragraphs':len(self.doc.paragraphs)},ensure_ascii=False))

if __name__=='__main__':Exporter().finish()
