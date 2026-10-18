"""Pack the three authored supporting NPCs; animation uses their aligned idle cutout."""
from pathlib import Path
import argparse,json,shutil
import numpy as np
from PIL import Image
from pack_painted_assets import crop_cell
ROOT=Path(__file__).resolve().parents[1]
parser=argparse.ArgumentParser();parser.add_argument('--source',type=Path);args=parser.parse_args()
source=ROOT/'art-source/v11/residents.png'
if args.source:shutil.copy2(args.source,source)
im=Image.open(source).convert('RGBA');manifest=json.loads((ROOT/'assets/characters/atlas.json').read_text())
for row,name in enumerate(['commune_cook','sech_cook','commune_child']):
 atlas=Image.new('RGBA',(1200,352));front=None
 for col in range(5):
  tile=crop_cell(im,col,row,5,3);scale=324/tile.height
  mask=np.array(tile.getchannel('A'))[:round(tile.height*.16)]>100;yy,xx=np.where(mask)
  head=float(xx.mean()) if len(xx) else tile.width/2
  size=(round(tile.width*scale),324);x=round(120-head*scale)
  assert x>=2 and x+size[0]<=238,(name,col,size,x)
  frame=tile.resize(size,Image.Resampling.LANCZOS);atlas.alpha_composite(frame,(col*240+x,18))
  if col==0:front=frame
 atlas.save(ROOT/'assets/characters'/f'{name}.png',optimize=True)
 portrait=front.crop((0,0,front.width,round(front.height*.43)));portrait.thumbnail((224,264),Image.Resampling.LANCZOS)
 canvas=Image.new('RGBA',(240,280));canvas.alpha_composite(portrait,((240-portrait.width)//2,280-portrait.height));canvas.save(ROOT/'assets/portraits'/f'{name}.png')
 manifest[name]={'file':name+'.png','directions':8,'source_angles':5,'poses':1,'cell':[240,352],'baseline':342,'body_pixels':324,'rear_diagonal_normalized':True,'clips':['idle_2d_rig']}
(ROOT/'assets/characters/atlas.json').write_text(json.dumps(manifest,indent=2)+'\n')
print('Packed Marfa, Darya and Misha')
