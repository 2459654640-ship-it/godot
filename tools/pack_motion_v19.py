"""Pack complete AI-painted Ivan poses. Never combine anatomical regions.

Sources: idle-master.png (4x2), walk-left/right.png (4x2), optional
right-{angle}.png full-figure corrections, and outfit sheets (8x3).
Only alpha cleanup, one uniform scale, translation and whole-frame exposure
registration are permitted. Raw sources belong in the reference repository.
"""
from pathlib import Path
import argparse, hashlib, json
import numpy as np
from PIL import Image, ImageChops, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
W, H, BODY, BASELINE = 280, 352, 324, 342

def extract(source, col=0, row=0, columns=1, rows=1):
    w,h=source.size
    im=source.crop((round(col*w/columns),round(row*h/rows),round((col+1)*w/columns),round((row+1)*h/rows))).convert('RGBA')
    a=np.asarray(im)[:,:,3]
    # Remove the weak-alpha generation backdrop, retaining antialiased edges.
    mask=Image.fromarray(np.uint8(a>210)*255).filter(ImageFilter.MaxFilter(3))
    im.putalpha(ImageChops.multiply(im.getchannel('A'),mask))
    bounds=im.getchannel('A').getbbox()
    if not bounds: raise ValueError('Empty figure')
    return im.crop(bounds)

def register(im, width=W):
    scale=BODY/im.height
    im=im.resize((round(im.width*scale),BODY),Image.Resampling.LANCZOS)
    a=np.asarray(im)[:,:,3]
    _,xs=np.where(a[:40]>120)
    if not len(xs):raise ValueError('No crown for registration')
    x=round(width/2-xs.mean())
    if x<0 or x+im.width>width:raise ValueError(f'Figure exceeds cell: {im.size}, x={x}, width={width}')
    out=Image.new('RGBA',(width,H));out.alpha_composite(im,(x,18))
    return out

def metrics(im):
    a=np.asarray(im)[:,:,3]>120
    def span(y0,y1):
        yy,xx=np.where(a[y0:y1])
        return int(np.percentile(xx,98)-np.percentile(xx,2)+1) if len(xx) else 0
    return {'head_span':span(23,67),'shoulder_span':span(100,135),'hip_span':span(190,220),'body_height':int(np.ptp(np.where(a)[0])+1)}

def pack(sources, report_path, preview=False):
    master=Image.open(sources/'idle-master.png').convert('RGBA')
    idle=[master.crop((i%4*W,i//4*H,(i%4+1)*W,(i//4+1)*H)) for i in range(8)]
    body=[idle]
    for name in ['walk-left','walk-right']:
        sheet=Image.open(sources/(name+'.png')).convert('RGBA')
        row=[]
        for i in range(8):
            override=sources/f'right-{i}.png'
            pose=extract(Image.open(override)) if name=='walk-right' and override.exists() else extract(sheet,i%4,i//4,4,2)
            row.append(register(pose))
        body.append(row)
    report={'reference_commit':'057fff3','anatomical_compositing':False,'registration':'whole-figure uniform scale and translation only','production_sources':{'ivan':'unarmed.png','ivan_masked':'masked.png','ivan_combat':['armed.png','reload.png'],'ivan_masked_combat':['masked-armed.png','masked-reload.png']},'source_sha256':{},'metrics':{}}
    for p in sources.glob('*.png'):report['source_sha256'][p.name]=hashlib.sha256(p.read_bytes()).hexdigest()
    atlas=Image.new('RGBA',(8*W,3*H))
    for p,row in enumerate(body):
        for i,im in enumerate(row):atlas.alpha_composite(im,(i*W,p*H))
    atlas.save(sources/'base-poses.png')
    # A separate per-view strip makes opposite feet and silhouette changes easy
    # to review without relying on frame numbers or pixel-difference assertions.
    review=Image.new('RGBA',(W*3,H*8))
    for i in range(8):
        for p in range(3):review.alpha_composite(body[p][i],(p*W,i*H))
    review.save(sources/'base-review.png')
    if preview:
        print(sources/'base-review.png');return
    def outfit(name, width=400):
        sheet=Image.open(sources/(name+'.png')).convert('RGBA')
        return [[register(extract(sheet,i,p,8,3),width) for i in range(8)] for p in range(3)]
    # Final whole-atlas AI consistency pass, derived from the reviewed 24 poses.
    # Each cell remains one complete generated figure; no regions are combined.
    if (sources/'unarmed.png').exists():body=outfit('unarmed',W);idle=body[0]
    masked=outfit('masked');armed=outfit('armed');masked_armed=outfit('masked-armed')
    reload=outfit('reload');masked_reload=outfit('masked-reload')
    def combat(ready,loading):return [ready[0],ready[0],loading[0],ready[1],ready[2],loading[1],loading[2]]
    atlases={'ivan':body,'ivan_masked':masked,'ivan_combat':combat(armed,reload),'ivan_masked_combat':combat(masked_armed,masked_reload)}
    manifest_path=ROOT/'assets/characters/atlas.json';manifest=json.loads(manifest_path.read_text())
    for actor,rows in atlases.items():
        width=400 if actor!='ivan' else W
        atlas=Image.new('RGBA',(width*8,H*len(rows)))
        for p,row in enumerate(rows):
            for i,im in enumerate(row):atlas.alpha_composite(im,(i*width,p*H))
        atlas.save(ROOT/'assets/characters'/f'{actor}.png',optimize=True)
        clips=['idle','walk_left','walk_right'] if len(rows)==3 else ['ready','shot','reload','walk_left','walk_right','reload_walk_left','reload_walk_right']
        manifest[actor]={'file':actor+'.png','directions':8,'source_angles':8,'poses':len(rows),'cell':[width,H],'baseline':BASELINE,'body_pixels':BODY,'clips':clips,'packing_revision':19,'reference_commit':'057fff3','whole_figure_redraw':True,'exposure':[[1.0]*8 for _ in rows],'frame_mirror':[[False]*8 for _ in rows]}
        report['metrics'][actor]=[[metrics(im) for im in row] for row in rows]
    manifest_path.write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n')
    for actor,cell in [('ivan',idle[0]),('ivan_masked',masked[0][0])]:
        center=cell.width//2;face=cell.crop((center-85,10,center+85,150));face.thumbnail((224,264),Image.Resampling.LANCZOS)
        canvas=Image.new('RGBA',(240,280));canvas.alpha_composite(face,((240-face.width)//2,280-face.height));canvas.save(ROOT/'assets/portraits'/f'{actor}.png')
    report_path.write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n')
    print('Packed four complete-figure Ivan atlases; no body regions copied.')

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--sources',type=Path,required=True);p.add_argument('--report',type=Path,default=Path('/tmp/ivan-v19-report.json'));p.add_argument('--preview',action='store_true');a=p.parse_args();pack(a.sources,a.report,a.preview)
