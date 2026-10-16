"""Original layered material maps and inventory illustrations, seed 1982.

Only run to regenerate art assets. Pillow/numpy are not game dependencies.
No reference image, downloaded material or story data is embedded here.
"""
from pathlib import Path
import math
import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parents[1] / 'assets' / 'visual'
ROOT.mkdir(parents=True, exist_ok=True)
RNG = np.random.default_rng(1982)
N = 512


def noise(n=N):
    out = np.zeros((n, n), dtype=float)
    for grid, weight in [(4, .34), (12, .27), (32, .20), (96, .13), (n, .06)]:
        a = RNG.random((grid, grid))
        im = Image.fromarray(np.uint8(a * 255)).resize((n, n), Image.Resampling.BICUBIC)
        out += np.asarray(im) / 255.0 * weight
    return out


def maps(name, color, height, roughness=.9):
    Image.fromarray(np.uint8(np.clip(color, 0, 255))).save(ROOT / f'{name}.png')
    gy, gx = np.gradient(height * 5.0)
    normal = np.stack([-gx, gy, np.ones_like(gx)], axis=-1)
    normal /= np.linalg.norm(normal, axis=-1, keepdims=True)
    Image.fromarray(np.uint8((normal * .5 + .5) * 255)).save(ROOT / f'{name}_normal.png')
    Image.fromarray(np.uint8(np.clip(roughness + (noise() - .5) * .15, 0, 1) * 255)).save(ROOT / f'{name}_rough.png')


def wall():
    n, fine = noise(), RNG.random((N, N))
    yy, xx = np.mgrid[0:N, 0:N]
    boundary = N * .59 + np.sin(xx / 23) * 1.3
    lower = yy > boundary
    pigment = np.where(lower[..., None], [69, 80, 65], [156, 147, 119]).astype(float)
    plaster = np.array([111, 106, 87])
    chips = (noise() < .32) | (fine < .006)
    chips |= (np.abs(yy - boundary) < 3) & (fine < .45)
    pigment[chips] = plaster
    pigment += ((n - .5) * 49 + (fine - .5) * 6)[..., None]
    # Leaks, oxidized brushwork, damp skirting and crumbled aggregate.
    for _ in range(24):
        x = RNG.integers(0, N)
        width = RNG.uniform(1.5, 8)
        start = RNG.integers(0, N // 2)
        run = np.maximum(0, 1 - (yy - start) / RNG.uniform(90, 370)) * (yy >= start)
        streak = np.exp(-((xx - x) / width) ** 2) * run
        pigment -= streak[..., None] * np.array([21, 24, 21])
    pigment -= (np.maximum(0, yy / N - .86) * 160)[..., None]
    image = Image.fromarray(np.uint8(np.clip(pigment, 0, 255)))
    d = ImageDraw.Draw(image)
    for _ in range(13):
        x, y = int(RNG.integers(N)), int(RNG.integers(N))
        pts = [(x, y)]
        for _ in range(int(RNG.integers(4, 12))):
            x += int(RNG.integers(-9, 10)); y += int(RNG.integers(2, 11)); pts.append((x, y))
        d.line(pts, fill=(70, 70, 59), width=1)
    h = n * .22 + chips * .13
    maps('wall', np.asarray(image), h)


def floors():
    n = noise()
    yy, xx = np.mgrid[0:N, 0:N]
    tile = N // 4
    variation = RNG.uniform(-14, 12, (4, 4))
    values = variation[np.minimum(yy // tile, 3), np.minimum(xx // tile, 3)]
    color = np.array([98, 97, 81]) + ((n - .5) * 63 + values)[..., None]
    grout = (xx % tile < 2) | (yy % tile < 2)
    color[grout] = [43, 44, 38]
    image = Image.fromarray(np.uint8(np.clip(color, 0, 255)))
    d = ImageDraw.Draw(image)
    for _ in range(440):
        x, y = int(RNG.integers(N)), int(RNG.integers(N))
        d.line((x, y, x + int(RNG.integers(1, 13)), y + int(RNG.integers(-2, 3))), fill=(113, 110, 92), width=1)
    for _ in range(20):
        x, y = int(RNG.integers(N)), int(RNG.integers(N))
        d.line([(x, y), (x+8, y+11), (x+4, y+18), (x+16, y+32)], fill=(45, 47, 40), width=1)
    maps('floor', np.asarray(image), n*.2-grout*.2)
    maps('cement', np.array([81, 85, 78])+((noise()-.5)*68)[..., None], noise()*.25)


def surfaces():
    n = noise(); yy, xx = np.mgrid[0:N, 0:N]
    for name, base in [('steel', [67, 76, 69]), ('oxide', [98, 61, 38])]:
        color = np.array(base) + ((n-.5)*52)[..., None]
        rust = noise() < .31
        color[rust] = np.array([101, 65, 41]) + ((n[rust]-.5)*35)[:, None]
        maps(name, color, n*.2 + rust*.06, .8)
    grain = np.sin(xx*.18 + np.sin(yy*.012)*6 + noise()*12)
    maps('timber', np.array([100, 74, 47])+((noise()-.5)*45+grain*8)[..., None], noise()*.10+grain*.025)
    weave = ((xx % 4 < 2).astype(float)+(yy % 4 < 2).astype(float)) * 2
    maps('weave', np.array([126, 126, 106])+((noise()-.5)*32+weave)[..., None], noise()*.04+weave*.03)


def poster():
    font = '/usr/share/fonts/truetype/dejavu/DejaVuSansCondensed-Bold.ttf'
    for index in range(3):
        im = Image.new('RGB', (512, 768), (173, 155, 111)); d = ImageDraw.Draw(im)
        red = (124, 44, 28); ink = (47, 50, 42)
        d.rectangle((19, 18, 494, 749), outline=red, width=9)
        lines = [('БЕРЕГИТЕ', 'ВОДУ', 'КАЖДАЯ КАПЛЯ — ЖИЗНЬ'), ('ТРУД', 'И ЧЕСТЬ', 'ДИСЦИПЛИНА СПАСАЕТ'), ('Д–6', '1982', 'МЫ ДЕРЖИМ СВЕТ')][index]
        for y, text, size in [(42, lines[0], 53), (114, lines[1], 65), (649, lines[2], 25)]:
            f = ImageFont.truetype(font, size)
            box = d.textbbox((0,0), text, font=f)
            d.text(((512-box[2])/2,y),text,font=f,fill=red)
        # Original geometric printmaking motifs: cistern, worker, electrical star.
        for i in range(11):
            x = 256 + (i-5)*42
            d.polygon([(256,395),(x-12,240),(x+12,240)], fill=red)
        d.ellipse((168,273,341,443), fill=ink)
        d.polygon([(211,391),(306,385),(365,568),(157,568)], fill=ink)
        d.polygon([(173,306),(311,288),(332,335),(177,341)], fill=red)
        d.line((115,574,397,574),fill=red,width=8)
        color=np.asarray(im).astype(float)
        color+=((noise(768)[:,:512]-.5)*32)[...,None]
        speck=RNG.random((768,512))<.006
        color[speck]=[94,85,65]
        Image.fromarray(np.uint8(np.clip(color,0,255))).save(ROOT/f'poster_{index}.png')


def icon_art():
    ids=['knife','cigarettes','photo','vodka','map','wrench','fuse','soup','permit','order','mask','filter','vitamins','frequency']
    for ident in ids:
        im=Image.new('RGBA',(144,144));d=ImageDraw.Draw(im)
        metal=(139,148,138); edge=(37,44,40); gold=(175,147,93); paper=(182,169,130)
        if ident in ['map','permit','order','frequency','photo']:
            d.polygon([(34,22),(109,27),(115,120),(28,115)], fill=paper, outline=edge,width=3)
            if ident=='photo':
                d.rectangle((42,37,99,98), fill=(81,83,68))
                d.ellipse((53,45,76,68), fill=(158,147,117)); d.polygon([(43,93),(57,67),(76,67),(89,93)],fill=(119,116,91))
            else:
                for y in range(45,104,11):d.line((44,y,99,y+2),fill=(101,98,75),width=2)
                d.ellipse((69,73,103,106),outline=(135,57,38),width=4)
        elif ident in ['vodka','vitamins','fuse','filter']:
            box=(53,38,91,121) if ident!='filter' else (42,42,103,118)
            color=(73,96,74) if ident=='vodka' else metal
            d.rounded_rectangle(box,8,fill=color,outline=edge,width=3)
            d.rectangle((60,20,84,39),fill=gold,outline=edge,width=2)
            d.rectangle((box[0]+4,68,box[2]-4,99),fill=paper)
            d.line((box[0]+6,109,box[2]-6,109),fill=(44,51,43),width=3)
            if ident=='vitamins':d.text((66,73),'D',fill=(120,58,39))
        elif ident in ['knife','wrench']:
            if ident=='knife':
                d.polygon([(40,111),(86,35),(105,20),(104,48),(58,122)],fill=metal,outline=edge,width=3)
                d.line((88,40,47,111),fill=(211,208,177),width=2)
                d.line((43,109,29,129),fill=(91,65,42),width=12)
                d.line((31,102,60,120),fill=gold,width=5)
            else:
                d.line((36,118,92,44),fill=edge,width=19);d.line((36,118,92,44),fill=metal,width=13)
                d.arc((75,19,117,61),-40,240,fill=metal,width=12)
                d.ellipse((28,112,43,127),outline=edge,width=4)
        elif ident=='cigarettes':
            d.polygon([(35,37),(101,27),(111,112),(45,122)],fill=paper,outline=edge,width=3)
            d.polygon([(39,76),(106,66),(111,112),(45,122)],fill=(132,54,35))
            for x in [48,60,72,84]:d.line((x,17,x+4,46),fill=(207,193,153),width=6)
        elif ident=='soup':
            d.ellipse((24,48,119,107),fill=metal,outline=edge,width=3)
            d.ellipse((28,44,115,87),fill=(120,80,42),outline=gold,width=4)
            for x,y in [(48,61),(81,59),(69,72)]:d.ellipse((x,y,x+11,y+7),fill=(167,133,65))
            d.arc((64,12,87,52),70,245,fill=(172,172,151),width=3)
        elif ident=='mask':
            d.ellipse((29,22,114,116),fill=(83,92,68),outline=edge,width=3)
            for x in [34,77]:
                d.ellipse((x,42,x+34,76),fill=(32,43,41),outline=metal,width=4)
                d.arc((x+6,48,x+27,69),190,280,fill=(129,155,147),width=3)
            d.ellipse((55,79,91,122),fill=(66,74,61),outline=gold,width=3)
            for y in [91,99,107]:d.line((63,y,84,y),fill=edge,width=3)
        im.save(ROOT/f'item_{ident}.png')


if __name__ == '__main__':
    wall(); floors(); surfaces(); poster(); icon_art()
    print('Original albedo/normal/roughness maps, posters and 14 item illustrations generated.')
