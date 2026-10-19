from pathlib import Path
from PIL import Image,ImageDraw
import numpy as np,json,hashlib,shutil,base64
root=Path('/workspace/ivan-motion-review');out=Path(__file__).parent;base=root/'base-motion-03'
sources={'06-back-left-A':'exec-969c4421-58d7-4733-b96d-4250f31adb3f.png','04-back-right-B':'exec-df1966ef-18cc-4452-8fa1-45074d32d7b2.png'}
for f in ['standing','steps','raw-selected','aligned-before-color','comparison','loops']:(out/f).mkdir(exist_ok=True)
for folder in ['standing','steps']:
 for p in (base/folder).glob('*.png'):shutil.copyfile(p,out/folder/p.name)
def anchor(im):
 a=np.asarray(im.getchannel('A'));yy,xx=np.where(a>250);top=int(yy.min());height=int(yy.max()+1-top);head=np.where((a>250)&(np.indices(a.shape)[0]<top+height*.14))[1];return top,height,float(head.mean())
transforms={}
for name,filename in sources.items():
 key=name[:-2];source=Path('/workspace/generated_images')/filename;shutil.copyfile(source,out/'raw-selected'/f'{name}.png');im=Image.open(source).convert('RGBA');ref=Image.open(out/'standing'/f'{key}.png').convert('RGBA');top,height,hx=anchor(im);rt,rh,rx=anchor(ref);scale=rh/height;x=round(rx-hx*scale);y=round(rt-top*scale);canvas=Image.new('RGBA',(384,512));canvas.alpha_composite(im.resize((round(im.width*scale),round(im.height*scale)),Image.Resampling.LANCZOS),(x,y));canvas.save(out/'aligned-before-color'/f'{name}.png');canvas.save(out/'steps'/f'{name}.png');transforms[name]={'source':filename,'reference':'eight-single-views/'+key+'.png','uniform_scale':scale,'translation':[x,y],'method':'whole-figure scale to original standing extent; head top and centroid alignment; no local deformation'}
def lin(v):return np.where(v<=.04045,v/12.92,((v+.055)/1.055)**2.4)
def srgb(v):return np.where(v<=.0031308,v*12.92,1.055*np.maximum(v,0)**(1/2.4)-.055)
def med(a,b):
 x,y,X,Y=b;r=a[y:Y,x:X];p=r[:,:,:3][r[:,:,3]>250]/255.;assert len(p)>100;return np.median(lin(p),axis=0)
records={};assets={}
for key,coat,pants in [('06-back-left',(145,150,190,250),(125,355,290,390)),('04-back-right',(180,150,220,250),(95,355,240,390))]:
 ims=[Image.open(out/'standing'/f'{key}.png').convert('RGBA')]+[Image.open(out/'steps'/f'{key}-{p}.png').convert('RGBA') for p in ['A','B']];ref=np.asarray(ims[0]);corrected=[ims[0]];records[key]={'frames':{}};assets[key]={}
 for phase,im in zip(['standing','A','B'],ims):
  a=np.asarray(im);changed=key+'-'+phase in sources
  g1=np.clip(med(ref,coat)/np.maximum(med(a,coat),.005),.65,1.55) if changed else np.ones(3);g2=np.clip(med(ref,pants)/np.maximum(med(a,pants),.005),.65,1.55) if changed else np.ones(3)
  if key=='04-back-right':g1=np.ones(3) # coat already matches; avoid worsening the independent holdout
  records[key]['frames'][phase]={'linear_rgb_gains':{'coat':g1.tolist(),'pants':g2.tolist()},'new_frame':changed};path=(out/'standing'/f'{key}.png') if phase=='standing' else out/'aligned-before-color'/f'{key}-{phase}.png'
  if not path.exists():path=out/'steps'/f'{key}-{phase}.png'
  assets[key][phase]='data:image/png;base64,'+base64.b64encode(path.read_bytes()).decode()
  if phase=='standing':continue
  if changed:
   t=np.clip((np.arange(512)-315)/30,0,1);t=t*t*(3-2*t);gain=g1[None,None,:]*(1-t[:,None,None])+g2[None,None,:]*t[:,None,None];b=a.copy();b[:,:,:3]=np.rint(np.clip(srgb(lin(a[:,:,:3]/255.)*gain),0,1)*255).astype('uint8');assert np.array_equal(a[:,:,3],b[:,:,3]);ci=Image.fromarray(b);ci.save(out/'steps'/f'{key}-{phase}.png')
  else:ci=im
  corrected.append(ci)
 board=Image.new('RGB',(1152,1080),(65,62,58));d=ImageDraw.Draw(board)
 for row,seq in enumerate([ims,corrected]):
  for col,(label,im) in enumerate(zip(['standing','A','B'],seq)):
   x=384*col;y=540*row;d.text((x+8,y+8),key+' '+label+(' before color' if row==0 else ' new frames color matched'),fill='white');board.paste(im,(x,y+28),im)
 board.save(out/'comparison'/f'{key}.jpg')
 for label,seq in [('before-color',ims),('color-matched',corrected)]:
  frames=[]
  for i in [1,0,2,0]:
   bg=Image.new('RGB',(384,512),(65,62,58));bg.paste(seq[i],(0,0),seq[i]);frames.append(bg)
  palette=Image.new('RGB',(1536,512))
  for i,f in enumerate(frames):palette.paste(f,(384*i,0))
  palette=palette.quantize(colors=255);ff=[f.quantize(palette=palette,dither=Image.Dither.NONE) for f in frames];ff[0].save(out/'loops'/f'{key}-{label}.gif',save_all=True,append_images=ff[1:],duration=[180,120,180,120],loop=0,disposal=2)
unchanged={}
for folder in ['standing','steps']:
 for p in (base/folder).glob('*.png'):
  if folder=='steps' and p.stem in sources:continue
  assert p.read_bytes()==(out/folder/p.name).read_bytes();unchanged[folder+'/'+p.name]=hashlib.sha256(p.read_bytes()).hexdigest()
assert len(unchanged)==22
(out/'verification.json').write_text(json.dumps({'approved_files_unchanged':unchanged,'count':22,'generation_count':5,'selected_new_frames':transforms,'game_modified':False,'status':'two new near-leg-forward candidates; visual user review pending','color':records},indent=2))
template=(root/'tone-calibration-lab-06/preview-template.html').read_text().replace('伊万色调校准验证','伊万后斜方向新迈步稿').replace('只验证色调处理。步幅不一致与腿部动作仍未通过，本页不代表人物动画已修好，也未修改游戏素材。','两张新候选：左后 A、右后 B。等待审阅，未放入游戏。其余 22 张原图保持不变。').replace('同一批旧候选','本次新候选与已认可的另一步').replace('校准前：旧候选','新帧调色前（另一步保留）').replace('校准后：同帧、同姿态','仅新帧调色后').replace('在衣服与裤子的固定采样区域估计每帧线性 RGB 增益','在衣服与裤子的固定采样区域估计两张新帧的线性 RGB 增益；站姿和已认可的另一步不调色')
template=template.replace('__DATA__',json.dumps({'records':records,'assets':assets},separators=(',',':')));(out/'preview.html').write_text(template)
print('22 approved files byte-identical; only two new frames color corrected; alpha unchanged')
