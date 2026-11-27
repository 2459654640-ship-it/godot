extends SceneTree
const Story=preload("res://scripts/story.gd")
const Contacts=preload("res://scripts/faction_contacts.gd")
const Atlas=preload("res://scripts/district_atlas.gd")
const Journal=preload("res://scripts/journal.gd")
var w
var checks=0
var failures=0

func _initialize():call_deferred("run")
func check(ok:bool,description:String):
 checks+=1
 if not ok:failures+=1;push_error(description)
func frames(count:int=5):
 for frame in count:await physics_frame
func freeze():
 w.set_physics_process(false);w.player.set_physics_process(false);w.combat.set_physics_process(false)
 if is_instance_valid(w.grey_camp):
  w.grey_camp.set_physics_process(false)
  for guard in w.grey_camp.guards:guard.set_physics_process(false)
 w.hud.close()
func journey():
 for repeat in 30:
  while current_scene==null:await process_frame
  w=current_scene
  if not w.story.flags.get("comic",{}).get("active",false):freeze();return
  var scene=w.story.Comic.panel(w.story)
  w.hud.comic_choose(0 if scene.has("choices") else -1)
  await frames()
 check(false,"journey must end in a playable scene")
func act(s,id:String):
 s.act("c_"+id)
 check(s.last_action_valid,"available action "+id)
func option(s,id:String,key:String)->bool:
 return s.view(id).options.any(func(entry):return entry.enabled and entry.key=="c_"+key)

func run():
 var s=Story.new()
 check(Contacts.heard(s,"labor") and not Contacts.heard(s,"commune") and not Contacts.heard(s,"sech"),"fresh Ivan knows D-6 and no other faction")
 s.Comic.start(s,"companions")
 check(not s.Comic.panel(s).choices.any(func(c):return c.next=="solo_commune"),"escape cannot select a faction Sergey has yet to name")
 s.Comic.choose(s,0);s.Comic.choose(s)
 check(Contacts.heard(s,"commune") and s.Comic.panel(s).choices.any(func(c):return c.next=="solo_commune"),"asking Sergey reveals the independent escape option")
 s=Story.new();s.context.floor="labor";s.route="official"
 s.flags.merge({"d6_cargo_returned":true,"d6_patrol_done":true,"faction_mapped_sech":true,"faction_mapped_commune":true})
 check(Contacts.sponsor_open(s,"sech") and not Contacts.sponsor_open(s,"commune"),"D-6 arranges neutral contact but an enemy gate stays shut")
 act(s,"faction_sponsor_sech");s.context.floor="east_district"
 check(Contacts.can_enter(s,"sech") and Contacts.can_enter(s,"labor") and not Contacts.can_enter(s,"commune"),"the sponsored destination and D-6 clearance are independent")
 s.flags.d6_wanted=true
 check(not Contacts.can_enter(s,"labor"),"a different faction's papers cannot cancel D-6 pursuit")

 s=Story.new();s.context.floor="commune";s.route="hatch"
 s.flags.merge({"intro_done":true,"departure_committed":true,"d6_wanted":true,"commune_member":true,"commune_trusted":true,"east_crossing_open":true,"east_power_restored":true,"first_meeting_commune_guard":2})
 s.give("mask");s.give("filter");s.give("revolver")
 check(option(s,"commune_guard","faction_ask_sech"),"the existing guard dialogue introduces a new contact")
 act(s,"faction_ask_sech")
 check(Contacts.heard(s,"sech") and not Contacts.located(s,"sech") and not Contacts.can_enter(s,"sech"),"rumor alone reveals no marker and grants no access")
 check(not option(s,"commune_guard","faction_sponsor_sech"),"sponsor request needs a located entrance")
 root.get_node("Session").pending={"story":s.serialize(),"floor":"commune","position":Vector3.INF}
 w=load("res://scenes/commune.tscn").instantiate();root.add_child(w);current_scene=w;await frames();freeze()
 w.perform("c_east_depart_commune","commune_leave");await journey()
 check(w.floor_id=="east_district" and w.story.f("raid_active"),"the full cutscene transition uses the traversable district")
 var features=Atlas.features(w,{})
 check(features.has("extraction") and features.has("east_commune_entry") and not features.has("east_sech_entry"),"early map shows the known gate and current extraction without revealing hearsay coordinates")
 check(not features.has("east_d6_entry"),"knowing the station does not reveal an unvisited exterior gate")
 check(not option(w.story,"east_sech_entry","east_enter_sech"),"arriving at the opposite side of the map cannot bypass authorization")
 act(w.story,"faction_read_sech")
 features=Atlas.features(w,{})
 check(features.east_sech_entry.kind=="closed" and not Contacts.can_enter(w.story,"sech"),"an actual dispatch log adds a closed marker")
 w.hud.show_map();await frames()
 var map=w.hud.map_large
 check(map.display_floor=="east_district" and map.size.y>500,"M opens the redesigned expanded chart")
 map.center_on("east_sech_entry")
 check(map.map_zoom>1 and map.map_selected=="east_sech_entry","the place selector centers the actual chart")
 w.hud.close()
 w.perform("c_east_enter_commune","east_commune_entry");await journey()
 check(w.floor_id=="commune" and option(w.story,"commune_guard","faction_sponsor_sech"),"found route returns to a named sponsor at home")
 act(w.story,"faction_sponsor_sech")
 var disk=Story.new();disk.restore(JSON.parse_string(JSON.stringify(w.story.serialize())))
 check(Contacts.sponsored(disk,"sech") and not Contacts.established(disk,"sech"),"save/load distinguishes sponsorship from an actual visit")
 w.perform("c_east_depart_commune","commune_leave");await journey()
 w.perform("c_east_enter_sech","east_sech_entry")
 check(w.story.flags.comic.sequence=="faction_arrive_sech" and not Contacts.established(w.story,"sech"),"the first city visit uses a checkpoint scene before the registration is established")
 await journey()
 check(w.floor_id=="sech" and Contacts.established(w.story,"sech") and Contacts.home(w.story)=="commune","entry creates durable limited access without switching campaign branches")
 check(w.story.f("commune_member") and not w.story.f("sech_member") and not w.story.Campaign.available(w.story,"sech_join"),"a visitor cannot accidentally join a conflicting storyline")
 w.perform("c_east_depart_sech","sech_leave");await journey()
 check(w.floor_id=="east_district" and w.story.flags.east_home=="sech" and Contacts.can_enter(w.story,"commune") and Contacts.can_enter(w.story,"sech"),"either legitimate gate remains usable after leaving the guest station")
 check(Atlas.features(w,{}).east_sech_entry.kind=="contact","registered station is visibly usable on the read map")
 disk.restore(w.story.serialize());disk.context.floor="east_district"
 act(disk,"east_enter_sech")
 check(disk.flags.next_sequence=="faction_revisit_sech","a return visit uses the guest register instead of repeating a first introduction")
 w.perform("c_east_enter_commune","east_commune_entry");await journey()
 check(w.floor_id=="commune" and w.story.Campaign.Complete.home(w.story)=="commune","the same character returns to its real quest contacts through the district")
 w.queue_free();await frames()

 s=Story.new();s.context.floor="life";s.flags.intro_done=true
 var leg=Journal.map_task(s,"life","report")
 check(leg.target=="lift" and leg.place=="life" and not s.flags.has("tracked_quest"),"a map preview shows the first real leg without silently tracking the task")
 print("FACTION_NAVIGATION_V39_RESULT checks=",checks," failures=",failures)
 quit(1 if failures else 0)
