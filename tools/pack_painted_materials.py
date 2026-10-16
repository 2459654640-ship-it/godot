"""Prepare generated albedos and derive conservative material detail channels.

No scenery is flattened into a background. These maps cover real 3D surfaces.
"""
from pathlib import Path
import argparse
import numpy as np
from PIL import Image, ImageFilter

DEST=Path(__file__).resolve().parents[1]/'assets/visual'


def prepare(name, image, roughness, size=1024):
    color=image.convert('RGB').resize((size,size),Image.Resampling.LANCZOS)
    color.save(DEST/f'{name}.png',optimize=True)
    grey=color.convert('L')
    luma=np.asarray(grey,dtype=np.float32)/255
    coarse=np.asarray(grey.filter(ImageFilter.GaussianBlur(5)),dtype=np.float32)/255
    height=(luma-coarse)*.45+luma*.06
    gy,gx=np.gradient(height*3.0)
    normal=np.stack([-gx,gy,np.ones_like(gx)],axis=-1)
    normal/=np.linalg.norm(normal,axis=-1,keepdims=True)
    Image.fromarray(np.uint8((normal*.5+.5)*255)).save(DEST/f'{name}_normal.png',optimize=True)
    rough=np.uint8(np.clip(roughness+(luma-.5)*.08,0,1)*255)
    Image.fromarray(rough).save(DEST/f'{name}_rough.png',optimize=True)


if __name__=='__main__':
    p=argparse.ArgumentParser()
    p.add_argument('--sources',type=Path,required=True)
    a=p.parse_args()
    prepare('wall',Image.open(a.sources/'exec-259b5c84-8af5-438c-a2e5-605b8cd15d15.png'),.95)
    sheet=Image.open(a.sources/'exec-4bdf54c8-6e7c-484b-8ca7-5cb89611d799.png')
    half=sheet.width//2
    for name,col,row,rough in [('floor',0,0,.87),('timber',1,0,.83),('cement',0,1,.94),('weave',1,1,.96)]:
        prepare(name,sheet.crop((col*half,row*half,(col+1)*half,(row+1)*half)),rough,512)
    rug=Image.open(a.sources/'exec-14a1c3c3-15b6-42e6-ae78-cb7e0c50c233.png').convert('RGB')
    rug.resize((768,960),Image.Resampling.LANCZOS).save(DEST/'rug.png',optimize=True)
    print('Prepared wall, ceramic floor, wood, concrete and wool material maps')
