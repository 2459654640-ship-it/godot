"""Two original MIDI cues with local piano/soft-string synthesis; no sampled music."""
from pathlib import Path
import json,math,struct,wave,tempfile,subprocess
import numpy as np
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'assets/audio';SR=32000
PIECES={
 'home_lamp':('门还为你留着',74,[62,66,69,66,64,62,57,61,64,69,67,64,62,61,59,57],[[38,50,57,62,66],[35,47,54,59,62],[43,50,55,59,62],[45,52,57,61,64]],0),
 'shift_below':('地下的晚班',68,[57,60,64,62,59,55,57,60,62,65,64,60,59,57,55,52],[[45,52,57,60],[41,48,53,57],[38,45,50,57],[40,47,55,59]],0)}
def vlq(n):
 b=[n&127];n>>=7
 while n:b.insert(0,(n&127)|128);n>>=7
 return bytes(b)
credits=[]
for name,(title,bpm,motif,chords,program) in PIECES.items():
 beat=60/bpm;notes=[]
 for bar in range(20):
  start=bar*3;ch=chords[(bar//2)%4];vol=52 if bar<4 else (64 if bar<14 else 46)
  # Varied phrases include a quiet bridge and a complete final cadence.
  tune=motif[(bar*2)%16:(bar*2)%16+2]
  for n,(offset,length) in zip(tune,[(0,1.25),(1.5,.95)]):notes.append((0,n+(12 if 8<=bar<12 else 0),start+offset,length,vol))
  notes.append((1,ch[0],start,2.8,39))
  for j,n in enumerate(ch[1:]):notes.append((1,n,start+.35+j*.55,1.9,28))
  if bar>=4:
   for n in ch[2:4]:notes.append((2,n,start,2.85,19 if name=='home_lamp' else 25))
 notes.extend((0,n,60+j*.2,3.3,43-j*3) for j,n in enumerate([62,66,69] if name=='home_lamp' else [57,60,64]))
 duration=66*beat;mix=np.zeros((int(duration*SR),2));events=[]
 for channel,pitch,start,length,velocity in notes:
  t=np.arange(int(length*beat*SR))/SR;frequency=440*2**((pitch-69)/12)
  if channel<2:
   signal=sum(gain*np.sin(2*np.pi*frequency*harm*t)*np.exp(-t*(.85+.40*harm)) for harm,gain in [(1,1),(2,.24),(3,.12),(4,.05),(5,.018)])
   envelope=np.minimum(t/.012,1)*np.minimum((length*beat-t)/.16,1)
  else:
   signal=sum(np.sin(2*np.pi*frequency*detune*t)*.25 for detune in [.997,1.0,1.003]);envelope=np.minimum(t/.45,1)*np.minimum((length*beat-t)/.5,1)*.42
  signal*=envelope*(velocity/127)*.16
  pos=int(start*beat*SR);n=min(len(signal),len(mix)-pos);pan=[.43,.58,.5][channel]
  mix[pos:pos+n,0]+=signal[:n]*math.sqrt(1-pan);mix[pos:pos+n,1]+=signal[:n]*math.sqrt(pan)
  events.extend([(round(start*480),bytes([0x90+channel,pitch,velocity])),(round((start+length)*480),bytes([0x80+channel,pitch,0]))])
 for delay,gain in [(.061,.13),(.109,.085),(.193,.06),(.317,.035)]:
  offset=int(delay*SR);mix[offset:]+=mix[:-offset]*gain
 t=np.arange(len(mix))/SR;mix*=np.minimum(t/.6,1)[:,None]*np.clip((duration-t)/2.8,0,1)[:,None]
 mix*=.48/max(abs(mix).max(),.0001);peak=float(abs(mix).max())
 with tempfile.TemporaryDirectory() as tmp:
  wav=Path(tmp)/'score.wav'
  with wave.open(str(wav),'wb') as f:f.setnchannels(2);f.setsampwidth(2);f.setframerate(SR);f.writeframes((mix*32767).astype('<i2').tobytes())
  subprocess.run(['ffmpeg','-v','error','-y','-i',str(wav),'-c:a','libvorbis','-q:a','4',str(OUT/(name+'.ogg'))],check=True)
 track=b'\0\xff\x51\x03'+round(60_000_000/bpm).to_bytes(3,'big')+b'\0\xc0\x00\0\xc1\x00\0\xc2\x30';last=0
 for tick,msg in sorted(events,key=lambda e:e[0]):track+=vlq(tick-last)+msg;last=tick
 track+=b'\0\xff\x2f\0';(OUT/'scores'/(name+'.mid')).write_bytes(b'MThd'+struct.pack('>IHHH',6,0,1,480)+b'MTrk'+struct.pack('>I',len(track))+track)
 credits.append(dict(id=name,title=title,bpm=bpm,seconds=round(duration,2),peak=peak,license='CC0-1.0',source='Original composition; matching MIDI and procedural piano / string rendering, no samples.'))
(OUT/'scores/journey_credits.json').write_text(json.dumps(credits,ensure_ascii=False,indent=2)+'\n')
(OUT/'licenses/journey_scores_v25.txt').write_text('home_lamp / 门还为你留着; shift_below / 地下的晚班\nOriginal compositions for Metro 1982. CC0-1.0. MIDI and local synthesized recordings included. No commercial melodies, recordings or instrument samples used.\n')
print(json.dumps(credits,ensure_ascii=False))
