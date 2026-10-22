extends RefCounted
## No interior geometry or inward travel exists in the current chapter.
static func build(w):
 var k=w.kit
 preload("res://scripts/surface_site.gd").ground(w,Rect2(-14,-6,28,24))
 k.box("StarMountainFacade",Vector3(0,2.5,-5.5),Vector3(28,5,1),"concrete",true)
 # A thick recessed portal with roof and side returns, rather than a flat
 # painted door on an isolated sheet. All new depth is behind the fence.
 k.box("StarPortalRoof",Vector3(0,3.7,-6.3),Vector3(6.6,.45,3.0),"exterior_concrete")
 for x in [-3.1,3.1]:
  k.box("StarPortalButtress",Vector3(x,1.8,-5.65),Vector3(.65,3.6,2.2),"exterior_concrete")
  k.box("PortalSnowCap",Vector3(x,3.66,-5.65),Vector3(.72,.08,2.3),"surface_snow")
 k.box("StarSealedBlastDoor",Vector3(0,1.55,-4.93),Vector3(4.2,3.1,.24),"blue",true)
 for x in [-1.5,-.75,0,.75,1.5]:k.box("BlastDoorStiffener",Vector3(x,1.55,-4.78),Vector3(.09,2.9,.10),"old_iron")
 for y in [.30,2.8]:k.box("BlastDoorCrossBrace",Vector3(0,y,-4.70),Vector3(4,.12,.09),"old_iron")
 k.box("BlastDoorCentreSeal",Vector3(0,1.55,-4.65),Vector3(.10,3,.08),"dark")
 for x in [-2.3,2.3]:k.box("BlastDoorFrame",Vector3(x,1.7,-4.75),Vector3(.25,3.4,.35),"old_iron")
 k.pipe(Vector3(-8,2.3,-4.7),Vector3(8,2.3,-4.7),.07,"rust")
 k.box("StarPerimeterBarrier",Vector3(0,.8,0),Vector3(27.8,1.6,.20),"old_iron",true)
 for x in range(-13,14,2):k.box("PerimeterWarningStripe",Vector3(x,.8,.12),Vector3(.12,.7,.025),"brass")
 for x in [-13,13]:k.lamp(Vector3(x,2.7,-4.65),false,1.5,10)
 k.box("ExternalIntercomPost",Vector3(2.6,.7,2),Vector3(.32,1.4,.30),"old_iron",true)
 k.box("IntercomSpeaker",Vector3(2.6,1.25,2.18),Vector3(.23,.23,.04),"dark")
 k.box("IntercomIndicator",Vector3(2.6,1.05,2.18),Vector3(.06,.04,.02),"green")
 # Open-front shelter lies outside every security barrier.
 k.box("WaitingShelterBack",Vector3(-9,1.25,6),Vector3(6,2.5,.18),"corrugated",true)
 k.box("WaitingShelterWest",Vector3(-12,1.25,8.5),Vector3(.18,2.5,5),"corrugated",true)
 for x in [-11.8,-6.2]:k.box("WaitingCanopyPost",Vector3(x,1.35,10.5),Vector3(.10,2.7,.10),"old_iron",true)
 k.box("WaitingCanopyCeiling",Vector3(-9,2.75,8.4),Vector3(6.4,.12,5.5),"exterior_roof")
 k.box("WaitingCanopyCeilingSnow",Vector3(-9,2.84,8.4),Vector3(6.15,.065,5.35),"surface_snow")
 for x in [-11.8,-9,-6.2]:k.box("WaitingCanopyBeam",Vector3(x,2.61,8.4),Vector3(.09,.14,5.4),"old_iron")
 k.bench(Vector3(-9,0,6.6),3.2,true)
 k.table(Vector3(-9,0,8.1),2.2)
 k.box("InquiryRegister",Vector3(-9,.82,8.1),Vector3(.65,.03,.45),"paper")
 k.lamp(Vector3(-10.5,2.3,6.2),true,1.8,9)
 k.box("ReturnRoutePost",Vector3(0,.8,15),Vector3(.12,1.6,.12),"old_iron",true)
 k.box("ReturnRouteArrow",Vector3(0,1.4,15),Vector3(1.2,.2,.05),"paper")
 preload("res://scripts/surface_site.gd").road(k,Vector3(0,0,17),Vector3(4,0,4),2.6)
