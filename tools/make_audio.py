"""Quiet original machinery ambience and a cloth/boot step; no sampled media."""
import wave,math,random,struct
from pathlib import Path
p=Path(__file__).resolve().parents[1]/'assets/audio'
p.mkdir(parents=True,exist_ok=True)
r=random.Random(1982)
def write(name,seconds,fn):
 with wave.open(str(p/name),'wb') as w:
  w.setnchannels(1);w.setsampwidth(2);w.setframerate(22050)
  w.writeframes(b''.join(struct.pack('<h',int(max(-1,min(1,fn(i/22050,i)))*32767)) for i in range(int(seconds*22050))))
write('ventilation.wav',4,lambda t,i: .18*math.sin(2*math.pi*50*t)+.07*math.sin(2*math.pi*100*t)+.035*math.sin(2*math.pi*73*t)+r.uniform(-.025,.025))
write('step.wav',.14,lambda t,i: (.33*math.sin(2*math.pi*(85-120*t)*t)+r.uniform(-.2,.2))*math.exp(-t*35)*min(t*500,1))
