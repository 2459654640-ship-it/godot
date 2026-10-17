"""Pack the authored 4x2 alpha atlas; no art is synthesized here."""
from pathlib import Path
from PIL import Image
root=Path(__file__).resolve().parents[1]
sheet=Image.open(root/'art-source/inventory-v5.png').convert('RGBA')
names=['bread','bandage','medkit','antirad','battery','cord','military','handmade']
for i,name in enumerate(names):
    w,h=sheet.size
    crop=sheet.crop((round(i%4*w/4),round(i//4*h/2),round((i%4+1)*w/4),round((i//4+1)*h/2)))
    crop=crop.crop(crop.getbbox())
    crop.thumbnail((236,236),Image.Resampling.LANCZOS)
    out=Image.new('RGBA',(256,256))
    out.alpha_composite(crop,((256-crop.width)//2,(256-crop.height)//2))
    out.save(root/'assets/visual'/f'item_{name}.png')
