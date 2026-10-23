"""Extract whole views; preserve one global scale and original anatomy/pixels.
No limb compositing, per-view stretching, recoloring or pose modifications.
"""
from pathlib import Path
from PIL import Image,ImageDraw,ImageFont
import numpy as np,json,hashlib,argparse,shutil
ROOT=Path(__file__).resolve().parent
p=argparse.ArgumentParser();p.add_argument('source',type=Path);p.add_argument('--candidate',default='candidate');args=p.parse_args()
out=ROOT/args.candidate
for d in ['transparent','neutral']: (out/d).mkdir(parents=True,exist_ok=True)
im=Image.open(args.source).convert('RGBA');a=np.array(im.getchannel('A'));occupied=np.any(a>100,axis=0)
edges=np.diff(np.r_[False,occupied,False].astype(int));groups=[(int(l),int(r)) for l,r in zip(np.where(edges==1)[0],np.where(edges==-1)[0]) if r-l>40]
assert len(groups)==3, f'Expected exactly three separate figures; got {groups}'
records=[]
for name,(l,r) in zip(['front','side','back'],groups):
 ys,xs=np.where(a[:,l:r]>100);records.append({'name':name,'source_bounds':[l,int(ys.min()),r,int(ys.max())+1],'height':int(ys.max()-ys.min()+1)})
heights=[r['height'] for r in records]
assert (max(heights)-min(heights))/max(heights)<.02,'Body-height drift exceeds 2%; regenerate instead of stretching.'
# Common source top/bottom and a single scale for all three views.
top=min(r['source_bounds'][1] for r in records);bottom=max(r['source_bounds'][3] for r in records)
scale=900/(bottom-top);w=1024;h=1024
preview=Image.new('RGB',(w*3,h+64),'#e6e5e2');draw=ImageDraw.Draw(preview)
font=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',26)
for record in records:
 l,_,r,_=record['source_bounds'];margin=6;l=max(0,l-margin);r=min(im.width,r+margin)
 crop=im.crop((l,top,r,bottom));crop=crop.resize((round(crop.width*scale),900),Image.Resampling.LANCZOS)
 canvas=Image.new('RGBA',(w,h));canvas.alpha_composite(crop,((w-crop.width)//2,62))
 canvas.save(out/'transparent'/(record['name']+'.png'))
 neutral=Image.new('RGBA',(w,h),'#e6e5e2');neutral.alpha_composite(canvas);neutral.convert('RGB').save(out/'neutral'/(record['name']+'.png'))
 i=['front','side','back'].index(record['name']);preview.paste(neutral.convert('RGB'),(i*w,64));draw.text((i*w+w/2,20),record['name'].upper(),font=font,fill='#514c42',anchor='mt')
 record['scale']=scale;record['canvas']=[w,h];record['output_sha256']=hashlib.sha256((out/'transparent'/(record['name']+'.png')).read_bytes()).hexdigest()
preview.resize((1536,544),Image.Resampling.LANCZOS).save(out/'three-view-preview.png')
shutil.copyfile(args.source,out/'three-view-original.png')
report={'candidate':args.candidate,'source_sha256':hashlib.sha256(args.source.read_bytes()).hexdigest(),'source_size':list(im.size),'views':records,'height_spread_percent':round((max(heights)-min(heights))/max(heights)*100,3),'method':'Whole-figure extraction and common uniform scale only; no per-view scaling or anatomy edits.','status':'Generated modeling reference candidate; requires appearance approval before model generation.'}
(out/'preparation-report.json').write_text(json.dumps(report,ensure_ascii=False,indent=2))
print(json.dumps(report,ensure_ascii=False))
