extends RefCounted
## Physical staging for the faction stories, on existing station routes.
const Props=preload("res://scripts/production_props.gd")
const D6_GLASS=Vector3(1.3,0,-16.2)
const SECH_LANTERN=Vector3(16.3,0,-18.9)
const SECH_BRIDGE=Vector3(16.3,0,-3.8)
const COMMUNE_TABLE=Vector3(26.9,0,1.4)

static func dress(w):
	var k=w.kit
	match w.floor_id:
		"labor":
			var p=Vector3(0,0,-16.65)
			k.box("VisitWindowBase",p+Vector3(0,.52,0),Vector3(.19,1.04,1.4),"metal",true)
			for z in [-.64,.64]:
				k.box("VisitWindowUpright",p+Vector3(0,1.60,z),Vector3(.16,1.15,.10),"metal")
			k.box("VisitWindowLintel",p+Vector3(0,2.14,0),Vector3(.18,.1,1.4),"metal")
			var glass=k.box("VisitGlass",p+Vector3(0,1.59,0),Vector3(.036,1.02,1.19),"metal")
			var material=StandardMaterial3D.new()
			material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
			material.albedo_color=Color(.41,.48,.45,.24)
			material.roughness=.32
			glass.material_override=material
			for x in [-.153,.153]:
				k.box("VisitHandset",p+Vector3(x,1.16,.38),Vector3(.08,.13,.32),"dark")
		"sech":
			var p=SECH_LANTERN+Vector3(-.78,0,-.25)
			Props.bevel(k,"RailLanternStand",p+Vector3(0,.46,0),Vector3(.62,.92,.58),"old_iron",null,true)
			k.cyl("RailLanternFoot",p+Vector3(0,.98,0),.18,.12,"dark_steel")
			k.cyl("RailLanternLens",p+Vector3(0,1.11,0),.105,.21,"cream")
			k.cyl("RailLanternCowl",p+Vector3(0,1.23,0),.15,.08,"old_iron")
			k.box("RailSignalCard",p+Vector3(.16,.937,.08),Vector3(.13,.02,.2),"paper").rotation.y=-.12
		"commune":
			var p=COMMUNE_TABLE+Vector3(.72,0,-.85)
			Props.bevel(k,"TruceTransferTable",p+Vector3(0,.46,0),Vector3(1.55,.92,.61),"institution_enamel",null,true)
			k.box("TruceCarbonPaper",p+Vector3(.34,.942,-.08),Vector3(.29,.014,.21),"paper").rotation.y=.17
			var parcel=k.box("TruceClothParcel",p+Vector3(-.28,1.02,0),Vector3(.51,.19,.38),"cloth")
			parcel.set_meta("dynamic",true)
			var tie=k.cyl("TruceParcelTie",p+Vector3(-.30,1.126,0),.012,.38,"wood")
			tie.rotation.x=PI/2
			tie.set_meta("dynamic",true)

static func sync(director):
	var w=director.w
	var s=w.story
	match w.floor_id:
		"labor":
			var active=s.f("arc_d6_accepted") and s.Campaign.Access.public_entry(s)
			var mother_pos=D6_GLASS if s.f("arc_d6_at_glass") else Vector3(-1.9,0,-11.6)
			director.actor("arc_d6_mother",mother_pos,"ambient_elder",active)
			director.actor("arc_d6_son",Vector3(-1.36,0,-16.17),"queue",active and s.f("arc_d6_heard"))
			if active and s.f("arc_d6_clearance"):
				director.target("arc_d6_glass",D6_GLASS+Vector3(.8,0,0))
		"sech":
			director.actor("arc_sech_aglaya",Vector3(18.45,0,-18.95),"ambient_elder",s.f("sech_member") and s.f("late_s1_done"))
			if s.f("arc_sech_signals_learned"):director.target("arc_sech_lantern",SECH_LANTERN)
			var guest=Vector3(3.8,0,-10.3) if s.f("arc_sech_done") else (SECH_BRIDGE if s.f("arc_sech_at_bridge") else Vector3(16.6,0,-26.65))
			director.actor("arc_sech_varya",guest,"diner",s.f("arc_sech_incoming"))
		"commune":
			if s.f("arc_commune_accepted"):director.target("arc_commune_bundle",COMMUNE_TABLE)
			director.actor("arc_commune_liuba",Vector3(18.9,0,2.2),"ambient_woman",s.f("arc_commune_tag_checked"))
			var awaiting=not s.f("arc_commune_done")
			w.get_node("TruceClothParcel").visible=awaiting
			w.get_node("TruceParcelTie").visible=awaiting

static func tick(director):
	var w=director.w
	var s=w.story
	match w.floor_id:
		"labor":
			if s.f("arc_d6_walk"):
				director.walk("arc_d6_mother",[Vector3(-.1,0,-12.2),Vector3(0,0,-14.1),D6_GLASS],"arc_d6_at_glass")
		"sech":
			if s.f("arc_sech_walk") and not s.f("arc_sech_done"):
				director.walk("arc_sech_varya",[Vector3(17,0,-24.4),Vector3(17,0,-20.1),Vector3(17,0,-11),SECH_BRIDGE],"arc_sech_at_bridge")
			if s.f("arc_sech_done"):
				w.living.direct("arc_sech_varya","arc_sech_meeting_end",Vector3(3.8,0,-10.3))
		"commune":
			if s.f("arc_commune_terms"):
				director.walk("arc_commune_liuba",[Vector3(22.2,0,2.0),Vector3(24.9,0,2.15),COMMUNE_TABLE-Vector3(1,0,0)],"arc_commune_at_table")
