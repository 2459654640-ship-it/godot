extends RefCounted
const PLANS={
 "junction":{"spawn":Vector3(0,.04,20),"palette":"a5a995","ambient":"859b9d","energy":.22,"warm":false,
 "rooms":[["01","西北检修间",Rect2(-26,-22,17,14)],["02","医护与候车",Rect2(9,-20,17,15)],["03","西南工具间",Rect2(-26,7,17,15)],["04","调度与接收",Rect2(9,4,17,18)],["00","西侧维修廊",Rect2(-29,-8,20,15)],["00","货场换乘站台",Rect2(-9,-25,18,50)]],
 "doors":[[-9,-14,"x",1.4],[9,-12,"x",1.4],[-9,13,"x",1.4],[9,12,"x",1.4],[-18,-8,"z",1.3],[-18,7,"z",1.3],[-9,-3,"x",1.5]],"objects":[["junction_yuri",-18,-14,"marker"],["junction_car",2.5,10.5,"marker"],["junction_tools",-20,13,"marker"],["junction_switch",-3,19,"marker"],["junction_manifest",17,13,"marker"],["junction_family",17,-10,"marker"],["junction_exit",0,21,"marker"],["junction_bypass",-12,-3,"marker"],["junction_final_receiver",15,9,"marker"]]},
 "star_interior":{"spawn":Vector3(0,.04,18),"palette":"a6b4b0","ambient":"849d9d","energy":.24,"warm":false,
 "polygons":{"02":[Vector2(-8,-11),Vector2(8,-11),Vector2(12,-7),Vector2(12,5),Vector2(8,9),Vector2(-8,9),Vector2(-12,5),Vector2(-12,-7)]},
 "rooms":[["01","接待与交接间",Rect2(-12,9,24,12)],["02","测控大厅",Rect2(-12,-11,24,20)],["03","低压配电",Rect2(-28,-8,16,12)],["04","调阅档案",Rect2(-24,-25,12,14)],["05","仪器标定",Rect2(12,-23,16,15)],["06","通信与校核",Rect2(12,-8,20,17)],["07","休息与保管",Rect2(-28,9,16,12)],["08","观测记录台",Rect2(-12,-23,24,12)]],
 "doors":[[0,9,"z",1.6],[-12,-2,"x",1.3],[-12,-17,"x",1.2],[12,-15,"x",1.3],[12,2,"x",1.4],[-12,15,"x",1.3],[0,-11,"z",1.6]],
 "objects":[["late_star_guard",-6,15,"marker"],["late_father",-8,-4,"marker"],["late_lab",19,-16,"marker"],["late_archive",-18,-19,"marker"],["late_lev",21,3,"marker"],["late_planning",3,13,"marker"],["late_watchdesk",0,-18,"marker"],["late_star_exit",0,19,"marker"]]},
 "relay":{"spawn":Vector3(-24,.04,22),"palette":"a4afb4","ambient":"a0b0b9","energy":.36,"warm":false,
 "rooms":[["01","西侧控制屋",Rect2(-30,-24,20,18)],["02","馈线与天线基座",Rect2(8,-23,20,18)],["03","备用供电场",Rect2(5,5,21,15)],["04","南侧接应点",Rect2(-29,13,22,13)],["00","中继站检修场",Rect2(-34,-29,68,58)]],"doors":[],"objects":[["relay_power",-21,-12,"marker"],["relay_mast",17,-15,"marker"],["relay_probe",22,-23,"marker"],["relay_exit",-24,23,"marker"],["relay_generator",14,11,"marker"]]}}
