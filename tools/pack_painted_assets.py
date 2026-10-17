"""Slice authored/generated atlases into aligned production assets; no repainting.

The source PNGs keep their original alpha and colors. Crops are normalized to
one foot baseline and one idle height per character so turning cannot resize
or shift an actor. Pass --sources to the directory containing the source PNGs.
"""
from pathlib import Path
import argparse
import json
import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageChops

ROOT = Path(__file__).resolve().parents[1]
CELL = (240, 352)
BODY_HEIGHT = 324


def crop_cell(source, col, row, cols, rows, padding=False):
    w, h = source.size
    px=round(w/cols*.035) if padding else 0
    py=round(h/rows*.055) if padding else 0
    tile = source.crop((max(0,round(col*w/cols)-px), max(0,round(row*h/rows)-py),
                        min(w,round((col+1)*w/cols)+px), min(h,round((row+1)*h/rows)+py)))
    # Generated atlases can place the next row's hair or a neighbour's blade
    # a few pixels over a nominal cell edge. Extract the connected main figure
    # before cropping; never retain those detached fragments in runtime art.
    alpha = np.asarray(tile.getchannel('A'))
    yy, xx = np.where(alpha > 100)
    if not len(xx):
        raise ValueError(f'Empty sprite cell {col},{row}')
    seed=np.argmin((xx-tile.width*.5)**2+(yy-tile.height*.42)**2)
    binary=Image.fromarray(np.uint8(alpha>100)*255).copy()
    ImageDraw.floodfill(binary,(int(xx[seed]),int(yy[seed])),128)
    connected=Image.fromarray(np.uint8(np.asarray(binary)==128)*255)
    connected=connected.filter(ImageFilter.MaxFilter(3))
    tile.putalpha(ImageChops.multiply(tile.getchannel('A'),connected))
    alpha=np.asarray(tile.getchannel('A'))
    yy,xx=np.where(alpha>100)
    bounds = (max(0, int(xx.min())-2), max(0, int(yy.min())-2),
              min(tile.width, int(xx.max())+3), min(tile.height, int(yy.max())+3))
    return tile.crop(bounds)


def pack_character(id, source, row, extra=None, motions=None):
    idle = [crop_cell(source, c, row, 5, 2, True) for c in range(5)]
    # A single scale for all angles, then a foot anchor. Small source variation
    # gets corrected per angle to avoid visible height pops during turning.
    frames = [idle]
    if id == 'ivan':
        frames.append([crop_cell(source,c,1,5,2,True) for c in range(5)])
        if extra:
            frames.append([crop_cell(extra,c,1,5,2,True) for c in range(5)])
    elif motions:
        for pose in range(3):
            frames.append([crop_cell(motions,c,pose,5,3,True) for c in range(5)])
    # Source sheets were authored with the rear diagonal pointing left,
    # whereas our runtime angle sequence is front/right/rear-right/back.
    for angles in frames:
        angles[3]=angles[3].transpose(Image.Transpose.FLIP_LEFT_RIGHT)
    atlas = Image.new('RGBA', (CELL[0]*5, CELL[1]*len(frames)))
    for pose, angles in enumerate(frames):
        for angle, crop in enumerate(angles):
            # Normalize all poses to the same top/sole span; generated walk
            # sheets can use a different canvas scale from the idle sheet.
            scale = BODY_HEIGHT / crop.height
            size = (round(crop.width*scale), round(crop.height*scale))
            if size[0] > CELL[0]-12:
                raise ValueError(f'{id} frame too wide: {size}')
            sprite = crop.resize(size, Image.Resampling.LANCZOS)
            # Anchor on the head, not the bounding box: a forward boot must
            # not make the torso jump sideways between idle and stride.
            mask=np.asarray(crop.getchannel('A'))[:max(1,round(crop.height*.16))]>100
            _,head_x=np.where(mask)
            anchor=float(head_x.mean()) if len(head_x) else crop.width*.5
            local_x=max(2,min(CELL[0]-size[0]-2,round(CELL[0]*.5-anchor*scale)))
            x = angle*CELL[0]+local_x
            y = pose*CELL[1]+CELL[1]-10-size[1]
            atlas.alpha_composite(sprite, (x,y))
    dest=ROOT/'assets/characters'
    dest.mkdir(parents=True, exist_ok=True)
    atlas.save(dest/f'{id}.png', optimize=True)
    # A portrait crop of this very same asset, rather than an unrelated face.
    front=idle[0]
    portrait=front.crop((0,0,front.width,min(front.height,round(front.height*.43))))
    canvas=Image.new('RGBA',(240,280))
    portrait.thumbnail((224,264),Image.Resampling.LANCZOS)
    canvas.alpha_composite(portrait,((240-portrait.width)//2,280-portrait.height))
    portrait_dir=ROOT/'assets/portraits'
    portrait_dir.mkdir(parents=True, exist_ok=True)
    canvas.save(portrait_dir/f'{id}.png', optimize=True)
    return {'file':f'{id}.png','directions':8,'source_angles':5,'poses':len(frames),
            'cell':list(CELL),'baseline':CELL[1]-10,'body_pixels':BODY_HEIGHT,
            'rear_diagonal_normalized':True,'clips':['idle','walk_left','walk_right']+(['talk'] if motions else [])}


def pack_icons(path):
    sheet=Image.open(path).convert('RGBA')
    names=['knife','cigarettes','photo','vodka','map','wrench','fuse','soup',
           'permit','order','mask','filter','vitamins','frequency','satchel','mug']
    for i,id in enumerate(names):
        crop=crop_cell(sheet,i%4,i//4,4,4)
        crop.thumbnail((236,236),Image.Resampling.LANCZOS)
        canvas=Image.new('RGBA',(256,256))
        canvas.alpha_composite(crop,((256-crop.width)//2,(256-crop.height)//2))
        canvas.save(ROOT/'assets/visual'/f'item_{id}.png',optimize=True)


if __name__=='__main__':
    parser=argparse.ArgumentParser()
    parser.add_argument('--sources',type=Path,required=True)
    parser.add_argument('--manifest',type=Path,required=True)
    args=parser.parse_args()
    jobs=json.loads(args.manifest.read_text())
    metadata={}
    for id, spec in jobs['characters'].items():
        source=Image.open(args.sources/spec['source']).convert('RGBA')
        extra=Image.open(args.sources/spec['stride']).convert('RGBA') if spec.get('stride') else None
        motions=Image.open(args.sources/spec['motions']).convert('RGBA') if spec.get('motions') else None
        metadata[id]=pack_character(id,source,spec['row'],extra,motions)
    if jobs.get('icons'):pack_icons(args.sources/jobs['icons'])
    if jobs.get('extra_icons'):
        sheet=Image.open(args.sources/jobs['extra_icons']).convert('RGBA')
        for col, id in enumerate(['rag','report']):
            crop=crop_cell(sheet,col,0,2,1)
            crop.thumbnail((236,236),Image.Resampling.LANCZOS)
            canvas=Image.new('RGBA',(256,256))
            canvas.alpha_composite(crop,((256-crop.width)//2,(256-crop.height)//2))
            canvas.save(ROOT/'assets/visual'/f'item_{id}.png',optimize=True)
    (ROOT/'assets/characters/atlas.json').write_text(json.dumps(metadata,indent=2)+'\n')
    print('Packed characters:',', '.join(metadata))
