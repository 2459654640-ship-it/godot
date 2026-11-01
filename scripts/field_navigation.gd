extends Node2D
## A selected objective's region, never hidden enemies or a route through walls.
var h
var destination=Vector2.INF
var distance=0
var elapsed=0.0
var hint:Label
var combat_was_active=false
const Guide=preload("res://scripts/field_guide.gd")
func setup(hud):
 h=hud;name="FieldNavigation"
 hint=h.label("",14,Color("c0c9c7"));hint.position=Vector2(42,350);hint.size=Vector2(272,65);hint.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;hint.add_theme_constant_override("outline_size",5);hint.add_theme_color_override("font_outline_color",Color("101c24"));h.add_child(hint)
func _process(delta):
 if not is_instance_valid(h) or not h.world.initialized:return
 elapsed+=delta
 if elapsed<.12:return
 elapsed=0
 var w=h.world;var modal=h.modal_visible();hint.visible=not modal;destination=Vector2.INF
 if modal:queue_redraw();return
 var focus=h.Journal.active(w.story);var active=is_instance_valid(w.combat) and w.combat.active
 var bandits=is_instance_valid(w.grey_camp) and w.grey_camp.alarm
 if active:
  var brief=Guide.encounter(w.combat.encounter)
  h.objective_kind.text="现场交火 / "+brief.title;h.objective_kind.add_theme_color_override("font_color",Color("d79279"))
  h.objective.text=brief.purpose;hint.text="随后  ·  "+brief.after
 elif bandits:
  h.objective_kind.text="遭遇持枪守卫";h.objective.text="找实体掩体。可以交战，也可脱离视线后绕行；原任务进度保留。";hint.text="脱离追击后，继续手记中的任务方向。"
 else:
  h.objective_kind.add_theme_color_override("font_color",h.muted)
  if combat_was_active:h.refresh_status()
  var p=Guide.point(w,focus)
  if p.is_finite():
   distance=roundi(Vector2(p.x-w.player.position.x,p.z-w.player.position.z).length());destination=w.camera.unproject_position(p+Vector3.UP*.15)
   hint.text=("目标区域  ·  %d 米"%distance)+("\n靠近后观察现场，按 E 选择互动对象。" if distance<8 else "\nM 查看入口与当前目的地。")
  else:hint.text="J 查看当前目标与返程安排。" if not focus.is_empty() else "探索沿路设施，与已认识的人交谈。"
 combat_was_active=active or bandits;queue_redraw()
func _draw():
 if not is_instance_valid(h) or h.modal_visible() or not destination.is_finite():return
 var rect=Rect2(330,88,920,700);var color=Color("ddc49a")
 if rect.has_point(destination):
  if distance<24:
   draw_arc(destination,11,0,TAU,32,Color(color,.55),1.3,true)
   draw_line(destination+Vector2(0,-18),destination+Vector2(0,-13),color,2,true)
 else:
  var center=rect.get_center();var d=(destination-center).normalized();var amount=minf(rect.size.x*.5/maxf(.001,absf(d.x)),rect.size.y*.5/maxf(.001,absf(d.y)));var p=center+d*(amount-12);var side=Vector2(-d.y,d.x)
  draw_colored_polygon(PackedVector2Array([p+d*8,p-d*5+side*5,p-d*5-side*5]),color)
  draw_string(h.font,p-d*17+Vector2(-15,21),str(distance)+" m",HORIZONTAL_ALIGNMENT_LEFT,-1,13,color)
