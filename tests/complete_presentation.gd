extends SceneTree
const ComicUI=preload("res://scripts/ui_comic.gd")
var checks=0
var failures=0
var w
func _initialize():call_deferred("run")
func check(ok:bool,why:String):
 checks+=1
 if not ok:failures+=1;push_error(why)
func frames(n:int=4):
 for i in n:await process_frame
func bounds():
 var rect=Rect2(Vector2.ZERO,Vector2(1600,1000))
 for b in w.hud.modal.find_children("*","Button",true,false):
  if b.is_visible_in_tree():check(rect.encloses(b.get_global_rect()),"cinematic button fits: "+b.text)
func run():
 w=load("res://scenes/d6.tscn").instantiate();root.add_child(w);current_scene=w;await frames()
 var prop=load("res://scripts/production_props.gd").bevel(w.kit,"CabinetFaceContract",Vector3(0,0,0),Vector3(1,2,.8),"metal")
 var arrays=prop.mesh.surface_get_arrays(0);var verts:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX];var norms:PackedVector3Array=arrays[Mesh.ARRAY_NORMAL];var faces_out=true
 for i in range(0,verts.size(),3):
  if (verts[i+1]-verts[i]).cross(verts[i+2]-verts[i]).dot(norms[i])>0.000001:faces_out=false
 check(faces_out and verts.size()>100,"closed prop housing has outward normals and visible clockwise front faces")
 prop.queue_free()
 w.set_physics_process(false);w.player.set_physics_process(false);w.story.flags.intro_done=true
 w.story.flags.signal_heard=true;w.hud.show_comic("companions");await frames()
 check(w.hud.speech_buttons.is_empty(),"choices are withheld while opening paragraph is unread")
 var p=w.story.Comic.panel(w.story);var entries=ComicUI.paragraphs(w.hud,p)
 w.hud.finish_typing();ComicUI.advance(w.hud);await frames()
 check(w.story.flags.comic.line_index==1,"continue advances one paragraph")
 var saved=w.story.serialize();var restored=load("res://scripts/story.gd").new();restored.restore(JSON.parse_string(JSON.stringify(saved)))
 check(restored.flags.comic.line_index==1,"save resumes exact unread paragraph")
 w.story.flags.comic.line_index=entries.size()-1;w.hud.show_comic();await frames();w.hud.finish_typing()
 check(w.hud.speech_buttons.size()==6,"all six known route questions remain accessible")
 await frames();bounds()
 var long={"body":"完整的长段需要在逐句显示时保留所有文字。".repeat(60)}
 var parts=ComicUI.paragraphs(w.hud,long);var joined=""
 for part in parts:joined+=part.text
 check(parts.size()>1 and joined==long.body,"long cinematic paragraphs preserve every character")
 w.story.flags.comic={"active":false};w.hud.comic_active=false;w.hud.close()
 w.story.flags.merge({"late_four_plans_seen":true,"late_final_mode":"watch"},true)
 w.story.context.floor="star_interior"
 # The world must be on the matching scene for the actual final save hook.
 var snapshot=w.story.serialize();w.queue_free();await frames()
 root.get_node("Session").pending={"story":snapshot,"floor":"star_interior","position":Vector3.INF}
 w=load("res://scenes/star_interior.tscn").instantiate();root.add_child(w);current_scene=w;await frames()
 w.story.flags.comic={"active":false};w.hud.comic_active=false;w.hud.close()
 w.perform("c_late_final_confirm","late_planning");await frames()
 var before=w.SaveStore.read(w.SaveStore.FINAL)
 check(not before.is_empty() and before.floor=="star_interior" and not before.flags.get("late_final_started",false),"actual final confirmation stores the pre-action state in an independent slot")
 check(w.story.f("late_final_started"),"final confirmation begins action only after saving")
 for mode in ["shared","central","distributed","watch"]:
  w.story.flags.late_final_mode=mode;w.story.Campaign.Complete.finish(w.story);w.hud.show_chapter_end();await frames();bounds()
  check(w.hud.modal.find_children("*","ScrollContainer",true,false).is_empty(),"ending has fixed controls: "+mode)
 w.queue_free();await frames();print("COMPLETE_PRESENTATION_RESULT checks=",checks," failures=",failures);quit(1 if failures else 0)
