"""Pack user-approved whole-figure AI review. No anatomy compositing or local warps.
Requires the extracted review pack. The approved normal atlas and base24 are locked.
"""
from pathlib import Path
from PIL import Image
from scipy import ndimage
import argparse,json,hashlib
import numpy as np
r=Path(__file__).resolve().parents[1];parser=argparse.ArgumentParser();parser.add_argument('review',type=Path);args=parser.parse_args();src=args.review
manifest=json.loads((r/'assets/characters/atlas.json').read_text());locked=json.loads((src/'locked-base-sha256.json').read_text())
def verify():
 for k,v in locked.items():
  f=r/'assets/characters/ivan.png' if k.startswith('runtime/') else r/'art-source/v20/base'/k
  assert hashlib.sha256(f.read_bytes()).hexdigest()==v,str(f)
def bounds(im):
 a=np.asarray(im.getchannel('A'))>230;labels,n=ndimage.label(a);counts=np.bincount(labels.ravel());counts[0]=0;a=labels==counts.argmax();ys,xs=np.where(a);return int(xs.min()),int(ys.min()),int(xs.max()+1),int(ys.max()+1)
verify();records={}
for kind,art in [('masked','ivan_masked'),('armed','ivan_combat'),('masked_armed','ivan_masked_combat')]:
 keys=[p.stem.removesuffix('-standing') for p in sorted((src/'frames'/kind).glob('*-standing.png'))];assert len(keys)==8
 width=384 if kind!='masked' else 280;atlas=Image.new('RGBA',(width*8,352*3))
 for col,key in enumerate(keys):
  stand=Image.open(src/'frames'/kind/f'{key}-standing.png').convert('RGBA');x0,y0,x1,y1=bounds(stand);scale=324/(y1-y0);dx=round(width/2-(x0+x1)/2*scale);dy=round(18-y0*scale)
  for row,phase in enumerate(['standing','A','B']):
   im=Image.open(src/'frames'/kind/f'{key}-{phase}.png').convert('RGBA');resized=im.resize((round(im.width*scale),round(im.height*scale)),Image.Resampling.LANCZOS);cell=Image.new('RGBA',(width,352));cell.alpha_composite(resized,(dx,dy));atlas.paste(cell,(col*width,row*352));records[f'{art}/{key}/{phase}']={'uniform_scale':scale,'translation':[dx,dy],'source_sha256':hashlib.sha256((src/'frames'/kind/f'{key}-{phase}.png').read_bytes()).hexdigest()}
 atlas.save(r/'assets/characters'/f'{art}.png')
 manifest[art].update(poses=3,cell=[width,352],clips=['ready' if kind!='masked' else 'idle','walk_A','walk_B'],packing_revision=22,equipment_layered=False,full_figure_ai=True,review_commit='eb98b27715c1c56ff3b73a91474c6cd9fe35759b',frame_mirror=[[False]*8 for _ in range(3)],exposure=[[1.0]*8 for _ in range(3)])
(r/'assets/characters/atlas.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n');verify()
(r/'art-source/v22').mkdir(exist_ok=True);(r/'art-source/v22/equipment-packing.json').write_text(json.dumps(records,indent=2)+'\n');print('72 complete-figure equipment frames packed; normal atlas + base24 unchanged')
