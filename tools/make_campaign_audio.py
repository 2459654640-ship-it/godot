"""Original offline sound design: soft boot, latch, paper, UI, and sparse tuned notes.
No steady noise bed or mains-frequency hum. Re-run with Python standard library only.
"""
from pathlib import Path
import wave, struct, math, random
DEST=Path(__file__).resolve().parents[1]/'assets/audio'
RATE=22050
TAU=math.tau
rng=random.Random(1982)
def write(name,seconds,fn):
    pcm=bytearray()
    for i in range(int(RATE*seconds)):
        t=i/RATE
        v=max(-.95,min(.95,fn(t)))
        pcm.extend(struct.pack('<h',round(v*32767)))
    with wave.open(str(DEST/(name+'.wav')),'wb') as w:
        w.setnchannels(1); w.setsampwidth(2);w.setframerate(RATE);w.writeframes(pcm)
def tone(t,f,d):return math.sin(TAU*f*t)*math.exp(-t*d)*min(1,t*350)
write('step',.24,lambda t:(.46*math.sin(TAU*(105*t-55*t*t))+.08*rng.uniform(-1,1))*math.exp(-t*24)*min(1,t*800))
write('ui',.09,lambda t:.14*tone(t,660,48))
write('interact',.28,lambda t:.26*tone(t,165,18)+.08*tone(t,490,25))
write('page',.26,lambda t:.07*rng.uniform(-1,1)*math.sin(math.pi*t/.26)**2)
write('save',.4,lambda t:.2*tone(t,440,16)+(.16*tone(t-.13,660,18) if t>.13 else 0))
notes=[(0,146.83),(3,220),(6,174.61),(10,130.81),(14,196),(19,164.81),(23,146.83),(27,110)]
def theme(t):
    s=0
    for start,f in notes:
        u=t-start
        if 0<=u<4:
            envelope=math.sin(math.pi*u/4)**2*math.exp(-u*.7)
            s+=.25*envelope*(math.sin(TAU*f*u)+.16*math.sin(TAU*f*2*u))
    return s
write('shelter_theme',32,theme)
