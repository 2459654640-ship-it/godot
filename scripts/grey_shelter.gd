extends RefCounted
static func build(w):
 var k=w.kit
 k.wall_surface="city29_plaster";k.wall_normal="cement_normal";k.wall_color=Color("b9b8a2")
 preload("res://scripts/facility_shell.gd").build(w,w.CampaignMaps.LAYOUTS.grey_shelter,w.zones)
 # Dormitory, communal kitchen and repair room are actual enclosed rooms.
 for z in [3.5,7.2]:
  for x in [3,7.5]:k.bed(Vector3(x,0,z),"cloth")
 for x in [2,6.5]:k.locker(Vector3(x,0,8.4))
 k.table(Vector3(-5.5,0,-2.5),3);k.bench(Vector3(-5.5,0,-1.2),2.6,true,PI)
 k.box("ShelterKitchenStove",Vector3(-8,.55,-6.8),Vector3(1.5,1.1,.9),"old_iron",true)
 for x in [-8.4,-7.7]:k.cyl("ShelterCookingPot",Vector3(x,1.3,-6.8),.22,.35,"metal")
 k.pipe(Vector3(-8.5,1,-7),Vector3(-8.5,2.8,-7),.1,"rust")
 k.table(Vector3(5.5,0,-6.8),3.5)
 for x in [4.6,5.5,6.4]:k.box("WeaponsRepairParts",Vector3(x,.84,-6.8),Vector3(.4,.09,.24),"metal")
 for z in [-5,-2]:k.crate(Vector3(8.5,0,z),Vector3(1,.8,.8))
 for x in [-7,7]:
  k.pipe(Vector3(x,2.6,-8),Vector3(x,2.6,8),.12,"rust")
  for z in [-6,0,6]:k.box("ShelterPipeBracket",Vector3(x,2.6,z),Vector3(.4,.15,.15),"old_iron")
 for p in [Vector3(-4,2.5,-3),Vector3(5,2.5,-4),Vector3(5,2.5,5),Vector3(-4,2.5,5)]:k.lamp(p,true,1.4,8)
 k.box("ShelterExitDoor",Vector3(-7.5,1.1,9),Vector3(1.8,2.2,.16),"corrugated",true)
 k.label("ВЫХОД",Vector3(-7.5,2.35,8.85),19,Color("d4c4a3"))
 # Washing corner and ration shelves occupy the entry side, leaving the exit path open.
 for x in [-5,-2.5]:
  k.box("ShelterStoreShelf",Vector3(x,.7,8.5),Vector3(1.7,.10,.8),"wood")
  k.box("ShelterStoreShelf",Vector3(x,1.45,8.5),Vector3(1.7,.10,.8),"wood")
  for dx in [-.75,.75]:k.box("ShelterShelfPost",Vector3(x+dx,.9,8.5),Vector3(.07,1.8,.7),"old_iron",true)
  for dx in [-.5,0,.5]:k.cyl("SalvagedFoodTin",Vector3(x+dx,.86,8.5),.12,.23,"metal")
 for x in [-8.5,-6.8]:
  k.cyl("ShelterWaterDrum",Vector3(x,.5,2),.38,1,"old_iron")
  k.box("ShelterWaterFootprint",Vector3(x,.5,2),Vector3(.8,1,.8),"dark",true).visible=false
 k.box("ShelterToolBoard",Vector3(5,1.65,-8.82),Vector3(3.2,1.15,.10),"wood")
 for x in [4,4.5,5,5.5,6]:k.box("HungSpareTool",Vector3(x,1.6,-8.72),Vector3(.08,.6,.05),"metal")
 for p in [Vector3(-9.7,0,-8.7),Vector3(9.7,0,-8.7),Vector3(9.7,0,9.7),Vector3(-9.7,0,9.7)]:
  k.box("BunkerCornerPier",p+Vector3.UP*1.4,Vector3(.42,2.8,.42),"concrete",true)
 k.finish_walls()
static func enter(w):
 if w.floor_id!="east_district" or not w.targets.has("grey_shelter_entry") or w.player.position.distance_to(w.targets.grey_shelter_entry.pos)>2.5:return
 if not preload("res://scripts/raid_loot.gd").safe(w):w.hud.toast("岗哨正在盯着入口，先绕开他们的视线。");return
 w.story.Campaign.District.remember_combat(w);w.story.flags.visited_grey_shelter=true
 if not w.story.f("arrival_v8_grey_shelter"):
  w.story.flags.arrival_v8_grey_shelter=true;w.hud.show_comic("arrive_grey_shelter");return
 w.get_node("/root/Session").enter(w.save_snapshot(),"grey_shelter",Vector3(-7.5,.04,7.7))
static func leave(w):
 if w.floor_id!="grey_shelter" or w.player.position.distance_to(Vector3(-7.5,0,8))>2.5:return
 if not preload("res://scripts/raid_loot.gd").safe(w):w.hud.toast("先脱离入口附近的交火，再沿楼梯撤出。");return
 w.get_node("/root/Session").enter(w.save_snapshot(),"east_district",Vector3(41,.04,-11))
