extends RefCounted
## Shared exterior architecture, in metres. Four walls, real recessed openings,
## floor plates and damaged roof silhouettes replace the old two-plane scenery.
static func materials(k):
 for spec in [["exterior_brick","ruined_brick",Color("bcb6ac"),.64],["exterior_render","cement",Color("91948d"),.4],["exterior_concrete","cement",Color("999e9e"),.55],["exterior_roof","corrugated",Color("687478"),.7]]:
  var ink=k.mats.concrete.duplicate()
  ink.albedo_texture=load("res://assets/visual/"+spec[1]+".png");ink.albedo_color=spec[2]
  ink.normal_enabled=false;ink.roughness_texture=null;ink.roughness=.96
  ink.uv1_scale=Vector3.ONE*spec[3];k.mats[spec[0]]=ink
 var glass=StandardMaterial3D.new();glass.albedo_color=Color("253b41");glass.roughness=.38;glass.metallic=.15;k.mats.exterior_glass=glass

static func block(k,p:Vector3,size:Vector2,storeys:int,seed:int)->Node3D:
 var root=Node3D.new();root.name="ExteriorBlock%d"%seed;root.position=p;k.root.add_child(root)
 root.set_meta("exterior_building",true);root.set_meta("footprint",Rect2(p.x-size.x/2,p.z-size.y/2,size.x,size.y))
 root.set_meta("storeys",storeys)
 var pitch=2.65;var h=storeys*pitch;var thickness=.32
 var finish="exterior_brick" if seed%3!=1 else "exterior_render"
 k.box("BuildingFoundation",Vector3(0,.05,0),Vector3(size.x+.25,.30,size.y+.25),"exterior_concrete",false,root)
 for level in storeys:
  var floor_y=.22+level*pitch
  k.box("BuildingFloorPlate",Vector3(0,floor_y,0),Vector3(size.x,.16,size.y),"exterior_concrete",false,root)
  # A remaining interior spine makes views through broken windows read as rooms.
  k.box("InteriorPartition",Vector3(-size.x*.18,floor_y+1.0,0),Vector3(.15,1.9,size.y*.65),"exterior_render",false,root)
  for face in 4:
   var along_x=face<2;var sign=-1 if face%2==0 else 1
   var width=size.x if along_x else size.y
   var wall_z=sign*size.y/2 if along_x else 0.0
   var wall_x=0.0 if along_x else sign*size.x/2
   var bays=maxi(2,floori(width/2.1));var bay=width/bays
   var opening=minf(1.25,bay-.48)
   for n in bays:
    var axis=-width/2+bay*(n+.5)
    var centre=Vector3(axis,0,wall_z) if along_x else Vector3(wall_x,0,axis)
    var sill=Vector3(bay,.70,thickness) if along_x else Vector3(thickness,.70,bay)
    var lintel=Vector3(bay,.62,thickness) if along_x else Vector3(thickness,.62,bay)
    var low=k.box("ExteriorWallSill",centre+Vector3.UP*(floor_y+.43),sill,finish,false,root);low.set_meta("wall_face",face)
    # One upper opening has lost its lintel, not an entire missing building side.
    var damaged=level==storeys-1 and n==0 and face==posmod(seed,4)
    if not damaged:k.box("ExteriorWindowLintel",centre+Vector3.UP*(floor_y+2.35),lintel,finish,false,root)
    for side in [-1,1]:
     var pier=centre+Vector3.UP*(floor_y+1.4)
     if along_x:pier.x+=side*(opening/2+(bay-opening)/4)
     else:pier.z+=side*(opening/2+(bay-opening)/4)
     k.box("ExteriorWindowPier",pier,Vector3((bay-opening)/2,1.24,thickness) if along_x else Vector3(thickness,1.24,(bay-opening)/2),finish,false,root)
    var out=Vector3(0,0,sign) if along_x else Vector3(sign,0,0)
    k.box("ProjectingStoneSill",centre+Vector3.UP*(floor_y+.79)+out*.045,Vector3(opening+.18,.10,.46) if along_x else Vector3(.46,.10,opening+.18),"exterior_concrete",false,root)
    # Frames follow the wall plane; panes are recessed inside the opening.
    for side in [-1,1]:
     var jamb=centre+Vector3.UP*(floor_y+1.40)-out*.04
     if along_x:jamb.x+=side*(opening/2-.035)
     else:jamb.z+=side*(opening/2-.035)
     k.box("DecayedWindowJamb",jamb,Vector3(.065,1.18,.09) if along_x else Vector3(.09,1.18,.065),"wood",false,root)
    if posmod(seed+n+face+level,3)!=0:
     k.box("RemainingWindowPane",centre+Vector3.UP*(floor_y+1.40)-out*.09,Vector3(opening-.14,1.10,.025) if along_x else Vector3(.025,1.10,opening-.14),"exterior_glass",false,root)
    if posmod(seed+n+face,3)==0:
     k.box("WindowCrossbar",centre+Vector3.UP*(floor_y+1.37),Vector3(opening,.045,.07) if along_x else Vector3(.07,.045,opening),"wood",false,root)
   k.box("FacadeFloorCourse",Vector3(wall_x,floor_y+.08,wall_z),Vector3(width+.10,.13,.40) if along_x else Vector3(.40,.13,width+.10),"exterior_concrete",false,root)
 # Partial roof, exposed supports and stepped broken parapets form a volume
 # from every camera angle. Snow rests above, never inside the wall texture.
 var roof_y=h+.28
 for panel in 3:
  var z=-size.y/2+size.y/3*(panel+.5)
  var span=size.x*(.46 if panel==posmod(seed,3) else .72)
  var centre=size.x/2-span/2
  k.box("RemainingRoofDeck",Vector3(centre,roof_y,z),Vector3(span,.18,size.y/3-.035),"exterior_roof",false,root)
  k.box("RoofSnowLoad",Vector3(centre,roof_y+.12,z),Vector3(span-.14,.065,size.y/3-.18),"surface_snow",false,root)
 for z in [-size.y*.36,0,size.y*.36]:k.box("ExposedRoofJoist",Vector3(0,roof_y-.07,z),Vector3(size.x,.18,.13),"old_iron",false,root)
 for side in [-1,1]:
  for n in 4:
   var width=size.x/4;var rise=.18+.12*posmod(n+seed,3)
   k.box("BrokenRoofParapet",Vector3(-size.x/2+width*(n+.5),roof_y+rise/2,side*size.y/2),Vector3(width-.05,rise,.32),finish,false,root)
 for x in [-size.x/2+.22,size.x/2-.22]:
  k.box("WeatheredRainPipe",Vector3(x,h/2,size.y/2+.22),Vector3(.075,h,.075),"rust",false,root)
 k.box("OldHeatingChimney",Vector3(size.x*.22,roof_y+.5,-size.y*.25),Vector3(.6,1,.6),"exterior_brick",false,root)
 k.box("ChimneyCap",Vector3(size.x*.22,roof_y+1.03,-size.y*.25),Vector3(.75,.12,.75),"exterior_concrete",false,root)
 k.box("ChimneySoot",Vector3(size.x*.22,roof_y+1.10,-size.y*.25),Vector3(.38,.025,.38),"dark",false,root)
 # Exposed courses where render has fallen away and a collapsed fragment
 # at the foot prevent every building reading as the same immaculate box.
 if finish=="exterior_render":
  k.box("ExposedBrickPatch",Vector3(-size.x*.30,.57,size.y/2+.166),Vector3(1.1,.48,.018),"exterior_brick",false,root)
  k.box("ExposedBrickPatch",Vector3(size.x/2+.166,pitch+.56,-size.y*.22),Vector3(.018,.45,1.2),"exterior_brick",false,root)
 var fallen=k.box("FallenWallFragment",Vector3(-size.x*.25,.15,size.y/2+.6),Vector3(1.5,.25,.9),finish,false,root);fallen.rotation.y=.3+seed*.23
 for n in 9:
  var at=Vector3(-size.x*.4+posmod(n*7+seed,11)*size.x*.075,.27,-size.y*.4+posmod(n*3+seed,9)*size.y*.09)
  var debris=k.box("MasonryAtBuildingFoot",at,Vector3(.3+.1*(n%3),.2,.25),finish,false,root);debris.rotation.y=n*.71
 return root

static func skyline(k):
 var positions=[Vector3(-34,0,-26),Vector3(-22,0,-31),Vector3(-6,0,-28),Vector3(19,0,-27),Vector3(31,0,-21),Vector3(-32,0,23),Vector3(-15,0,30),Vector3(8,0,29),Vector3(28,0,22)]
 for n in positions.size():
  var wide=5.0+posmod(n*7,6);var depth=4.8+posmod(n*3,4)
  block(k,positions[n],Vector2(wide,depth),2 if n%3 else 3,n)
  k.ellipsoid("BuildingSnowDrift",positions[n]+Vector3(0,.04,depth*.52),Vector3(wide*.48,.25,1.0),"snowbank")
