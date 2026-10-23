"""Original transient combat cues, CC0. No external audio samples."""
from pathlib import Path
import wave
import numpy as np
root=Path(__file__).resolve().parents[1]/'assets/audio'
rng=np.random.default_rng(1982)
rate=22050
for name,duration,level in [('combat_hit',.105,.19),('combat_kill',.17,.18),('combat_wall',.07,.11),('creature_warn',.34,.10)]:
    t=np.arange(int(rate*duration))/rate
    noise=np.convolve(rng.normal(0,1,len(t)),np.ones(4)/4,mode='same')
    envelope=np.exp(-t/(duration/5))*(1-np.exp(-t/.001))
    if name=='creature_warn':
        samples=(np.sin(2*np.pi*(160*t-70*t*t))*.65+noise*.25)*np.sin(np.pi*t/duration)**2
    else:
        frequency=280 if name=='combat_wall' else 110
        samples=(noise*.75+np.sin(2*np.pi*frequency*t)*.25)*envelope
    with wave.open(str(root/(name+'.wav')),'wb') as stream:
        stream.setnchannels(1);stream.setsampwidth(2);stream.setframerate(rate)
        stream.writeframes((np.clip(samples*level,-1,1)*32767).astype('<i2').tobytes())
