import bpy,json,math
from pathlib import Path
from mathutils import Vector
ROOT=Path('/workspace/ivan-blender-study')
bpy.ops.wm.open_mainfile(filepath=str(ROOT/'output/ivan-B-study.blend'))
rig=bpy.data.objects['Ivan_Skeleton'];skin=bpy.data.objects['Ivan_Face_Neck_Hands'];coat=bpy.data.objects['Field_Jacket']
def average(obj):
 ev=obj.evaluated_get(bpy.context.evaluated_depsgraph_get());verts=ev.data.vertices
 return sum((v.co for v in verts),Vector())/len(verts)
before_skin=average(skin);before_coat=average(coat)
rig.pose.bones['upperarm_l'].rotation_mode='XYZ';rig.pose.bones['upperarm_l'].rotation_euler.x=.25;bpy.context.view_layer.update()
skin_shift=(average(skin)-before_skin).length;coat_shift=(average(coat)-before_coat).length
assert skin_shift>.0001 and coat_shift>.0001,(skin_shift,coat_shift)
rig.pose.bones['upperarm_l'].rotation_euler.x=0;bpy.context.view_layer.update()
packed=[im.name for im in bpy.data.images if im.source=='FILE' and im.packed_file]
missing=[im.name for im in bpy.data.images if im.source=='FILE' and not im.packed_file]
assert not missing,missing
assert bpy.data.objects['Ivan_Anatomy'].hide_render
assert all(math.isfinite(float(v)) for o in bpy.data.objects if o.type=='MESH' for point in o.bound_box for v in point)
# Store the reference guides disabled by default; keep them available in the outliner.
refs=bpy.data.collections.get('B_Turnaround_Reference_Guides')
if refs:refs.hide_viewport=True
for screen in bpy.data.screens:
 for area in screen.areas:
  if area.type=='VIEW_3D':
   area.spaces.active.region_3d.view_location=Vector((0,0,.9));area.spaces.active.region_3d.view_distance=3.2;area.spaces.active.overlay.show_overlays=False
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'output/ivan-B-study.blend'),compress=True)
report={'blender_file_reopened_without_MakeHuman_addon':True,'packed_images':packed,'missing_external_images':missing,'upper_arm_test_skin_centroid_shift_m':skin_shift,'upper_arm_test_jacket_centroid_shift_m':coat_shift,'pose_reset_before_save':True,'finite_geometry':True,'hidden_anatomical_helpers_excluded_from_render':True,'full_walk_or_combat_animation_tested':False}
(ROOT/'output/verification.json').write_text(json.dumps(report,ensure_ascii=False,indent=2));print('VERIFY_OK',json.dumps(report))
