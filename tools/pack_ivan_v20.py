"""Pack approved Ivan gait with authored equipment layers. No leg reshaping/mirroring.
Run: python tools/pack_ivan_v20.py [--review /tmp/ivan-v20]
Sources are retained in art-source/v20; only Ivan runtime atlases are rebuilt.
"""
from pathlib import Path
from PIL import Image,ImageDraw,ImageFilter
import numpy as np,json,argparse,hashlib
from scipy import ndimage
ROOT=Path(__file__).resolve().parents[1];SRC=ROOT/'art-source/v20';BASE=SRC/'base'
parser=argparse.ArgumentParser();parser.add_argument('--review',type=Path,default=Path('/tmp/ivan-v20'));args=parser.parse_args();REVIEW=args.review;REVIEW.mkdir(parents=True,exist_ok=True)
KEYS=[p.stem.removesuffix('-standing') for p in sorted(BASE.glob('*-standing.png'))]
POLYGONS=[[(229,43),(261,43),(275,57),(277,83),(265,99),(267,119),(250,128),(230,118),(228,100),(217,83),(216,61)],[(225,43),(248,44),(255,57),(259,77),(277,85),(286,98),(278,119),(262,129),(246,111),(225,94),(210,80),(210,61)],[(181,47),(201,47),(213,61),(215,81),(228,93),(228,117),(214,126),(197,112),(183,91),(162,83),(157,69),(159,58),(177,57)],[(129,64),(166,64),(180,71),(188,86),(198,91),(204,108),(192,120),(180,112),(171,93),(150,89),(135,84)],[(205,54),(274,54),(274,73),(262,77),(215,77),(205,69)],[(164,53),(180,54),(208,59),(240,56),(242,70),(218,79),(192,80),(182,89),(177,105),(159,113),(148,103),(150,85),(165,75)],[(144,45),(165,48),(179,55),(201,54),(207,67),(197,81),(173,86),(162,95),(153,110),(137,120),(121,108),(122,90),(136,81),(137,61)],[(131,41),(152,43),(165,55),(166,79),(155,96),(145,105),(142,120),(123,129),(107,116),(108,99),(119,87),(119,63)]]
def anchor(im):
 a=np.asarray(im.getchannel('A'));ys,xs=np.where(a>250);top=int(ys.min());h=int(ys.max()+1-top);head=np.where((a>250)&(np.indices(a.shape)[0]<top+h*.14))[1];return top,h,float(head.mean())
def smooth(t):t=np.clip(t,0,1);return t*t*(3-2*t)
def lin(v):return np.where(v<=.04045,v/12.92,((v+.055)/1.055)**2.4)
def srgb(v):return np.where(v<=.0031308,v*12.92,1.055*np.maximum(v,0)**(1/2.4)-.055)
def tone(im,ref):
 a=np.array(im);b=np.array(ref);mask=(a[:,:,3]>250)&(b[:,:,3]>250);roi=np.zeros(mask.shape,bool);roi[140:230]=True;mask&=roi;g=np.clip(np.median(lin(b[:,:,:3][mask]/255),axis=0)/np.maximum(np.median(lin(a[:,:,:3][mask]/255),axis=0),.005),.9,1.1);a[:,:,:3]=np.rint(np.clip(srgb(lin(a[:,:,:3]/255)*g),0,1)*255).astype('uint8');return Image.fromarray(a)
sheets={name:Image.open(SRC/(name+'-source.png')).convert('RGBA') for name in ['mask','ready','reload']};normal=[];masked=[];armed=[];masked_armed=[];layers={};stats={}
for n,key in enumerate(KEYS):
 frames=[Image.open(BASE/f'{key}-{phase}.png').convert('RGBA') for phase in ['standing','A','B']];ref=frames[0];rt,rh,rx=anchor(ref);equipment={}
 for name,sheet in sheets.items():
  W,H=sheet.size;c=n%4;r=n//4;tile=sheet.crop((c*W//4,r*H//2,(c+1)*W//4,(r+1)*H//2));t,h,x=anchor(tile);scale=rh/h*(1 if name=='mask' else 1.035);dest=Image.new('RGBA',(384,512));dest.alpha_composite(tile.resize((round(tile.width*scale),round(tile.height*scale)),Image.Resampling.LANCZOS),(round(rx-x*scale),round(rt-t*scale)));equipment[name]=dest if name=='mask' else tone(dest,ref)
 mask=Image.new('L',(384,512));ImageDraw.Draw(mask).polygon(POLYGONS[n],fill=255);a=np.array(equipment['mask']);a[:,:,3]=np.minimum(a[:,:,3],np.array(mask));masklayer=Image.fromarray(a);masklayer.save(REVIEW/f'{key}-mask-layer.png');layers[key]=masklayer
 def add_mask(im,phase):
  t,h,x=anchor(frames[phase]);delta=(round(x-rx),t-rt);result=im.copy();result.alpha_composite(masklayer,delta);return result
 def upper(im,kind,phase):
  a=np.array(im);b=np.array(equipment[kind]);out=a.copy();out[103:270]=b[103:270]
  w=smooth(np.arange(16)/15)[:,None,None];out[87:103]=np.rint(a[87:103]*(1-w)+b[87:103]*w).astype('uint8')
  # Detect the original bare hands by their warm skin hue, not by trouser
  # shadows. Only real hand-sized components are replaced, including cuffs.
  yy=np.indices((512,384))[0];rgb=a[:,:,:3].astype(float);skin=(yy>240)&(yy<335)&(rgb[:,:,0]>rgb[:,:,1]*1.45)&((rgb[:,:,0]-rgb[:,:,1])>20)&(a[:,:,3]>200)
  labels,count=ndimage.label(skin)
  for i,sl in enumerate(ndimage.find_objects(labels)):
   if (labels[sl]==i+1).sum()<50:continue
   x0=max(0,sl[1].start-5);x1=min(384,sl[1].stop+5);y0=max(270,sl[0].start-25);y1=min(340,sl[0].stop+4)
   if y1>y0:out[y0:y1,x0:x1]=b[y0:y1,x0:x1]
  # This approved contact frame has a longer lowered-arm coat hem. Use the
  # authored equipment hip beneath it, so the gun pose cannot show two hems.
  if n==5 and phase==1:out[286:311,145:295]=b[286:311,145:295]
  # The authored equipment coat goes OVER the gait. Its standing trousers
  # never enter the walking sprite. Missing mask pixels reveal the original
  # complete drawing, rather than creating holes at the hip.
  layer=b.copy();coat=(b[:,:,0].astype(float)>b[:,:,2]*1.32)&(b[:,:,1].astype(float)>b[:,:,2]*1.18)
  layer[:270]=0;layer[330:]=0;layer[~coat,3]=0;result=Image.fromarray(out);result.alpha_composite(Image.fromarray(layer));final=np.array(result);final[:87]=a[:87];final[340:]=a[340:]
  return Image.fromarray(final)

 ns=frames;ms=[add_mask(im,i) for i,im in enumerate(ns)];ready=[upper(im,'ready',i) for i,im in enumerate(frames)];reload=[upper(im,'reload',i) for i,im in enumerate(frames)];ars=[ready[0],ready[0],reload[0],ready[1],ready[2],reload[1],reload[2]];phase_indices=[0,0,0,1,2,1,2];mars=[add_mask(im,phase_indices[i]) for i,im in enumerate(ars)]
 for seq in [ready,reload]:
  for i,im in enumerate(seq):assert np.array_equal(np.array(im)[340:],np.array(frames[i])[340:]),'lower gait altered'
 for i,im in enumerate(ms):assert np.array_equal(np.array(im)[140:],np.array(frames[i])[140:]),'mask altered body'
 normal.append(ns);masked.append(ms);armed.append(ars);masked_armed.append(mars)
 stats[key]={'mask_does_not_change_body_below_y':140,'armed_lower_gait_unchanged_below_y':340,'reference_extent':rh,'body_anchors':[rt,rx]}
 for name,seq in [('normal',ns),('masked',ms),('armed',ready),('masked-armed',[mars[i] for i in [0,3,4]]),('reload',reload)]:
  board=Image.new('RGB',(1152,540),(65,62,58));draw=ImageDraw.Draw(board)
  for i,im in enumerate(seq):board.paste(im,(384*i,28),im);draw.text((384*i+8,8),key+' '+name+' '+['standing','A','B'][i],fill='white')
  board.save(REVIEW/f'{key}-{name}.jpg')
  fs=[]
  for i in [1,0,2,0]:
   bg=Image.new('RGB',(384,512),(65,62,58));bg.paste(seq[i],(0,0),seq[i]);fs.append(bg)
  pal=Image.new('RGB',(1536,512))
  for i,f in enumerate(fs):pal.paste(f,(384*i,0))
  pal=pal.quantize(colors=255);ff=[f.quantize(palette=pal,dither=Image.Dither.NONE) for f in fs];ff[0].save(REVIEW/f'{key}-{name}.gif',save_all=True,append_images=ff[1:],duration=[180,120,180,120],loop=0,disposal=2)
manifest=json.loads((ROOT/'assets/characters/atlas.json').read_text())
for actor,views in [('ivan',normal),('ivan_masked',masked),('ivan_combat',armed),('ivan_masked_combat',masked_armed)]:
 cw,ch=(384,352) if 'combat' in actor else (280,352);poses=len(views[0]);atlas=Image.new('RGBA',(cw*8,ch*poses))
 for n,seq in enumerate(views):
  rt,rh,rx=anchor(normal[n][0]);scale=324/rh;dx=round(cw/2-rx*scale);dy=round(18-rt*scale)
  for row,im in enumerate(seq):
   tile=Image.new('RGBA',(cw,ch));tile.alpha_composite(im.resize((round(im.width*scale),round(im.height*scale)),Image.Resampling.LANCZOS),(dx,dy));a=np.array(tile.getchannel('A'));assert a[:2].max()<100 and a[:,-2:].max()<100 and a[:,:2].max()<100,(actor,n,row,'clipped');atlas.alpha_composite(tile,(n*cw,row*ch))
 atlas.save(ROOT/'assets/characters'/f'{actor}.png',optimize=True)
 manifest[actor]={'file':actor+'.png','directions':8,'source_angles':8,'poses':poses,'cell':[cw,ch],'baseline':342,'body_pixels':324,'clips':['ready','recoil','reload','walk_left','walk_right','reload_walk_left','reload_walk_right'] if poses==7 else ['idle','walk_left','walk_right'],'packing_revision':20,'reference_commit':'057fff3','approved_motion_review':'98c86c37e5b2e6d9825365ee3f10d71efb90acd1','equipment_layered':True,'frame_mirror':[[False]*8 for _ in range(poses)],'exposure':[[1.0]*8 for _ in range(poses)]}
(ROOT/'assets/characters/atlas.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n');(REVIEW/'verification.json').write_text(json.dumps(stats,indent=2));print('Packed four Ivan atlases; 8 directions; base gait retained in all outfits, including moving reload.')
