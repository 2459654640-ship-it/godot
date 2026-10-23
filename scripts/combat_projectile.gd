extends Node3D
## Swept sphere, fixed aim and finite lifetime. Pauses and serializes with battle.
var director
var direction=Vector3.FORWARD
var speed=4.6
var remaining=2.5
var harm=10
var shape=SphereShape3D.new()
func setup(d,p:Vector3,heading:Vector3):
 director=d;position=p;direction=heading.normalized();shape.radius=.10
 var body=MeshInstance3D.new();var sphere=SphereMesh.new();sphere.radius=.11;sphere.height=.22;sphere.radial_segments=8;sphere.rings=4;body.mesh=sphere;body.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 var ink=StandardMaterial3D.new();ink.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;ink.albedo_color=Color("c8ad72");body.material_override=ink;add_child(body)
func _physics_process(delta):
 if not is_instance_valid(director):queue_free();return
 if director.paused():return
 remaining-=delta
 if remaining<=0:queue_free();return
 var motion=direction*speed*delta
 var query=PhysicsShapeQueryParameters3D.new();query.shape=shape;query.transform=Transform3D(Basis.IDENTITY,global_position);query.motion=motion;query.collision_mask=1|2|4
 var space=get_world_3d().direct_space_state;var travel=space.cast_motion(query)
 if not travel.is_empty() and travel[0]<1:
  position+=motion*minf(1.0,float(travel[1])+.003)
  query.transform.origin=global_position;query.motion=Vector3.ZERO
  var hits=space.intersect_shape(query)
  var blocked=false
  for hit in hits:
   if hit.collider!=director.w.player and hit.collider!=director.veteran:blocked=true
  if not blocked:
   for hit in hits:
    if hit.collider==director.w.player or hit.collider==director.veteran:director.bite(hit.collider,harm,"喷吐");break
  director.impact_effect(global_position,false);queue_free();return
 position+=motion
func serialize()->Dictionary:return {"position":[position.x,position.y,position.z],"direction":[direction.x,direction.y,direction.z],"speed":speed,"remaining":remaining,"harm":harm}
func _exit_tree():
 if is_instance_valid(director):director.projectiles.erase(self)
