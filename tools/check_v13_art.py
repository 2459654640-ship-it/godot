"""Check real atlas pixels, including the formerly same-foot front/back gait."""
from pathlib import Path
import hashlib,json
import numpy as np
from PIL import Image
ROOT=Path(__file__).resolve().parents[1]
manifest=json.loads((ROOT/'assets/characters/atlas.json').read_text())
checks=0
def check(ok,message):
    global checks
    checks+=1
    if not ok:raise AssertionError(message)
def bias(image,spec,pose,column):
    width,height=spec['cell']
    alpha=np.asarray(image.crop((column*width,pose*height,(column+1)*width,(pose+1)*height)).getchannel('A'))>100
    ys,xs=np.where(alpha);check(len(xs)>0,'sprite must contain a complete figure')
    _,head=np.where(alpha[ys.min():ys.min()+48]);_,toe=np.where(alpha[ys.max()-12:ys.max()+1])
    value=float(toe.mean()-head.mean())
    if spec.get('frame_mirror',[[False]*5]*spec['poses'])[pose][column]:value=-value
    return value
summary={}
for actor,spec in manifest.items():
    image=Image.open(ROOT/'assets/characters'/spec['file']).convert('RGBA')
    check(image.size==(spec['cell'][0]*5,spec['cell'][1]*spec['poses']),actor+' atlas matches runtime grid')
    if spec.get('packing_revision')!=13:continue
    width,height=spec['cell']
    spans=[]
    for pose in range(spec['poses']):
        for column in range(5):
            tile=np.asarray(image.crop((column*width,pose*height,(column+1)*width,(pose+1)*height)))
            ys,xs=np.where(tile[:,:,3]>100)
            check(len(xs)>100,actor+' nonempty figure')
            check(xs.min()>1 and xs.max()<width-2 and ys.min()>1 and ys.max()<height-2,actor+' no clipped head, hand, weapon or boot')
            spans.append(int(ys.max()-ys.min()+1))
    check(max(spans)-min(spans)<8,actor+' fixed crown-to-sole span across views/poses')
    if actor in ['ivan','ivan_masked','commander','commander_masked']:
        pairs=[(1,2)]
    elif actor.endswith('_combat'):pairs=[(3,4),(5,6)]
    else:pairs=[]
    strides=[]
    for a,b in pairs:
        for column in [0,4]:
            first=bias(image,spec,a,column);second=bias(image,spec,b,column)
            check(first*second<0 and abs(first-second)>8,actor+f' {a}/{b} view{column}: frontmost boots alternate across body axis: {first:.1f}/{second:.1f}')
            strides.append({'poses':[a,b],'view':column,'toe_bias':[round(first,2),round(second,2)]})
    summary[actor]={'poses':spec['poses'],'cell':spec['cell'],'pixel_height_range':[min(spans),max(spans)],'opposite_stride_checks':strides}
digests=[]
for index in range(18):
    image=Image.open(ROOT/'assets/publications'/f'cover_{index:02d}.png').convert('RGBA')
    alpha=np.asarray(image.getchannel('A'))
    check(image.size==(160,208) and (alpha>180).sum()>12000,'publication cover has compact visible artwork')
    digests.append(hashlib.sha256(image.tobytes()).hexdigest())
check(len(set(digests))==18,'eighteen distinct covers')
output={'checks':checks,'failures':0,'actors':summary,'distinct_publication_covers':len(set(digests))}
(ROOT/'docs/ART-AUDIT-V13.json').write_text(json.dumps(output,ensure_ascii=False,indent=2)+'\n')
print(json.dumps({'checks':checks,'failures':0,'actors':len(summary),'covers':18}))
