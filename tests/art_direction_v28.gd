extends SceneTree
const Story=preload("res://scripts/story.gd")
const Storage=preload("res://scripts/supply_storage.gd")
const Inventory=preload("res://scripts/ui_inventory.gd")
var count=0
func check(value:bool,label:String):
	count+=1
	if not value:push_error(label);quit(1)
func _initialize():call_deferred("run")
func run():
	var s=Story.new();s.context.floor="commune";s.economy.goods={"scrap_metal":5,"bandage":2,"portable_radio":1}
	check(Storage.move(s,"commune","scrap_metal",3,true),"deposit")
	check(s.economy.goods.scrap_metal==2 and s.economy.stashes.commune.scrap_metal==3,"quantity conservation")
	check(not Storage.move(s,"commune","scrap_metal",3,true),"cannot overdraw")
	check(not Storage.move(s,"commune","bandage",-1,true),"cannot mint negative transfers")
	check(not Storage.move(s,"sech","bandage",1,true),"remote locker blocked")
	check(Storage.move(s,"commune","portable_radio",1,true),"portable equipment can be stored before a raid")
	check(Storage.move(s,"commune","portable_radio",1,false),"portable equipment can be withdrawn")
	var saved=JSON.parse_string(JSON.stringify(s.serialize()));var restored=Story.new();restored.restore(saved);restored.context.floor="commune"
	check(Storage.move(restored,"commune","scrap_metal",3,false),"withdraw after save/load")
	check(restored.economy.goods.scrap_metal==5 and restored.economy.stashes.commune.is_empty(),"saved quantities conserved")
	var legacy=Story.new();legacy.restore({"economy":{"goods":{"bread":2}}})
	check(legacy.economy.stashes.is_empty() and legacy.economy.goods.bread==2,"legacy save migration")
	var entries=Inventory.entries(s)
	check(entries.filter(func(e):return e.id=="scrap_metal")[0].category=="materials","material category")
	check(entries.filter(func(e):return e.id=="portable_radio")[0].category=="equipment","radio equipment category")
	check(not s.Campaign.data().interactions.commune_records.body.contains("双方医护担保"),"no enemy-faction visitor-pass contradiction")
	for id in ["art28_terrazzo","art28_plaster","art28_snow","art28_asphalt","commune_mural_v28"]:
		var texture:Texture2D=load("res://assets/visual/"+id+".png")
		check(texture.get_image().has_mipmaps(),"runtime mip chain "+id)
	var session=root.get_node("Session");session.pending={}
	var w=load("res://scenes/d6.tscn").instantiate();root.add_child(w)
	await process_frame
	check(w.targets.has("personal_storage"),"physical locker target")
	w.player.position=Vector3(-13.1,.04,-2);check(Storage.accessible(w),"locker available nearby")
	w.hud.close();Storage.render(w.hud);check(w.hud.modal_visible(),"storage UI opens")
	w.player.position=Vector3(0,.04,0);check(not Storage.accessible(w),"storage unavailable remotely")
	w.hud.show_inventory();await process_frame
	check(w.hud.modal.find_child("InventoryGrid",true,false)!=null,"inventory grid remains usable")
	check(w.ambience.stream.resource_path=="" and w.ambience.stream is AudioStreamOggVorbis,"location score owns isolated stream")
	var env:Environment=w.find_children("*","WorldEnvironment",true,false)[0].environment
	var advanced=RenderingServer.get_current_rendering_method()=="forward_plus"
	session.preview_video({"quality":3})
	check(root.msaa_3d==Viewport.MSAA_8X and env.ssil_enabled==advanced,"extreme preset applies actual anti-aliasing and supported indirect lighting")
	session.preview_video({"quality":0})
	check(not env.ssao_enabled and not env.ssil_enabled and not env.glow_enabled,"low preset removes expensive effects")
	session.revert_video()
	check(root.msaa_3d==Viewport.MSAA_4X,"quality preview restores previous preset")
	w.story.flags.nina_job=true;w.story.flags.intro_done=true;w.story.give("mask");w.story.give("filter")
	for route in ["official","pipe"]:
		w.pending_route=route;w.hud.comic_active=false;w.story.flags.comic={"active":false};w.hud.show_departure(false)
		for b in w.hud.modal.find_children("*","Button",true,false):
			if b.text=="确认出发":b.pressed.emit();break
		check(w.story.flags.get("failed_quests",{}).is_empty() if route=="official" else not w.story.flags.get("failed_quests",{}).is_empty(),"departure consequence follows identity: "+route)
	w.queue_free();await process_frame
	w=load("res://scenes/east_district.tscn").instantiate();root.add_child(w)
	await physics_frame;await physics_frame
	w.set_physics_process(false);w.player.set_physics_process(false);w.combat.set_physics_process(false);w.grey_camp.set_physics_process(false)
	# Upgrade an old position that is now inside each rebuilt block. The normal
	# load placement resolver must preserve the save and put Ivan on clear floor.
	var capsule=CapsuleShape3D.new();capsule.radius=.30;capsule.height=1.7
	for block in preload("res://scripts/east_district.gd").layout().parcels.filter(func(b):return not b.get("open",false)):
		var at=Vector3(block.building[0],.04,block.building[1]);var clear:Vector3=w.clear_arrival(at)
		var query=PhysicsShapeQueryParameters3D.new();query.shape=capsule;query.collision_mask=1
		query.transform=Transform3D(Basis.IDENTITY,clear+Vector3.UP*.90)
		check(clear.distance_to(at)>1.0 and w.get_world_3d().direct_space_state.intersect_shape(query).is_empty(),"old saved position safely moved out of rebuilt block: "+block.id)
	var route:PackedVector3Array=w.navigation.path(Vector3(-64,.04,46),Vector3(-39,.04,35))
	check(not route.is_empty() and route[-1].distance_to(Vector3(-39,0,35))<1.5,"new courtyard has a continuous route from the settlement exit")
	check(w.save_snapshot().layout_revision==29,"new layout is explicitly versioned in saves")
	w.queue_free();await process_frame
	print("ART_DIRECTION_V28_RESULT ",count," checks passed");quit()
