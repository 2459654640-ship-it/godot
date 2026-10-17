extends SceneTree
const Story=preload("res://scripts/story.gd")
var checks=0
var failures:Array[String]=[]
func _initialize():call_deferred("run")
func check(ok:bool,text:String):
	checks+=1
	if not ok:failures.append(text);push_error(text)
func frames(n:int):
	for i in n:await physics_frame
func dispose(w):
	w.ambience.stop();w.ambience.stream=null;w.step_audio.stop();w.step_audio.stream=null
	w.queue_free();await frames(3)
func actions(s,keys:Array):
	for key in keys:s.act(key);check(s.last_action_valid,"action accepted: "+key)
func run():
	var s=Story.new()
	var initial=s.economy.military
	check(s.Economy.buy(s,"bread").contains("黑面包"),"can buy food")
	check(s.economy.military==initial-4 and s.economy.handmade==12,"only military ammunition is spent")
	s.Economy.consume(s,"bread")
	check(s.economy.food==90 and not s.economy.goods.has("bread"),"food restores satiety and consumes one unit")
	s.economy.military=0
	s.Economy.buy(s,"medkit")
	check(not s.economy.goods.has("medkit") and s.economy.handmade==12,"handmade bullets never pay for goods")
	actions(s,["search_box","open_cache"])
	s.Economy.sell_vodka(s);var earned=s.economy.military
	s.Economy.sell_vodka(s)
	check(earned==18 and s.economy.military==18 and not s.has("vodka"),"unique vodka sold exactly once")
	s.act("use_vodka");check(not s.last_action_valid,"sold vodka cannot also bribe guard")
	var t=Story.new();t.restore(JSON.parse_string(JSON.stringify(s.serialize())))
	check(JSON.parse_string(JSON.stringify(t.economy))==JSON.parse_string(JSON.stringify(s.economy)),"wallet, stock, supplies and ledger survive saves")
	s=Story.new();actions(s,["accept","get_kit"])
	check(s.has("mask") and s.f("kit"),"armory retains deterministic formal equipment route")
	for seq in ["intro","official","solo"]:
		for branch in [0,1]:
			s=Story.new();s.Comic.start(s,seq)
			var count=0
			while s.flags.comic.active and count<20:
				var panel=s.Comic.panel(s)
				check(ResourceLoader.exists("res://assets/cinematics/"+panel.art+".png"),"illustration exists: "+panel.art)
				s.Comic.choose(s,mini(branch,panel.get("choices",[0]).size()-1) if panel.has("choices") else -1)
				var saved=JSON.parse_string(JSON.stringify(s.serialize()));t=Story.new();t.restore(saved)
				check(t.flags.comic==s.flags.comic,"comic position and decisions persist")
				count+=1
			check(count<20 and not s.flags.comic.active,"comic branch terminates: "+seq+str(branch))
			check(s.f("intro_done") if seq=="intro" else s.ending,"intro returns to play; departure reaches recorded endpoint")
	s=Story.new();s.Comic.start(s,"solo")
	check(s.Comic.panel(s).art=="descent_unmasked" and s.economy.radiation==12,"unprotected departure uses matching art and recorded exposure")
	s.Comic.start(s,"solo");check(s.economy.radiation==12,"resuming or reopening comic cannot repeat exposure")
	s=Story.new();s.give("mask");s.give("filter");s.Comic.start(s,"solo")
	check(s.Comic.panel(s).art=="descent" and s.economy.radiation==0,"equipped departure uses masked art and no exposure penalty")
	s=Story.new()
	check(not JSON.stringify(preload("res://scripts/journal.gd").tasks(s)).contains("照片"),"new journal does not reveal undiscovered photo")
	s=Story.new();s.restore({"version":1,"flags":{"accepted":true,"kit":true},"items":["mask","filter"],"route":"official","ending":true})
	check(s.flags.comic.active and s.flags.comic.sequence=="official" and not s.ending,"old completed v4 save continues from departure instead of inventing a later endpoint")
	for floor in ["life","labor"]:
		var w=load("res://scenes/d6.tscn" if floor=="life" else "res://scenes/labor.tscn").instantiate()
		root.add_child(w);await frames(5)
		check(w.initialized and w.floor_id==floor,"floor starts: "+floor)
		check(w.player.is_on_floor(),"floor supports the real player capsule: "+floor)
		w.hud.show_dialogue("semyon" if floor=="life" else "main_gate")
		var txt=w.hud.modal_box.get_parent().get_parent()
		check(w.hud.modal_visible(),"conversation transcript renders: "+floor)
		if floor=="life":
			var options=[]
			for node in w.hud.modal.find_children("*","Button",true,false):options.append(node.text)
			check(not JSON.stringify(options).contains("照片"),"unavailable photo option is hidden")
			w.hud.last_choice="你好，老爹。";w.perform("semyon_fear","semyon")
			var records=w.story.conversations.semyon.duplicate(true)
			w.hud.close();w.hud.show_dialogue("semyon")
			check(w.story.conversations.semyon==records,"reopening conversation retains history without duplicating greeting")
			w.hud.show_shop();check(w.hud.modal_visible(),"shop renders")
			w.hud.show_comic("intro");check(w.hud.comic_active,"intro UI renders")
			w.story.flags.comic.node="intro_semyon";w.hud.show_comic();await frames(3)
			var reply_count=0
			for control in w.hud.modal.find_children("*","Button",true,false):
				if control.text in ["×","暂停"]:continue
				reply_count+=1
				check(control.get_global_rect().end.y<w.hud.modal.get_global_rect().end.y-30,"comic replies stay above footer and do not require scrolling")
			check(reply_count==2,"both comic choices visible together")
			check(w.hud.modal.position==Vector2.ZERO and w.hud.modal.size==w.hud.get_viewport_rect().size,"comic covers the entire viewport")
			var node=w.story.flags.comic.node
			w.hud.show_comic_pause();w.hud.show_inventory();w.hud.close()
			check(w.hud.comic_active and w.story.flags.comic.node==node,"inventory from comic pause preserves current panel")
			w.hud.comic_active=false
		else:
			check(w.npcs.has("commander") and w.targets.has("armory") and w.targets.has("coal_door"),"labor floor exposes approved facilities")
			check(w.kit.scrap_meshes.size()>20,"labor floor uses physical scrap partitions")
			check(not JSON.stringify(w.story.view("coal_door")).contains("安娜"),"coal gate reveals no future brother plot")
		w.hud.close()
		for tab in ["tasks","lore","map"]:w.hud.show_journal(tab);await frames(1);check(w.hud.modal_visible(),"journal section: "+tab)
		await dispose(w)
	print("CHAPTER_CONTRACT_RESULT checks=",checks," failures=",failures.size())
	quit(0 if failures.is_empty() else 1)
