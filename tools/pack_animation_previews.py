"""Crop controlled gameplay captures into small documentation animations."""
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SOURCES = Path('/tmp/metro-v11-gait')
names = {'ivan-right-down': 'ivan-diagonal-walk', 'ivan-left-down': 'ivan-left-diagonal-walk',
         'ivan-side': 'ivan-side-walk', 'child-walk': 'child-walk'}
for tag, output in names.items():
    files = sorted((SOURCES / tag).glob('*.png'))
    if len(files) != 12:
        raise ValueError(f'{tag}: expected 12 captured frames, got {len(files)}')
    frames = [Image.open(p).crop((710, 360, 900, 665)) for p in files]
    frames[0].save(ROOT / 'docs/screenshots/visual-v11' / (output + '.webp'), save_all=True,
                   append_images=frames[1:], duration=90, loop=0, quality=92, method=6)
    print(output + '.webp')
