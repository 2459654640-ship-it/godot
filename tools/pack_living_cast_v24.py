"""Pack whole AI-authored walks around the unchanged standing rows.

Supply --sources with anna_a.png / anna_b.png / anna_fb.png / anna_back.png,
moro_a.png / moro_b.png / moro_front.png. A sheets are 5x2 (row 0 used),
B sheets 5x1; Anna front/back correction is 2x1, Moro correction 1x1.
No limb reconstruction, mirroring or mesh deformation is used here.
"""
import argparse,json
from pathlib import Path
import numpy as np
from PIL import Image,ImageDraw
from pack_painted_assets import crop_cell
ROOT=Path(__file__).resolve().parents[1]
a=argparse.ArgumentParser();a.add_argument('--sources',type=Path,required=True);a.add_argument('--review',type=Path,required=True);opt=a.parse_args();opt.review.mkdir(parents=True,exist_ok=True)
manifest=json.loads((ROOT/'assets/characters/atlas.json').read_text());metrics={}
for id,prefix in [('anna','anna'),('commune_moro','moro')]:
 meta=manifest[id];cw,ch=map(int,meta['cell']);original=Image.open(ROOT/'assets/characters'/meta['file']).convert('RGBA').crop((0,0,cw*5,ch))
 sheet_a=Image.open(opt.sources/(prefix+'_a.png')).convert('RGBA');sheet_b=Image.open(opt.sources/(prefix+'_b.png')).convert('RGBA')
 correction=Image.open(opt.sources/('anna_fb.png' if id=='anna' else 'moro_front.png')).convert('RGBA')
 result=Image.new('RGBA',(cw*5,ch*3));result.paste(original,(0,0));rows=[]
 for row in range(2):
  for col in range(5):
   tile=crop_cell(sheet_a,col,0,5,2) if row==0 else crop_cell(sheet_b,col,0,5,1)
   if row==1 and col==0:tile=crop_cell(correction,0,0,2 if id=='anna' else 1,1)
   if row==1 and col==4 and id=='anna':tile=crop_cell(Image.open(opt.sources/'anna_back.png').convert('RGBA'),0,0,1,1)
   # One proportional transform of the entire painted figure; feet share baseline 342.
   scale=324/tile.height;tile=tile.resize((round(tile.width*scale),324),Image.Resampling.LANCZOS)
   arr=np.array(tile);mask=arr[:,:,3]>100;yy,xx=np.where(mask[:55]);anchor=float(xx.mean())
   ref=np.array(original.crop((cw*col,0,cw*(col+1),ch)));rm=ref[:,:,3]>100
   # Match diffuse costume tone in a stable central torso region, not moving hands/feet.
   def tone(rgb,alpha,cx,y0,y1):
    ys,xs=np.indices(alpha.shape);valid=alpha&(ys>=y0)&(ys<y1)&(np.abs(xs-cx)<22)
    return np.median(rgb[valid,:3],axis=0)
   target=tone(ref,rm,cw/2,95,180);current=tone(arr,mask,anchor,77,162)
   gain=np.clip(target/np.maximum(current,1),.90,1.10)
   arr[:,:,:3]=np.clip(arr[:,:,:3].astype(float)*gain,0,255).astype('uint8');tile=Image.fromarray(arr)
   x=round(cw/2-anchor)
   if x<2 or x+tile.width>cw-2:raise ValueError((id,row,col,'sprite would crop',x,tile.size))
   result.alpha_composite(tile,(cw*col+x,ch*(row+1)+18));rows.append({'pose':row+1,'angle':col,'whole_figure_gain':gain.tolist(),'head_anchor':anchor})
 result.save(ROOT/'assets/characters'/meta['file'],optimize=True)
 assert np.array_equal(np.array(result.crop((0,0,cw*5,ch))),np.array(original))
 meta.update(poses=3,clips=['idle','walk_a','walk_b'],packing_revision=24,exposure=[[1]*5 for _ in range(3)],frame_mirror=[[False]*5 for _ in range(3)])
 metrics[id]=rows
 # Opaque review contact sheet and four-beat full-size GIF; runtime PNGs stay transparent.
 background=Image.new('RGBA',result.size,'#3d4037');background.alpha_composite(result);background.convert('RGB').save(opt.review/(id+'-walks.jpg'),quality=92)
 for angle in [0,1,2,3,4]:
  frames=[]
  for pose in [1,0,2,0]:
   canvas=Image.new('RGBA',(cw,ch),'#3d4037');canvas.alpha_composite(result.crop((cw*angle,ch*pose,cw*(angle+1),ch*(pose+1))));frames.append(canvas.convert('RGB'))
  frames[0].save(opt.review/(id+'-'+str(angle)+'.gif'),save_all=True,append_images=frames[1:],duration=170,loop=0)
(ROOT/'assets/characters/atlas.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n')
(opt.review/'packing-metrics.json').write_text(json.dumps(metrics,indent=2)+'\n')
