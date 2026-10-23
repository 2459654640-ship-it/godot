extends SceneTree
const Story=preload("res://scripts/story.gd")
const Rad=preload("res://scripts/radiation.gd")
var checks=0
var failures=0
func check(ok:bool,why:String):
 checks+=1
 if not ok:failures+=1;push_error(why)
func _initialize():call_deferred("run")
func run():
 for pair in [[0,0],[19,0],[20,1],[39,1],[40,2],[59,2],[60,3],[79,3],[80,4],[100,4]]:check(Rad.index(pair[0])==pair[1],"exact tier boundary "+str(pair))
 for pair in [[0,90],[20,180],[40,270],[60,0],[80,0]]:
  var s=Story.new();s.economy.radiation=pair[0];s.economy.health=50;s.economy.food=100
  s.Economy.advance(s,89,true);check(s.economy.health==50,"no premature regeneration")
  s.economy.recovery_clock=0;s.Economy.advance(s,pair[1] if pair[1]>0 else 1000,true)
  check(s.economy.health==(51 if pair[1]>0 else 50),"distinct regeneration effect at "+str(pair[0]))
  check(s.economy.health>=50,"exposure never passively damages health")
 var s=Story.new();s.economy.radiation=40;s.economy.food=50;s.economy.health=50;s.Economy.advance(s,270,true);check(s.economy.health==50,"moderate tier requires enough food")
 s.economy.food=60;s.Economy.advance(s,270,true);check(s.economy.health==51,"moderate tier recovers when fed")
 s.economy.health=20;s.economy.radiation=80;s.economy.goods.medkit=1;s.Economy.consume(s,"medkit");check(s.economy.health==50,"severe tier changes actual medkit healing to 30")
 s.economy.goods.antirad=1;s.Economy.consume(s,"antirad");check(s.economy.radiation==60 and Rad.heal_amount(s,40)==40,"medicine immediately restores normal treatment at lower tier")
 for pair in [["medical","labor"],["commune_leader","commune"],["sech_quartermaster","sech"],["coal_medic","coal"]]:
  s=Story.new();s.context.floor=pair[1];s.economy.radiation=100;s.economy.military=0
  check(s.view(pair[0]).options.any(func(o):return o.key=="decontam_"+pair[0] and o.enabled),"treatment can be accessed at actual hub dialogue")
  for i in 4:s.act("decontam_"+pair[0]);check(s.last_action_valid,"free treatment remains available without money")
  check(s.economy.radiation==0 and s.economy.military==0,"safe hub offers full recovery without resource trap")
  s.act("decontam_"+pair[0]);check(not s.last_action_valid,"no redundant treatment at zero exposure")
 s=Story.new();s.economy.radiation=85;var copy=Story.new();copy.restore(s.serialize());check(Rad.state(copy).name==Rad.state(s).name,"effects derive from saved radiation, no stale status flags")
 s.economy.health=30;s.economy.radiation=60;s.economy.recovery_clock=89;s.Economy.advance(s,90,true);s.economy.radiation=0;check(s.economy.recovery_clock==0,"disabled regeneration cannot bank healing time")
 print("RADIATION_V25_RESULT checks=",checks," failures=",failures);quit(0 if failures==0 else 1)
