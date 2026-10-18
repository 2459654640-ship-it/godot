"""Document four whole-pose samples captured in the actual rooms."""
from pathlib import Path
from PIL import Image,ImageDraw
ROOT=Path(__file__).resolve().parents[1]
DEST=ROOT/'docs/screenshots/visual-v11-1'
DEST.mkdir(parents=True,exist_ok=True)
for tag in ['ivan-right-down','ivan-left-down','masked-right-down','masked-left-down']:
    files=sorted((Path('/tmp/metro-v11-1-gait')/tag).glob('*.png'))
    if len(files)!=4:raise ValueError(f'{tag}: expected four samples')
    frames=[Image.open(p).crop((560,260,840,670)) for p in files]
    frames[0].save(DEST/f'{tag}.webp',save_all=True,append_images=frames[1:],duration=150,loop=0,quality=92,method=6)
    canvas=Image.new('RGB',(1120,410),(26,28,27))
    for i,frame in enumerate(frames):canvas.paste(frame,(280*i,0))
    canvas.save(DEST/f'{tag}-poses.webp',quality=94)
    print(tag)
