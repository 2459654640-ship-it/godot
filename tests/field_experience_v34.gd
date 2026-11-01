extends SceneTree
const Story=preload("res://scripts/story.gd")
const Guide=preload("res://scripts/field_guide.gd")
var checks=0
var failures=0
var w
func _initialize():call_deferred("run")
func check(ok:bool,text:String):
 checks+=1
 if not ok:failures+=1;push_error(text)
func frames(n:int=4):
 for i in n:await physics_frame
func fixture():
 var s=Story.new();s.flags.intro_done=true;s.flags.surface_job=true;s.flags.tracked_quest="surface_survey";s.flags.east_home="commune";s.flags.surface_from_commune=true;s.give("mask");s.give("filter");s.give("revolver");return s
func task(s):return s.Campaign.side_tasks(s).filter(func(t):return t.id=="surface_survey")[0]
func run():
 var s=fixture();s.context.floor="surface"
 check(task(s).target=="surface_board","first action is the real drainage diagram")
 s.flags.surface_notes=true
 check("兽群" in task(s).step and not "然后打开" in task(s).step,"blocked valve stage explicitly identifies the courtyard fight")
 s.flags.battle_surface_yard=true;check("按 E" in task(s).step and "排低水位" in task(s).step,"courtyard clear points to actual valve interaction")
 s.flags.surface_drain_open=true;check("北侧下池" in task(s).step and "兽群" in task(s).step,"second threat has a place and purpose")
 s.flags.battle_surface_pool=true;check("封存" in task(s).step,"pool clear points to sample interaction")
 s.flags.surface_sample_sealed=true;s.give("pool_sample");check(task(s).target=="surface_exit","sealed sample leads to actual exit, not another fight")
 s.context.floor="east_district";var active=load("res://scripts/journal.gd").active(s)
 check(active.target=="east_commune_entry","tracked remote handover produces the correct local return leg")
 check(s.flags.tracked_quest=="surface_survey","wayfinding never silently changes player-selected task")
 s=fixture();s.context.floor="east_district";active=load("res://scripts/journal.gd").active(s);check(active.target=="east_pump_entry","outbound task points to pump entrance in city")
 s.context.floor="labor";check(Guide.stage(s,{"id":"late_star_access"},{"place":"labor","target":"d6_surface_gate","step":"出站"}).target=="main_gate","D-6 dialogue identifier resolves to its actual physical gate")
 var visitor=fixture();visitor.flags.sech_member=true;visitor.flags.east_home="sech";visitor.context.floor="east_district"
 var denied=Guide.bridge(visitor,{"id":"anna","place":"commune","target":"commune_anna","step":"向安娜报信。"})
 check(denied.target=="east_sech_entry" and "访站" in denied.step,"cross-faction guide honors visit cost instead of promising free entry")
 s.flags.star_registered=true;s.flags.late_relay_assigned=true
 check(not load("res://scripts/journal.gd").tasks(s).any(func(t):return t.id=="father"),"obsolete indefinite StarCity waiting task disappears after technical contact")
 for id in ["pump","workshop","warehouse","surface_yard","surface_pool","east_road","city_radio_nest","relay_final","junction_c2"]:
  var b=Guide.encounter(id);check(b.purpose!="" and b.after!="","encounter explains purpose and next action: "+id)
 check("无需另找派工人" in Guide.briefing(s,{"id":"city_basin","background":""})["return"],"self-directed boss challenge does not imply a missing handover")
 root.get_node("Session").pending={"story":s.serialize(),"floor":"surface","position":Vector3.INF}
 w=load("res://scenes/surface.tscn").instantiate();root.add_child(w);current_scene=w;await frames();w.set_physics_process(false);w.player.set_physics_process(false);w.combat.set_physics_process(false);w.hud.close()
 w.story.context.floor="surface";w.story.flags.surface_notes=true
 var p=Guide.point(w,task(w.story));check(p==Guide.AREAS.surface_yard,"pre-fight marker denotes the yard region rather than a locked valve")
 w.story.flags.battle_surface_yard=true;p=Guide.point(w,task(w.story));check(p.distance_to(w.targets.surface_valve.pos)<.01,"after fight the same guide resolves actual valve target")
 load("res://scripts/ui_workbench.gd").journal(w.hud,"tasks","","surface_survey");await frames()
 var labels=w.hud.modal.find_children("*","Label",true,false)
 check(labels.any(func(l):return "外勤安排" in l.text),"accepted mission detail includes route and handover briefing")
 var bounds=Rect2(Vector2.ZERO,Vector2(1600,1000))
 for b in w.hud.modal.find_children("*","Button",true,false):
  if b.is_visible_in_tree():check(bounds.encloses(b.get_global_rect()),"briefing controls stay inside screen")
 w.queue_free();await frames();print("FIELD_EXPERIENCE_V34_RESULT checks=",checks," failures=",failures);quit(1 if failures else 0)
