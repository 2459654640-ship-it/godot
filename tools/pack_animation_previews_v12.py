"""Four phase samples rendered by Godot, cropped only for review."""
from pathlib import Path
from PIL import Image
ROOT=Path(__file__).resolve().parents[1];DEST=ROOT/'docs/screenshots/visual-v12'
for sub in sorted(Path('/tmp/metro-v12-gait').iterdir()):
 files=sorted(sub.glob('*.png'))
 if len(files)!=4:raise ValueError((sub, 'expected four rendered phases'))
 frames=[Image.open(p).convert('RGB').crop((430,220,850,600)) for p in files]
 frames[0].save(DEST/(sub.name+'.webp'),save_all=True,append_images=frames[1:],duration=160,loop=0,quality=88,method=6)
 canvas=Image.new('RGB',(420*4,380))
 for i,frame in enumerate(frames):canvas.paste(frame,(420*i,0))
 canvas.save(DEST/(sub.name+'-poses.webp'),quality=90)
