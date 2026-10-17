"""Blender 4.3 authoring: one CC0 human foundation, fitted clothing and one rig.
Usage: blender -b -t 4 --python-exit-code 1 --python tools/build_ivan_pilot.py -- --preview
Full bake: same command without --preview. No AI-generated animation frames.
"""
from pathlib import Path
import bpy, math, json, gzip, sys, random
from mathutils import Vector, Matrix, Quaternion
from mathutils.kdtree import KDTree
ROOT=Path(__file__).resolve().parents[1]
BASE=ROOT/'art-source/v10/ivan/base'; OUT=ROOT/'art-source/v10/ivan'
PREVIEW='--preview' in sys.argv
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.samples=12
scene.cycles.use_denoising=False;scene.render.threads_mode='FIXED';scene.render.threads=4
scene.render.resolution_x=192;scene.render.resolution_y=288;scene.render.resolution_percentage=100
scene.render.film_transparent=True;scene.render.image_settings.file_format='PNG';scene.render.image_settings.color_mode='RGBA'
scene.view_settings.view_transform='Standard';scene.view_settings.look='None';scene.view_settings.exposure=0;scene.view_settings.gamma=1
scene.world.color=(.15,.15,.15)
# Read only the CC0 mesh/target/weight data. No MPFB executable code is vendored.
verts=[];faces=[];groups={};group='';uv=[];uvfaces=[]
for line in (BASE/'base.obj').read_text().splitlines():
 p=line.split()
 if not p:continue
 if p[0]=='v':verts.append(Vector(map(float,p[1:4])))
 elif p[0]=='vt':uv.append(tuple(map(float,p[1:3])))
 elif p[0]=='g':group=p[1];groups.setdefault(group,set())
 elif p[0]=='f':
  ids=[int(t.split('/')[0])-1 for t in p[1:]];groups[group].update(ids)
  if group=='body':faces.append(ids);uvfaces.append([int(t.split('/')[1])-1 if '/' in t else 0 for t in p[1:]])
for line in gzip.decompress((BASE/'male-young.target.gz').read_bytes()).decode().splitlines():
 p=line.split()
 if p and not p[0].startswith('#'):
  i=int(p[0]);verts[i]+=Vector(map(float,p[1:4]))
body_indices=sorted(groups['body']);bottom=min(verts[i].y for i in body_indices);top=max(verts[i].y for i in body_indices)
scale=1.75/(top-bottom)
V=[Vector((p.x*scale,-p.z*scale,(p.y-bottom)*scale)) for p in verts]
weights=json.loads((BASE/'weights.json').read_text())['weights'];W=[{} for v in V]
for name,entries in weights.items():
 for i,w in entries:W[i][name]=w
kd=KDTree(len(body_indices))
for i in body_indices:kd.insert(V[i],i)
kd.balance()

def material(name,color,tex=None):
 m=bpy.data.materials.new(name);m.diffuse_color=(*color,1);m.use_nodes=True
 n=m.node_tree.nodes;n.clear();o=n.new('ShaderNodeOutputMaterial');p=n.new('ShaderNodeBsdfPrincipled');p.inputs['Base Color'].default_value=(*color,1);p.inputs['Roughness'].default_value=.88
 m.node_tree.links.new(p.outputs[0],o.inputs['Surface'])
 noise=n.new('ShaderNodeTexNoise');noise.inputs['Scale'].default_value=125;noise.inputs['Detail'].default_value=3
 bump=n.new('ShaderNodeBump');bump.inputs['Strength'].default_value=.15;bump.inputs['Distance'].default_value=.008;m.node_tree.links.new(noise.outputs['Fac'],bump.inputs['Height']);m.node_tree.links.new(bump.outputs[0],p.inputs['Normal'])
 # A subdued, reusable fabric scan provides grain instead of a flat colour.
 if tex:
  tc=n.new('ShaderNodeTexCoord');t=n.new('ShaderNodeTexImage');t.image=bpy.data.images.load(str(ROOT/tex),check_existing=True);t.projection='BOX';t.projection_blend=.28
  m.node_tree.links.new(tc.outputs['Generated'],t.inputs['Vector'])
  mix=n.new('ShaderNodeMixRGB');mix.blend_type='MULTIPLY';mix.inputs[0].default_value=.65;mix.inputs[1].default_value=(*color,1);m.node_tree.links.new(t.outputs['Color'],mix.inputs[2]);m.node_tree.links.new(mix.outputs[0],p.inputs['Base Color'])
 return m
mats={
 'jacket':material('Weathered brown cotton',(.28,.17,.095),'assets/visual/weave.png'),
 'edge':material('Reinforced seams',(.19,.105,.055)),
 'trousers':material('Olive wool trousers',(.12,.15,.105),'assets/visual/weave.png'),
 'scarf':material('Undyed wool scarf',(.61,.56,.43),'assets/visual/weave.png'),
 'boot':material('Worn leather boots',(.085,.065,.048)),
 'sole':material('Rubber sole',(.03,.028,.023)),
 'bag':material('Canvas rucksack',(.22,.16,.09),'assets/visual/weave.png'),
 'strap':material('Leather straps',(.12,.075,.036)),
 'skin':material('Skin',(.56,.36,.25)),
 'hair':material('Chestnut hair',(.16,.085,.04),'art-source/v10/ivan/hair_paint.png'),
 'hair_light':material('Chestnut hair highlights',(.21,.12,.06),'art-source/v10/ivan/hair_paint.png'),
 'eye':material('Eyes',(.24,.21,.16)),
 'metal':material('Tarnished fasteners',(.19,.18,.13)),
}
# The game-engine rig resolves named anatomical joint cubes on the morphed body.
rdef=json.loads((BASE/'rig.json').read_text())
def point(d):
 ids=d.get('vertex_indices') or groups.get(d.get('cube_name',''))
 if ids:return sum((V[i] for i in ids),Vector())/len(ids)
 return Vector((0,0,0))
armdata=bpy.data.armatures.new('Ivan skeleton');rig=bpy.data.objects.new('Ivan unified rig',armdata);scene.collection.objects.link(rig)
bpy.context.view_layer.objects.active=rig;rig.select_set(True);bpy.ops.object.mode_set(mode='EDIT')
for name,d in rdef.items():
 b=armdata.edit_bones.new(name);b.head=point(d['head']);b.tail=point(d['tail'])
 if name=='Root':b.head=(0,0,0);b.tail=(0,0,.15)
 if (b.tail-b.head).length<.001:b.tail=b.head+Vector((0,0,.05))
 b.roll=d.get('roll',0)
for name,d in rdef.items():
 if d.get('parent'):armdata.edit_bones[name].parent=armdata.edit_bones[d['parent']]
bpy.ops.object.mode_set(mode='OBJECT');rig.select_set(False)
model=[]
def skin(obj,bone=None,source_ids=None):
 model.append(obj)
 if source_ids is not None:
  entries=[W[i] for i in source_ids]
 elif bone:entries=[{bone:1.0}]*len(obj.data.vertices)
 else:entries=[W[kd.find(v.co)[1]] for v in obj.data.vertices]
 for i,ws in enumerate(entries):
  for name,w in ws.items():
   if name not in armdata.bones:continue
   vg=obj.vertex_groups.get(name) or obj.vertex_groups.new(name=name);vg.add([i],w,'REPLACE')
 mod=obj.modifiers.new('Shared skeletal deformation','ARMATURE');mod.object=rig;mod.use_deform_preserve_volume=True
 obj.parent=rig
 for poly in obj.data.polygons:poly.use_smooth=True
 return obj

def mesh(name,points,polys,mat,bone=None,source=None,sub=1):
 data=bpy.data.meshes.new(name);data.from_pydata(points,[],polys);data.update();o=bpy.data.objects.new(name,data);scene.collection.objects.link(o);data.materials.append(mats[mat]);skin(o,bone,source)
 if mat in ['jacket','trousers']:
  tex=bpy.data.textures.get('Fixed cloth folds') or bpy.data.textures.new('Fixed cloth folds',type='CLOUDS');tex.noise_scale=.065;tex.noise_depth=2
  d=o.modifiers.new('Rest-space cloth creasing','DISPLACE');d.texture=tex;d.strength=.005;d.mid_level=.5
  bpy.context.view_layer.objects.active=o;bpy.ops.object.modifier_move_up(modifier=d.name)
 if sub:
  mod=o.modifiers.new('Cloth surface smoothing','SUBSURF');mod.levels=sub;mod.render_levels=sub
 return o
# Only the visible head, neck and hands use the detailed anatomical foundation.
selected=[]
for f in faces:
 c=sum((V[i] for i in f),Vector())/len(f)
 if c.z>1.48 or (abs(c.x)>.35 and c.z<1.25):selected.append(f)
used=sorted(set(i for f in selected for i in f));remap={n:i for i,n in enumerate(used)}
head=mesh('Ivan face neck and hands',[V[i] for i in used],[[remap[i] for i in f] for f in selected],'skin',source=used,sub=1)
# Skin facial colour is projected from Ivan's existing portrait, not a new identity.
face=bpy.data.materials.new('Ivan original face colours');face.use_nodes=True;n=face.node_tree.nodes;p=n.get('Principled BSDF');p.inputs['Roughness'].default_value=.9
img=n.new('ShaderNodeTexImage');img.image=bpy.data.images.load(str(ROOT/'assets/characters/ivan.png'));mix=n.new('ShaderNodeMixRGB');mix.inputs[0].default_value=.65;mix.inputs[1].default_value=(.56,.36,.25,1);face.node_tree.links.new(img.outputs['Color'],mix.inputs[2]);face.node_tree.links.new(mix.outputs[0],p.inputs['Base Color'])
head.data.materials.append(face);layer=head.data.uv_layers.new(name='Original face projection')
for poly in head.data.polygons:
 c=sum((head.data.vertices[i].co for i in poly.vertices),Vector())/len(poly.vertices)
 if c.z>1.55 and c.y<-.035:poly.material_index=1
 for li in poly.loop_indices:
  co=head.data.vertices[head.data.loops[li].vertex_index].co
  px=120+co.x*290;py=65-(co.z-1.65)*315
  layer.data[li].uv=(px/1200,1-py/1056)

def rings(name,sections,mat,bone=None,segments=20):
 points=[];polys=[]
 for z,rx,ry,cy in sections:
  for i in range(segments):
   t=2*math.pi*i/segments;points.append((rx*math.cos(t),cy+ry*math.sin(t),z))
 for j in range(len(sections)-1):
  for i in range(segments):polys.append((j*segments+i,j*segments+(i+1)%segments,(j+1)*segments+(i+1)%segments,(j+1)*segments+i))
 polys.extend([tuple(reversed(range(segments))),tuple((len(sections)-1)*segments+i for i in range(segments))])
 return mesh(name,points,polys,mat,bone)
# Tailored jacket includes a hem and collar, not a painted naked torso.
rings('Jacket body',[(.80,.215,.197,0),(.82,.218,.198,0),(.94,.209,.19,0),(1.06,.21,.18,0),(1.25,.248,.18,0),(1.39,.234,.14,0),(1.43,.19,.116,0),(1.48,.086,.082,-.005),(1.49,.082,.08,-.005)],'jacket','pelvis')
# Close-fitting trousers are derived from the same legs and rig.
legfaces=[f for f in faces if max(V[i].z for i in f)<1.04 and min(V[i].z for i in f)>.30 and max(abs(V[i].x) for i in f)<.30]
used=sorted(set(i for f in legfaces for i in f));remap={n:i for i,n in enumerate(used)}
tr=[]
for i in used:
 p=V[i].copy();side=1 if p.x>0 else -1;cx=.105*side;p.x=cx+(p.x-cx)*1.15;p.y*=1.20;tr.append(p)
mesh('Wool trousers',tr,[[remap[i] for i in f] for f in legfaces],'trousers',source=used)

def tube(name,centers,radii,mat,bone=None,n=12):
 ps=[];fs=[]
 for j,c in enumerate(centers):
  c=Vector(c);t=Vector(centers[min(j+1,len(centers)-1)])-Vector(centers[max(0,j-1)])
  if t.length<.00001:t=Vector((0,0,1))
  t.normalize();a=t.cross(Vector((0,1,0))).normalized();b=t.cross(a).normalized()
  for i in range(n):ps.append(c+(math.cos(i*2*math.pi/n)*a+math.sin(i*2*math.pi/n)*b)*radii[j])
 for j in range(len(centers)-1):
  for i in range(n):fs.append((j*n+i,j*n+(i+1)%n,(j+1)*n+(i+1)%n,(j+1)*n+i))
 fs+=[tuple(reversed(range(n))),tuple((len(centers)-1)*n+i for i in range(n))]
 return mesh(name,ps,fs,mat,bone)
def box(name,loc,size,mat,bone='spine_03',bevel=.012):
 bpy.ops.mesh.primitive_cube_add(size=1,location=loc);o=bpy.context.object;o.name=name;o.dimensions=size;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
 # All model geometry uses world coordinates before armature deformation.
 for v in o.data.vertices:v.co+=o.location
 o.location=(0,0,0);o.data.materials.append(mats[mat]);skin(o,bone)
 if bevel:
  m=o.modifiers.new('Worn rounded edges','BEVEL');m.width=bevel;m.segments=3;o.modifiers.new('Weighted corner normals','WEIGHTED_NORMAL')
 return o
def ellipsoid(name,loc,scale,mat,bone='head'):
 bpy.ops.mesh.primitive_uv_sphere_add(segments=20,ring_count=12,location=loc);o=bpy.context.object;o.name=name;o.scale=scale;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
 for v in o.data.vertices:v.co+=o.location
 o.location=(0,0,0);o.data.materials.append(mats[mat]);return skin(o,bone)
for side in ['l','r']:
 s=1 if side=='l' else -1
 shoulder=armdata.bones['upperarm_'+side].head_local;elbow=armdata.bones['lowerarm_'+side].head_local;wrist=armdata.bones['hand_'+side].head_local
 tube('Padded sleeve '+side,[shoulder,shoulder.lerp(elbow,.3),elbow,elbow.lerp(wrist,.75),wrist],[.082,.088,.071,.058,.052],'jacket')
 tube('Wrist cuff '+side,[wrist.lerp(elbow,.06),wrist],[.057,.054],'edge')
 ankle=armdata.bones['foot_'+side].head_local;foot=armdata.bones['foot_'+side];x=ankle.x
 ellipsoid('Leather boot foot '+side,(x,ankle.y-.055,.085),(.073,.15,.077),'boot','foot_'+side)
 box('Boot sole '+side,(x,ankle.y-.055,.027),(.15,.30,.039),'sole','foot_'+side,.018)
 tube('Boot shaft '+side,[(x,ankle.y,.10),(x,ankle.y,.17),(x*.9,ankle.y,.32),(x*.9,ankle.y,.35)],[.069,.065,.073,.073],'boot','calf_'+side)
 for z in [.19,.25,.31]:box('Boot seam '+side,(x,ankle.y-.068,z),(.10,.009,.007),'edge','calf_'+side,.002)
 for z in [1.03,1.27]:
  xx=s*(.12 if z>1.2 else .118);yy=-.18 if z>1.2 else -.202
  box('Jacket patch pocket',(xx,yy,z),(.105,.012,.10),'jacket','spine_03' if z>1.2 else 'pelvis')
  box('Pocket flap',(xx,yy-.018,z+.045),(.112,.014,.027),'edge','spine_03' if z>1.2 else 'pelvis',.006)
 # Leather rucksack harness follows shoulders to waist in rest coordinates.
 tube('Rucksack strap '+side,[(s*.145,.12,1.04),(s*.185,.135,1.38),(s*.16,-.04,1.43),(s*.16,-.153,1.28),(s*.16,-.145,1.08)],[.019]*5,'strap','spine_03',8)
box('Jacket central fastening',(0,-.204,1.14),(.014,.010,.49),'edge','spine_02',.003)
for z in [.97,1.06,1.15,1.24,1.33]:ellipsoid('Jacket button',(0,-.215,z),(.011,.005,.011),'metal','spine_02')
# Scarf is a real loose wool collar and two ribbed hanging ends.
rings('Wool scarf collar',[(1.43,.112,.104,-.008),(1.45,.114,.108,-.008),(1.48,.106,.104,-.01),(1.51,.098,.093,-.012)],'scarf','neck_01',24)
for i in range(7):
 z=1.439+i*.01;rings('Scarf knit ridge',[(z,.115,.109,-.009),(z+.003,.115,.11,-.009)],'scarf','neck_01',20)
box('Scarf long end',(-.035,-.177,1.34),(.067,.015,.25),'scarf','spine_03',.012)
box('Scarf short end',(.035,-.181,1.38),(.058,.017,.17),'scarf','spine_03',.012)
for x in [-.059,-.041,-.023,.020,.038,.056]:box('Scarf knitted rib',(x,-.193,1.35),(.003,.004,.18),'scarf','spine_03',.001)
box('Rucksack body',(0,.218,1.15),(.29,.14,.33),'bag','spine_02',.04)
box('Rucksack top flap',(0,.225,1.31),(.30,.16,.06),'jacket','spine_03',.02)
for x in [-.079,.079]:
 box('Rucksack outer pocket',(x,.316,1.07),(.13,.075,.15),'bag','spine_02',.018)
 box('Rucksack securing strap',(x,.354,1.18),(.024,.018,.26),'strap','spine_02',.004)
 box('Rucksack buckle',(x,.367,1.19),(.036,.012,.04),'metal','spine_02',.004)
# Short tousled hair, each lock attached to the same head bone.
random.seed(1982)
ellipsoid('Hair cap',(0,-.046,1.685),(.105,.116,.098),'hair')
for i in range(46):
 t=random.uniform(0,2*math.pi);a=random.uniform(.10,1.52)
 x=.098*math.sin(a)*math.cos(t);y=-.046+.116*math.sin(a)*math.sin(t);z=1.685+.095*math.cos(a)
 # Parted short locks sweep toward the side and rear, never a ponytail.
 end=Vector((x+.012,y+.014,z-.035));start=Vector((x*.85,y*.85,z+.006));mid=(start+end)*.5+Vector((.01,-.004,.012))
 tube('Tousled chestnut lock',[start,mid,end],[.015,.019,.003],'hair_light' if i%4==0 else 'hair','head',7)
for x in [-.075,-.05,-.025,0,.025,.05,.075]:
 tube('Short swept fringe',[(x-.008,-.135,1.728),(x+.009,-.153,1.708),(x+.023,-.153,1.686)],[.014,.018,.002],'hair','head',8)
# Eyeballs fill anatomical sockets; facial features otherwise remain the base topology.
for side in ['l','r']:
 eye=point({'cube_name':'joint-'+side+'-eye'});ellipsoid('Eye '+side,eye,(.0115,.0115,.0115),'eye')
# Project the existing painted clothing onto the fixed rest mesh. UVs travel with
# the skeleton, so every frame keeps exactly the same wear, seams and identity.
reference=bpy.data.images.load(str(ROOT/'assets/characters/ivan.png'),check_existing=True)
for key in ['jacket','trousers','bag','boot','strap','edge','scarf']:
 m=mats[key];nodes=m.node_tree.nodes;links=m.node_tree.links;p=next(n for n in nodes if n.type=='BSDF_PRINCIPLED')
 tex=nodes.new('ShaderNodeTexImage');tex.image=reference;tex.interpolation='Linear'
 blend=nodes.new('ShaderNodeMixRGB');factor=nodes.new('ShaderNodeMath');factor.operation='MULTIPLY';factor.inputs[1].default_value=.72
 links.new(tex.outputs['Alpha'],factor.inputs[0]);links.new(factor.outputs[0],blend.inputs[0]);links.new(tex.outputs['Color'],blend.inputs[2])
 if p.inputs['Base Color'].is_linked:links.new(p.inputs['Base Color'].links[0].from_socket,blend.inputs[1])
 else:blend.inputs[1].default_value=p.inputs['Base Color'].default_value
 links.new(blend.outputs[0],p.inputs['Base Color'])
for obj in model:
 if obj==head:continue
 layer=obj.data.uv_layers.get('Paint projection') or obj.data.uv_layers.new(name='Paint projection')
 obj.data.uv_layers.active=layer;layer.active_render=True
 for poly in obj.data.polygons:
  normal=poly.normal;angle=-math.atan2(normal.x,-normal.y) if abs(normal.x)+abs(normal.y)>.1 else 0
  slot=int(round(angle/(math.pi/4)));slot=max(-4,min(4,slot));theta=slot*math.pi/4
  for li in poly.loop_indices:
   p=obj.data.vertices[obj.data.loops[li].vertex_index].co
   x=p.x*math.cos(theta)-p.y*math.sin(theta);y=p.x*math.sin(theta)+p.y*math.cos(theta)
   if slot<0:x=-x
   px=abs(slot)*240+120+x*242;py=342-242*(p.z*math.cos(math.radians(40))+y*math.sin(math.radians(40)))
   px=max(abs(slot)*240+1,min((abs(slot)+1)*240-1,px));py=max(1,min(350,py))
   layer.data[li].uv=(px/1200,1-py/1056)
# Face uses the same camera calibration as the clothing rather than a stretched crop.
for li in range(len(head.data.loops)):
 p=head.data.vertices[head.data.loops[li].vertex_index].co
 head.data.uv_layers[0].data[li].uv=((120+p.x*242)/1200,1-(342-242*(p.z*.766044+p.y*.642788))/1056)
# Save a reusable native file, with mesh, materials, skeleton, and authored keyframes.
def set_segment(name,head,tail):
 b=rig.pose.bones[name];rest=armdata.bones[name];q=(rest.tail_local-rest.head_local).rotation_difference(Vector(tail)-Vector(head))
 m=q.to_matrix().to_4x4()@rest.matrix_local;m.translation=Vector(head);b.matrix=m;bpy.context.view_layer.update()

def pose(kind,t):
 for b in rig.pose.bones:b.matrix_basis=Matrix.Identity(4)
 moving=kind=='walk';phase=t*2*math.pi
 bob=-.050-.012*math.cos(phase*2) if moving else .0015*math.sin(phase)
 root=rig.pose.bones['pelvis'];root.location.z=bob
 h=rig.pose.bones['head'];h.rotation_mode='XYZ';h.rotation_euler.x=math.radians(-8)
 bpy.context.view_layer.update()
 for side,offset in [('l',0),('r',math.pi)]:
  s=1 if side=='l' else -1;ph=(t+offset/(2*math.pi))%1
  hip=armdata.bones['thigh_'+side].head_local+Vector((0,0,bob))
  restankle=armdata.bones['foot_'+side].head_local
  # First half: foot planted and travelling backward. Second half: clearance.
  if moving:
   u=ph*2 if ph<.5 else (ph-.5)*2
   yy=(-.30+.60*u) if ph<.5 else (.30-.60*(u*u*(3-2*u)))
   zz=0 if ph<.5 else .075*math.sin(math.pi*u)
  else:yy=0;zz=0
  ankle=Vector((restankle.x*.66,restankle.y+yy,restankle.z+zz))
  l1=(armdata.bones['thigh_'+side].tail_local-armdata.bones['thigh_'+side].head_local).length;l2=(armdata.bones['calf_'+side].tail_local-armdata.bones['calf_'+side].head_local).length
  delta=ankle-hip;dist=min(delta.length,l1+l2-.001);direction=delta.normalized();along=(l1*l1-l2*l2+dist*dist)/(2*dist)
  bend=Vector((0,-1,0));bend=(bend-direction*bend.dot(direction)).normalized()
  knee=hip+direction*along+bend*math.sqrt(max(.00001,l1*l1-along*along))
  set_segment('thigh_'+side,hip,knee);set_segment('calf_'+side,knee,ankle)
  footdir=armdata.bones['foot_'+side].tail_local-armdata.bones['foot_'+side].head_local
  set_segment('foot_'+side,ankle,ankle+footdir)
  shoulder=armdata.bones['upperarm_'+side].head_local+Vector((0,0,bob));swing=.07*math.cos(phase+offset) if moving else 0
  elbow=shoulder+Vector((s*.035,swing-.015,-.245));wrist=shoulder+Vector((s*.048,swing*1.7-.055,-.47))
  if kind=='aim':elbow=shoulder+Vector((s*.085,-.17,-.10));wrist=shoulder+Vector((-s*.05,-.38,-.065))
  set_segment('upperarm_'+side,shoulder,elbow);set_segment('lowerarm_'+side,elbow,wrist)
  handdir=Vector((0,-.025,-.075)) if kind!='aim' else Vector((0,-.075,0))
  set_segment('hand_'+side,wrist,wrist+handdir)
 bpy.context.view_layer.update()
# Separate actions preserve the continuous rig, even though runtime uses baked frames.
for kind,count in [('idle',4),('walk',16),('aim',4)]:
 rig.animation_data_create();action=bpy.data.actions.new('Ivan '+kind);rig.animation_data.action=action
 for i in range(count+1):
  pose(kind,i/count)
  for b in rig.pose.bones:
   b.rotation_mode='QUATERNION';b.keyframe_insert('rotation_quaternion',frame=i+1);b.keyframe_insert('location',frame=i+1)
 action.use_fake_user=True
rig.animation_data_clear();pose('idle',0)
bpy.ops.object.camera_add(location=(0,-6,5.734));cam=bpy.context.object;cam.name='Fixed isometric bake camera';cam.rotation_euler=(Vector((0,0,.7))-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.type='ORTHO';cam.data.ortho_scale=2.2;scene.camera=cam
for loc,energy,size in [((2,-4,5),220,4),((-3,-2,2.5),100,3),((1,3,4),180,3)]:
 bpy.ops.object.light_add(type='AREA',location=loc);l=bpy.context.object;l.data.energy=energy;l.data.shape='DISK';l.data.size=size;l.rotation_euler=(Vector((0,0,1))-l.location).to_track_quat('-Z','Y').to_euler()
scene.render.filepath=str(OUT/'preview.png')
bpy.context.preferences.filepaths.save_version=0
bpy.ops.file.pack_all()
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'ivan.blend'))
if PREVIEW:
 scene.render.resolution_x=512;scene.render.resolution_y=768;scene.cycles.samples=48
 scene.render.filepath=str(OUT/'preview.png');bpy.ops.render.render(write_still=True)
 print('IVAN_PREVIEW_READY');sys.exit(0)
# Render colour (soft local AO, no baked directional lights), and view-space normals.
# Emission colours keep the runtime free to apply its own room lighting.
for m in list(bpy.data.materials):
 if not m.use_nodes:continue
 n=m.node_tree.nodes;links=m.node_tree.links;o=n.get('Material Output');p=next((x for x in n if x.type=='BSDF_PRINCIPLED'),None)
 if not p:continue
 em=n.new('ShaderNodeEmission');em.inputs['Strength'].default_value=1
 if p.inputs['Base Color'].is_linked:links.new(p.inputs['Base Color'].links[0].from_socket,em.inputs['Color'])
 else:em.inputs['Color'].default_value=p.inputs['Base Color'].default_value
 ao=n.new('ShaderNodeAmbientOcclusion');ao.inputs['Distance'].default_value=.10;ao.samples=8;ao.only_local=True
 mix=n.new('ShaderNodeMixRGB');mix.blend_type='MULTIPLY';mix.inputs[0].default_value=.40
 if em.inputs['Color'].is_linked:links.new(em.inputs['Color'].links[0].from_socket,mix.inputs[1])
 else:mix.inputs[1].default_value=em.inputs['Color'].default_value
 links.new(ao.outputs['Color'],mix.inputs[2]);links.new(mix.outputs[0],em.inputs['Color']);links.new(em.outputs[0],o.inputs['Surface'])
normal_mat=bpy.data.materials.new('View-space baked surface normals');normal_mat.use_nodes=True
n=normal_mat.node_tree.nodes;n.clear();links=normal_mat.node_tree.links;o=n.new('ShaderNodeOutputMaterial');e=n.new('ShaderNodeEmission');geo=n.new('ShaderNodeNewGeometry');vec=n.new('ShaderNodeVectorTransform');vec.vector_type='NORMAL';vec.convert_from='WORLD';vec.convert_to='CAMERA';links.new(geo.outputs['Normal'],vec.inputs[0]);mult=n.new('ShaderNodeVectorMath');mult.operation='MULTIPLY_ADD';mult.inputs[1].default_value=(.5,.5,.5);mult.inputs[2].default_value=(.5,.5,.5);links.new(vec.outputs[0],mult.inputs[0]);links.new(mult.outputs[0],e.inputs['Color']);links.new(e.outputs[0],o.inputs[0])
# Put actual geometric depth into normal PNG alpha in the same render pass.
# This allows the game to depth-test feet, walls and lamps using the model,
# rather than the unrelated position of the flat drawing plane.
aov=scene.view_layers[0].aovs.add();aov.name='FrameDepth';aov.type='VALUE'
dot=n.new('ShaderNodeVectorMath');dot.operation='DOT_PRODUCT';dot.inputs[1].default_value=(0,-.766044443,.642787610)
links.new(geo.outputs['Position'],dot.inputs[0])
subtract=n.new('ShaderNodeMath');subtract.operation='SUBTRACT';subtract.inputs[1].default_value=.7*.642787610;links.new(dot.outputs['Value'],subtract.inputs[0])
encode=n.new('ShaderNodeMath');encode.operation='MULTIPLY_ADD';encode.inputs[1].default_value=1/3;encode.inputs[2].default_value=.5;links.new(subtract.outputs[0],encode.inputs[0])
output_aov=n.new('ShaderNodeOutputAOV');output_aov.aov_name='FrameDepth';links.new(encode.outputs[0],output_aov.inputs['Value'])
scene.use_nodes=True;nodes=scene.node_tree.nodes;nodes.clear();cl=scene.node_tree.links
layers=nodes.new('CompositorNodeRLayers');composite=nodes.new('CompositorNodeComposite');alpha=nodes.new('CompositorNodeSetAlpha');alpha.mode='APPLY'
cl.new(layers.outputs['Image'],alpha.inputs['Image']);cl.new(layers.outputs['FrameDepth'],alpha.inputs['Alpha'])
scene.cycles.samples=12
frames=OUT/('probe' if '--probe' in sys.argv else 'frames');frames.mkdir(exist_ok=True)
index=[]
for row,(kind,t) in enumerate([('idle',i/4) for i in range(4)]+[('walk',i/16) for i in range(16)]+[('aim',i/4) for i in range(4)]):
 pose(kind,t)
 for direction in range(8):
  rig.rotation_euler.z=direction*math.pi/4;bpy.context.view_layer.update()
  stem=f'{row:02d}-{direction}'
  scene.view_layers[0].material_override=None;scene.view_settings.view_transform='Standard';scene.cycles.use_denoising=False
  cl.new(layers.outputs['Image'],composite.inputs['Image'])
  scene.render.filepath=str(frames/(stem+'-color.png'));bpy.ops.render.render(write_still=True)
  if '--color-only' not in sys.argv:
   scene.view_layers[0].material_override=normal_mat;scene.view_settings.view_transform='Raw';scene.cycles.use_denoising=False
   cl.new(alpha.outputs['Image'],composite.inputs['Image'])
   scene.render.filepath=str(frames/(stem+'-normal.png'));bpy.ops.render.render(write_still=True)
  index.append({'row':row,'direction':direction,'animation':kind,'phase':t})
  if '--probe' in sys.argv:break
 print('IVAN_BAKE_ROW',row,kind,flush=True)
 if '--probe' in sys.argv:break
(OUT/('probe.json' if '--probe' in sys.argv else 'frames.json')).write_text(json.dumps(index,indent=2)+'\n')
print('IVAN_BAKE_COMPLETE',len(index))
