"""Crop transparent group illustrations without changing painted anatomy/colors."""
from pathlib import Path
from PIL import Image
import numpy as np
ROOT=Path(__file__).resolve().parents[1]
sheet=Image.open(ROOT/'art-source/v11_1/commune_resident_groups.png').convert('RGBA')
for i,name in enumerate(('workers','queue','family','readers')):
 x,y=i%2,i//2
 crop=sheet.crop((x*768,y*512,(x+1)*768,(y+1)*512))
 yy,xx=np.where(np.asarray(crop.getchannel('A'))>100)
 crop=crop.crop((max(0,int(xx.min())-2),max(0,int(yy.min())-2),min(768,int(xx.max())+3),min(512,int(yy.max())+3)))
 scale=648/crop.height
 crop=crop.resize((round(crop.width*scale),648),Image.Resampling.LANCZOS)
 crop.save(ROOT/f'assets/characters/group_{name}.png',optimize=True)
 print(name,crop.size)
