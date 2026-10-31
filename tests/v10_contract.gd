extends SceneTree
const Story=preload("res://scripts/story.gd")
const Campaign=preload("res://scripts/campaign.gd")
var checks=0
var failed=0
func _initialize():call_deferred("run")
func check(ok:bool,why:String):
 checks+=1
 if not ok:failed+=1;push_error(why)
func frames(n:int=3):
 for i in n:await physics_frame
func run():
 var c=Campaign.data();var s=Story.new();s.context.floor="waterworks"
 var lieutenant=[];var veteran=[]
 for flags in [[],["plant_diagram"],["plant_diagram","plant_bled","plant_fuse"],["plant_diagram","plant_power"],["plant_diagram","plant_power","water_secured"]]:
  s.flags={}
  for flag in flags:s.flags[flag]=true
  lieutenant.append(s.view("plant_guide").body);veteran.append(s.view("plant_veteran").body)
 check(lieutenant[0]!=lieutenant[1] and lieutenant[1]!=lieutenant[2] and lieutenant[2]!=lieutenant[3] and lieutenant[3]!=lieutenant[4],"lieutenant responds to every actual puzzle phase")
 check(veteran[0]!=veteran[1] and veteran[1]!=veteran[3] and veteran[3]!=veteran[4],"veteran reacts to diagram power and secured cargo")
 check(lieutenant[-1].contains("滤芯") and lieutenant[-1].contains("铁门") and not lieutenant[-1].contains("先看图"),"completed objective describes real cargo and exit")
 s.flags.seal_done=true;s.flags.mail_done=true
 check(s.view("plant_guide").body==lieutenant[-1] and s.view("plant_veteran").body==veteran[-1],"optional rewards do not revert main completion greeting")
 check(Campaign.available(s,"plant_cargo_check") and Campaign.available(s,"veteran_cargo_check"),"new return topic is available to completed old saves")
 for key in ["plant_cargo_check","veteran_cargo_check"]:
  var reply=s.act("c_"+key);check(reply.contains("滤芯") and not Campaign.available(s,key),"cargo topic answers question once: "+key)
 check(c.actions.plant_open.reply.begins_with("木箱里是一批生产于1962年的净水滤芯。"),"crate copy identifies manufacturing year without irrelevant mask comparison")
 for p in c.panels.values():
  for choice in p.get("choices",[]):check(not choice.text.contains("带水回去"),"departure choices name filter cartridges")
 s=Story.new();s.context.floor="commune"
 check(s.view("commune_grower").body.contains("遮光") and s.view("commune_grower").body.contains("回水"),"grower distinguishes two different jobs")
 for flag in ["greenhouse_fixed","grow_fixed","grow_done"]:
  var before=s.view("commune_grower").body;s.flags[flag]=true;check(s.view("commune_grower").body!=before,"grower acknowledges changed state: "+flag)
 # All four task directions agree with the target order in the journal.
 for entry in [["medicine_seal_accept",["联络","配给"]],["mine_air_accept",["档案","工牌板"]],["archive_labels_accept",["档案","带盒"]],["pressure_copy_accept",["铭牌","交接"]]]:
  var text:String=c.actions[entry[0]].reply
  check(text.contains(entry[1][0]) and text.contains(entry[1][1]),"named destinations in question answer: "+entry[0])
 s=Story.new();s.context.floor="starcity"
 s.act("c_star_name");check(not s.last_action_valid,"old internal registration cannot open the current perimeter")
 s.act("c_star_perimeter_name");check(s.last_action_valid and s.last_reply.contains("没有确认") and not s.f("star_access"),"outside inquiry never confirms staff identity or permits entry")
 # Restoring earlier revisions keeps possessions/rewards, reopens corrected information only.
 s=Story.new();s.flags.c_done_grow_talk=true;s.flags.grow_done=true;s.economy.military=23;s.give("mask")
 var saved=s.serialize();saved.content_revision=9
 var restored=Story.new();restored.restore(saved)
 check(restored.has("mask") and restored.economy.military==23 and restored.f("grow_done") and not restored.f("c_done_grow_talk"),"v9 migration preserves goods and rewards while reopening clarification")
 var panels=JSON.parse_string(FileAccess.get_file_as_string("res://data/story_panels.json"))
 check(panels.arrive_waterworks.art=="plant_interior" and panels.return_crossing.art=="filter_return","interior and return use distinct matching illustrations")
 for p in panels.values():check(ResourceLoader.exists("res://assets/cinematics/"+p.get("art","wake")+".png"),"illustrated panel has real art: "+p.title if p.has("title") else "panel art exists")
 for id in ["commune","waterworks"]:
  var w=load("res://scenes/"+id+".tscn").instantiate();root.add_child(w);await frames(8)
  w.set_physics_process(false);w.hud.close()
  if id=="commune":
   for floor_mesh in w.find_children("Floor_*","MeshInstance3D",true,false):
    var path:String=floor_mesh.material_override.albedo_texture.resource_path
    check(not path.ends_with("timber.png"),"no timber public station floor")
   check(w.find_children("*","MeshInstance3D",true,false).filter(func(m):return m.get_meta("vegetable_leaf",false)).size()>100,"gardens contain actual curved textured leaves")
   check(w.find_children("*","MeshInstance3D",true,false).filter(func(m):return m.get_meta("poster_art","")=="CommuneWorkersPoster").size()==2,"revolutionary poster artwork is used on scene geometry")
   var before=Vector3(-12.6,.04,-3.4);var safe=w.clear_arrival(before)
   check(safe.distance_to(before)>.5 and safe.distance_to(before)<2.5,"old save inside a new pump relocates to a nearby navigable cell")
   check(w.clear_arrival(Vector3(-2,.04,4))==Vector3(-2,.04,4),"unobstructed saved positions remain unchanged")
   w.story.flags.first_meeting_commune_grower=2;w.hud.show_dialogue("commune_grower");w.hud.finish_typing()
   for i in 5:await process_frame
   w.story.flags.grow_done=true;w.hud.show_dialogue("commune_grower");w.hud.finish_typing()
   for i in 6:await process_frame
   var latest=w.story.Conversation.split_text(w.story.view("commune_grower").body,"commune_grower")[0].text
   check(w.hud.modal.find_children("*","ScrollContainer",true,false).filter(func(c):return c.is_visible_in_tree()).is_empty() and w.hud.modal.find_children("*","RichTextLabel",true,false).any(func(c):return c.is_visible_in_tree() and c.text.contains(latest.left(25))),"changed greeting appears in fixed speech pane after instant reveal without scrolling through old history")
   w.hud.close()
   w.story.flags.grow_fixed=true;w.on_story_changed()
   check(w.get_node("FungusShade").visible and is_equal_approx(w.get_node("FungusShade").position.y,2.08) and w.get_node("FungusShade").get_meta("dynamic",false),"shade moves visibly after adjustment and is not baked into static batches")
  else:
   check(w.targets.plant_exit.pos.z>10 and w.factory_exit_leaves.size()==2,"factory exit target is on an actual double gate")
   var leaf:Node3D=w.factory_exit_leaves[0]
   check(leaf.find_children("*","StaticBody3D",true,false).size()==1,"steel leaf has moving collision")
   w.story.flags.water_secured=true;w.story.give("water_core");w.hud.show_dialogue("plant_exit");w.perform("c_plant_leave","plant_exit")
   await frames(18)
   check(w.departure_animating and absf(leaf.rotation.y)>.02 and absf(leaf.rotation.y)<1.5,"exit visibly opens before the travel cutscene")
   await frames(60)
   check(not w.departure_animating and w.story.flags.comic.active and w.story.flags.comic.node=="return_crossing","animated departure continues into correct filter return journey")
  w.queue_free();await frames()
 check(not ResourceLoader.exists("res://scenes/ivan_pilot.tscn"),"game no longer exposes the rejected pilot")
 check(not DirAccess.dir_exists_absolute("res://experiments/ivan-render-lab"),"abandoned 3D Ivan project is removed as requested")
 check(not ResourceLoader.exists("res://scripts/prerendered_ivan.gd"),"game has no rejected 3D character controller")
 print("V10_RESULT checks=",checks," failures=",failed)
 quit(0 if failed==0 else 1)
