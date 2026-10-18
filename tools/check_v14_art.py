"""Pixel/atlas checks; anatomy and gait still require the rendered review sheets."""
from pathlib import Path
import hashlib,json
import numpy as np
from PIL import Image,ImageOps

ROOT=Path(__file__).resolve().parents[1]
MANIFEST=json.loads((ROOT/'assets/characters/atlas.json').read_text())
checks=0
def check(value,message):
    global checks
    checks+=1
    if not value:raise AssertionError(message)
def tile(image,spec,pose,col,mirror=False):
    w,h=spec['cell'];result=image.crop((col*w,pose*h,(col+1)*w,(pose+1)*h))
    return ImageOps.mirror(result) if mirror else result
def mask(image):return np.asarray(image.getchannel('A'))>100
def bias(image):
    alpha=mask(image);ys,xs=np.where(alpha);body=alpha[ys.min():ys.max()+1]
    _,head=np.where(body[:48]);_,toes=np.where(body[-13:])
    return float(toes.mean()-head.mean())
def proportions(image):
    alpha=mask(image);ys,xs=np.where(alpha)
    image=image.crop((xs.min(),ys.min(),xs.max()+1,ys.max()+1))
    image=image.resize((round(image.width*324/image.height),324))
    alpha=mask(image);_,head=np.where(alpha[:36]);_,torso=np.where(alpha[80:150])
    return {'upper_head_width_px':int(head.max()-head.min()+1),'upper_torso_envelope_px':int(torso.max()-torso.min()+1)}
summary={};direction_groups=0
for actor,spec in MANIFEST.items():
    if spec.get('packing_revision')!=14:continue
    image=Image.open(ROOT/'assets/characters'/spec['file']).convert('RGBA');w,h=spec['cell']
    check(image.size==(5*w,spec['poses']*h),actor+' runtime grid dimensions')
    spans=[]
    for pose in range(spec['poses']):
        for col in range(5):
            alpha=mask(tile(image,spec,pose,col));ys,xs=np.where(alpha)
            check(len(xs)>300,actor+' nonempty full figure')
            check(xs.min()>1 and xs.max()<w-2 and ys.min()>1 and ys.max()<h-2,actor+' unclipped figure/weapon')
            spans.append(int(ys.max()-ys.min()+1))
    check(max(spans)-min(spans)<8,actor+' stable full height')
    groups=[(0,1,2)] if spec['poses']==3 else ([(0,3,4),(2,5,6)] if actor.endswith('_combat') else [])
    for group in groups:
        for angle in range(8):
            col=min(angle,8-angle);samples=[]
            for pose in group:
                mirror=(angle>4)!=spec['frame_mirror'][pose][col]
                samples.append(tile(image,spec,pose,col,mirror))
            check(len({hashlib.sha256(s.tobytes()).hexdigest() for s in samples})==3,actor+f' direction {angle}: three distinct full poses')
            direction_groups+=1
        for col in [0,4]:
            a=tile(image,spec,group[1],col,spec['frame_mirror'][group[1]][col])
            b=tile(image,spec,group[2],col,spec['frame_mirror'][group[2]][col])
            first,second=bias(a),bias(b)
            check(first*second<0 and abs(first-second)>8,actor+f' opposing front/back boots view {col}: {first:.1f}/{second:.1f}')
    summary[actor]={'poses':spec['poses'],'height_range':list([min(spans),max(spans)]),'front_metrics':proportions(tile(image,spec,0,0))}
check(len(summary)==8,'all eight costume/action sets updated')
check(direction_groups==80,'all eight directions, including moving reload, checked')
baseline=json.loads((ROOT/'art-source/v14/references/v13-validation-baseline.json').read_text())
for actor,entry in summary.items():
    entry['v13_front_metrics']=baseline['sets'][actor]
result={'checks':checks,'failures':0,'eight_direction_pose_groups':direction_groups,'sets':summary,'note':'Head-width sampling includes hair/cap; torso envelope can include sleeves. These measurements are not an anatomical head-count test.'}
(ROOT/'docs/ART-AUDIT-V14.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n')
print(json.dumps({'checks':checks,'failures':0,'sets':len(summary),'direction_groups':direction_groups}))
