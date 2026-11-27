extends RefCounted
## Upright, metre-scaled variants. The presentation and collider share the same shell.
const SIZES={
 "bag":Vector3(.62,.32,.45),"case":Vector3(.62,.32,.44),"tool":Vector3(.77,.36,.44),
 "crate":Vector3(.87,.60,.64),"foot":Vector3(.91,.48,.56),"cabinet":Vector3(.72,.79,.47),
 "med":Vector3(.65,.70,.43),"locker":Vector3(.64,1.38,.46)
}
const FINISH={"bag":"cloth","case":"wood","tool":"old_iron","crate":"wood","foot":"wood","cabinet":"old_iron","med":"cream","locker":"corrugated"}

static func build(w,id:String,p:Vector3,kind:String,facing:float)->Dictionary:
 var k=w.kit
 var root=Node3D.new()
 root.name="Salvage_"+id;root.position=p;root.rotation.y=facing;w.add_child(root)
 var size:Vector3=SIZES[kind]
 var body:MeshInstance3D
 if kind=="bag":
  body=k.ellipsoid("StitchedCanvas",Vector3.UP*.165,size*.5,"cloth",root)
  for x in [-.175,.175]:k.box("CanvasWebbing",Vector3(x,.292,0),Vector3(.052,.031,.37),"wood",false,root)
  k.box("BagClosure",Vector3(0,.208,size.z/2-.012),Vector3(.30,.052,.037),"old_iron",false,root)
 else:
  body=k.box("SearchableShell",Vector3.UP*(size.y*.5),size,FINISH[kind],true,root)
  var footprint=size if absf(sin(facing))<.5 else Vector3(size.z,size.y,size.x)
  w.kit.solids.append({"name":root.name,"rect":Rect2(Vector2(p.x-footprint.x/2,p.z-footprint.z/2),Vector2(footprint.x,footprint.z)),"bottom":p.y,"top":p.y+size.y})
  if kind in ["cabinet","med","locker"]:doors(k,root,size,kind)
  else:fasteners(k,root,size,kind)
 var outline=MeshInstance3D.new()
 outline.name="SalvageContour";outline.mesh=body.mesh
 outline.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 root.add_child(outline)
 outline.transform=body.transform
 outline.scale*=Vector3.ONE+Vector3(.042/size.x,.042/size.y,.042/size.z)
 outline.visible=false
 var face=Vector3.BACK.rotated(Vector3.UP,facing)
 var marker=p+face*(size.z*.5+.45)
 return {"outline":outline,"front":marker}

static func doors(k,root:Node3D,size:Vector3,kind:String):
 var z=size.z*.5
 if kind=="cabinet":
  for y in [size.y*.29,size.y*.72]:
   k.box("DrawerFront",Vector3(0,y,z+.012),Vector3(size.x-.07,size.y*.38,.035),"frosted_salvage",false,root)
   k.box("DrawerPull",Vector3(0,y,z+.04),Vector3(.21,.035,.05),"brass",false,root)
 else:
  k.box("InsetDoor",Vector3(0,size.y*.49,z+.012),Vector3(size.x-.08,size.y-.08,.04),"frosted_salvage" if kind=="locker" else "cream",false,root)
  k.box("DoorTurn",Vector3(-size.x*.29,size.y*.52,z+.044),Vector3(.046,.137,.039),"old_iron",false,root)
  for y in [size.y*.22,size.y*.77]:k.box("Hinge",Vector3(size.x*.45,y,z+.04),Vector3(.055,.09,.056),"old_iron",false,root)
  if kind=="med":
   k.box("AidCrossHorizontal",Vector3(.035,size.y*.68,z+.042),Vector3(.19,.055,.017),"red",false,root)
   k.box("AidCrossVertical",Vector3(.035,size.y*.68,z+.052),Vector3(.055,.19,.014),"red",false,root)
  else:
   for y in [size.y*.78,size.y*.82,size.y*.86]:
    k.box("LockerBaffle",Vector3(0,y,z+.040),Vector3(.37,.021,.022),"dark",false,root)

static func fasteners(k,root:Node3D,size:Vector3,kind:String):
 var lid="frosted_salvage" if kind=="tool" else ("old_iron" if kind=="case" else "wood")
 k.box("SalvageLid",Vector3.UP*(size.y+.017),Vector3(size.x+.034,.034,size.z+.026),lid,false,root)
 for x in [-size.x*.34,size.x*.34]:
  k.box("LidBand",Vector3(x,size.y+.036,0),Vector3(.059,.016,size.z-.015),"old_iron",false,root)
  k.box("BoxCatch",Vector3(x,size.y-.06,size.z*.5+.016),Vector3(.075,.113,.044),"brass",false,root)
 if kind in ["tool","case"]:
  k.box("CarryHandle",Vector3(0,size.y*.54,size.z*.5+.05),Vector3(.214,.056,.071),"old_iron",false,root)
 else:
  for y in [size.y*.33,size.y*.59]:
   k.box("FastenedCrateBoard",Vector3(0,y,size.z*.5+.011),Vector3(size.x-.08,.016,.025),"old_iron",false,root)

static func prepare(w):
 var base:StandardMaterial3D=w.kit.mats.old_iron.duplicate()
 base.albedo_color=Color("a9a99a");base.roughness=.79
 w.kit.mats.frosted_salvage=base
 var dim:ShaderMaterial=w.kit.highlight_material.duplicate()
 dim.set_shader_parameter("width",0.0)
 dim.set_shader_parameter("edge_color",Color("bbcfba"))
 var bright:ShaderMaterial=dim.duplicate()
 bright.set_shader_parameter("edge_color",Color("ffe0a5"))
 w.loot_ink=[dim,bright]
