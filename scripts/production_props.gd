extends RefCounted
## Reusable measured props. Parent heading is applied before collisions are registered.
static func material(k,id:String,texture:String,color:String,scale:float=.5):
 var m=k.mats.concrete.duplicate();m.albedo_texture=load("res://assets/visual/"+texture+".png");m.albedo_color=Color(color);m.normal_enabled=false;m.roughness_texture=null;m.uv1_scale=Vector3.ONE*scale;m.roughness=.84;k.mats[id]=m
static func prepare(k):
 material(k,"institution_floor","art28_terrazzo","b7bab0",.26)
 material(k,"institution_enamel","star_enamel","92a39d",.7)
 material(k,"institution_tile","plant_ivory_tile","b7bcb2",.65)
 material(k,"junction_stone","art28_terrazzo","aaa99c",.42)
 material(k,"junction_paint","factory_green_wall_v13","7e8b7d",.5)
 material(k,"dark_steel","star_enamel","495e5f",.65)
 material(k,"warm_wood","timber","95866c",.5)
static func root(k,name:String,p:Vector3,heading:float=0)->Node3D:
 var n=Node3D.new();n.name=name;k.root.add_child(n);n.position=p;n.rotation.y=heading;return n
static func bevel(k,id:String,p:Vector3,size:Vector3,mat:String,parent:Node3D=null,solid:bool=false,b:float=.045)->MeshInstance3D:
 # A chamfered metal housing, with face, edge and corner normals.
 var half=size*.5;b=minf(b,minf(half.x,minf(half.y,half.z))*.45)
 var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
 for axis in 3:
  var u=(axis+1)%3;var v=(axis+2)%3
  for sign in [-1.,1.]:
   var q=[]
   for corner in [Vector2(-1,-1),Vector2(1,-1),Vector2(1,1),Vector2(-1,1)]:
    var pos=Vector3.ZERO;pos[axis]=half[axis]*sign;pos[u]=(half[u]-b)*corner.x;pos[v]=(half[v]-b)*corner.y;q.append(pos)
   var normal=Vector3.ZERO;normal[axis]=sign;quad(st,q,normal)
 for a in 3:
  var u=(a+1)%3;var v=(a+2)%3
  for su in [-1.,1.]:
   for sv in [-1.,1.]:
    var q=[]
    for side in [-1.,1.]:
     var p1=Vector3.ZERO;p1[a]=(half[a]-b)*side;p1[u]=half[u]*su;p1[v]=(half[v]-b)*sv
     var p2=p1;p2[u]=(half[u]-b)*su;p2[v]=half[v]*sv
     if side<0:q.append(p1);q.append(p2)
     else:q.append(p2);q.append(p1)
    var normal=Vector3.ZERO;normal[u]=su;normal[v]=sv;quad(st,q,normal.normalized())
 for sx in [-1.,1.]:
  for sy in [-1.,1.]:
   for sz in [-1.,1.]:
    var sign=Vector3(sx,sy,sz);var points=[]
    for a in 3:
     var p1=(half-Vector3.ONE*b)*sign;p1[a]=half[a]*sign[a];points.append(p1)
    triangle(st,points,sign.normalized())
 var mesh=MeshInstance3D.new();mesh.name=id;mesh.mesh=st.commit();mesh.material_override=k.mats[mat];(parent if parent else k.root).add_child(mesh);mesh.position=p;mesh.set_meta("design_id",id)
 if solid:
  var hull=k.box(id+"_Hull",p,size,mat,true,parent);hull.visible=false
  if parent:
   var bounds:AABB=hull.global_transform*hull.get_aabb()
   k.solids.append({"name":id+"_Hull","rect":Rect2(bounds.position.x,bounds.position.z,bounds.size.x,bounds.size.z),"bottom":bounds.position.y,"top":bounds.end.y})
 return mesh
static func triangle(st,points:Array,n:Vector3):
 var p=points.duplicate()
 if (p[1]-p[0]).cross(p[2]-p[0]).dot(n)<0:p.reverse()
 for v in p:st.set_normal(n);st.set_uv(Vector2(v.x,v.z));st.add_vertex(v)
static func quad(st,q:Array,n:Vector3):triangle(st,[q[0],q[1],q[2]],n);triangle(st,[q[0],q[2],q[3]],n)
static func chair(k,p:Vector3,heading:float=0):
 var n=root(k,"UtilityChair",p,heading)
 bevel(k,"ChairSeat",Vector3(0,.46,0),Vector3(.48,.10,.48),"warm_wood",n,true)
 bevel(k,"ChairBack",Vector3(0,.83,.22),Vector3(.49,.45,.065),"warm_wood",n)
 for x in [-.18,.18]:
  for z in [-.18,.18]:k.cyl("ChairLeg",Vector3(x,.23,z),.023,.46,"dark_steel",n)
static func console(k,p:Vector3,heading:float=0,width:float=1.5):
 var n=root(k,"AnalogConsole",p,heading)
 bevel(k,"ConsoleBase",Vector3(0,.42,0),Vector3(width,.84,.68),"dark_steel",n,true)
 bevel(k,"ConsolePanel",Vector3(0,.98,0),Vector3(width+.06,.30,.8),"institution_enamel",n)
 for x in [-width*.28,width*.12]:
  bevel(k,"MeterRim",Vector3(x,1.03,.41),Vector3(.35,.21,.03),"brass",n)
  k.box("MeterFace",Vector3(x,1.03,.432),Vector3(.31,.17,.012),"paper",false,n)
  k.box("MeterNeedle",Vector3(x,1.03,.445),Vector3(.012,.12,.008),"black",false,n).rotation.z=.28
 for x in [-.26,0,.26]:
  k.cyl("ConsoleToggle",Vector3(x,1.15,.15),.025,.06,"black",n)
  k.box("ConsoleCaption",Vector3(x,1.143,.23),Vector3(.14,.008,.045),"paper",false,n)
 k.box("PanelIndicator",Vector3(width*.39,1.04,.425),Vector3(.06,.07,.02),"warm_light",false,n)
static func rack(k,p:Vector3,heading:float=0):
 var n=root(k,"InstrumentRack",p,heading)
 bevel(k,"RackCabinet",Vector3(0,1.05,0),Vector3(.95,2.10,.62),"dark_steel",n,true)
 for y in [.4,.85,1.3,1.75]:
  bevel(k,"RackUnit",Vector3(0,y,.33),Vector3(.83,.33,.045),"institution_enamel",n)
  k.box("RackMeter",Vector3(-.22,y,.359),Vector3(.25,.19,.012),"paper",false,n)
  for x in [.05,.23]:k.cyl("RackKnob",Vector3(x,y,.383),.045,.045,"black",n).rotation.x=PI/2
  k.box("RackNameplate",Vector3(0,y-.105,.365),Vector3(.38,.025,.01),"paper",false,n)
 for y in [.22,1.98]:k.box("RackVent",Vector3(0,y,.335),Vector3(.66,.035,.02),"black",false,n)
static func arch(k,centre:Vector3,width:float,height:float,heading:float=0):
 for i in 16:
  var a=PI*float(i)/16.;var b=PI*float(i+1)/16.
  var p1=Vector3(cos(a)*width*.5,sin(a)*height,0).rotated(Vector3.UP,heading)+centre
  var p2=Vector3(cos(b)*width*.5,sin(b)*height,0).rotated(Vector3.UP,heading)+centre
  k.pipe(p1,p2,.055,"institution_enamel")
static func carriage(k,p:Vector3,heading:float=0,medical:bool=false):
 var n=root(k,"MedicalCarriage" if medical else "FreightCarriage",p,heading)
 bevel(k,"CarChassis",Vector3(0,.45,0),Vector3(2.45,.30,8.8),"dark_steel",n,true)
 k.box("CarInteriorFloor",Vector3(0,.62,0),Vector3(2.35,.05,8.5),"warm_wood",false,n)
 for x in [-1.15,1.15]:
  k.box("CarSideLower",Vector3(x,1.2,0),Vector3(.12,1.1,8.5),"junction_paint",false,n)
  k.box("CarSideCrown",Vector3(x,2.50,0),Vector3(.12,.38,8.5),"junction_paint",false,n)
  for z in [-4.2,-2.1,0,2.1,4.2]:k.box("CarWindowPillar",Vector3(x,2.0,z),Vector3(.12,.9,.15),"junction_paint",false,n)
 for z in [-4.3,4.3]:
  k.box("CarEndPanel",Vector3(0,1.55,z),Vector3(2.3,1.85,.10),"junction_paint",false,n)
  k.box("CarEndGlass",Vector3(0,2.0,z+.065),Vector3(.72,.5,.025),"dark",false,n)
 for x in [-.99,.99]:
  for z in [-2.8,2.8]:k.cyl("CarWheel",Vector3(x,.25,z),.3,.14,"dark",n).rotation.z=PI/2
 # An open, curved roof frame preserves the cutaway view and fades over characters.
 for z in [-3.5,-1.75,0,1.75,3.5]:
  for i in 12:
   var a=PI*float(i)/12.;var b=PI*float(i+1)/12.
   var one=Vector3(cos(a)*1.22,2.67+sin(a)*.4,z);var two=Vector3(cos(b)*1.22,2.67+sin(b)*.4,z)
   k.pipe(n.global_transform*one,n.global_transform*two,.035,"dark_steel")
 if medical:
  for mesh in n.find_children("*","MeshInstance3D",true,false):mesh.set_meta("dynamic",true)
  k.box("CarMedicalMarkV",Vector3(1.225,1.35,1.2),Vector3(.025,.55,.14),"paper",false,n)
  k.box("CarMedicalMarkH",Vector3(1.23,1.35,1.2),Vector3(.025,.14,.55),"paper",false,n)
 return n
