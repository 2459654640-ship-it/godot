"""Pack generated combat drawings with fixed head anchors and a fixed body height.
Inputs remain in art-source/v11; runtime cells have generous transparent gutters.
"""
from pathlib import Path
import json, shutil, argparse
import numpy as np
from PIL import Image
from pack_painted_assets import crop_cell
ROOT=Path(__file__).resolve().parents[1]
SOURCES={
 'ivan_masked_combat':('exec-0cd66d8e-b0dd-4ece-a45c-ec540f936c0d.png',3),
 'veteran_masked_combat':('exec-66dd1e59-38b8-4611-af5c-b0552d629621.png',3),
 'tunnel_scavenger':('exec-378b7413-1c9a-458b-b887-462cc5023e7d.png',4)}
parser=argparse.ArgumentParser();parser.add_argument("--sources",type=Path);args=parser.parse_args()
manifest=json.loads((ROOT/'assets/characters/atlas.json').read_text())
source_dir=ROOT/'art-source/v11';source_dir.mkdir(parents=True,exist_ok=True)
def head_anchor(im):
 a=np.array(im.getchannel('A'));ys,xs=np.where(a[:round(im.height*.17)]>100)
 return float(xs.mean()) if len(xs) else im.width/2
facing_path=source_dir/'combat_front_back.png'
if args.sources:shutil.copy2(args.sources/'exec-63b366f7-a35b-49d8-ab73-2b209cba35f2.png',facing_path)
facing=Image.open(facing_path).convert('RGBA')
for name,(file,rows) in SOURCES.items():
 dest=source_dir/(name+'.png')
 if args.sources:shutil.copy2(args.sources/file,dest)
 im=Image.open(dest).convert('RGBA');human=name!='tunnel_scavenger';cw,ch=(640,352) if human else (384,256)
 atlas=Image.new('RGBA',(cw*5,ch*rows));base=[]
 for r in range(rows):
  for c in range(5):
   tile=crop_cell(im,c,r,5,rows)
   if human and c in [0,4]:
    fix_col=(0 if c==0 else 1)+(2 if name=='veteran_masked_combat' else 0)
    tile=crop_cell(facing,fix_col,r,4,3)
   scale=(324 if human else 202)/tile.height
   width=round(tile.width*scale);height=round(tile.height*scale)
   if width>cw-12:scale=(cw-12)/tile.width;width=round(tile.width*scale);height=round(tile.height*scale)
   # A head anchor prevents the rifle's changing muzzle from moving the body.
   anchor=head_anchor(tile) if human else tile.width/2
   if human:
    x=round(cw*.5-anchor*scale)
    if x<3 or x+width>cw-3:raise ValueError(('head anchor would be clipped',name,r,c,x,width))
   else:x=(cw-width)//2
   atlas.alpha_composite(tile.resize((width,height),Image.Resampling.LANCZOS),(c*cw+x,r*ch+ch-10-height))
 atlas.save(ROOT/'assets/characters'/f'{name}.png',optimize=True)
 if human:manifest[name]={'file':name+'.png','directions':8,'source_angles':5,'poses':rows,'cell':[cw,ch],'baseline':342,'body_pixels':324,'clips':['ready','recoil','reload'],'rear_diagonal_normalized':True}
(ROOT/'assets/characters/atlas.json').write_text(json.dumps(manifest,indent=2)+'\n')
# The inventory icon is authored separately; never crop a character's hands as a weapon icon.
icon=crop_cell(Image.open(source_dir/'revolver.png').convert('RGBA'),0,0,1,1)
icon.thumbnail((224,224),Image.Resampling.LANCZOS)
canvas=Image.new('RGBA',(256,256));canvas.alpha_composite(icon,((256-icon.width)//2,(256-icon.height)//2))
canvas.save(ROOT/'assets/visual/item_revolver.png',optimize=True)
print('Packed',', '.join(SOURCES))
