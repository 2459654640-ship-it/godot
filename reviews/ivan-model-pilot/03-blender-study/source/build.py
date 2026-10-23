import bpy,sys,os,math,random,json
from pathlib import Path
from mathutils import Vector
random.seed(1982)
ROOT=Path('/workspace/ivan-blender-study');TOOLS=Path('/workspace/ivan-model-pilot/blender-tools')
sys.path.insert(0,str(TOOLS/'mpfb2/src'))
old=bpy.utils.extension_path_user
bpy.utils.extension_path_user=lambda p,*a,**k: '/workspace/ivan-model-pilot/mpfb-data' if p=='mpfb' else old(p,*a,**k)
bpy.ops.preferences.addon_enable(module='mpfb')
from mpfb.services.humanservice import HumanService
from mpfb.services.targetservice import TargetService
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
macro=TargetService.get_default_macro_info_dict();macro.update(gender=1.,age=.5,muscle=.42,weight=.42,height=.5,proportions=.6);macro['race']={'caucasian':1.,'asian':0.,'african':0.}
body=HumanService.create_human(macro_detail_dict=macro);body.name='Ivan_Anatomy'
for rel,amount in [('head/head-oval.target.gz',.15),('head/head-fat-decr.target.gz',.15),('chin/chin-bones-incr.target.gz',.15),('nose/nose-greek-incr.target.gz',.15)]:
 p=TOOLS/'mpfb2/src/mpfb/data/targets'/rel
 if p.exists():TargetService.load_target(body,str(p),weight=amount)
TargetService.bake_targets(body)
# Physical adult height before hair; all anatomy and helper joint markers share the scale.
body_ids={v.index for v in body.data.vertices if any(body.vertex_groups[g.group].name=='body' for g in v.groups)}
low=min(body.data.vertices[i].co.z for i in body_ids);high=max(body.data.vertices[i].co.z for i in body_ids);scale=1.725/(high-low)
for v in body.data.vertices:
 v.co.z-=low;v.co*=scale
 # Lower original A-pose arms toward the reference's relaxed A-pose, before rig fitting.
 x,y,z=v.co
 if abs(x)>.175 and z>.70:
  root=Vector((math.copysign(.175,x),0,1.42));w=min(1,max(0,(abs(x)-.175)/.085));angle=math.copysign(math.radians(17)*w,x)
  q=v.co-root;v.co=root+Vector((math.cos(angle)*q.x+math.sin(angle)*q.z,q.y,-math.sin(angle)*q.x+math.cos(angle)*q.z))
body.data.update();rig=HumanService.add_builtin_rig(body,'game_engine');rig.name='Ivan_Skeleton'
# High-poly fitting eyes from the same CC0 MakeHuman asset family.
eyepath=TOOLS/'makehuman/makehuman/data/eyes/high-poly/high-poly.mhclo'
eyes=HumanService.add_mhclo_asset(str(eyepath),body,asset_type='Eyes',subdiv_levels=0)

def plain(name,color,rough=.72,metal=0):
 m=bpy.data.materials.new(name);m.diffuse_color=(*color,1);m.use_nodes=True;p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=(*color,1);p.inputs['Roughness'].default_value=rough;p.inputs['Metallic'].default_value=metal;return m
skin=plain('Skin_Matte',(.43,.255,.17),.63);hairmat=plain('Hair_Dark_Chestnut',(.055,.027,.014),.69);leather=plain('Worn_Brown_Leather',(.075,.041,.021),.76);brass=plain('Aged_Brass',(.27,.18,.065),.45,.65);canvas=plain('Olive_Canvas',(.18,.155,.095),.9);scarfmat=plain('Cream_Wool',(.48,.44,.34),.94)
# Real mesh surfaces receive static UV projections from the B-sheet, not camera-facing planes.
images={v:bpy.data.images.load('/workspace/ivan-model-pilot/candidate-B/transparent/'+v+'.png') for v in ['front','side','back']}
proj=[]
for key in ['front','side','back']:
 m=plain('B_reference_'+key,(.09,.074,.049),.86);n=m.node_tree.nodes.new('ShaderNodeTexImage');n.image=images[key];mix=m.node_tree.nodes.new('ShaderNodeMixRGB');mix.blend_type='MIX';mix.inputs[1].default_value=(.09,.074,.049,1);m.node_tree.links.new(n.outputs['Alpha'],mix.inputs[0]);m.node_tree.links.new(n.outputs['Color'],mix.inputs[2]);m.node_tree.links.new(mix.outputs[0],m.node_tree.nodes.get('Principled BSDF').inputs['Base Color']);proj.append(m)

def surface_uv(obj,face_only=False):
 obj.data.materials.clear()
 for m in proj:
  copy=m.copy();fallback=(.06,.055,.052,1) if 'Trousers' in obj.name else ((.035,.026,.018,1) if 'Boots' in obj.name else (.09,.074,.049,1))
  for node in copy.node_tree.nodes:
   if node.type=='MIX_RGB':node.inputs[1].default_value=fallback
  obj.data.materials.append(copy)
 
 for layer in list(obj.data.uv_layers):obj.data.uv_layers.remove(layer)
 uv=obj.data.uv_layers.new(name='B_reference_projection')
 for poly in obj.data.polygons:
  n=poly.normal;mat=0 if n.y<0 else 2
  if face_only:mat=0 if n.y<-.45 else 3
  poly.material_index=mat;poly.use_smooth=True
  for li in poly.loop_indices:
   v=obj.matrix_world@obj.data.vertices[obj.data.loops[li].vertex_index].co;x,y,z=v
   u=.5+x*.502 if mat==0 else (.5-x*.502 if mat==2 else .535-y*.502)
   vv=.0605+z/1.75*.879
   if face_only and z>1.48:
    vv=.805+(z-1.505)*.43
    # Calibrate head width separately from the body A-pose projection.
    u=.5+x*.67 if mat==0 else (.5-x*.67 if mat==2 else .535-y*.67)
   uv.data[li].uv=(u,vv)

def add_rig(obj,source=None,indices=None,bone=None):
 if bone:
  g=obj.vertex_groups.new(name=bone);g.add(list(range(len(obj.data.vertices))),1,'REPLACE')
 elif source is not None:
  bones=set(rig.data.bones.keys());groups={g.name:obj.vertex_groups.new(name=g.name) for g in source.vertex_groups if g.name in bones}
  for local,original in enumerate(indices):
   for gw in source.data.vertices[original].groups:
    name=source.vertex_groups[gw.group].name
    if name in groups and gw.weight>0:groups[name].add([local],gw.weight,'REPLACE')
 mod=obj.modifiers.new('Skeleton_Deformation','ARMATURE');mod.object=rig;obj.parent=rig

def group_mesh(name,group,predicate,inflate=0,material=None,rigged=True):
 gi=body.vertex_groups[group].index;groupids={v.index for v in body.data.vertices if any(g.group==gi for g in v.groups)}
 polys=[p for p in body.data.polygons if all(i in groupids for i in p.vertices) and predicate(p)]
 ids=sorted({i for p in polys for i in p.vertices});mp={v:i for i,v in enumerate(ids)}
 vertices=[]
 for i in ids:
  v=body.data.vertices[i];co=v.co+v.normal*inflate
  if group=='helper-tights' and co.z>.8 and abs(co.x)<.23:
   co.x*=1.1;co.y*=1.12
  vertices.append(tuple(co))
 mesh=bpy.data.meshes.new(name);mesh.from_pydata(vertices,[],[[mp[i] for i in p.vertices] for p in polys]);mesh.update();o=bpy.data.objects.new(name,mesh);bpy.context.collection.objects.link(o)
 if material:o.data.materials.append(material)
 else:surface_uv(o)
 if rigged:add_rig(o,body,ids)
 for p in mesh.polygons:p.use_smooth=True
 return o

# Detailed anatomical head and separated fingers; body under clothing is omitted from display.
def vis_skin(p):
 z=p.center.z
 hand=any(sum(g.weight for g in body.data.vertices[i].groups if body.vertex_groups[g.group].name .startswith(('hand_','index_','middle_','ring_','pinky_','thumb_')))>.28 for i in p.vertices)
 return z>1.465 or hand or (z<1.15 and abs(p.center.x)>.30)
body.data.update()
visible=group_mesh('Ivan_Face_Neck_Hands','body',vis_skin,0)
surface_uv(visible,True)
# Skin fallback uses skin tone, never the olive fallback of the clothing projection.
face_material=proj[0].copy();face_material.name='Face_From_B_Front'
for node in face_material.node_tree.nodes:
 if node.type=='MIX_RGB':node.inputs[1].default_value=(.43,.255,.17,1)
visible.data.materials[0]=face_material
# Hands are unprojected skin to avoid picking up the jacket from a planar reference.
visible.data.materials.append(skin)
for p in visible.data.polygons:
 if p.center.z<1.43:p.material_index=3
# The hidden full basemesh stays available for editing and weight transfer.
body.hide_render=True;body.hide_set(True)

def jacket_pred(p):
 c=p.center
 hand=max([sum(g.weight for g in body.data.vertices[i].groups if body.vertex_groups[g.group].name .startswith(('hand_','index_','middle_','ring_','pinky_','thumb_'))) for i in p.vertices])
 return c.z>.79 and c.z<1.475 and hand<.18
jacket=group_mesh('Field_Jacket','helper-tights',jacket_pred,.018)
solid=jacket.modifiers.new('Cloth_Thickness','SOLIDIFY');solid.thickness=.004
jacket.modifiers.new('Tailored_Cloth_Smoothing','SUBSURF').levels=1
pants=group_mesh('Charcoal_Trousers','helper-tights',lambda p:.155<p.center.z<1.04 and abs(p.center.x)<.28,.012)
pants.modifiers.new('Cloth_Smoothing','SUBSURF').levels=1
boots=group_mesh('Leather_Boots','helper-tights',lambda p:p.center.z<.335,.014,leather)
boots.modifiers.new('Leather_Smoothing','SUBSURF').levels=1
surface_uv(boots)
# Fitted eyeball mesh/material was imported from the CC0 fitting asset.

def rounded(name,loc,dims,mat,bevel=.008,bone='spine_03'):
 bpy.ops.mesh.primitive_cube_add(size=1,location=loc);o=bpy.context.object;o.name=name;o.dimensions=dims;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
 b=o.modifiers.new('Soft_Edges','BEVEL');b.width=bevel;b.segments=3
 o.modifiers.new('Surface_Normals','WEIGHTED_NORMAL');o.data.materials.append(mat)
 for p in o.data.polygons:p.use_smooth=True
 if bone:add_rig(o,bone=bone)
 if name in ['Jacket_Pocket','Pocket_Flap','Canvas_Backpack','Backpack_Flap']:surface_uv(o)
 return o

def curve(name,points,radius,mat,bone='spine_03',resolution=3):
 cu=bpy.data.curves.new(name,'CURVE');cu.dimensions='3D';cu.resolution_u=3;cu.bevel_depth=radius;cu.bevel_resolution=resolution
 s=cu.splines.new('BEZIER');s.bezier_points.add(len(points)-1)
 for p,co in zip(s.bezier_points,points):p.co=co;p.handle_left_type='AUTO';p.handle_right_type='AUTO'
 o=bpy.data.objects.new(name,cu);bpy.context.collection.objects.link(o);o.data.materials.append(mat)
 if bone:
  bpy.ops.object.select_all(action='DESELECT');bpy.context.view_layer.objects.active=o;o.select_set(True);bpy.ops.object.convert(target='MESH');o=bpy.context.object;add_rig(o,bone=bone)
 return o
# Jacket surface details use actual volumes, seams and fittings.
for side in [-1,1]:
 for z,w,h in [(1.30,.105,.095),(.91,.135,.13)]:
  pouch=rounded('Jacket_Pocket',(.105*side,-.127,z),(w,.016,h),canvas,.012)
  rounded('Pocket_Flap',(.105*side,-.139,z+h*.36),(w*1.03,.008,.035),canvas,.006)
for z in [1.13,1.23,1.33]:
 bpy.ops.mesh.primitive_uv_sphere_add(segments=12,ring_count=6,radius=.006,location=(.018,-.15,z));o=bpy.context.object;o.name='Jacket_Button';o.scale=(1,.35,1);o.data.materials.append(brass);add_rig(o,bone='spine_03')
# Wide flat straps, instead of round tube shoulder harnesses.
def ribbon(name,points,width,mat,bone='spine_03'):
 verts=[]
 for x,y,z in points:verts.extend([(x-width/2,y,z),(x+width/2,y,z)])
 mesh=bpy.data.meshes.new(name);mesh.from_pydata(verts,[],[(2*i,2*i+1,2*i+3,2*i+2) for i in range(len(points)-1)]);mesh.update();o=bpy.data.objects.new(name,mesh);bpy.context.collection.objects.link(o);o.data.materials.append(mat);so=o.modifiers.new('Strap_Thickness','SOLIDIFY');so.thickness=.003;be=o.modifiers.new('Soft_Strap_Edges','BEVEL');be.width=.002;be.segments=2;add_rig(o,bone=bone);return o
for side in [-1,1]:
 ribbon('Backpack_Shoulder_Strap',[(side*.12,-.15,1.12),(side*.14,-.13,1.32),(side*.15,-.04,1.46),(side*.14,.07,1.45),(side*.12,.17,1.31),(side*.11,.20,1.14)],.027,leather)
 rounded('Strap_Buckle',(side*.125,-.159,1.20),(.032,.008,.038),brass,.003)
# Backpack has rounded shell, flap, straps and two buckles.
bag=rounded('Canvas_Backpack',(0,.175,1.225),(.255,.13,.30),canvas,.035)
rounded('Backpack_Flap',(0,.246,1.315),(.264,.018,.12),canvas,.02)
for side in [-1,1]:
 ribbon('Backpack_Closure',[(side*.075,.267,1.365),(side*.075,.274,1.27),(side*.075,.253,1.115)],.021,leather)
 rounded('Backpack_Closure_Buckle',(side*.075,.278,1.25),(.031,.009,.035),brass,.004)
# Flat leather waist band follows an ellipse, avoiding a rounded rope appearance.
verts=[]
for i in range(65):
 a=i*math.tau/64
 for z in [1.017,1.052]:verts.append((.178*math.cos(a),.119*math.sin(a),z))
me=bpy.data.meshes.new('Belt');me.from_pydata(verts,[],[(2*i,2*i+1,2*i+3,2*i+2) for i in range(64)]);me.update();o=bpy.data.objects.new('Leather_Waist_Belt',me);bpy.context.collection.objects.link(o);o.data.materials.append(leather);add_rig(o,bone='pelvis')
rounded('Belt_Buckle',(0,-.132,1.035),(.045,.014,.035),brass,.004,'pelvis')
# A continuous folded wool band, not stacked cylindrical rings.
verts=[];faces=[]
for row in range(7):
 for col in range(65):
  a=col*math.tau/64;front=max(0,-math.sin(a));r=.073+.005*math.sin(row*.9+a*3)
  verts.append((r*math.cos(a),r*.83*math.sin(a)-.046,1.50+row*.012-.07*front**3+.003*math.sin(col*.8)))
for r in range(6):
 for c in range(64):
  i=r*65+c;faces.append((i,i+1,i+66,i+65))
me=bpy.data.meshes.new('Wool');me.from_pydata(verts,[],faces);me.update();o=bpy.data.objects.new('Folded_Wool_Scarf',me);bpy.context.collection.objects.link(o);o.data.materials.append(scarfmat);mod=o.modifiers.new('Fabric','SOLIDIFY');mod.thickness=.008;o.modifiers.new('Soft_Wool','SUBSURF').levels=1;add_rig(o,bone='neck_01')
for poly in me.polygons:poly.use_smooth=True
# The B-sheet's scarf has a short tucked end; do not add an unreferenced long rectangular tail.
# Scalp follows the detailed skull; short coherent chestnut waves add silhouette.
scalp=group_mesh('Hair_Scalp','body',lambda p:p.center.z>(1.565 if p.center.y>-.06 else 1.665),.003,hairmat)
for i in range(850):
 theta=random.uniform(-math.pi,math.pi);phi=random.uniform(.1,1.22);radx=.086;rady=.112
 cx=radx*math.sin(phi)*math.cos(theta);cy=-.060+rady*math.sin(phi)*math.sin(theta);cz=1.638+.098*math.cos(phi)
 if cy<-.15 and cz<1.65:continue
 pts=[]
 for j in range(9):
  t=j/8;pts.append((cx+.035*t+.007*math.sin(t*math.pi*2+i),cy+.02*t+.006*math.sin(t*math.pi),cz+.015*math.sin(t*math.pi)-.022*t))
 curve('Short_Wavy_Hair',pts,random.uniform(.0008,.0015),hairmat,'head',1)
for material in [canvas,scarfmat,leather,skin]:
 nodes=material.node_tree.nodes;links=material.node_tree.links;noise=nodes.new('ShaderNodeTexNoise');noise.inputs['Scale'].default_value=240 if material==scarfmat else 140;noise.inputs['Detail'].default_value=2
 bump=nodes.new('ShaderNodeBump');bump.inputs['Strength'].default_value=.12;bump.inputs['Distance'].default_value=.001;links.new(noise.outputs['Fac'],bump.inputs['Height']);links.new(bump.outputs['Normal'],nodes.get('Principled BSDF').inputs['Normal'])
# Reference images are embedded and visible as Blender orthographic guides only.
refs=bpy.data.collections.new('B_Turnaround_Reference_Guides');bpy.context.scene.collection.children.link(refs)
for key,rot,loc in [('front',(math.pi/2,0,0),(0,.37,.875)),('side',(math.pi/2,0,math.pi/2),(-.65,0,.875)),('back',(math.pi/2,0,math.pi),(0,-.4,.875))]:
 o=bpy.data.objects.new('B_reference_'+key,None);o.empty_display_type='IMAGE';o.data=images[key];o.empty_display_size=1.75/.879;o.color[3]=.3;o.rotation_euler=rot;o.location=loc;o.hide_render=True;refs.objects.link(o)
# Reference images and native data are packed into the standalone blend.
for image in images.values():image.pack()
# Natural neutral studio and actual game-angle cameras.
scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.samples=48;scene.cycles.use_denoising=False;scene.render.resolution_x=900;scene.render.resolution_y=1000;scene.render.resolution_percentage=100
scene.world.color=(.18,.18,.18)
world=bpy.data.worlds.new('Neutral_Studio');world.use_nodes=True;world.node_tree.nodes['Background'].inputs[0].default_value=(.16,.18,.20,1);world.node_tree.nodes['Background'].inputs[1].default_value=.5;scene.world=world
bpy.ops.mesh.primitive_plane_add(size=200,location=(0,0,-.004));floor=bpy.context.object;floor.name='Studio_Ground';floor.data.materials.append(plain('Ground',(.13,.145,.14),.9))
for name,loc,power,size in [('Key',(-2,-3,4),400,4),('Fill',(3,-2,2.5),220,3),('Rim',(1,3,3),350,3)]:
 data=bpy.data.lights.new(name,'AREA');data.energy=power;data.shape='DISK';data.size=size;o=bpy.data.objects.new(name,data);bpy.context.collection.objects.link(o);o.location=loc;o.rotation_euler=(Vector((0,0,.9))-o.location).to_track_quat('-Z','Y').to_euler()
data=bpy.data.cameras.new('Review_Camera');cam=bpy.data.objects.new('Review_Camera',data);bpy.context.collection.objects.link(cam);scene.camera=cam;data.type='ORTHO';data.ortho_scale=2.05
# Save native editable study first. Never link this into the game automatically.
scene.view_settings.view_transform='AgX'
scene.render.image_settings.file_format='PNG'
body.hide_set(True);bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'output/ivan-B-study.blend'))
for name,loc,target in [('front',(0,-5,.92),(0,0,.92)),('side',(5,0,.92),(0,0,.92)),('back',(0,5,.92),(0,0,.92)),('game',(3,-4,3.7),(0,0,.9))]:
 cam.location=loc;cam.rotation_euler=(Vector(target)-cam.location).to_track_quat('-Z','Y').to_euler();scene.render.filepath=str(ROOT/'renders'/(name+'.png'));bpy.ops.render.render(write_still=True)
print('IVAN_STUDY_READY',len(bpy.data.objects))
