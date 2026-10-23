"""Pack whole AI-painted poses without limb edits; one uniform scale per species.
Sources and review sheets are kept outside the game repository.
"""
from PIL import Image
import numpy as np
from pathlib import Path
import argparse
ROOT=Path(__file__).resolve().parents[1]
SOURCES={'pouncer':'exec-8b19cc77-be21-4aa0-b72d-213016ee5de4.png','spitter':'exec-e9bd85a1-1618-4585-a9b8-37dc3832f95f.png'}
def bands(mask):
 edges=np.diff(np.r_[False,mask,False].astype(int));return list(zip(np.where(edges==1)[0],np.where(edges==-1)[0]))
def poses(path):
 im=Image.open(path).convert('RGBA');a=np.array(im)[:,:,3];out=[]
 for top,bottom in bands(np.any(a>100,axis=1)):
  if bottom-top<30:continue
  row=im.crop((0,int(top),im.width,int(bottom)));arr=np.array(row)[:,:,3]
  groups=[(l,r) for l,r in bands(np.any(arr>100,axis=0)) if r-l>20]
  # A few dead tails touch; the center of the original five views still separates bodies.
  if len(groups)!=5:
   cuts=[0,180,410,710,925,im.width] if im.width==1086 else [int(im.width*i/5) for i in range(6)]
   groups=list(zip(cuts,cuts[1:]))
  cells=[]
  for left,right in groups:
   cell=row.crop((int(left),0,int(right),row.height));bbox=cell.getbbox();cells.append(cell.crop(bbox))
  out.append(cells)
 return out
if __name__=='__main__':
 ap=argparse.ArgumentParser();ap.add_argument('--sources',type=Path,default=Path('/workspace/generated_images'));ap.add_argument('--review',type=Path,default=Path('/workspace/combat-v26/review'));args=ap.parse_args();args.review.mkdir(parents=True,exist_ok=True)
 for kind,name in SOURCES.items():
  rows=poses(args.sources/name)
  scale=190/np.median([im.height for im in rows[0]])
  if kind=='pouncer':
   crouch=poses(args.sources/'exec-2066b6c4-8890-4770-933f-2bba5d1cde90.png')[0]
   # Separate generation has 2x resolution: match each full-body width to its idle view.
   crouch=[im.resize((rows[0][i].width,round(im.height*rows[0][i].width/im.width)),Image.Resampling.LANCZOS) for i,im in enumerate(crouch)]
   rows=rows[:3]+[crouch]+rows[3:]
  scale=min(scale,360/max(im.width for row in rows for im in row))
  atlas=Image.new('RGBA',(384*5,320*7))
  for r,row in enumerate(rows):
   for c,im in enumerate(row):
    im=im.resize((round(im.width*scale),round(im.height*scale)),Image.Resampling.LANCZOS)
    atlas.alpha_composite(im,(c*384+(384-im.width)//2,r*320+300-im.height))
  atlas.save(ROOT/'assets/characters'/('tunnel_'+kind+'.png'))
  bg=Image.new('RGBA',atlas.size,'#30312c');bg.alpha_composite(atlas);bg.convert('RGB').resize((960,1120)).save(args.review/(kind+'-actions.jpg'),quality=94)
  seq=[]
  for row in [0,1,0,2,0,3,3,4,4,0,5,0,6]:
   frame=Image.new('RGBA',(384,320),'#30312c');frame.alpha_composite(atlas.crop((2*384,row*320,3*384,(row+1)*320)));seq.append(frame.convert('RGB'))
  seq[0].save(args.review/(kind+'.gif'),save_all=True,append_images=seq[1:],duration=150,loop=0)
  print(kind,'rows',len(rows),'uniform scale',scale)
