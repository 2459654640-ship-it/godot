extends SceneTree
const Story=preload("res://scripts/story.gd")
const Journal=preload("res://scripts/journal.gd")
const Campaign=preload("res://scripts/campaign.gd")
const Comic=preload("res://scripts/comic.gd")
var checks=0
var failures=0
func _initialize():call_deferred("run")
func check(ok:bool,why:String):
 checks+=1
 if not ok:failures+=1;push_error(why)
func frames(n:int=4):
 for i in n:await physics_frame
func run():
 for home in ["commune","sech"]:
  var s=Story.new();s.context.floor=home;s.flags.surface_job=true;s.flags.signal_heard=true;s.flags.tracked_quest="signal_trace";s.give("mask");s.give("filter");s.give("revolver")
  check(Journal.tasks(s).filter(func(t):return t.id=="surface_survey")[0].place==home,"preparation points to the settlement where the survey is accepted: "+home)
  s.act("c_surface_depart");s.context.floor="surface"
  check(s.last_action_valid and s.flags.tracked_quest=="surface_survey","departing for the pump station focuses the accepted survey: "+home)
  # Old saves may still track the radio; a clue with no local receiver must
  # not masquerade as a surface objective and hide the real survey.
  s.flags.tracked_quest="signal_trace"
  check(Journal.active(s).id=="surface_survey","legacy radio focus does not take over the surface map: "+home)
  for stage in [["surface_notes","surface_valve"],["surface_drain_open","surface_sample"],["surface_sample_sealed","surface_exit"]]:
   s.flags[stage[0]]=true
   var task=Journal.active(s)
   check(task.place=="surface" and task.target==stage[1],"pump station objective advances locally: "+stage[0]+home)
  s.context.floor=home
  var survey=Journal.tasks(s).filter(func(t):return t.id=="surface_survey")[0]
  check(survey.place==home and survey.target==("sech_quartermaster" if home=="sech" else "commune_guard"),"return directs to actual originating settlement: "+home)
  for sampled in [false,true]:
   s.flags.surface_sample_sealed=sampled;s.context.floor="surface"
   var before=s.economy.duplicate(true)
   Comic.start(s,"surface_back_"+home);var panel=Comic.panel(s)
   check(panel.art=="pump_hatch_return" and (panel.body.contains("封好的沉淀物") if sampled else panel.body.contains("还没取到")),"return illustration and text reflect actual sampling state: "+home+str(sampled))
   Comic.choose(s);panel=Comic.panel(s)
   check(panel.art=="pump_return_"+home,"destination has its own checkpoint painting: "+home)
   Comic.choose(s)
   check(s.flags.next_facility==home and not s.flags.comic.active and s.economy==before,"two-panel return reaches correct map without inventing loot or consuming resources")
 for id in ["starcity","surface","waterworks"]:
  var w=load("res://scenes/"+id+".tscn").instantiate();root.add_child(w);current_scene=w;await frames(8);w.hud.close();w.set_physics_process(false);w.player.set_physics_process(false)
  if is_instance_valid(w.combat):w.combat.set_physics_process(false)
  var buildings=w.find_children("ExteriorBlock*","Node3D",true,false)
  check(buildings.size()==9,"shared complete skyline exists on "+id)
  for building in buildings:
   var faces={}
   for part in building.get_children():
    if part.has_meta("wall_face"):faces[part.get_meta("wall_face")]=true
   check(faces.size()==4,"all four elevations are built: "+id+str(building.position))
   var bounds:Rect2=building.get_meta("footprint");var playable=false
   for zone in w.zones:
    if bounds.intersects(zone.rect):playable=true
   check(not playable,"scenery never occupies an exploration zone: "+id+str(building.position))
  if id=="starcity":
   check(w.floor_id=="starcity" and not w.targets.has("surface_exit") and w.targets.has("star_perimeter_call"),"Star City is its own sealed exterior scene")
  elif id=="surface":
   check(w.floor_id=="surface" and w.targets.has("surface_exit") and not w.targets.has("star_perimeter_call"),"pump station is an independent combat scene")
  w.queue_free();await frames()
 print("EXTERIOR_V23_RESULT checks=",checks," failures=",failures);quit(0 if failures==0 else 1)
