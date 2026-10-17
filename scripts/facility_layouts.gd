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
	"spawn":Vector3(25,.04,2),"palette":"b2a181","ambient":"b0a68b","energy":.23,"warm":true,
	"rooms":[["01","地下温室",Rect2(-23,-13,12,24)],["02","公用水井",Rect2(-11,-4,23,15)],["03","联络档案室",Rect2(12,-13,11,13)],["04","公社议事处",Rect2(-11,-8,23,4)],["05","医务与探访",Rect2(-11,11,14,9)],["06","联络气闸",Rect2(12,0,18,4)],["07","站台家属铺位",Rect2(12,4,11,13)]],
	"doors":[[-11,-6,"x"],[-11,3,"x"],[12,-2,"x"],[12,2,"x"],[12,7,"x"],[-3,11,"z"],[0,-4,"z"]],
	"objects":[["commune_greenhouse",-12.8,-2,"garden"],["commune_well",3,3,"well"],["commune_records",17,-6,"desk"],["commune_leader",-5,-6,"npc"],["commune_anna",-4,15,"npc"],["commune_leave",25,2,"exit"],["commune_printer",20,-3,"npc"],["commune_grower",-13,7,"npc"],["commune_proof",20,-7,"press"],["commune_mushroom",-20,-6.5,"marker"]]},
"sech":{
 "spawn":Vector3(1,.04,16),"palette":"8a7a64","ambient":"929caf","energy":.22,"warm":true,
 "rooms":[["01","调度车厢",Rect2(-8,-19,4,11)],["02","电台车厢",Rect2(-8,-6,4,7)],["04","水箱检修隔间",Rect2(-8,1,4,4)],["05","议事车厢",Rect2(-8,7,4,11)],["03","书架车厢",Rect2(4,-19,4,18)],["06","北线接送车厢",Rect2(4,2,4,16)],["00","检修库站台",Rect2(-4,-22,8,42)]],
 "doors":[[-4,-13,"x"],[-4,-2,"x"],[-6,1,"z"],[-4,12,"x"],[4,-9,"x"],[4,10,"x"]],
 "objects":[["sech_manual",-6,-16,"desk"],["sech_radio",-6,-2,"radio"],["sech_sergey",6,-3,"npc"],["sech_water",-6,3,"tank"],["sech_elder",-6,11,"npc"],["sech_leave",6,10,"exit"],["sech_quartermaster",-6,14.5,"npc"],["sech_brake",6,15,"car_brake"],["sech_signal",0,-19.5,"signal"],["sech_bookshelf",6,-13,"marker"]]},
"coal":{
	"spawn":Vector3(-13,.04,10),"palette":"817e72","ambient":"99a3a7","energy":.18,"warm":false,
	"rooms":[["01","班组档案",Rect2(-16,-11,14,9)],["02","医护值班",Rect2(-2,-18,11,5)],["03","井下休养间",Rect2(2,-11,14,9)],["04","探访登记",Rect2(-18,7,10,7)],["05","接送准备间",Rect2(-8,7,10,7)],["06","探视出口",Rect2(8,2,8,9)],["00","煤运旧巷",Rect2(-18,2,20,5)],["00","照护联络廊",Rect2(-2,-13,4,15)],["00","休养间前廊",Rect2(2,-2,14,4)]],
	"doors":[[-2,-6,"x"],[0,-13,"z"],[9,-2,"z"],[-13,7,"z"],[-3,7,"z"],[12,2,"z"],[0,2,"z"]],
	"objects":[["coal_archive",-10,-6,"desk"],["coal_medic",4,-15,"npc"],["coal_brother",10,-6,"npc"],["coal_clerk",-13,10,"npc"],["coal_exit",12,6,"exit"],["coal_tagboard",-15,12,"marker"],["coal_wash",-4,10,"wash"]]},
"starcity":{
	"spawn":Vector3(-14,.04,10),"palette":"81969a","ambient":"7e9da7","energy":.16,"warm":false,
	"rooms":[["01","配电隔离室",Rect2(-22,-11,11,9)],["02","旧转移档案",Rect2(-11,-19,9,4)],["03","测控室",Rect2(-7,-15,14,17)],["04","蓝门值班室",Rect2(-22,6,15,9)],["05","内门联锁台",Rect2(-7,6,14,5)],["06","远程通信室",Rect2(7,-5,14,11)],["00","检修侧廊",Rect2(-11,-11,4,13)],["00","隔离前廊",Rect2(-22,-2,11,4)],["00","蓝门前廊",Rect2(-22,2,29,4)]],
	"doors":[[-16,-2,"z"],[-9,2,"z"],[-16,2,"z"],[-14,6,"z"],[0,6,"z"],[0,2,"z"],[7,4,"x"],[-4,-15,"z"]],
	"objects":[["star_isolator",-16,-6,"panel"],["star_archive",-6,-17,"desk"],["star_father",-1.5,-12,"npc"],["star_manual",-18,10,"paper"],["star_guard",-12,10,"npc"],["star_bypass",3,8,"panel"],["star_radio",14,0,"radio"],["star_exit",17,4,"exit"],["star_technician",18,1,"npc"],["star_tape",19,-1,"marker"],["star_calibrator",10,1,"bench"]],
	"gate":Vector3(0,1.1,2),"gate_flag":"star_access"}}
static func rooms(id:String)->Array:
	var out=[]
	for entry in PLANS[id].rooms:out.append({"code":entry[0],"name":entry[1],"rect":entry[2]})
	return out
static func door_specs(id:String)->Array:
	var out=[]
	for entry in PLANS[id].doors:out.append({"position":Vector2(entry[0],entry[1]),"axis":entry[2],"exterior":entry.size()>3})
	return out
