extends RefCounted
## Profiles cover streets and service yards reachable from the game's normal entrances.
static var _data:Dictionary={}

static func data()->Dictionary:
 if _data.is_empty():_data=JSON.parse_string(FileAccess.get_file_as_string("res://data/district_expedition.json"))
 return _data

static func point(coords:Array)->Vector3:return Vector3(coords[0],.04,coords[1])

static func rng(s,id:String)->RandomNumberGenerator:
 var random=RandomNumberGenerator.new()
 random.seed=hash("%d/%d/%s"%[int(s.flags.get("social_seed",0)),int(s.flags.get("raid_index",0)),id])
 return random

static func wildlife(s)->Dictionary:
 var sites={}
 for spec in data().wildlife:
  var r=spec.rect
  var id="raid_"+String(spec.id)
  var random=rng(s,id)
  var pool:Array=spec.spawns.duplicate()
  var positions=[]
  for i in spec.kinds.size():
   var index=random.randi_range(0,pool.size()-1)
   positions.append(point(pool.pop_at(index)))
  sites[id]={"rect":Rect2(r[0],r[1],r[2],r[3]),"need":"raid_active","skip":"","name":spec.name,"purpose":spec.purpose,"spawns":positions,"reserve":pool.map(func(p):return point(p)),"kinds":spec.kinds}
 return sites

static func deployment(s)->Array:
 var teams=[]
 for team in data().patrols:
  var random=rng(s,team.id)
  var loop:Array=team.routes[random.randi_range(0,team.routes.size()-1)]
  for i in team.strengths.size():
   var patrol=[]
   for step in loop.size():patrol.append(point(loop[(step+i)%loop.size()]))
   teams.append({"group":team.id,"label":team.label,"role":team.strengths[i],"points":patrol,"transient":true})
 return teams
