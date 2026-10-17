"""Prepare the retained v10 texture sheet and two commune poster artworks."""
from pathlib import Path
from PIL import Image
from pack_painted_materials import prepare
ROOT=Path(__file__).resolve().parents[1]
sheet=Image.open(ROOT/'art-source/v10/facility_materials.png')
for name,col,row,rough in [('terrazzo',0,0,.88),('plant_tile',1,0,.82),('factory_floor',2,0,.94),('garden_soil',0,1,.98),('vegetable_leaf',1,1,.85),('painted_iron',2,1,.90)]:
 tile=sheet.crop((col*512,row*512,(col+1)*512,(row+1)*512))
 if name=='factory_floor':tile=tile.crop((0,80,320,400))
 prepare(name,tile,rough,512)
im=Image.open(ROOT/'art-source/v10/commune_posters.png');width,height=im.size
for i in range(2):im.crop((i*width//2,0,(i+1)*width//2,height)).resize((512,768),Image.Resampling.LANCZOS).save(ROOT/f'assets/visual/commune_poster_{i}.png')
print('Prepared six material sets and two poster faces')
