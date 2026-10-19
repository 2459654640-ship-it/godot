"""Compile the V3-referenced eight-view redraw into fixed-scale production atlases.

Input art is painted with imagegen, never produced by mirroring a walking pose.
Registration locks the head and sole baseline, limiting width registration
to three percent against ONE standing
master. Weapon upper-body drawings share the very same authored lower-body gait.
Raw art and the generation brief are kept in the independent reference branch.
"""
from pathlib import Path
import argparse,json,hashlib
import numpy as np
from PIL import Image,ImageFilter
from pack_painted_assets import crop_cell
ROOT=Path(__file__).resolve().parents[1]
W,H=280,352

def core_width(im):
 a=np.asarray(im)[:,:,3]>100;values=[]
 for y in range(152,183):
  row=a[y];x=140
  if not row[x]:continue
  lo=x;hi=x
  while lo>0 and row[lo-1]:lo-=1
  while hi<279 and row[hi+1]:hi+=1
  if hi-lo>25:values.append(hi-lo+1)
 return float(np.percentile(values,20)) if values else 85.0

def registered(source,col,row,columns,rows,reference):
 crop=crop_cell(source,col,row,columns,rows)
 scale=324/crop.height;crop=crop.resize((round(crop.width*scale),324),Image.Resampling.LANCZOS)
 a=np.asarray(crop);_,xs=np.where(a[:48,:,3]>100);cx=float(xs.mean())
 cell=Image.new('RGBA',(W,H));cell.alpha_composite(crop,(round(W*.5-cx),18))
 ratio=float(np.clip(core_width(reference)/core_width(cell),.97,1.03))
 # All anatomy, hands and boots use one registration transform; the common
 # head is then restored so no pose can grow a different face/hair silhouette.
 resized=cell.resize((round(W*ratio),H),Image.Resampling.LANCZOS)
 out=Image.new('RGBA',(W,H));out.alpha_composite(resized,((W-resized.width)//2,0))
 return out,ratio

def upper_lower(upper,lower,split=238):
 # Constant upper body while holding/reloading; all eight angles use the
 # same three real painted leg poses as the unarmed player.
 mask=Image.new('L',(W,H));a=np.zeros((H,W),dtype=np.uint8)
 for y in range(H):a[y,:]=round(255*np.clip((split+3-y)/6,0,1))
 return Image.composite(upper,lower,Image.fromarray(a))

def head_lock(frame,head,cut=96):
 out=frame.copy();out.paste(head.crop((96,0,184,84)),(96,0));return out

def masked_head(frame,head):
 a=np.zeros((H,W),dtype=np.uint8);a[:91,96:184]=255
 # Include filter and straps below the face without replacing chest-level arms.
 yy,xx=np.mgrid[0:H,0:W];ellipse=((xx-140)/48)**2+((yy-91)/28)**2<1
 a[ellipse & (yy<119)]=255
 return Image.composite(head,frame,Image.fromarray(a).filter(ImageFilter.GaussianBlur(.5)))

def pack(sources,report_path):
 master=Image.open(sources/'standing.png').convert('RGBA')
 idle=[master.crop((i%4*W,i//4*H,(i%4+1)*W,(i//4+1)*H)) for i in range(8)]
 sheets={n:Image.open(sources/(n+'.png')).convert('RGBA') for n in ['walk_left','walk_right','masked','armed','reload']}
 art={};report={'reference_commit':'057fff3','source_angles':8,'fixed_baseline':342,'source_sha256':{},'registration':{}}
 for n,im in sheets.items():
  report['source_sha256'][n]=hashlib.sha256((sources/(n+'.png')).read_bytes()).hexdigest()
  art[n]=[];report['registration'][n]=[]
  for i in range(8):
   cell,ratio=registered(im,i%4,i//4,4,2,idle[i]);art[n].append(cell);report['registration'][n].append(round(ratio,4))
 left=[head_lock(art['walk_left'][i],idle[i]) for i in range(8)]
 right=[head_lock(art['walk_right'][i],idle[i]) for i in range(8)]
 body=[idle,left,right]
 masked=[[masked_head(row[i],art['masked'][i]) for i in range(8)] for row in body]
 ready=[head_lock(art['armed'][i],idle[i]) for i in range(8)]
 reload=[head_lock(art['reload'][i],idle[i]) for i in range(8)]
 masked_ready=[];masked_reload=[]
 for i in range(8):
  # The mask is the same head throughout every action, including reloading.
  masked_ready.append(masked_head(ready[i],art['masked'][i]));masked_reload.append(masked_head(reload[i],art['masked'][i]))
 def combat(ready,reload):
  pairs=[(ready,idle),(ready,idle),(reload,idle),(ready,left),(ready,right),(reload,left),(reload,right)]
  return [[upper_lower(u[i],l[i]) for i in range(8)] for u,l in pairs]
 atlases={'ivan':body,'ivan_masked':masked,'ivan_combat':combat(ready,reload),'ivan_masked_combat':combat(masked_ready,masked_reload)}
 path=ROOT/'assets/characters/atlas.json';manifest=json.loads(path.read_text())
 for actor,rows in atlases.items():
  width=400 if actor.endswith('combat') else W
  atlas=Image.new('RGBA',(width*8,H*len(rows)))
  for p,row in enumerate(rows):
   for d,cell in enumerate(row):atlas.alpha_composite(cell,(d*width+(width-W)//2,p*H))
  atlas.save(ROOT/'assets/characters'/f'{actor}.png',optimize=True)
  clips=['idle','walk_left','walk_right'] if len(rows)==3 else ['ready','shot','reload','walk_left','walk_right','reload_walk_left','reload_walk_right']
  manifest[actor]={'file':actor+'.png','directions':8,'source_angles':8,'poses':len(rows),'cell':[width,H],'baseline':342,'body_pixels':324,'clips':clips,'packing_revision':18,'reference_commit':'057fff3','exposure':[[1.0]*8 for _ in rows],'frame_mirror':[[False]*8 for _ in rows]}
  report[actor]={'head_identical_during_walk':all(np.array_equal(np.asarray(rows[p][i])[:80,102:178],np.asarray(rows[0][i])[:80,102:178]) for p in ([1,2] if len(rows)==3 else [3,4]) for i in range(8)),'waist_widths':[[round(core_width(c),1) for c in row] for row in rows]}
 path.write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n')
 for actor,row in [('ivan',idle),('ivan_masked',masked[0])]:
  face=row[0].crop((55,10,225,150));face.thumbnail((224,264),Image.Resampling.LANCZOS)
  canvas=Image.new('RGBA',(240,280));canvas.alpha_composite(face,((240-face.width)//2,280-face.height));canvas.save(ROOT/'assets/portraits'/f'{actor}.png')
 report_path.write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n')
 print(json.dumps({k:v for k,v in report.items() if k in atlases},ensure_ascii=False))
if __name__=='__main__':
 parser=argparse.ArgumentParser();parser.add_argument('--sources',type=Path,required=True);parser.add_argument('--report',type=Path,required=True);args=parser.parse_args();pack(args.sources,args.report)
