"""Current character reference from shipped atlases, not a gameplay screenshot."""
from pathlib import Path
from PIL import Image,ImageDraw
import json,re,math
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'docs/characters';OUT.mkdir(exist_ok=True)
manifest=json.loads((ROOT/'assets/characters/atlas.json').read_text());line=re.search(r'const HEIGHTS=(\{[^\n]+\})',(ROOT/'scripts/painted_actor.gd').read_text()).group(1);heights=json.loads(line)
for key in ['ivan','ivan_masked','ivan_combat','ivan_masked_combat']:
 spec=manifest[key];im=Image.open(ROOT/'assets/characters'/spec['file']).convert('RGBA');cw,ch=spec['cell'];rows=[0,3,4,2] if spec['poses']==7 else [0,1,2];board=Image.new('RGB',(320*8,380*len(rows)),(65,62,58));d=ImageDraw.Draw(board)
 for row,source_row in enumerate(rows):
  for col in range(8):
   tile=im.crop((cw*col,ch*source_row,cw*(col+1),ch*(source_row+1)));tile.thumbnail((310,345));board.paste(tile,(col*320+(320-tile.width)//2,row*380+28),tile);d.text((col*320+8,row*380+8),key+' '+str(col*45)+' deg '+spec['clips'][source_row],fill='white')
 board.save(OUT/(key+'-eight-directions.png'),optimize=True)
keys=list(manifest);board=Image.new('RGB',(300*6,390*math.ceil(len(keys)/6)),(65,62,58));d=ImageDraw.Draw(board)
for i,key in enumerate(keys):
 spec=manifest[key];cw,ch=spec['cell'];im=Image.open(ROOT/'assets/characters'/spec['file']).convert('RGBA').crop((0,0,cw,ch));height=heights.get(key.removesuffix('_combat'),1.75);scale=260*height/1.75/spec.get('body_pixels',324);tile=im.resize((round(cw*scale),round(ch*scale)),Image.Resampling.LANCZOS);x=i%6*300+(300-tile.width)//2;y=i//6*390+360-tile.height;board.paste(tile,(x,y),tile);d.text((i%6*300+8,i//6*390+8),key,fill='white')
board.save(OUT/'all-characters.png',optimize=True);print('Current reference gallery:',len(keys),'entries')
