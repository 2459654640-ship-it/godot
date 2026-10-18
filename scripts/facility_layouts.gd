extends RefCounted
## Authored footprints, open circulation and door normals in metres, independent of decoration.
const PLANS={
"waterworks":{
	"spawn":Vector3(15,.04,9),"palette":"78877f","ambient":"82949e","energy":.19,"warm":false,
	"rooms":[["01","西侧泵房",Rect2(-19,-14,13,14)],["02","工具修配",Rect2(-6,-10,11,10)],["03","封存仓库",Rect2(5,-14,14,14)],["04","交接档案室",Rect2(-23,4,13,8)],["05","送电控制室",Rect2(-10,4,14,9)],["06","入口气闸",Rect2(4,4,15,8)],["00","设备联络廊",Rect2(-23,0,42,4)]],
	"doors":[[-12,0,"z"],[-1,0,"z"],[12,0,"z"],[-17,4,"z"],[-3,4,"z"],[12,4,"z"],[-6,-6,"x"],[15,12,"z",1.6]],
	"objects":[["plant_bypass",-12,-6,"valve"],["plant_bench",-1,-6,"bench"],["plant_store",11,-6,"store"],["plant_log",-17,7,"desk"],["plant_power",0,7,"panel"],["plant_diagram",8,6,"paper"],["plant_exit",15,10.8,"factory_exit"],["plant_lockers",3,-4,"lockers"],["plant_seals",-8,-2,"shelf"]],
	"gate":Vector3(12,1.1,0),"gate_flag":"plant_power"},
"commune":{
 "spawn":Vector3(25,.04,2),"palette":"c4b99f","ambient":"b0a68b","energy":.24,"warm":true,
 "rooms":[["01","地下温室",Rect2(-29,-22,18,33)],["02","公共厅与配给室",Rect2(-11,-4,23,10)],["03","联络档案室",Rect2(12,-14,11,14)],["04","人民议事厅",Rect2(-11,-12,23,8)],["05","公社医务室",Rect2(-11,16,13,8)],["06","联络气闸",Rect2(23,0,7,4)],["07","家属房与客铺",Rect2(12,4,11,20)],["08","公社食堂",Rect2(-11,6,13,10)],["09","共用厨房",Rect2(2,6,10,10)],["10","守备值班与军需",Rect2(2,16,10,8)],["11","机修与绕线间",Rect2(-11,-22,8,8)],["12","缝补与制鞋工房",Rect2(-3,-22,7,8)],["13","锅炉房",Rect2(4,-22,8,8)],["00","生产联络廊",Rect2(-11,-14,23,2)],["00","联络前厅",Rect2(12,0,11,4)]],
 "doors":[[-11,-6,"x"],[-11,3,"x"],[12,-7,"x"],[12,2,"x"],[23,2,"x"],[17,4,"z"],[12,9,"x"],[12,19,"x"],[-3,6,"z"],[5,6,"z"],[2,11,"x"],[-5,16,"z"],[7,16,"z"],[2,20,"x"],[.5,-4,"z",1.5],[-11,-13,"x",.8],[12,-13,"x",.8],[-9.5,-12,"z"],[-7,-14,"z"],[.5,-14,"z"],[8,-14,"z"]],
 "objects":[["commune_greenhouse",-12.8,-2,"garden"],["commune_well",8,2,"ledger"],["commune_records",17,-6,"desk"],["commune_leader",-5,-9.5,"npc"],["commune_anna",-4,20,"npc"],["commune_leave",25,2,"exit"],["commune_printer",20,-3,"npc"],["commune_grower",-13,7,"npc"],["commune_proof",20,-7,"press"],["commune_mushroom",-20,-6.5,"marker"],["commune_receiver",14,-10,"radio"],["commune_cook",5,11,"npc"],["commune_hall",2,-7.3,"marker"],["commune_radiator",20.9,22.8,"marker"],["commune_child",3,3,"npc"],["commune_bunks",14.8,12,"marker"],["commune_moro",6.2,-16.5,"npc"],["commune_guard",8.8,18.1,"npc"],["commune_baranova",20.6,19.5,"npc"],["commune_salvage",-6,-17,"marker"],["commune_shift_archive",-9,-16.2,"marker"],["commune_tailor",.5,-17,"marker"],["commune_boiler",9,-19,"marker"]]},
"sech":{
 "spawn":Vector3(17,.04,16),"palette":"ad9b80","ambient":"929caf","energy":.23,"warm":true,
 "rooms":[["01","北线调度室",Rect2(-12,-21,8,7)],["02","电台维修车厢",Rect2(-12,-14,8,9)],["03","书房与晾晒间",Rect2(0,-24,9,10)],["04","储水与洗漱",Rect2(9,0,5,10)],["05","谢契议事室",Rect2(-4,-14,13,9)],["06","北线装卸站台",Rect2(14,-24,6,44)],["07","共用厨房与饭桌",Rect2(-16,-5,12,10)],["08","住户车厢与客铺",Rect2(-16,5,12,15)],["09","诊疗与缝补间",Rect2(-4,10,13,10)],["00","检修库公共厅",Rect2(-4,-5,13,15)],["00","北侧过桥",Rect2(9,-5,5,5)],["00","南侧过桥",Rect2(9,10,5,4)]],
 "open_edges":[["x",20,-24,20]],
 "doors":[[-8,-14,"z"],[-4,-10,"x"],[3,-14,"z"],[1,-5,"z",1.5],[-4,0,"x"],[-10,5,"z"],[-4,13,"x"],[3,10,"z"],[9,-2,"x"],[14,-2,"x"],[9,5,"x"],[14,5,"x"],[9,12,"x"],[14,12,"x"]],
 "objects":[["sech_manual",-8,-18,"desk"],["sech_radio",-8,-9,"radio"],["sech_sergey",5,-18,"npc"],["sech_water",11,6,"tank"],["sech_elder",4,-11,"npc"],["sech_leave",17,16,"exit"],["sech_quartermaster",5,14,"npc"],["sech_brake",17,11,"car_brake"],["sech_signal",17,-17,"signal"],["sech_bookshelf",5,-21,"marker"],["sech_cook",-10,1,"npc"],["sech_stove",-13,-2,"marker"],["sech_bunks",-10,11,"marker"],["sech_meeting",1,-9,"marker"]]},
"coal":{
	"spawn":Vector3(-13,.04,10),"palette":"817e72","ambient":"99a3a7","energy":.18,"warm":false,
	"rooms":[["01","班组档案",Rect2(-16,-11,14,9)],["02","医护值班",Rect2(-2,-18,11,5)],["03","井下休养间",Rect2(2,-11,14,9)],["04","探访登记",Rect2(-18,7,10,7)],["05","接送准备间",Rect2(-8,7,10,7)],["06","探视出口",Rect2(8,2,8,9)],["11","矿口提升与检票",Rect2(-28,-8,10,15)],["12","旧检修支巷",Rect2(-28,-22,10,14)],["00","煤运旧巷",Rect2(-18,2,20,5)],["00","照护联络廊",Rect2(-2,-13,4,15)],["00","休养间前廊",Rect2(2,-2,14,4)]],
	"doors":[[-18,4,"x"],[-23,-8,"z"],[-2,-6,"x"],[0,-13,"z"],[9,-2,"z"],[-13,7,"z"],[-3,7,"z"],[12,2,"z"],[0,2,"z"]],
	"objects":[["coal_archive",-10,-6,"desk"],["coal_medic",4,-15,"npc"],["coal_brother",10,-6,"npc"],["coal_clerk",-13,10,"npc"],["coal_exit",12,6,"exit"],["coal_tagboard",-15,12,"marker"],["coal_wash",-4,10,"wash"]]},
"starcity":{
	"spawn":Vector3(-14,.04,10),"palette":"81969a","ambient":"7e9da7","energy":.16,"warm":false,
	"rooms":[["01","配电隔离室",Rect2(-22,-11,11,9)],["02","旧转移档案",Rect2(-11,-19,9,4)],["03","测控室",Rect2(-7,-15,14,17)],["04","蓝门值班室",Rect2(-22,6,15,9)],["05","内门联锁台",Rect2(-7,6,14,5)],["06","远程通信室",Rect2(7,-5,14,11)],["00","检修侧廊",Rect2(-11,-11,4,13)],["00","隔离前廊",Rect2(-22,-2,11,4)],["00","蓝门前廊",Rect2(-22,2,29,4)]],
	"doors":[[-16,-2,"z"],[-9,2,"z"],[-16,2,"z"],[-14,6,"z"],[0,6,"z"],[0,2,"z"],[7,4,"x"],[-4,-15,"z"]],
	"objects":[["star_isolator",-16,-6,"panel"],["star_archive",-6,-17,"desk"],["star_father",-1.5,-12,"npc"],["star_manual",-18,10,"paper"],["star_guard",-12,10,"npc"],["star_bypass",3,8,"panel"],["star_radio",14,0,"radio"],["star_exit",17,4,"exit"],["star_technician",18,1,"npc"],["star_tape",19,-1,"marker"],["star_calibrator",10,1,"bench"],["star_handover",12,4,"marker"]],
	"gate":Vector3(0,1.1,2),"gate_flag":"star_access"}}
static func rooms(id:String)->Array:
	var out=[]
	for entry in PLANS[id].rooms:out.append({"code":entry[0],"name":entry[1],"rect":entry[2]})
	return out
static func door_specs(id:String)->Array:
	var out=[]
	for entry in PLANS[id].doors:out.append({"position":Vector2(entry[0],entry[1]),"axis":entry[2],"exterior":entry.size()>3})
	return out
