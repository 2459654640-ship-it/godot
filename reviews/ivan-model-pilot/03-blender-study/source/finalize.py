import bpy,math,json,random
from pathlib import Path
from mathutils import Vector
ROOT=Path('/workspace/ivan-blender-study')
bpy.ops.wm.open_mainfile(filepath=str(ROOT/'output/ivan-B-study.blend'))
rig=bpy.data.objects['Ivan_Skeleton'];mat=bpy.data.materials['Hair_Dark_Chestnut']
random.seed(2301)
for i in range(180):
 angle=random.uniform(.12,math.pi-.12);start=random.uniform(.45,.9)
 cu=bpy.data.curves.new('Nape_Wave','CURVE');cu.dimensions='3D';cu.bevel_depth=.0012;cu.bevel_resolution=1;cu.resolution_u=2
 sp=cu.splines.new('BEZIER');sp.bezier_points.add(8)
 for j,p in enumerate(sp.bezier_points):
  t=j/8;phi=start+t*(1.95-start);a=angle+.05*math.sin(t*7+i)
  p.co=(.086*math.sin(phi)*math.cos(a),-.05+.114*math.sin(phi)*math.sin(a),1.634+.108*math.cos(phi));p.handle_left_type='AUTO';p.handle_right_type='AUTO';p.radius=1-.8*t**3
 o=bpy.data.objects.new('Nape_Wave',cu);bpy.context.collection.objects.link(o);cu.materials.append(mat)
 bpy.ops.object.select_all(action='DESELECT');o.select_set(True);bpy.context.view_layer.objects.active=o;bpy.ops.object.convert(target='MESH');o=bpy.context.object
 g=o.vertex_groups.new(name='head');g.add(list(range(len(o.data.vertices))),1,'REPLACE');mod=o.modifiers.new('Skeleton','ARMATURE');mod.object=rig;o.parent=rig
# Merge the many strand meshes into one editable hair object, keeping bone weights.
hair=[o for o in bpy.data.objects if o.type=='MESH' and (o.name.startswith('Short_Wavy_Hair') or o.name.startswith('Nape_Wave') or o.name.startswith('Hair_Fringe_Wave'))]
bpy.ops.object.select_all(action='DESELECT')
for o in hair:o.select_set(True)
bpy.context.view_layer.objects.active=hair[0];bpy.ops.object.join();bpy.context.object.name='Ivan_Wavy_Hair_Strands'
for image in bpy.data.images:
 if image.source=='FILE':
  try:image.pack()
  except RuntimeError:pass
s=bpy.context.scene;s.cycles.use_denoising=False;s.cycles.samples=48;s.render.resolution_x=900;s.render.resolution_y=1000
for name,loc,target in [('front',(0,-5,.92),(0,0,.92)),('side',(5,0,.92),(0,0,.92)),('back',(0,5,.92),(0,0,.92)),('game',(3,-4,3.7),(0,0,.9))]:
 s.camera.location=loc;s.camera.rotation_euler=(Vector(target)-s.camera.location).to_track_quat('-Z','Y').to_euler();s.render.filepath=str(ROOT/'renders'/(name+'.png'));bpy.ops.render.render(write_still=True)
# Native Blender project is the primary deliverable; no model installation in the game.
bpy.ops.object.select_all(action='DESELECT');rig.hide_set(False);rig.select_set(True);bpy.context.view_layer.objects.active=rig
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'output/ivan-B-study.blend'),compress=True)
meshes=[o for o in bpy.data.objects if o.type=='MESH' and not o.hide_render]
report={'reference':'AI B-sheet: original front/side/back images embedded as orthographic guides and used for surface projections','method':'MPFB/MakeHuman detailed CC0 anatomical topology adjusted to adult proportions; tailored clothing, actual mesh equipment, wave strands and reference-based UV projections. Not automatic multi-view AI reconstruction.','blender':bpy.app.version_string,'visible_mesh_objects':len(meshes),'base_mesh_vertices':sum(len(o.data.vertices) for o in meshes),'skeleton_bones':len(rig.data.bones),'animations_authored':False,'in_game_replacement':False,'status':'Static form/material study for review; side projections, fine face/hair likeness and clothing seams remain candidates for further refinement.'}
(ROOT/'output/study-report.json').write_text(json.dumps(report,ensure_ascii=False,indent=2))
# Lightweight real Blender turntable renders, not a generated illustration.
s.render.resolution_x=540;s.render.resolution_y=600;s.cycles.samples=16
for frame in range(16):
 a=frame*math.tau/16;loc=Vector((4*math.sin(a),-4*math.cos(a),1.2));s.camera.location=loc;s.camera.rotation_euler=(Vector((0,0,.91))-loc).to_track_quat('-Z','Y').to_euler();s.render.filepath=str(ROOT/'renders'/('turn-%02d.png'%frame));bpy.ops.render.render(write_still=True)
print('FINAL_STUDY_READY',json.dumps(report))
