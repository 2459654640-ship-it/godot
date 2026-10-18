"""Pack original-reference redraws. No anatomy warping or limb compositing."""
from pathlib import Path
import json
from pack_v13_art import figures,pack

ROOT=Path(__file__).resolve().parents[1]
SOURCE=ROOT/'art-source/v14'

def main():
    report={}
    for actor in ['ivan','ivan_masked','commander','commander_masked']:
        rows=figures(SOURCE/(actor+'.png'),3)
        report[actor]=pack(actor,rows,revision=14)
    report['veteran_masked']=pack('veteran_masked',figures(SOURCE/'veteran_masked.png',1),clips=['idle'],revision=14)
    clips=['ready','shot','reload','walk_left','walk_right','reload_walk_left','reload_walk_right']
    for actor in ['ivan','ivan_masked','veteran_masked']:
        if actor=='ivan_masked':
            rows=figures(SOURCE/(actor+'_combat.png'),5)[:3]+figures(SOURCE/'ivan_masked_reload.png',3)
        else:rows=figures(SOURCE/(actor+'_combat.png'),6)
        fixed=figures(SOURCE/(actor+'_combat_front_back.png'),2,6)
        for pose in range(6):rows[pose][0]=fixed[0][pose];rows[pose][4]=fixed[1][pose]
        if actor=='veteran_masked':
            rear=figures(SOURCE/'veteran_combat_rear.png',1,6)[0]
            for pose in range(6):rows[pose][4]=rear[pose]
        report[actor+'_combat']=pack(actor+'_combat',[rows[i] for i in [0,0,3,1,2,4,5]],400,clips,revision=14)
    (SOURCE/'packing_report.json').write_text(json.dumps(report,indent=2)+'\n')
    print('Packed eight original-reference character sets.')

if __name__=='__main__':main()
