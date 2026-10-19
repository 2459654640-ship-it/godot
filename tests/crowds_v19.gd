extends "res://tests/campaign_contract.gd"
func run():
 w=load("res://scenes/commune.tscn").instantiate();root.add_child(w);current_scene=w;await frames(8)
 w.set_physics_process(false);w.player.set_physics_process(false)
 var g=w.get_node("ResidentGroup_assembly")
 check(g.position==Vector3(-10,0,-9.15),"assembly group sits against the west wall")
 check(g.get_meta("seat_forward")==Vector3.RIGHT and g.get_meta("seat_row_axis")==Vector3.BACK,"seats face into hall and their row follows the west wall")
 check(g.member_materials.size()==3,"three whole seated characters have independent animation materials")
 var previous=-INF
 for i in 3:
  var member=g.get_node("SeatedResident_"+str(i));var p=member.global_position
  check(is_equal_approx(p.x,-10) and p.z>previous,"each actual seat position belongs to the north-south row")
  check(overlap(p),"seated character/chair has actual player collision")
  check(p.z<-7.9 and p.z>-10.3,"seats leave the west entrance and north doorway clear")
  previous=p.z
 var old=g.member_materials.map(func(m):return m.get_shader_parameter("idle_time"));g._process(.6)
 for i in 3:check(g.member_materials[i].get_shader_parameter("idle_time")!=old[i],"idle advances independently on each seated figure")
 check(not overlap(Vector3(-10.8,.04,-6)),"west doorway approach remains free")
 w.queue_free();await frames();print("CROWDS_V19_RESULT checks=",checks," failures=",failed.size());quit(0 if failed.is_empty() else 1)
