extends RefCounted
const MATERIALS=["scrap_metal","copper_wire","salvage_cloth","mutant_bone","mutant_sample","battery","cord"]
const TABS=[["all","全部"],["equipment","装备"],["supplies","补给"],["materials","材料"],["quest","任务与文件"],["keepsakes","个人物品"]]
static func entries(s)->Array:
	var out=[]
	for id in s.items:
		var d=s.ITEMS[id];var category="equipment" if d[2] in ["武器","装备","工具","维修"] else ("keepsakes" if d[2] in ["记忆","纪念"] else "quest")
		out.append({"id":id,"name":d[0],"detail":d[1],"kind":d[2],"category":category,"count":1,"good":false})
	for id in s.economy.goods:
		if int(s.economy.goods[id])<=0 or not s.Economy.GOODS.has(id):continue
		var d=s.Economy.GOODS[id]
		out.append({"id":id,"name":d.name,"detail":d.detail,"kind":"消耗品" if d.effect!="" else "物资","category":"materials" if id in MATERIALS else ("equipment" if id=="portable_radio" else "supplies"),"count":int(s.economy.goods[id]),"good":true})
	out.sort_custom(func(a,b):return a.category<b.category if a.category!=b.category else a.id<b.id)
	return out
static func render(h,tab:String="all",selected:String=""):
	h.start_modal("随身背包","ИНВЕНТАРЬ   /   装备与补给",true)
	h.modal.position=Vector2(220,75);h.modal.size=Vector2(1160,850)
	h.modal_hint.text="鼠标选择物品 · 滚轮浏览 · Esc 返回"
	var s=h.world.story;var weapon=s.equipped_weapon()
	var top=HBoxContainer.new();top.add_theme_constant_override("separation",18);h.modal_box.add_child(top)
	top.add_child(h.label("武器栏",18,h.amber))
	top.add_child(h.icon_rect(h.item_icon(weapon if weapon!="" else "revolver"),44))
	top.add_child(h.label("空置" if weapon=="" else s.ITEMS[weapon][0]+(" · 已拔出" if s.weapon_drawn() else " · 已收起"),19,h.text_color))
	if weapon!="":top.add_child(h.button("卸下",func():s.equip_weapon("");render(h,tab,weapon),true,true))
	top.add_spacer(false);top.add_child(h.label("制式弹 %d   /   土制弹 %d"%[s.economy.military,s.economy.handmade],18,h.amber))
	h.body("生命 %d / 100    饱食 %d / 100    辐射 %d / 100"%[s.economy.health,s.economy.food,s.economy.radiation],17,h.muted)
	var reaction=h.button("辐射状态："+s.Economy.Radiation.state(s).name+" · 查看影响与处理方法",func():h.show_radiation(),true,true);reaction.tooltip_text=s.Economy.Radiation.describe(s);h.modal_box.add_child(reaction)
	var tabs=HBoxContainer.new();tabs.add_theme_constant_override("separation",10);h.modal_box.add_child(tabs)
	for pair in TABS:
		var key:String=pair[0];var b=h.button(pair[1],func():render(h,key),true,true);tabs.add_child(b)
		if key==tab:b.add_theme_color_override("font_color",h.amber);b.add_theme_stylebox_override("normal",h.style(Color("344039"),h.amber,1,3))
	var items=entries(s).filter(func(e):return tab=="all" or e.category==tab)
	if not items.any(func(e):return e.id==selected):selected=items[0].id if not items.is_empty() else ""
	var browser=HBoxContainer.new();browser.add_theme_constant_override("separation",22);h.modal_box.add_child(browser)
	var scroll=ScrollContainer.new();scroll.custom_minimum_size=Vector2(680,420);scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;browser.add_child(scroll)
	var grid=GridContainer.new();grid.name="InventoryGrid";grid.columns=5;grid.add_theme_constant_override("h_separation",9);grid.add_theme_constant_override("v_separation",9);scroll.add_child(grid)
	for e in items:
		var id:String=e.id;var b=h.button("",func():render(h,tab,id),true,true);b.name="InventoryCell_"+id;b.custom_minimum_size=Vector2(126,126);b.tooltip_text=e.name+"\n"+e.detail
		b.add_theme_stylebox_override("normal",h.style(Color("303c33") if id==selected else Color("142321"),h.amber if id==selected else Color("46544a"),2 if id==selected else 1,3));grid.add_child(b)
		var content=VBoxContainer.new();content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);content.offset_left=7;content.offset_right=-7;content.offset_top=7;content.offset_bottom=-7;content.mouse_filter=Control.MOUSE_FILTER_IGNORE;b.add_child(content)
		var icon=h.icon_rect(h.item_icon(id),70);icon.mouse_filter=Control.MOUSE_FILTER_IGNORE;content.add_child(icon)
		var title=h.label(e.name,14,h.text_color);title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;title.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;title.mouse_filter=Control.MOUSE_FILTER_IGNORE;content.add_child(title)
		var count=h.label("已装备" if id==weapon else ("× %d"%e.count if e.good else e.kind),13,h.amber if id==weapon else h.muted);count.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;count.mouse_filter=Control.MOUSE_FILTER_IGNORE;content.add_child(count)
	# Empty cells show this is a grid without implying an inventory capacity limit.
	for i in maxi(0,15-items.size()):
		var empty=PanelContainer.new();empty.custom_minimum_size=Vector2(126,126);empty.add_theme_stylebox_override("panel",h.style(Color("101b1b"),Color("29382f"),1,3));empty.mouse_filter=Control.MOUSE_FILTER_IGNORE;grid.add_child(empty)
	var card=PanelContainer.new();card.name="InventoryDetail";card.custom_minimum_size.x=350;card.size_flags_horizontal=Control.SIZE_EXPAND_FILL;card.add_theme_stylebox_override("panel",h.style(Color("192825"),Color("786b4f"),1,3));browser.add_child(card);h.UiSurface.attach(card)
	var details=h.margin_box(card,20,20)
	if selected!="":
		var e=items.filter(func(x):return x.id==selected)[0];details.add_child(h.icon_rect(h.item_icon(selected),112))
		details.add_child(h.label(e.kind+"  /  "+("× %d"%e.count),15,h.amber))
		var title=h.label(e.name,26,h.text_color);title.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;details.add_child(title)
		var text=h.label(e.detail,19,h.text_color);text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;details.add_child(text)
		if e.good:
			var price:int=s.Economy.RESALE.get(selected,0)
			var value=h.label("商人收购：%d 发制式弹 / 份"%price if price>0 else ("个人装备 · 不出售" if selected=="portable_radio" else "商人暂不收购"),16,h.muted);value.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;details.add_child(value)
			var g:Dictionary=s.Economy.GOODS[selected]
			if g.effect!="":
				var effects={"food":"恢复 %d 点饱食","health":"恢复 %d 点生命","radiation":"降低 %d 点辐射","handmade":"补充 %d 发土制弹"}
				var amount=s.Economy.Radiation.heal_amount(s,int(g.amount)) if g.effect=="health" else int(g.amount)
				details.add_child(h.label(effects[g.effect]%amount,19,h.amber))
			if selected in ["salvage_cloth","scrap_metal"]:
				var craft=h.label("制作地点：东郊工人街修配间。恢复供电后，可把布料制成绷带，或用布料与金属件制作捆扎用品。" if s.f("visited_east_district") else "可以留给有设备的修配工房，用来制作绷带与捆扎用品。",16,h.muted);craft.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;details.add_child(craft)
		var id:String=selected
		if e.good and s.Economy.GOODS[id].effect=="health" and s.economy.radiation>=80:
			var actual=h.label("当前状态下恢复 %d 点生命。"%s.Economy.Radiation.heal_amount(s,int(s.Economy.GOODS[id].amount)),17,h.amber);details.add_child(actual)
		if e.kind=="武器":details.add_child(h.button("卸下武器" if id==weapon else "装备到武器栏",func():s.equip_weapon("" if id==weapon else id);render(h,tab,id)))
		elif e.good and s.Economy.GOODS[id].effect!="":details.add_child(h.button("使用一份",func():h.toast(s.Economy.consume(s,id));render(h,tab,id)))
		elif id=="portable_radio":details.add_child(h.button("收听随身收音机",func():h.world.public_radio.open_controls(true)))
		else:
			var note=h.label("可交给商人收购，也可以存入聚落物资柜。" if e.category=="materials" else "在相关场景或人物对话中使用。任务文件和纪念物不会被自动出售。",16,h.muted);note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;details.add_child(note)
	else:details.add_child(h.label("这一栏暂时没有物品。",19,h.muted))
	h.body("选择格子查看详情 · 聚落物资柜可寄存补给与材料 · 按 1 拔枪 / 收枪",16,h.muted)
