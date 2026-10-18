extends RefCounted
const Publications=preload("res://scripts/publications.gd")
## The Y coordinate is the actual supporting shelf/table surface, not a
## character destination. Targets remain at floor level for proximity rays.
const PLACES={
	"pub_prewar_crisis":Vector3(-12.3,.355,-4.85),
	"pub_diary_stairs":Vector3(-6.0,.465,8.7),
	"pub_diary_shift":Vector3(-8.8,.805,-10.8),
	"pub_magazine_radio":Vector3(-.7,.805,-6.5),
	"pub_prewar_water":Vector3(-11.0,1.61,10.8),
	"pub_magazine_water":Vector3(-7.2,.805,11.15),
	"pub_commune_sketches":Vector3(-8.5,.805,9.12),
	"pub_poems_window":Vector3(5.9,.805,-20.15),
	"pub_route_sech":Vector3(-8.9,.805,-20.1),
	"pub_diary_mine":Vector3(11.35,.805,-9.85),
	"pub_prewar_science":Vector3(-21,.465,9),
	"pub_route_weather":Vector3(12.65,.805,2.85)}

static func build(world):
	for book in Publications.data().entries:
		if book.source.kind!="pickup" or book.source.floor!=world.floor_id:continue
		if not Publications.owned(world.story,book.id):build_copy(world,book)
	if world.floor_id=="commune":build_terminal(world)

static func build_copy(world,book:Dictionary):
	var id:String=book.id
	var p:Vector3=PLACES[id]
	var root=Node3D.new();root.name="Publication_"+id;world.add_child(root);root.position=p
	root.rotation.y=.13 if int(book.cover)%2==0 else -.14
	root.set_meta("publication_id",id)
	var paper=world.kit.box("PublicationPages",Vector3(0,.018,0),Vector3(.26,.032,.35),"paper",false,root)
	paper.set_meta("dynamic",true)
	var cover=MeshInstance3D.new();cover.name="PublicationCover";cover.set_meta("dynamic",true)
	var mesh=QuadMesh.new();mesh.size=Vector2(.275,.365);cover.mesh=mesh
	var ink=StandardMaterial3D.new();ink.albedo_texture=Publications.icon(book);ink.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR;ink.roughness=1
	cover.material_override=ink;cover.rotation.x=-PI/2;cover.position.y=.036;root.add_child(cover)
	world.target(id,Vector3(p.x,0,p.z),"旧书刊","collect")

static func refresh(world):
	for book in Publications.data().entries:
		if book.source.kind!="pickup" or book.source.floor!=world.floor_id:continue
		var node=world.get_node_or_null("Publication_"+book.id)
		if Publications.owned(world.story,book.id):
			if node:node.hide()
			if world.targets.has(book.id):
				var target=world.targets[book.id]
				for marker in [target.ring,target.marker]:
					if is_instance_valid(marker):marker.queue_free()
				world.targets.erase(book.id)
		else:
			if not node:build_copy(world,book)
			else:
				node.show()
				if not world.targets.has(book.id):
					var p:Vector3=PLACES[book.id]
					world.target(book.id,Vector3(p.x,0,p.z),"旧书刊","collect")

static func build_terminal(w):
	# Against the dining room's west wall, facing into the room. Clear of both
	# dining tables, benches, doorways and the radiator; the front is local +Z.
	var k=w.kit
	var root=Node3D.new();root.name="CommonRoomTerminal";w.add_child(root)
	root.position=Vector3(-10.55,0,11);root.rotation.y=PI/2
	root.set_meta("terminal_front",Vector3.RIGHT)
	for x in [-.44,.44]:
		for z in [-.3,.3]:k.box("TerminalStandLeg",Vector3(x,.36,z),Vector3(.065,.72,.065),"metal",false,root)
	k.box("TerminalDesk",Vector3(0,.76,0),Vector3(1.15,.09,.80),"wood",false,root)
	k.box("TerminalCase",Vector3(0,1.19,-.08),Vector3(.84,.74,.46),"old_iron",false,root)
	k.box("TerminalBezel",Vector3(0,1.23,.16),Vector3(.69,.53,.055),"dark",false,root)
	var screen=k.box("TerminalPhosphor",Vector3(0,1.23,.193),Vector3(.56,.41,.012),"dark",false,root)
	var phosphor=ShaderMaterial.new();phosphor.shader=load("res://assets/visual/blocks_terminal.gdshader");screen.material_override=phosphor
	for y in [1.02,1.09,1.16,1.23,1.30,1.37]:k.box("TerminalVent",Vector3(.36,y,.166),Vector3(.035,.015,.012),"dark",false,root)
	k.box("TerminalKeyboard",Vector3(0,.835,.24),Vector3(.68,.07,.23),"metal",false,root)
	for row in 3:
		for col in 9:k.box("TerminalKey",Vector3(-.27+col*.067,.88,.17+row*.064),Vector3(.049,.024,.044),"cream",false,root)
	k.box("TerminalSpaceKey",Vector3(0,.882,.35),Vector3(.29,.022,.038),"cream",false,root)
	k.box("TerminalPowerButton",Vector3(.30,1.01,.191),Vector3(.035,.035,.014),"red",false,root)
	k.pipe(root.position+Vector3(-.25,.09,-.25),root.position+Vector3(-.25,.09,.45),.012,"dark")
	# Axis-aligned world-space hull; decorative local meshes need no colliders.
	k.box("TerminalFootprint",root.position+Vector3(.04,.77,0),Vector3(.82,1.54,1.15),"dark",true).visible=false
	w.target("common_blocks",Vector3(-9.72,0,11),"СМ-4 终端 · 方块")
