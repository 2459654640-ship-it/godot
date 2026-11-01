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
static func panel_face(k,parent:Node3D,p:Vector3,size:Vector2,variant:int=0,tilt:float=0):
 var face=MeshInstance3D.new();face.name="InstrumentFace";var quad_mesh=QuadMesh.new();quad_mesh.size=size;face.mesh=quad_mesh
 var ink=ShaderMaterial.new();ink.shader=load("res://assets/visual/control_panel.gdshader");ink.set_shader_parameter("panel_atlas",load("res://assets/visual/control_panels.png"));ink.set_shader_parameter("atlas_cell",Vector2(posmod(variant,2),posmod(variant/2,2)))
 face.material_override=ink;parent.add_child(face);face.position=p;face.rotation.x=tilt
 return face
static func console(k,p:Vector3,heading:float=0,width:float=1.5):
 var n=root(k,"AnalogConsole",p,heading)
 bevel(k,"ConsoleBase",Vector3(0,.42,0),Vector3(width,.84,.72),"dark_steel",n,true)
 # Sloping console housing; the face looks toward the operator at +Z.
 var left=-width*.5;var right=width*.5;var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
 var a=Vector3(left,.80,-.36);var b=Vector3(right,.80,-.36);var c=Vector3(right,.80,.47);var d=Vector3(left,.80,.47)
 var e=Vector3(left,1.62,-.36);var f=Vector3(right,1.62,-.36);var g=Vector3(right,1.02,.47);var h=Vector3(left,1.02,.47)
 quad(st,[a,b,c,d],Vector3.DOWN);quad(st,[a,b,f,e],Vector3.FORWARD);quad(st,[d,c,g,h],Vector3.BACK)
 quad(st,[a,d,h,e],Vector3.LEFT);quad(st,[b,f,g,c],Vector3.RIGHT);quad(st,[e,h,g,f],Vector3(0,.81,.59).normalized())
 var shell=MeshInstance3D.new();shell.name="SlopedConsoleHousing";shell.mesh=st.commit();shell.material_override=k.mats.institution_enamel;n.add_child(shell)
 var count=maxi(1,ceili(width/1.7));var step=width/count
 for i in count:
  var face_width=step-.08;var face_height=minf(.94,face_width/1.5)
  panel_face(k,n,Vector3(-width*.5+step*(i+.5),1.335,.073),Vector2(face_width,face_height),posmod(roundi(p.x+p.z)+i,4),-.945)
 for x in [-width*.5-.006,width*.5+.006]:
  for z in [-.18,0,.18]:k.box("ConsoleVent",Vector3(x,.42,z),Vector3(.012,.34,.055),"black",false,n)
static func rack(k,p:Vector3,heading:float=0):
 var n=root(k,"InstrumentRack",p,heading)
 bevel(k,"RackCabinet",Vector3(0,1.05,0),Vector3(.95,2.10,.62),"dark_steel",n,true)
 var i=0
 for y in [.43,1.05,1.67]:
  bevel(k,"RackUnitRim",Vector3(0,y,.33),Vector3(.86,.57,.045),"institution_enamel",n)
  panel_face(k,n,Vector3(0,y,.36),Vector2(.80,.533),posmod(roundi(p.x)+i,4));i+=1
 for y in [.12,2.01]:k.box("RackVent",Vector3(0,y,.335),Vector3(.66,.035,.02),"black",false,n)
static func gimbal(k,p:Vector3):
 var n=root(k,"CalibrationGimbal",p)
 bevel(k,"GimbalPlinth",Vector3(0,.16,0),Vector3(2.7,.32,2.7),"dark_steel",n,true)
 for x in [-1.24,1.24]:
  bevel(k,"GimbalBearingStand",Vector3(x,.94,0),Vector3(.16,1.56,.38),"institution_enamel",n)
  var bearing=k.cyl("GimbalBearing",Vector3(x,1.6,0),.13,.28,"brass",n);bearing.rotation.z=PI/2
 var radius=1.17
 for rot in [Vector3.ZERO,Vector3(PI/2,0,0),Vector3(0,0,PI/2)]:
  var ring=MeshInstance3D.new();ring.name="CalibrationRing";var mesh=TorusMesh.new();mesh.inner_radius=radius-.07;mesh.outer_radius=radius;mesh.rings=48;mesh.ring_segments=10;ring.mesh=mesh;ring.material_override=k.mats.brass;n.add_child(ring);ring.position=Vector3(0,1.6,0);ring.rotation=rot;radius-=.11
 k.ellipsoid("ReferenceMass",Vector3(0,1.6,0),Vector3(.42,.42,.42),"institution_enamel",n)
 var hull=k.box("GimbalCollision",p+Vector3(0,1.3,0),Vector3(2.5,2.6,2.5),"dark",true);hull.visible=false
 return n
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
  k.box("CarMedicalMarkV",Vector3(1.225,1.35,1.2),Vector3(.025,.55,.14),"paper",false,n)
  k.box("CarMedicalMarkH",Vector3(1.23,1.35,1.2),Vector3(.025,.14,.55),"paper",false,n)
  for mesh in n.find_children("*","MeshInstance3D",true,false):mesh.set_meta("dynamic",true)
 return n
