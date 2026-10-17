"""Pack fixed-camera Blender output; never normalize frame bounding boxes."""
from pathlib import Path
from PIL import Image
import json,hashlib
import numpy as np
ROOT=Path(__file__).resolve().parents[1]
SRC=ROOT/'art-source/v10/ivan';DST=ROOT/'assets/characters/ivan_pilot'
DST.mkdir(exist_ok=True,parents=True)
index=json.loads((SRC/'frames.json').read_text())
assert len(index)==192
for channel in ['color','normal']:
 atlas=Image.new('RGBA',(192*8,288*24),(0,0,0,0))
 for f in index:
  im=Image.open(SRC/'frames'/f"{f['row']:02d}-{f['direction']}-{channel}.png").convert('RGBA');assert im.size==(192,288)
  if channel=='normal':
   values=np.array(im);coverage=np.array(Image.open(SRC/'frames'/f"{f['row']:02d}-{f['direction']}-color.png").convert('RGBA'))[:,:,3].astype(float)/255
   # Compositor alpha contains depth times antialias coverage.
   values[:,:,3]=np.uint8(np.clip(values[:,:,3]/255/np.maximum(coverage,.001),0,1)*255)
   values[:,:,2]=255-values[:,:,2]
   valid=coverage>.01
   values[~valid]=[128,128,255,128]
   # Dilate data using the colour coverage, not the encoded depth alpha.
   # This prevents dark normal/depth fringes during linear/mipmap sampling.
   for padding in range(3):
    expanded=valid.copy()
    for axis,shift in [(0,1),(0,-1),(1,1),(1,-1)]:
     adjacent=np.roll(valid,shift,axis=axis);copy=(~expanded)&adjacent
     shifted=np.roll(values,shift,axis=axis);values[copy]=shifted[copy];expanded|=copy
    valid=expanded
   im=Image.fromarray(values)
  if channel=='color':
   box=im.getchannel('A').point(lambda x:255 if x>128 else 0).getbbox()
   assert box and box[0]>=3 and box[1]>=3 and box[2]<=189 and box[3]<=285,(f,'clipped bake envelope',box)
  atlas.paste(im,(f['direction']*192,f['row']*288))
 atlas.save(DST/(channel+'.png'),optimize=True)
meta={'source':'art-source/v10/ivan/ivan.blend','cell':[192,288],'columns':8,'rows':24,'directions':8,'height':1.75,'screen_height':2.2,'camera_elevation':40,'pivot_height':.7,'stride_meters':1.2,'animations':{'idle':{'first':0,'count':4,'fps':3},'walk':{'first':4,'count':16},'aim':{'first':20,'count':4,'fps':6}},'frames':192,'normal_space':'view','depth_range':3.0,'depth_channel':'normal alpha, camera-relative meters encoded over 3m','color_sha256':hashlib.sha256((DST/'color.png').read_bytes()).hexdigest()}
(DST/'manifest.json').write_text(json.dumps(meta,indent=2)+'\n')
# A reviewable animation uses exactly the rendered frames, not image morphing.
for direction,name in [(0,'front'),(1,'diagonal'),(2,'side')]:
 frames=[Image.open(SRC/'frames'/f'{i:02d}-{direction}-color.png').convert('RGBA') for i in range(4,20)]
 canvases=[]
 for im in frames:
  bg=Image.new('RGBA',im.size,(39,45,39,255));bg.alpha_composite(im);canvases.append(bg.convert('RGB'))
 canvases[0].save(SRC/('walk-'+name+'.webp'),save_all=True,append_images=canvases[1:],duration=85,loop=0,lossless=True)
print('Packed',len(index),'fixed-scale frames + real rendered normals')
