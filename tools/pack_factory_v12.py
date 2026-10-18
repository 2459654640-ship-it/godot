"""Pack authored atlas panels without painting, deforming or stacking wall skins."""
from pathlib import Path
from PIL import Image
ROOT=Path(__file__).resolve().parents[1]
def panels(file,names):
 im=Image.open(ROOT/'art-source/v12'/file).convert('RGB')
 for i,name in enumerate(names):
  x=i%3;y=i//3
  tile=im.crop((round(x*im.width/3),round(y*im.height/2),round((x+1)*im.width/3),round((y+1)*im.height/2)))
  tile.resize((512,512),Image.Resampling.LANCZOS).save(ROOT/'assets/visual'/f'{name}.png',optimize=True)
panels('factory_materials.png',['plant_damp_floor','plant_blue_wall','plant_ivory_tile','plant_rust_steel','plant_rubber','plant_archive_wall'])
if (ROOT/'art-source/v12/factory_decals.png').exists():
 panels('factory_decals.png',['plant_pump_chart','plant_safety_chart','plant_roster_chart','plant_filter_label','plant_tool_board','plant_electric_warning'])
