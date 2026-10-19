from pathlib import Path
from PIL import Image,ImageDraw
import numpy as np,json,hashlib,shutil
root=Path('/workspace/ivan-motion-review');out=Path(__file__).parent;base=root/'base-motion-03'
for f in ['standing','steps','calibrated-preview','comparison','loops']:(out/f).mkdir(exist_ok=True)
for folder in ['standing','steps']:
 for p in (base/folder).glob('*.png'):shutil.copyfile(p,out/folder/p.name)
# Existing targeted patch supplies correctly registered old candidate; no new drawing.
shutil.copyfile(root/'rear-contact-patch-04/steps/04-back-right-B.png',out/'steps/04-back-right-B.png')
def lin(v):return np.where(v<=.04045,v/12.92,((v+.055)/1.055)**2.4)
def srgb(v):return np.where(v<=.0031308,v*12.92,1.055*np.maximum(v,0)**(1/2.4)-.055)
def med(a,b):
 x,y,X,Y=b;r=a[y:Y,x:X];p=r[:,:,:3][r[:,:,3]>250]/255.;return np.median(lin(p),axis=0)
records={}
for key,coat,pants in [('06-back-left',(145,150,190,250),(125,355,290,390)),('04-back-right',(180,150,220,250),(95,355,240,390))]:
 ims=[Image.open(out/'standing'/f'{key}.png').convert('RGBA')]+[Image.open(out/'steps'/f'{key}-{p}.png').convert('RGBA') for p in ['A','B']]
 ref=np.asarray(ims[0]);corrected=[ims[0]];records[key]={}
 for phase,im in zip(['A','B'],ims[1:]):
  a=np.asarray(im);g1=np.clip(med(ref,coat)/np.maximum(med(a,coat),.005),.65,1.55);g2=np.clip(med(ref,pants)/np.maximum(med(a,pants),.005),.65,1.55)
  t=np.clip((np.arange(512)-315)/30,0,1);t=t*t*(3-2*t);gain=g1[None,None,:]*(1-t[:,None,None])+g2[None,None,:]*t[:,None,None]
  b=a.copy();b[:,:,:3]=np.rint(np.clip(srgb(lin(a[:,:,:3]/255.)*gain),0,1)*255).astype('uint8');assert np.array_equal(a[:,:,3],b[:,:,3]);ci=Image.fromarray(b);ci.save(out/'calibrated-preview'/f'{key}-{phase}.png');corrected.append(ci);records[key][phase]={'coat_gain':g1.tolist(),'pants_gain':g2.tolist(),'alpha_unchanged':True}
 board=Image.new('RGB',(1152,1080),(65,62,58));d=ImageDraw.Draw(board)
 for row,seq in enumerate([ims,corrected]):
  for col,(label,im) in enumerate(zip(['standing','A','B'],seq)):
   x=384*col;y=540*row;d.text((x+8,y+8),key+' '+label+(' raw' if row==0 else ' color preview'),fill='white');board.paste(im,(x,y+28),im)
 board.save(out/'comparison'/f'{key}.jpg')
 # A single palette per GIF, avoiding quantization flicker from separate palettes.
 for label,seq in [('raw',ims),('color',corrected)]:
  frames=[]
  for i in [1,0,2,0]:
   bg=Image.new('RGB',(384,512),(65,62,58));bg.paste(seq[i],(0,0),seq[i]);frames.append(bg)
  palette=Image.new('RGB',(384*4,512))
  for i,f in enumerate(frames):palette.paste(f,(384*i,0))
  palette=palette.quantize(colors=255)
  ff=[f.quantize(palette=palette,dither=Image.Dither.NONE) for f in frames]
  ff[0].save(out/'loops'/f'{key}-{label}.gif',save_all=True,append_images=ff[1:],duration=[180,120,180,120],loop=0,disposal=2)
unchanged=[]
for folder in ['standing','steps']:
 for p in (base/folder).glob('*.png'):
  if folder=='steps' and p.stem in ['06-back-left-A','04-back-right-B']:continue
  assert p.read_bytes()==(out/folder/p.name).read_bytes();unchanged.append(folder+'/'+p.name)
assert len(unchanged)==22
(out/'verification.json').write_text(json.dumps({'approved_files_unchanged':unchanged,'count':22,'new_ai_generations':0,'gait_approved':False,'color_preview_only':records},indent=2))
print('22 approved files unchanged; historical candidates only; alpha preserved')
