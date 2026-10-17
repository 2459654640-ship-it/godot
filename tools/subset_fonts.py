"""Rebuild the bundled CJK subsets from system Noto fonts after changing authored text."""
from pathlib import Path
from fontTools import subset
from fontTools.ttLib import TTFont
root=Path(__file__).resolve().parents[1]
text=''.join(p.read_text() for suffix in ['*.gd','*.json','*.md','*.tscn'] for p in root.rglob(suffix) if '.godot' not in p.parts and '.git' not in p.parts)
for face,target in [('Sans','MetroSans.otf'),('Serif','MetroSerif.otf')]:
    font=TTFont(f'/usr/share/fonts/opentype/noto/Noto{face}CJK-Regular.ttc',fontNumber=2)
    opts=subset.Options();opts.layout_features=['*'];opts.name_IDs=['*'];opts.name_legacy=True
    sub=subset.Subsetter(options=opts);sub.populate(text=text+''.join(map(chr,range(32,127))));sub.subset(font)
    font.save(root/'assets/fonts'/target)
    print(target,'updated')
