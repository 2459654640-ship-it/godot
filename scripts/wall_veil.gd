extends Node
## Coverage-weighted visual occlusion. Physical walls and collision never change.
var world
var states:Array[Dictionary]=[]
var roof_samples:Array=[]
var interior_roofs:Array=[]
var focus_overlay:ColorRect
var interior_active=false
var active_interior=Rect2()
var focus_amount=0.0
const ACQUIRE=.09
const HOLD=.38
const FADED=.42
const ROOF_FADED=.38
func setup(owner_world):
 world=owner_world
 for mesh in world.find_children("*","MeshInstance3D",true,false):
  if mesh.has_meta("interior_rect"):
   interior_roofs.append(mesh)
   var roof_material=world.kit.new_veil_material(mesh.material_override)
   mesh.material_override=roof_material
   add_state(mesh,mesh.global_transform*mesh.get_aabb(),[roof_material],true)
 focus_overlay=ColorRect.new();focus_overlay.name="InteriorFocus";focus_overlay.mouse_filter=Control.MOUSE_FILTER_IGNORE
 focus_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 var shader=Shader.new();shader.code="""shader_type canvas_item;
uniform vec2 room_points[8];
uniform int point_count = 0;
uniform float shade_alpha = 0.0;
void fragment() {
 bool inside = false;
 float distance_to_edge = 2.0;
 for (int i=0; i<8; i++) {
  if (i>=point_count) { break; }
  vec2 a=room_points[i]; vec2 b=room_points[(i+1)%point_count];
  vec2 edge=b-a;
  float t=clamp(dot(UV-a,edge)/max(dot(edge,edge),0.000001),0.0,1.0);
  distance_to_edge=min(distance_to_edge,length(UV-a-edge*t));
  if ((a.y>UV.y)!=(b.y>UV.y)) {
   if (UV.x<(b.x-a.x)*(UV.y-a.y)/(b.y-a.y)+a.x) { inside=!inside; }
  }
 }
 float shade=inside ? 0.0 : smoothstep(0.0,0.025,distance_to_edge);
 COLOR=vec4(0.012,0.022,0.026,shade*shade_alpha);
}"""
 var material=ShaderMaterial.new();material.shader=shader;focus_overlay.material=material;focus_overlay.visible=false
 world.hud.add_child(focus_overlay);world.hud.move_child(focus_overlay,0)
 # Thin pipes can fall between the nine wall samples. A denser upper-body
 # grid keeps them detectable even when only the face/shoulders are covered.
 for height in range(12):
  var y=.12+height*.15
  for x in [-.22,0,.22]:roof_samples.append([x,y,1.5 if y>1.1 else 1.0])
 for mesh in world.kit.wall_meshes+world.kit.scrap_meshes:
  var bounds=mesh.global_transform*mesh.get_aabb()
  var materials=[]
  for i in mesh.mesh.get_surface_count():materials.append(mesh.mesh.surface_get_material(i))
  for entry in world.kit.veil_materials.get(mesh.get_instance_id(),[]):materials.append(entry.material)
  add_state(mesh,bounds,materials,false)
 for entry in world.kit.roof_occluders:add_state(entry.mesh,entry.bounds,[entry.material],true)
func add_state(mesh,bounds:AABB,materials:Array,roof:bool):
 states.append({"mesh":mesh,"bounds":bounds,"materials":materials,"roof":roof,"opacity":1.0,"coverage":0.0,"acquire":0.0,"hold":0.0,"active":false,"switches":0})
 mesh.set_meta("veil_opacity",1.0)
 var center=bounds.get_center();var priority=clampi(roundi((center.x*.65+center.z*.76)*3),-120,120)
 for material in materials:material.render_priority=priority
func coverage(bounds:AABB,padding:float=0.0,roof:bool=false)->float:
 var camera:Camera3D=world.camera;var p:Vector3=world.player.global_position;var area=bounds.grow(padding)
 # Every body ray lies within this conservative central corridor. Most
 # distant batches can skip the detailed grid without changing coverage.
 var center=p+Vector3.UP*.90
 if area.grow(.95).intersects_segment(center+camera.global_basis.z*65,center)==null:return 0.0
 var right:Vector3=camera.global_basis.x;right.y=0;right=right.normalized()
 var hit_weight=0.0;var total=0.0
 # Sample the real body width, with more weight on head/chest. The old 2.8m
 # neighborhood rays made nearby walls disappear even beside the character.
 var samples=roof_samples if roof else [[-.23,.40,1.0],[.23,.40,1.0],[-.23,.90,1.4],[.23,.90,1.4],[0,1.25,1.8],[-.17,1.58,1.4],[.17,1.58,1.4],[0,1.72,1.2],[0,.12,.5]]
 for sample in samples:
  var end=p+right*sample[0]+Vector3.UP*sample[1];var start=end+camera.global_basis.z*65
  total+=sample[2]
  if area.intersects_segment(start,end)!=null:hit_weight+=sample[2]
 return hit_weight/total
func obstruction(bounds:AABB,padding:float=0.0)->bool:return coverage(bounds,padding)>0
func _process(delta):
 if not is_instance_valid(world) or not world.initialized:return
 var inside=Rect2()
 var player=Vector2(world.player.position.x,world.player.position.z)
 for roof in interior_roofs:
  if not is_instance_valid(roof):continue
  var footprint:Rect2=roof.get_meta("interior_rect")
  var occupied=footprint.grow(.15 if footprint==active_interior else -.30).has_point(player)
  roof.visible=not occupied
  if occupied:inside=footprint
 interior_active=inside.has_area();active_interior=inside
 focus_amount=move_toward(focus_amount,.62 if interior_active else 0.0,delta*1.8)
 focus_overlay.visible=focus_amount>.001
 focus_overlay.material.set_shader_parameter("shade_alpha",focus_amount)
 if interior_active:
  var points=PackedVector2Array()
  for x in [inside.position.x,inside.end.x]:
   for z in [inside.position.y,inside.end.y]:
    for y in [0.0,3.8]:
     points.append(world.camera.unproject_position(Vector3(x,y,z)))
  var viewport=world.get_viewport().get_visible_rect().size
  var hull=Geometry2D.convex_hull(points);hull.remove_at(hull.size()-1)
  focus_overlay.material.set_shader_parameter("point_count",hull.size())
  for i in hull.size():hull[i]/=viewport
  hull.resize(8);focus_overlay.material.set_shader_parameter("room_points",hull)
 for state in states:
  if state.mesh.get_meta("dynamic",false) and state.mesh is MeshInstance3D:state.bounds=state.mesh.global_transform*state.mesh.get_aabb()
  var fraction=coverage(state.bounds,.06 if state.active else 0,state.roof)
  if world.overview and not state.roof and state.mesh.get_meta("foreground",false):fraction=maxf(fraction,.32)
  var hit=fraction>0
  if hit:
   state.acquire+=delta;state.hold=HOLD
   if state.acquire>=ACQUIRE and not state.active:state.active=true;state.switches+=1
  else:
   state.acquire=0;state.hold=maxf(0,state.hold-delta)
   if state.hold<=0 and state.active:state.active=false;state.switches+=1
  state.coverage=move_toward(state.coverage,fraction,delta*3.8)
  var minimum=ROOF_FADED if state.roof else FADED
  if state.mesh.name in ["CityInteriorRoof","CityInteriorRoofSnow"]:minimum=.08
  var goal=lerpf(.84,minimum,smoothstep(0,.30 if state.roof else .85,state.coverage)) if state.active else 1.0
  var opacity=move_toward(state.opacity,goal,delta*2.2)
  if not is_equal_approx(opacity,state.opacity):
   state.opacity=opacity;state.mesh.set_meta("veil_opacity",opacity)
   for material in state.materials:material.set_shader_parameter("visibility",opacity)
