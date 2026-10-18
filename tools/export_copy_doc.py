"""Export the shipped copy, branching rules and source locations to editable Word.

Run export_copy_data.gd first. No game content is changed by this tool.
The coverage index includes every Chinese/Cyrillic string outside comments in
runtime scripts and every such JSON string. Unresolved fragments remain labelled
as source templates instead of being presented as complete spoken sentences.
"""
from __future__ import annotations
import ast
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
OUT=ROOT/'docs/copy'
RUNTIME=ROOT/'docs/copy/runtime-v13.json'
HUMAN=re.compile(r'[\u3400-\u9fff\u0400-\u04ff]')
FLOORS={'life':'D-6生活层','labor':'D-6作业层','waterworks':'东郊水处理厂','commune':'莫斯科公社','sech':'谢契','coal':'D-6煤运休养区','starcity':'星城'}
FILES={p.name:json.loads(p.read_text()) for p in (ROOT/'data').glob('*.json')}
CAMPAIGN=FILES['campaign.json']
R=json.loads(RUNTIME.read_text())
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
FLAG_LABELS.update({'accepted':'伊万已登记接受征召','kit':'已领取离站装备','father':'已向谢苗诺夫询问父亲','signal_heard':'已经听到东方-7信号','plant_diagram':'已查阅水厂值班图','plant_bled':'水厂旁通已经卸压','plant_fuse':'已找到仓门回路保险件','plant_power':'水厂仓门回路供电已恢复','water_secured':'已取得并装稳两箱净水滤芯','sided_veteran':'支持老兵离队，一同前往公社','commune_joined':'已选择加入公社','sech_joined':'已选择留在谢契','radio_fixed':'已恢复谢契短波电台','anna_reunited':'已将核实结果带回安娜','father_met':'已与父亲见面'})
def flag_name(key):return key+('【'+FLAG_LABELS[key]+'】' if key in FLAG_LABELS else '')

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
        elif isinstance(value,str) and (HUMAN.search(value) or (path and path[-1] in ['name','text','body','title','role','detail','hint','description','author','date','reward_reply','background','step','location'])):records.append({'id':file+':'+'.'.join(path),'source':'data/'+file,'path':'.'.join(path),'text':value})
    for name,data in FILES.items():walk(data,[],name)
    for path in [ROOT/'project.godot',*sorted((ROOT/'scenes').glob('*.tscn'))]:
        for n,line in enumerate(path.read_text().splitlines(),1):
            if not re.match(r'\s*(?:config/name|config/description|text|tooltip_text|placeholder_text|title)\s*=',line):continue
            for offset,value,token in literals(line):
                if value:records.append({'id':str(path.relative_to(ROOT))+':'+str(n),'source':str(path.relative_to(ROOT)),'line':n,'text':value})
    return records

class Exporter:
    def __init__(self):
        self.doc=Document();self.records=scan();self.printed_text=set()
        section=self.doc.sections[0];section.top_margin=Cm(1.8);section.bottom_margin=Cm(1.8);section.left_margin=Cm(2.1);section.right_margin=Cm(2.1)
        for name in ['Normal','Body Text','List Bullet','List Number']:
            style=self.doc.styles[name];style.font.name='Microsoft YaHei';style.font.size=Pt(10)
            style.element.get_or_add_rPr().rFonts.set(qn('w:eastAsia'),'微软雅黑')
            style.paragraph_format.space_after=Pt(5)
        for name,size in [('Title',29),('Heading 1',19),('Heading 2',14),('Heading 3',11)]:
            style=self.doc.styles[name];style.font.name='Microsoft YaHei';style.font.size=Pt(size);style.font.color.rgb=RGBColor.from_string('37574A')
            style.element.get_or_add_rPr().rFonts.set(qn('w:eastAsia'),'微软雅黑')
        self.doc.core_properties.title='地铁1982 v13 · 全文案与分支校订本'
        self.doc.core_properties.subject='实际工程文案、触发条件、选项与后果、源码索引'
        self.doc.core_properties.author='地铁1982项目'
        footer=section.footer.paragraphs[0];footer.alignment=2;footer.add_run('地铁1982 · 文案校订本　|　')
        field=OxmlElement('w:fldSimple');field.set(qn('w:instr'),'PAGE');footer._p.append(field)
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
            elif key=='not':parts.extend('尚未满足 '+flag_name(x) for x in value)
            elif key=='items':parts.append('持有 '+'、'.join(ITEMS.get(x,[x])[0] for x in value))
            elif key=='goods':parts.extend('持有 '+GOODS.get(x,{'name':x})['name']+' ≥ '+str(n) for x,n in value.items())
            else:parts.append(key+'='+dump(value))
        return '；'.join(parts)
    def title_page(self):
        self.doc.add_heading('地铁1982',0);self.h('v13 全文案与分支校订本',1)
        self.p('导出日期：'+date.today().isoformat())
        self.p('本文件从当前工程数据与运行脚本导出，供逐项校正文字。章节中的稳定ID和文件路径用于把修改对应回游戏。')
        self.p('建议开启 Word 的“视图 → 导航窗格”，按章节、NPC、任务或ID定位。可用修订模式修改原文，或在其下添加批注；只修改本文档不会自动改变游戏。')
        self.h('怎样阅读触发条件',2)
        self.p('对话先显示对应交互对象的开场，再按条件替换为状态变化后的开场。替换规则按列出顺序执行，后满足的规则可以覆盖先前规则。只有有效条件下的选项能够执行。')
        self.p('all 表示全部状态成立，any 表示至少一项成立，not 表示这些状态尚未成立；items 表示背包条件，goods 表示数量条件。状态ID保留原名，附录中的状态索引说明其由哪些选择设置。')
        self.p('限次动作执行后会记录 c_done_动作ID，已完成选项不能重复领取奖励。已失败支线的动作不再允许执行。主线改道、已完成、支线失败分别显示，未接取的支线不进入任务列表。')
        self.p('旁白与台词：带「」的部分由当前NPC说出；带姓名前缀的台词使用该姓名。其余部分按旁白显示。图文过场有单独的说话者字段。动态数字和物品名以模板保留，文档不会虚构一次具体游玩的数值。')
        self.p('D-6的文本由多层规则组成：Story → Narrative → ResidentDialogue → D6Chapter → Campaign → Economy → Progression；后层可改写前层。第五章保留这些规则所在的函数、分支和原始条件，避免把旧默认文案误认为最终必定出现的句子。')
        self.p('覆盖范围：data 内全部JSON文字；scripts 内除注释外的中文／西里尔文字符串及可识别的界面英文、符号、数字标签；场景文本与工程标题。图像内没有字符串资源的装饰印刷，另列示例图与素材位置供校对。外部参考文档、测试断言、工具日志不混入文案。动态拼接片段保留原始语句。')
        self.h('故事路线定位',2)
        for route,nodes in [('征召离站','D-6登记与领取装备 → 地表行军与减员 → 水厂解谜、战斗及取滤芯 → 归途岔路选择'),('独自离站','取得防护装备 → 检修许可／侧门／管线等离站方式 → 结识谢尔盖 → 选择公社或谢契路线'),('公社','抵达登记 → 认识居民与生活生产 → 留下后仍可探索、完成信任任务 → 星城联络；安娜线可返回D-6煤运设施'),('谢契','抵达旧军列营地 → 供水、电台与居民委托 → 留下后继续建立信任 → 获得前往星城的途径'),('星城','隔离外线与身份核验 → 与父亲见面 → 完成交接工作 → 根据实际选择收束旅程')]:self.meta(route,nodes)
        self.p(f'索引共 {len(self.records)} 个文字来源；全部来源同时保存在 copy-index-v13.json，便于后续自动核对。')
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
            self.source('最终运行文本：Comic.panel；基础 Comic.PANELS / campaign.panels；覆盖 data/story_panels.json')
            self.meta('到达方式','；'.join(triggers.get(key,[])+incoming[key]) or '未发现静态入口；可能由参数调用进入，或属于保留版本。可按该ID全文检索核对。')
            if panel.get('location'):self.meta('地点',panel['location']);self.printed_text.add(panel['location'])
            if panel.get('art'):self.meta('配图素材','assets/cinematics/'+panel['art']+'.png')
            if 'lines' in panel:
                for line in panel['lines']:self.p(('旁白：' if line['speaker']=='旁白' else line['speaker']+'：')+line['text']);self.printed_text.add(line['text'])
            else:self.prose(panel.get('body',''))
            if panel.get('choices'):
                for i,choice in enumerate(panel['choices'],1):
                    self.p(f'选项{i}：'+choice['text']);self.printed_text.add(choice['text'])
                    self.meta('选中后','进入 '+choice['next']+('；设置 '+choice['flag']+'=true' if choice.get('flag') else ''))
                    extra={k:v for k,v in choice.items() if k not in ['text','next','flag']}
                    if extra:self.meta('其它条件或影响',dump(extra))
            elif panel.get('next'):self.meta('继续后','进入 '+panel['next'])
            if panel.get('end'):self.meta('本段结束','返回／前往 '+panel['end'])
            if panel.get('finish_flags'):self.meta('结束后设置',dump(panel['finish_flags']))
            if panel.get('same_moment'):self.meta('时间','发生于同一时刻，不推进故事日')
        self.h('结局与收束文本',2)
        for key,ending in CAMPAIGN['endings'].items():
            self.h(ending.get('title',key)+' 〔'+key+'〕',3)
            linked=[k for k,a in CAMPAIGN['actions'].items() if a.get('ending')==key]
            linked+=['过场 '+k for k,p in R['panels'].items() if p.get('end')=='ending:'+key]
            self.meta('触发','；'.join(linked) or '未发现当前动作或过场直接连接；作为已有保留文案列出，不保证目前可达。')
            for field,value in ending.items():
                if isinstance(value,str):self.meta(field,value);self.printed_text.add(value)
    def action(self,key):
        a=CAMPAIGN['actions'][key]
        self.h(a['text']+' 〔c_'+key+'〕',3);self.printed_text.add(a['text'])
        self.meta('可执行条件',self.condition(a.get('req',{})))
        self.meta('重复限制','完成一次后停用' if a.get('once',True) else '可重复；仍受当前状态限制')
        if a.get('offer_for'):
            self.meta('首次提出任务','尚未设置 '+a['offer_for']+' 时，还需 '+self.condition(a.get('offer_unlock',{})))
            if a.get('offer_busy'):self.meta('暂缓提出的情况','；'.join('已接 '+x[0]+' 且未完成 '+x[1] for x in a['offer_busy']))
        self.prose(a.get('reply',''))
        for field,label in [('flags','写入状态'),('give','获得任务物品'),('take','交出物品'),('goods','普通物资变化'),('reward','子弹报酬'),('travel','接续过场'),('ending','触发结局')]:
            if a.get(field):self.meta(label,dump(a[field]))
        rewards=[b for b in FILES['publications.json']['entries'] if b['source'].get('action')==key]
        for book in rewards:self.meta('新增刊物答谢',book.get('reward_reply','')+book['title'])
    def interactions(self):
        self.h('二、设施NPC、场景交互与选项')
        done=set()
        for floor in ['waterworks','commune','sech','coal','starcity','labor','life']:
            entries=[(k,v) for k,v in CAMPAIGN['interactions'].items() if v.get('facility')==floor]
            if not entries:continue
            self.h(FLOORS[floor],2)
            for key,v in entries:
                self.h(v['name']+' 〔'+key+'〕',2);self.printed_text.add(v['name']);self.printed_text.add(v.get('role',''))
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
    def items_books(self):
        self.h('四、物品、商店物资与刊物正文')
        self.h('任务物品、装备与纪念物',2)
        for key,v in ITEMS.items():
            self.h(v[0]+' 〔'+key+'〕',3);self.meta('类别',v[2]);self.prose(v[1]);self.printed_text.update(v)
        self.h('可购买／出售／使用的普通物资',2)
        for key,v in GOODS.items():
            self.h(v['name']+' 〔'+key+'〕',3);self.printed_text.add(v['name']);self.prose(v['detail'])
            self.meta('机制','售价 '+str(v['price'])+' 制式弹；库存 '+str(v['stock'])+'；效果 '+str(v.get('effect',''))+' '+str(v.get('amount',0)))
        self.h('可收集刊物：6系列、18册',2)
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
                if cover.exists():self.doc.add_picture(str(cover),width=Cm(1.7))
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
                    self.prose(r['text'])
                    self.meta('原始语句／动态拼接',r['expression'])
    def remaining_json(self):
        rows=[r for r in self.records if not r['source'].startswith('scripts/') and r['text'] not in self.printed_text]
        if not rows:return
        self.h('六、其余JSON文案与被覆盖的基础文本')
        self.p('这里列出尚未在正文出现的JSON文字。campaign.panels 与 story_panels.json 同节点的文本，以第一章运行解析后的版本为准；这里保留未生效的基础版本，便于清理历史文案。')
        for r in rows:self.source(r['source']+' · '+r.get('path',str(r.get('line',''))));self.prose(r['text'])
    def printed_art(self):
        self.h('附录、场景图内告示与印刷装饰')
        self.p('下列素材中的印刷、图表与装饰字直接画在图片里。这里保留缩略图、出现位置和路径，供你圈画校正；不把无法可靠识读的AI装饰字臆造为台词。书刊封面已在刊物章节逐册列出。')
        references=[('commune_poster_0','公社人民议事厅墙面：革命宣传画'),('commune_poster_1','公社食堂入口北墙：生产与生活宣传画'),('plant_pump_chart','水厂西侧泵房北墙：泵组检修图'),('plant_roster_chart','水厂交接档案室北墙：旧值班表'),('plant_safety_chart','水厂档案室与入口气闸：安全告示'),('plant_tool_board','水厂工具修配间北墙：工具板'),('plant_electric_warning','水厂送电控制柜正面：高压警告'),('plant_filter_label','水厂封存仓库木箱正面：滤芯装箱标签')]
        for asset,place in references:
            path=ROOT/'assets/visual'/(asset+'.png')
            if not path.exists():continue
            self.h(place,3);self.meta('显示条件','进入相应场景即可看到；固定场景装饰，不需接任务')
            self.source(str(path.relative_to(ROOT)));self.doc.add_picture(str(path),width=Cm(4.0))
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
        self.title_page();self.panels();self.interactions();self.quests();self.items_books();self.d6_constants();self.remaining_json();self.printed_art();self.states();self.repeated_sources()
        # Exact source coverage, independent of how duplicate sentences are laid out.
        missing=[r for r in self.records if r['text'] not in self.printed_text]
        assert not missing,[(r['id'],r['text'][:50]) for r in missing]
        document=OUT/'地铁1982-v13-全文案与分支校订本.docx';self.doc.save(document)
        index={'version':13,'source_files':{},'records':self.records,'coverage':{'total':len(self.records),'missing':len(missing)}}
        for source in sorted({r['source'] for r in self.records}):index['source_files'][source]=hashlib.sha256((ROOT/source).read_bytes()).hexdigest()
        (OUT/'copy-index-v13.json').write_text(json.dumps(index,ensure_ascii=False,indent=2)+'\n')
        print(json.dumps({'document':str(document),'bytes':document.stat().st_size,'source_records':len(self.records),'missing':0,'paragraphs':len(self.doc.paragraphs)},ensure_ascii=False))

if __name__=='__main__':Exporter().finish()
