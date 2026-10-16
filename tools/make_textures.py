"""Deterministic original material swatches. No downloaded/reference imagery."""
from PIL import Image, ImageDraw
from pathlib import Path
import random
ROOT=Path(__file__).resolve().parents[1]/'assets/textures'
ROOT.mkdir(parents=True,exist_ok=True)
r=random.Random(1982)
for name,base in [('plaster',(112,115,105)),('concrete',(82,90,88)),('metal',(69,83,80)),('rust',(100,64,43)),('wood',(101,73,48)),('cloth',(86,91,63)),('tile',(109,111,98)),('red',(111,40,30))]:
 im=Image.new('RGB',(128,128));p=im.load()
 for y in range(128):
  for x in range(128):
   d=r.randrange(-3,4)
   if name=='wood': d+=int(7*__import__('math').sin(y*.8+x*.03))
   p[x,y]=tuple(max(0,min(255,c+d)) for c in base)
 dr=ImageDraw.Draw(im)
 for _ in range(65):
  x,y=r.randrange(128),r.randrange(128)
  color=tuple(max(0,c-r.randrange(5,16)) for c in base)
  dr.line((x,y,x+r.randrange(1,9),y+r.randrange(-1,2)),fill=color)
 if name=='tile':
  for q in range(0,128,32):
   dr.line((q,0,q,127),fill=(54,62,58),width=2);dr.line((0,q,127,q),fill=(54,62,58),width=2)
 if name in ['metal','rust']:
  dr.line((0,1,127,1),fill=tuple(c+18 for c in base),width=2)
  for x in [5,121]:
   for y in [5,121]:dr.rectangle((x-1,y-1,x+1,y+1),fill=(35,41,38))
 im.save(ROOT/(name+'.png'))
