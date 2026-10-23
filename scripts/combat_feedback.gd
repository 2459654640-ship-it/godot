extends Control
var director
var flashes:Array=[]
func setup(d):
 director=d;mouse_filter=Control.MOUSE_FILTER_IGNORE;set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
func hit(p:Vector3,killed:bool):
 flashes.append({"position":p,"remaining":.28 if killed else .16,"killed":killed});queue_redraw()
func _process(delta):
 if not is_instance_valid(director):return
 if director.paused():visible=false;return
 visible=true
 for f in flashes:f.remaining-=delta
 flashes=flashes.filter(func(f):return f.remaining>0)
 queue_redraw()
func _draw():
 if not is_instance_valid(director):return
 for f in flashes:
  if director.w.camera.is_position_behind(f.position):continue
  var p=director.w.camera.unproject_position(f.position)
  var ink=Color("d6ab66") if f.killed else Color("eee2c5");ink.a=minf(1,f.remaining*10)
  for sign in [Vector2(-1,-1),Vector2(1,-1),Vector2(-1,1),Vector2(1,1)]:draw_line(p+sign*5,p+sign*(12 if f.killed else 9),ink,2,true)
