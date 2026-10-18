"""Align whole painted figures by fixed head anchor and common foot baseline.
No per-body-part warping, synthesized limbs, or reflected half-body frames.
"""
from pathlib import Path
import json
import numpy as np
from PIL import Image
from pack_painted_assets import crop_cell
ROOT=Path(__file__).resolve().parents[1];SOURCE=ROOT/'art-source/v12'
def aligned(sheet,c,r,rows,width):
 crop=crop_cell(sheet,c,r,5,rows)
 scale=324/crop.height;size=(round(crop.width*scale),324)
 sprite=crop.resize(size,Image.Resampling.LANCZOS)
 _,hx=np.where(np.asarray(crop.getchannel('A'))[:round(crop.height*.16)]>100)
 x=round(width/2-hx.mean()*scale)
 if x<2 or x+sprite.width>width-2:raise ValueError((c,r,x,sprite.width,width))
 cell=Image.new('RGBA',(width,352));cell.alpha_composite(sprite,(x,18));return cell
manifest=json.loads((ROOT/'assets/characters/atlas.json').read_text())
neutral=Image.open(SOURCE/'ivan_volume.png').convert('RGBA').crop((425,0,1747,724))
for r,actor in enumerate(['ivan','ivan_masked']):
 atlas=Image.open(ROOT/f'assets/characters/{actor}.png').convert('RGBA')
 for c in range(5):atlas.paste(aligned(neutral,c,r,2,240),(c*240,0))
 atlas.save(ROOT/f'assets/characters/{actor}.png',optimize=True)
for actor in ['ivan_masked','veteran_masked']:
 file=SOURCE/('ivan_armed_walk.png' if actor=='ivan_masked' else 'veteran_armed_walk.png')
 if not file.exists():continue
 sheet=Image.open(file).convert('RGBA');old=Image.open(ROOT/f'assets/characters/{actor}_combat.png').convert('RGBA');width=old.width//5
 # The original three ready/recoil/reload rows are retained verbatim.
 atlas=Image.new('RGBA',(old.width,1760));atlas.alpha_composite(old.crop((0,0,old.width,1056)))
 for r in range(2):
  for c in range(5):atlas.paste(aligned(sheet,c,r,2,width),(c*width,(r+3)*352))
 atlas.save(ROOT/f'assets/characters/{actor}_combat.png',optimize=True)
 spec=manifest[actor+'_combat'];spec['poses']=5;spec['clips']=['ready','shot','reload','walk_left','walk_right']
(ROOT/'assets/characters/atlas.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n')
# Peaceful facilities use the same manual equipment slot without putting a
# gas mask onto Ivan merely because he draws his firearm.
sheet=Image.open(SOURCE/'ivan_unmasked_armed.png').convert('RGBA')
atlas=Image.new('RGBA',(3200,1056))
for r in range(3):
 for c in range(5):atlas.paste(aligned(sheet,c,r,3,640),(c*640,r*352))
atlas.save(ROOT/'assets/characters/ivan_combat.png',optimize=True)
manifest['ivan_combat']={'file':'ivan_combat.png','directions':8,'source_angles':5,'poses':3,'cell':[640,352],'baseline':342,'body_pixels':324,'rear_diagonal_normalized':True,'clips':['ready','walk_left','walk_right']}
(ROOT/'assets/characters/atlas.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n')
