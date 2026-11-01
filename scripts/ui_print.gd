extends Node2D
## Stationery and instrument engraving at UI resolution; no animated visual noise.
var host:Control
var paper=false
static func attach(control:Control,is_paper:bool=false):
 var n=load("res://scripts/ui_print.gd").new();n.host=control;n.paper=is_paper;control.add_child(n,false,Node.INTERNAL_MODE_FRONT);control.resized.connect(n.queue_redraw);return n
func _draw():
 if not is_instance_valid(host):return
 var size=host.size
 if size.x<40 or size.y<40:return
 if paper:
  for y in range(6,int(size.y)-4,4):
   var alpha=.012+.009*sin(y*1.734)
   draw_line(Vector2(3,y),Vector2(size.x-3,y),Color(.20,.16,.11,alpha),1)
  draw_line(Vector2(12,15),Vector2(12,size.y-15),Color(.52,.20,.15,.24),1)
  for y in range(22,int(size.y)-10,24):draw_line(Vector2(10,y),Vector2(15,y),Color(.35,.27,.20,.20),1)
  draw_line(Vector2(23,8),Vector2(size.x-15,8),Color(.40,.30,.20,.22),1)
 else:
  for x in range(22,int(size.x)-20,24):draw_line(Vector2(x,5),Vector2(x,9 if x%120 else 14),Color(.71,.72,.64,.2),1)
  draw_line(Vector2(20,size.y-10),Vector2(size.x-20,size.y-10),Color(.57,.62,.61,.14),1)
  for x in [12,size.x-12]:
   for y in [12,size.y-12]:
    draw_circle(Vector2(x,y),2.4,Color("485252"));draw_line(Vector2(x-1.5,y),Vector2(x+1.5,y),Color("1b2428"),1)
