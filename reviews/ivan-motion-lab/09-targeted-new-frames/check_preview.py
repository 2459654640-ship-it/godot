from pathlib import Path
import json
from playwright.sync_api import sync_playwright
root=Path(__file__).parent
with sync_playwright() as p:
 browser=p.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage'])
 page=browser.new_page(viewport={'width':1280,'height':1050},device_scale_factor=1)
 errors=[];page.on('pageerror',lambda e: errors.append(str(e)))
 page.set_content((root/'preview.html').read_text(),wait_until='load');page.wait_for_function('window.reviewReady === true')
 results=[]
 for key in ['06-back-left','04-back-right']:
  for phase in ['A','B','standing']:
   page.evaluate('([k,f])=>window.setReviewFrame(k,f)',[key,phase])
   report=page.evaluate('''([key,phase])=>{const p=window.getCalibrationPixels(key,phase),t=window.getCalibrationPixels(key,'standing').before;let alpha=0;for(let i=3;i<p.before.length;i+=4)if(p.before[i]!==p.after[i])alpha++;
const lin=v=>{v/=255;return v<=.04045?v/12.92:((v+.055)/1.055)**2.4};
const mean=(a,box)=>{let sums=[0,0,0],n=0;for(let y=box[1];y<box[3];y++)for(let x=box[0];x<box[2];x++){let i=(y*384+x)*4;if(a[i+3]<251)continue;n++;for(let c=0;c<3;c++)sums[c]+=lin(a[i+c]);}return {rgb:sums.map(v=>v/n),n}};
const box=key==='06-back-left'?[200,270,230,295]:[140,275,165,300];let target=mean(t,box),before=mean(p.before,box),after=mean(p.after,box);let dist=a=>Math.hypot(...a.rgb.map((v,i)=>v-target.rgb[i]));return {key,phase,alphaMismatch:alpha,holdoutCoat:{before:dist(before),after:dist(after),counts:[target.n,before.n,after.n]},state:window.reviewState}}''',[key,phase])
   assert report['alphaMismatch']==0
   assert report['state']['phase']==phase and not report['state']['gaitAccepted']
   results.append(report)
  page.evaluate('k=>window.setReviewFrame(k,"A")',key)
  page.screenshot(path=str(root/f'{key}-preview.png'),full_page=True)
  for frame_name in ['A','standing','B']:
   page.evaluate('([k,f])=>window.setReviewFrame(k,f)',[key,frame_name]);page.locator('.grid').screenshot(path=str(root/f'{key}-{frame_name}-render.png'))
 assert not errors,errors
 page.click('#next');assert page.evaluate('window.reviewState.phase')=='standing'
 browser.close()
(root/'browser-verification.json').write_text(json.dumps({'errors':errors,'frames':results,'checks':'six frame states, source/calibrated synchronization, alpha unchanged, manual frame stepping; gait remains unaccepted'},ensure_ascii=False,indent=2)+'\n')
for r in results:print(r['key'],r['phase'],'alpha mismatch',r['alphaMismatch'],'holdout coat',r['holdoutCoat'])
