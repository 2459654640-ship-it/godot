"""Four original scores. Write standard MIDI type 0 and render the same note events.
No external recording, quotation of a commercial melody or online dependency.
"""
from pathlib import Path
import math,struct,wave,json
import numpy as np
r=Path(__file__).resolve().parents[1]/'assets/audio';(r/'scores').mkdir(exist_ok=True)
SR=22050
pieces={
 'letters_theme':('来信以后',72,[57,60,64,62,60,57,55,57,60,64,67,64,62,60,59,57],[[45,52,57,60],[41,48,53,57],[48,55,60,64],[43,50,55,59]],0),
 'dawn_theme':('还可以安排明天',76,[62,66,69,71,69,66,64,62,64,66,69,66,64,62,61,62],[[38,45,50,54],[43,50,55,59],[45,52,57,61],[38,45,50,54]],0),
 'anna_elegy':('留给下一班的课',60,[64,67,69,67,64,62,60,62,64,67,64,62,59,60,62,64],[[40,47,52,55],[36,43,48,52],[45,52,57,60],[35,42,47,51]],0),
 'frontline_theme':('南口识别灯',66,[50,57,53,52,50,48,45,48,50,53,57,55,53,52,48,50],[[38,45,50,53],[34,41,46,50],[41,48,53,57],[36,43,48,52]],48),
}
def vlq(n):
 b=[n&127];n>>=7
 while n:b.insert(0,(n&127)|128);n>>=7
 return bytes(b)
meta=[]
for name,(title,bpm,melody,chords,prog) in pieces.items():
 beat=60/bpm;events=[]
 for bar in range(16):
  start=bar*4;ch=chords[(bar//2)%4]
  # Four-bar melody develops over a low, spacious accompaniment.
  root=melody[bar%16]+(12 if name=='dawn_theme' and bar>=8 else 0)
  events += [(0,root,start,1.65,63),(0,melody[(bar+1)%16],start+2.5,1.1,48)]
  for i,n in enumerate(ch):events.append((1,n,start+i*.75,2.8,34))
  events.append((2,ch[0]-12,start,3.7,38))
 duration=64*beat+4;mix=np.zeros((int(duration*SR),2),dtype=np.float64);midi=[(0,bytes([0xc0,prog])),(0,bytes([0xc1,0])),(0,bytes([0xc2,48]))]
 for channel,pitch,start,length,vel in events:
  t=np.arange(int(length*beat*SR))/SR;freq=440*2**((pitch-69)/12)
  # Soft hammer/transient followed by a restrained harmonic decay.
  signal=np.sin(2*np.pi*freq*t)*np.exp(-t*(.7 if channel==2 else 1.5))
  for harmonic,gain in [(2,.23),(3,.09),(4,.035)]:signal+=gain*np.sin(2*np.pi*freq*harmonic*t)*np.exp(-t*(1.4+harmonic*.55))
  signal*=np.minimum(1,t/.025)*np.minimum(1,(length*beat-t)/.12)*(vel/127)*(.075 if channel==0 else .045)
  pos=int(start*beat*SR);pan=[.47,.30,.62][channel];n=min(len(signal),len(mix)-pos)
  mix[pos:pos+n,0]+=signal[:n]*math.sqrt(1-pan);mix[pos:pos+n,1]+=signal[:n]*math.sqrt(pan)
  midi.extend([(round(start*480),bytes([0x90+channel,pitch,vel])),(round((start+length)*480),bytes([0x80+channel,pitch,0]))])
 # Small room reflections, with peak verified after the mix.
 for delay,gain in [(.073,.13),(.137,.08),(.241,.045)]:
  offset=int(delay*SR);mix[offset:]+=mix[:-offset]*gain
 t=np.arange(len(mix))/SR;mix*=np.minimum(1,t/.8)[:,None]*np.clip((duration-t)/2,0,1)[:,None]
 mix*=4.0
 peak=float(np.max(abs(mix)));assert 0<peak<.6
 with wave.open(str(r/(name+'.wav')),'wb') as w:w.setnchannels(2);w.setsampwidth(2);w.setframerate(SR);w.writeframes((mix*32767).astype('<i2').tobytes())
 tempo=round(60000000/bpm);track=bytes([0,0xff,0x51,3])+tempo.to_bytes(3,'big');last=0
 for tick,msg in sorted(midi,key=lambda x:x[0]):track+=vlq(tick-last)+msg;last=tick
 track+=b'\0\xff\x2f\0';(r/'scores'/(name+'.mid')).write_bytes(b'MThd'+struct.pack('>IHHH',6,0,1,480)+b'MTrk'+struct.pack('>I',len(track))+track)
 meta.append({'id':name,'title':title,'bpm':bpm,'seconds':round(duration,2),'peak':peak,'source':'original MIDI composition, rendered from identical note events','license':'CC0-1.0'})
(r/'scores/credits.json').write_text(json.dumps(meta,ensure_ascii=False,indent=2)+'\n')
(r/'licenses/original_story_scores.txt').write_text('Original story scores: letters_theme, dawn_theme, anna_elegy, frontline_theme.\nComposed for this project; dedicated under CC0-1.0. MIDI and matching rendered audio included.\nanna_elegy is an original composition, NOT Here\'s to You. No commercial melody or recording used.\n')
print(json.dumps(meta,ensure_ascii=False))
