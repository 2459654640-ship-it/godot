"""Replace only Ivan's second front-diagonal stride with a complete painted pose.
No deformation/repainting. Keep original atlas cells, portraits and other angles.
"""
from pathlib import Path
import numpy as np
from PIL import Image
from pack_painted_assets import crop_cell
ROOT=Path(__file__).resolve().parents[1]
SOURCE=ROOT/'art-source/v11_1'
for actor in ('ivan','ivan_masked'):
    source=Image.open(SOURCE/f'{actor}_opposite_step.png').convert('RGBA')
    crop=crop_cell(source,0,0,1,1)
    scale=324/crop.height
    sprite=crop.resize((round(crop.width*scale),324),Image.Resampling.LANCZOS)
    _,head_x=np.where(np.asarray(crop.getchannel('A'))[:round(crop.height*.16)]>100)
    x=round(120-float(head_x.mean())*scale)
    if x<2 or x+sprite.width>238:raise ValueError('Sprite exceeds cell')
    atlas=Image.open(SOURCE/f'{actor}_base.png').convert('RGBA')
    atlas.paste((0,0,0,0),(240,704,480,1056))
    atlas.alpha_composite(sprite,(240+x,704+18))
    atlas.save(ROOT/f'assets/characters/{actor}.png',optimize=True)
    print(actor, sprite.size, 'head anchor',x)
