"""Catch clipped feet and divergent lower gait across equipment/reload atlases."""
from pathlib import Path
from PIL import Image
import numpy as np,json
ROOT=Path(__file__).resolve().parents[1]/'assets/characters';manifest=json.loads((ROOT/'atlas.json').read_text());checks=0
for name in ['ivan','ivan_masked','ivan_combat','ivan_masked_combat']:
 image=np.array(Image.open(ROOT/(name+'.png')));w,h=manifest[name]['cell']
 for row in range(manifest[name]['poses']):
  for col in range(8):
   alpha=image[row*h:(row+1)*h,col*w:(col+1)*w,3]
   assert max(alpha[-2:].max(),alpha[:2].max(),alpha[:,:2].max(),alpha[:,-2:].max())<=100,(name,row,col,'clipped edge')
   checks+=1
for plain,equipped in [('ivan','ivan_combat'),('ivan_masked','ivan_masked_combat')]:
 a=np.array(Image.open(ROOT/(plain+'.png')));b=np.array(Image.open(ROOT/(equipped+'.png')));aw,ah=manifest[plain]['cell'];bw,bh=manifest[equipped]['cell'];offset=(bw-aw)//2
 for col in range(8):
  for row,other_rows in [(0,[0,1,2]),(1,[3,5]),(2,[4,6])]:
   for other in other_rows:
    old=a[row*ah+250:(row+1)*ah,col*aw:(col+1)*aw];new=b[other*bh+250:(other+1)*bh,col*bw+offset:col*bw+offset+aw]
    assert np.array_equal(old,new),(plain,col,row,other,'equipment changes lower gait')
    checks+=1
print(f'IVAN_V20_ASSETS checks={checks} failures=0')
