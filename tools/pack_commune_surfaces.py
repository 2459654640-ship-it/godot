"""Pack the authored 2x2 material atlas. No generated character pixels are edited."""
from pathlib import Path
from PIL import Image
ROOT=Path(__file__).resolve().parents[1]
source=Image.open(ROOT/'art-source/v11_1/commune_surfaces.png').convert('RGB')
for index,name in enumerate(['commune_terrazzo','commune_linoleum','commune_ivory_tile','commune_plaster']):
    x,y=index%2,index//2
    tile=source.crop((round(x*source.width/2),round(y*source.height/2),round((x+1)*source.width/2),round((y+1)*source.height/2)))
    tile.save(ROOT/'assets/visual'/(name+'.png'),optimize=True)
    print(name)
