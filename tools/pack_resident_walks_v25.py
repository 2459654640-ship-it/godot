"""Pack full AI-painted walks around unchanged standing art; no limb splicing.
Whole figures are scaled uniformly, head-anchored and gently colour-matched.
"""
import argparse,json,sys
from pathlib import Path
import numpy as np
from PIL import Image
from pack_painted_assets import crop_cell
ROOT=Path(__file__).resolve().parents[1]
p=argparse.ArgumentParser();p.add_argument('--sources',type=Path,required=True);p.add_argument('--review',type=Path,required=True);a=p.parse_args();a.review.mkdir(parents=True,exist_ok=True)
m=json.loads((ROOT/'assets/characters/atlas.json').read_text());report={}
for id in ['ambient_worker','ambient_woman']:
 meta=m[id];cw,ch=map(int,meta['cell']);standing=Image.open(ROOT/'assets/characters'/meta['file']).convert('RGBA').crop((0,0,cw*5,ch));source=Image.open(a.sources/(id+'.png')).convert('RGBA');result=Image.new('RGBA',(cw*5,ch*3));result.paste(standing,(0,0));stats=[]
 for row in range(2):
  for col in range(5):
   tile=crop_cell(source,col,row,5,2);scale=324/tile.height;tile=tile.resize((round(tile.width*scale),324),Image.Resampling.LANCZOS)
   arr=np.array(tile);alpha=arr[:,:,3]>100;ys,xs=np.where(alpha[:52]);anchor=xs.mean()
   ref=np.array(standing.crop((col*cw,0,(col+1)*cw,ch)));mask=ref[:,:,3]>100
   def tone(rgb,valid,x,y0,y1):
    yy,xx=np.indices(valid.shape);region=valid&(yy>=y0)&(yy<y1)&(abs(xx-x)<20);return np.median(rgb[region,:3],axis=0)
   gain=np.clip(tone(ref,mask,cw/2,100,170)/np.maximum(1,tone(arr,alpha,anchor,82,152)),.9,1.1)
   arr[:,:,:3]=np.clip(arr[:,:,:3].astype(float)*gain,0,255).astype('uint8');tile=Image.fromarray(arr)
   x=round(cw/2-anchor)
   if x<1 or x+tile.width>cw-1:raise ValueError((id,row,col,'would clip'))
   if col in [0,4]:result.alpha_composite(tile,(col*cw+x,(row+1)*ch+18))
   else:result.paste(standing.crop((col*cw,0,(col+1)*cw,ch)),(col*cw,(row+1)*ch))
   stats.append(dict(row=row,col=col,gain=gain.tolist(),width=tile.width,head_anchor=float(anchor)))
 assert np.array_equal(np.array(result.crop((0,0,cw*5,ch))),np.array(standing))
 result.save(ROOT/'assets/characters'/meta['file'],optimize=True)
 meta.update(poses=3,clips=['idle','walk_a','walk_b'],packing_revision=25,walk_views=[0,4],exposure=[[1]*5 for _ in range(3)],frame_mirror=[[False]*5 for _ in range(3)])
 bg=Image.new('RGBA',result.size,'#45453d');bg.alpha_composite(result);bg.convert('RGB').save(a.review/(id+'.jpg'),quality=94)
 for col in range(5):
  frames=[]
  for row in [1,0,2,0]:
   canvas=Image.new('RGBA',(cw,ch),'#45453d');canvas.alpha_composite(result.crop((cw*col,ch*row,cw*(col+1),ch*(row+1))));frames.append(canvas.convert('RGB'))
  frames[0].save(a.review/(id+'-'+str(col)+'.gif'),save_all=True,append_images=frames[1:],duration=190,loop=0)
 report[id]=stats
(ROOT/'assets/characters/atlas.json').write_text(json.dumps(m,ensure_ascii=False,indent=2)+'\n');(a.review/'metrics.json').write_text(json.dumps(report,indent=2)+'\n')
