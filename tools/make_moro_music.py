"""Original 24-second quiet instrumental demo, no borrowed melody or recording."""
from pathlib import Path
import wave
import numpy as np
ROOT=Path(__file__).resolve().parents[1]
SR=22050;BEAT=.5;SECONDS=25
mix=np.zeros(int(SR*SECONDS),dtype=np.float64)
rng=np.random.default_rng(1982)
def note(midi,start,length,volume,bass=False):
 n=int(SR*length);t=np.arange(n)/SR;f=440*2**((midi-69)/12)
 signal=np.zeros(n)
 for h in range(1,7 if bass else 12):
  signal+=np.sin(2*np.pi*f*h*t)*np.exp(-t*(1.6+h*.7))/(h**(1.6 if bass else 1.35))
 signal*=np.minimum(1,t/.008)*np.minimum(1,(length-t)/.06)*volume
 p=int(start*SR);mix[p:p+n]+=signal[:len(mix[p:p+n])]
# Twelve bars of an original slow E-minor progression, arpeggiated guitar,
# restrained picked bass, and brushes. No vocals or imitation of a song.
chords=[[40,47,52,55],[36,43,48,52],[43,50,55,59],[38,45,50,54]]
for bar in range(12):
 c=chords[bar%4];start=bar*2
 for i,j in enumerate([0,2,1,3]):note(c[j]+12,start+i*.5,1.3,.085)
 note(c[0]-0,start,1.6,.10,True);note(c[1]-12,start+1,0.8,.07,True)
 for b in [1,3]:
  p=int((start+b*.5)*SR);t=np.arange(int(.10*SR))/SR
  brush=rng.normal(0,1,len(t))*np.exp(-t*45)*.018
  mix[p:p+len(t)]+=brush
mix*=np.minimum(1,np.arange(len(mix))/SR/.4)*np.clip((SECONDS-np.arange(len(mix))/SR)/1.2,0,1)
assert np.max(abs(mix))<.85
p=ROOT/'assets/audio/moro_first_song.wav'
with wave.open(str(p),'wb') as w:
 w.setnchannels(1);w.setsampwidth(2);w.setframerate(SR);w.writeframes((mix*32767).astype('<i2').tobytes())
print(p,'peak',float(np.max(abs(mix))))
