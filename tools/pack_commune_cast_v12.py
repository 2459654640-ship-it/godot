"""Align full painted standing views; never synthesize limb motion."""
from pathlib import Path
import json
import numpy as np
from PIL import Image
from pack_painted_assets import crop_cell
ROOT=Path(__file__).resolve().parents[1]
sheet=Image.open(ROOT/'art-source/v12/commune_cast.png').convert('RGBA')
manifest=json.loads((ROOT/'assets/characters/atlas.json').read_text())
for row,id in enumerate(['commune_moro','commune_guard']):
 atlas=Image.new('RGBA',(1200,352));front=None
 for col in range(5):
  crop=crop_cell(sheet,col,row,5,2)
  if col==0:front=crop.copy()
  scale=324/crop.height;size=(round(crop.width*scale),324)
  sprite=crop.resize(size,Image.Resampling.LANCZOS)
  _,head=np.where(np.asarray(crop.getchannel('A'))[:round(crop.height*.16)]>100)
  x=round(120-float(head.mean())*scale)
  if x<2 or x+size[0]>238:raise ValueError((id,col,size,x))
  atlas.alpha_composite(sprite,(col*240+x,18))
 atlas.save(ROOT/f'assets/characters/{id}.png',optimize=True)
 portrait=front.crop((0,0,front.width,round(front.height*.43)))
 portrait.thumbnail((224,264),Image.Resampling.LANCZOS)
 canvas=Image.new('RGBA',(240,280));canvas.alpha_composite(portrait,((240-portrait.width)//2,280-portrait.height));canvas.save(ROOT/f'assets/portraits/{id}.png',optimize=True)
 manifest[id]={'file':id+'.png','directions':8,'source_angles':5,'poses':1,'cell':[240,352],'baseline':342,'body_pixels':324,'rear_diagonal_normalized':True,'clips':['idle']}
(ROOT/'assets/characters/atlas.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n')

# Group art has an authored transparent separator at x=1044, not a guessed
# equal split that would truncate the seated third resident.
groups=Image.open(ROOT/'art-source/v12/commune_groups.png').convert('RGBA')
for id,bounds in [('group_assembly',(0,0,1044,groups.height)),('group_militia',(1044,0,groups.width,groups.height))]:
 tile=groups.crop(bounds);yy,xx=np.where(np.asarray(tile.getchannel('A'))>100)
 tile=tile.crop((int(xx.min()),int(yy.min()),int(xx.max())+1,int(yy.max())+1))
 tile.resize((round(tile.width*648/tile.height),648),Image.Resampling.LANCZOS).save(ROOT/f'assets/characters/{id}.png',optimize=True)
scenes=Image.open(ROOT/'art-source/v12/moro_scenes.png').convert('RGB')
for name,y0,y1 in [('moro_hall',0,379),('moro_boiler',379,758)]:
 scenes.crop((500,y0,1524,y1)).save(ROOT/f'assets/cinematics/{name}.png',optimize=True)
