"""Arrange actual Godot-rendered rows into four-phase review animations."""
from pathlib import Path
import numpy as np
from PIL import Image

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'docs/screenshots/visual-v14'
for path in sorted(OUT.glob('*.png')):
    if not (path.stem.endswith('-walk') or path.stem.endswith('-reload')):continue
    image=Image.open(path).convert('RGB');pixels=np.array(image)
    changed=np.max(abs(pixels.astype(int)-pixels[0,0].astype(int)),axis=2)>8
    rows=np.where(changed.sum(axis=1)>20)[0];bands=[]
    for y in rows:
        if not bands or y>bands[-1][-1]+45:bands.append([int(y)])
        else:bands[-1].append(int(y))
    if len(bands)!=3:raise ValueError((path,'three rendered pose rows required',[(min(b),max(b)) for b in bands]))
    height=max(max(b)-min(b)+1 for b in bands)+24
    samples=[image.crop((0,min(b)-12,image.width,min(b)-12+height)) for b in bands]
    frames=[samples[i] for i in [1,0,2,0]]
    frames[0].save(path.with_suffix('.webp'),save_all=True,append_images=frames[1:],duration=180,loop=0,quality=90,method=6)
print('Packed ten eight-direction four-phase preview animations.')
