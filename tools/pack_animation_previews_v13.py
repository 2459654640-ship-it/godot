"""Crop four fixed-position Godot-rendered phases for visual review only."""
from pathlib import Path
from PIL import Image

ROOT=Path(__file__).resolve().parents[1]
SOURCE=Path('/tmp/metro-v13/gait')
DEST=ROOT/'docs/screenshots/visual-v13'

for directory in sorted(SOURCE.iterdir()):
    files=sorted(directory.glob('*.png'))
    if len(files)!=4:raise ValueError((directory,'expected four rendered phases'))
    frames=[Image.open(path).convert('RGB').crop((590,300,1010,740)) for path in files]
    frames[0].save(DEST/(directory.name+'.webp'),save_all=True,append_images=frames[1:],duration=160,loop=0,quality=88,method=6)
    sheet=Image.new('RGB',(420*4,440))
    for index,frame in enumerate(frames):sheet.paste(frame,(420*index,0))
    sheet.save(DEST/(directory.name+'-poses.webp'),quality=90,method=6)
