extends SceneTree
const Story=preload("res://scripts/story.gd")
const Comic=preload("res://scripts/comic.gd")
const Campaign=preload("res://scripts/campaign.gd")
var checks=0
var failures=0
func _initialize():call_deferred("run")
func check(ok:bool,why:String):
 checks+=1
 if not ok:failures+=1;push_error(why)
func walk(s,sequence:String,wanted:String=""):
 Comic.start(s,sequence);var n=0
 while s.flags.comic.active and n<60:
  var p=Comic.panel(s);check(not p.is_empty(),"panel resolves: "+str(s.flags.comic.node))
  if p.is_empty():break
  check(ResourceLoader.exists("res://assets/cinematics/"+p.art+".png"),"art exists: "+p.art)
  var choice=-1
  if p.has("choices"):
   choice=0
   if wanted!="":
    for i in p.choices.size():
     if p.choices[i].next==wanted:choice=i
  Comic.choose(s,choice);n+=1
 check(n<60 and not s.flags.comic.active,"finite travel sequence: "+sequence)
func run():
 var s=Story.new();walk(s,"solo")
 check("solo_shelter" in s.flags.comic.visited,"solo Ivan asks about shelter before meeting endpoint")
 for branch in ["solo_commune","dogs_watch"]:
  s=Story.new();walk(s,"companions",branch)
  check(s.flags.next_facility in ["commune","sech"],"informed route choice reaches a playable settlement")
 s=Story.new();Comic.start(s,"companions")
 check(not Comic.panel(s).choices.any(func(c):return c.next=="solo_about_signal"),"Ivan cannot ask about a broadcast he never heard")
 s.flags.signal_heard=true
 check(Comic.panel(s).choices.any(func(c):return c.next=="solo_about_signal"),"a heard broadcast unlocks the appropriate question")
 s=Story.new();walk(s,"official")
 for node in ["official_approach","official_loss","official_rollcall"]:check(node in s.flags.comic.visited,"squad losses have an approach, event and aftermath: "+node)
 var loss=Comic.authored().official_loss;var roll=Comic.authored().official_rollcall
 for name in ["列昂尼德","格里沙","萨沙"]:check(str(loss).contains(name) and str(roll).contains(name),"each soldier is identified in the event and aftermath: "+name)
 s=Story.new();walk(s,"star_road");check(s.flags.next_facility=="starcity" and not s.f("star_access"),"reaching the perimeter never grants internal access")
 check(not Campaign.data().actions.sech_father.reply.contains("名单上有"),"outsiders do not possess a confirmed staff roster")
 for key in Campaign.data().actions:
  var a:Dictionary=Campaign.data().actions[key]
  if a.has("travel"):check(not Comic.authored().get(a.travel,Campaign.data().panels.get(a.travel,{})).is_empty(),"travel target exists: "+a.travel)
 print("NARRATIVE_V19_RESULT checks=",checks," failures=",failures);quit(0 if failures==0 else 1)
