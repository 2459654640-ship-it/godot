"""Deterministic offline effects; no third-party samples or continuous noise bed."""
from pathlib import Path
import math
import random
import struct
import wave

DEST = Path(__file__).resolve().parents[1] / 'assets/audio'
RATE = 22050

def write(name, seconds, rifle=False):
    rng = random.Random(198211 + int(rifle))
    low = 0.0
    pcm = bytearray()
    for i in range(round(seconds * RATE)):
        t = i / RATE
        noise = rng.uniform(-1, 1)
        low += .32 * (noise - low)
        if name == 'reload':
            # Three small cylinder/hammer clicks, with silence between them.
            value = 0.0
            for start, pitch in [(0, 1300), (.23, 980), (.51, 1600)]:
                u = t - start
                if 0 <= u < .10:
                    value += (.12 * low + .055 * math.sin(math.tau * pitch * u)) * math.exp(-u * 85) * min(1, u * 2000)
        else:
            # Restrained, low-pass report, decaying body and a short room tail.
            envelope = min(1, t * 2500)
            body = math.sin(math.tau * (72 if rifle else 92) * t) * math.exp(-t * 26)
            value = envelope * (.42 * low * math.exp(-t * (29 if rifle else 35)) + .14 * body)
            if t > .035:
                value += .045 * low * math.exp(-(t - .035) * 14)
        value *= min(1, max(0, (seconds-t) / .015))
        pcm.extend(struct.pack('<h', round(max(-.8, min(.8, value)) * 32767)))
    with wave.open(str(DEST / (name + '.wav')), 'wb') as out:
        out.setnchannels(1)
        out.setsampwidth(2)
        out.setframerate(RATE)
        out.writeframes(pcm)

for name, seconds, rifle in [('shot', .32, False), ('rifle', .40, True), ('reload', .68, False)]:
    write(name, seconds, rifle)
    print(name + '.wav')
