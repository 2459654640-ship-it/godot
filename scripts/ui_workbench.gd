extends RefCounted
## Fixed screens: navigation stays in place while only the selected pane changes.
const Bag=preload("res://scripts/backpack.gd")
const Books=preload("res://scripts/publications.gd")
const Journal=preload("res://scripts/journal.gd")
const PAPER=Color("ded8c5")
const DIM=Color("93a49e")
const GOLD=Color("d3b679")
const RED=Color("c68d79")
const NAV=[["inventory","01  随身装备"],["tasks","02  任务手记"],["map","03  区域地图"],["collection","04  书刊收藏"],["lore","05  见闻百科"],["history","06  经历记录"]]

static func words(h,parent,text:String,size:int=20,color:Color=PAPER)->Label:
 var l=h.label(text,size,color);l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;l.size_flags_horizontal=Control.SIZE_EXPAND_FILL;parent.add_child(l);return l
static func gap(parent):
 var c=Control.new();c.size_flags_vertical=Control.SIZE_EXPAND_FILL;parent.add_child(c)
static func row(parent,separation:int=14)->HBoxContainer:
 var c=HBoxContainer.new();c.add_theme_constant_override("separation",separation);parent.add_child(c);return c
static func column(parent,width:float=0)->VBoxContainer:
 var c=VBoxContainer.new();c.add_theme_constant_override("separation",14);c.custom_minimum_size.x=width;parent.add_child(c);return c
static func line(parent):
 var r=ColorRect.new();r.color=Color("3b4c47");r.custom_minimum_size.y=1;r.mouse_filter=Control.MOUSE_FILTER_IGNORE;parent.add_child(r)
static func action(h,parent,title:String,callback:Callable,enabled:bool=true,selected:bool=false)->Button:
 var b=h.button(title,callback,enabled,true);b.custom_minimum_size=Vector2(minf(270,h.font.get_string_size(title,HORIZONTAL_ALIGNMENT_LEFT,-1,18).x+32),42);b.clip_text=true;b.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;b.tooltip_text=title;parent.add_child(b)
 var base=h.style(Color("273b36") if selected else Color("182824"),GOLD if selected else Color("3a4d46"),1,0)
 base.content_margin_left=14;base.content_margin_right=14;base.content_margin_top=9;base.content_margin_bottom=9
 b.add_theme_stylebox_override("normal",base)
 if selected:b.add_theme_color_override("font_color",GOLD)
 return b
static func panel(h,parent,width:float=0)->VBoxContainer:
 var p=PanelContainer.new();p.custom_minimum_size.x=width;p.size_flags_horizontal=Control.SIZE_EXPAND_FILL;p.size_flags_vertical=Control.SIZE_EXPAND_FILL;p.add_theme_stylebox_override("panel",h.style(Color("14231f"),Color("344740"),1,0));parent.add_child(p)
 return h.margin_box(p,22,20)
static func shell(h,title:String,code:String,active:String)->VBoxContainer:
 h.start_modal(title,"",true,"screen:"+active)
 for child in h.modal.get_children(true):h.modal.remove_child(child);child.queue_free()
 h.modal.position=Vector2(38,28);h.modal.size=Vector2(1524,944);h.modal.add_theme_stylebox_override("panel",h.style(Color("0e1917"),Color("617064"),1,0))
 h.scrim.color=Color(.018,.028,.026,.94);h.set_meta("fixed_screen",active)
 var root=h.margin_box(h.modal,28,22);root.add_theme_constant_override("separation",18)
 var header=row(root,24)
 var mark=column(header,174);words(h,mark,"МЕТРО / 1982",17,GOLD);words(h,mark,"ЛИЧНОЕ ДЕЛО",12,DIM)
 var titles=column(header);titles.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 h.dialog_title=words(h,titles,title,32);h.dialog_title.add_theme_font_override("font",h.serif)
 words(h,titles,code,13,DIM)
 var s=h.world.story;words(h,header,"ИВАН\n"+h.world.floor_name(),15,DIM).horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
 action(h,header,"返回游戏  ×",func():h.close())
 line(root)
 var main=row(root,24);main.size_flags_vertical=Control.SIZE_EXPAND_FILL
 var nav=column(main,174)
 for entry in NAV:
  var id:String=entry[0]
  action(h,nav,entry[1],func():navigate(h,id),true,id==active)
 gap(nav);words(h,nav,"第七号个人档案\n物品、经历与未完的事",13,DIM);line(nav)
 words(h,nav,"制式弹  %d\n土制弹  %d"%[s.economy.military,s.economy.handmade],17,GOLD)
 var content=column(main);content.size_flags_horizontal=Control.SIZE_EXPAND_FILL;content.size_flags_vertical=Control.SIZE_EXPAND_FILL;h.modal_box=content
 line(root);h.modal_hint=words(h,root,"鼠标选择 · 页码切换内容 · Esc 返回游戏",13,DIM)
 return content
static func navigate(h,id:String):
 if id=="inventory":h.show_inventory()
 else:h.show_journal(id)
static func page(h,parent,key:String,total:int,per_page:int,callback:Callable)->int:
 var count=maxi(1,ceili(float(total)/per_page));var index=clampi(int(h.get_meta(key,0)),0,count-1);h.set_meta(key,index)
 var bar=row(parent,6);action(h,bar,"‹",func():h.set_meta(key,index-1);callback.call(),index>0)
 var l=words(h,bar,"%02d / %02d  ·  共 %d 项"%[index+1,count,total],14,DIM);l.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;l.autowrap_mode=TextServer.AUTOWRAP_OFF
 action(h,bar,"›",func():h.set_meta(key,index+1);callback.call(),index+1<count)
 return index
static func choose(h,items:Array,key:String,preferred:String="")->String:
 var id=preferred if preferred!="" else String(h.get_meta(key,""))
 if not items.any(func(e):return e.id==id):id=String(items[0].id) if not items.is_empty() else ""
 h.set_meta(key,id);return id
static func text_panel(h,parent,heading:String,content:String):
 words(h,parent,heading,14,GOLD);words(h,parent,content,20)

static func inventory(h,tab:String="all",selected:String=""):
 var content=shell(h,"随身装备","ИНВЕНТАРЬ  /  外勤装备与个人物品","inventory");var s=h.world.story
 var bars=row(content)
 for pair in load("res://scripts/ui_inventory.gd").TABS:
  var id:String=pair[0];action(h,bars,pair[1],func():inventory(h,id),true,tab==id)
 var main=row(content,20);main.size_flags_vertical=Control.SIZE_EXPAND_FILL
 var equipment=panel(h,main,198);equipment.get_parent().get_parent().size_flags_horizontal=0
 words(h,equipment,"外勤装备",19,GOLD);line(equipment)
 var weapon:String=s.equipped_weapon()
 for spec in [[weapon,"武器栏"],["mask" if s.has("mask") else "","面部防护"],["filter" if s.has("filter") else "","滤毒罐"]]:
  var id:String=spec[0];words(h,equipment,spec[1],13,DIM)
  var item_row=row(equipment,8);item_row.add_child(h.icon_rect(h.item_icon(id if id!="" else "mask"),40))
  action(h,item_row,s.ITEMS[id][0] if id!="" else "空置",func():inventory(h,"all",id),id!="",id==selected and id!="")
 if weapon!="":action(h,equipment,"卸下",func():s.equip_weapon("");inventory(h,tab,weapon))
 gap(equipment);line(equipment)
 words(h,equipment,"生命  %d / 100\n饱食  %d / 100\n辐射  %d"%[s.economy.health,s.economy.food,s.economy.radiation],17)
 action(h,equipment,"查看身体状态",func():h.show_radiation())
 var all:Array=load("res://scripts/ui_inventory.gd").entries(s)
 var entries=all.filter(func(e):return tab=="all" or e.category==tab)
 selected=choose(h,entries,"inventory_selection",selected)
 var pack=Bag.pack(s)
 var bag=column(main,520);bag.add_theme_constant_override("separation",8);words(h,bag,"随身背包     %02d / 48 格"%pack.used,20,GOLD)
 var grid=load("res://scripts/inventory_grid.gd").new();grid.cell=65;bag.add_child(grid);grid.setup(h,selected,tab)
 words(h,bag,"拖动整理 · 分类高亮物品，保留背包实际位置",13,DIM)
 if not pack.overflow.is_empty():words(h,bag,"有 %d 组物品待整理；原物品仍保留。"%pack.overflow.size(),15,RED)
 var extra=entries.filter(func(e):return not pack.pieces.any(func(p):return p.id==e.id))
 if not extra.is_empty():
  words(h,bag,"任务随身夹 / 栏外物品",14,GOLD)
  var page_key="inventory_pouch_"+tab
  var index=clampi(int(h.get_meta(page_key,0)),0,maxi(0,ceili(extra.size()/2.0)-1))
  var tiles=GridContainer.new();tiles.columns=2;tiles.add_theme_constant_override("h_separation",8);tiles.add_theme_constant_override("v_separation",8);bag.add_child(tiles)
  for e in extra.slice(index*2,index*2+2):
   var id:String=e.id;var b=action(h,tiles,e.name,func():inventory(h,tab,id),true,id==selected);b.name="InventoryCell_"+id;b.custom_minimum_size.x=250
  page(h,bag,page_key,extra.size(),2,func():inventory(h,tab,selected))
 var detail=panel(h,main);detail.get_parent().get_parent().name="InventoryDetail"
 if selected=="":words(h,detail,"这一栏暂时没有物品。",21,DIM);return
 var e:Dictionary=entries.filter(func(item):return item.id==selected)[0];detail.add_child(h.icon_rect(h.item_icon(selected),110))
 words(h,detail,e.kind+"  /  ×%d"%e.count,13,GOLD);words(h,detail,e.name,27);line(detail);words(h,detail,e.detail,19)
 if e.good:
  var price:int=s.Economy.RESALE.get(selected,0);words(h,detail,"商人收购  %d 发制式弹 / 份"%price if price>0 else "个人物品 / 不收购",15,DIM)
 gap(detail)
 var id:String=selected
 if e.kind=="武器":action(h,detail,"卸下武器" if id==weapon else "装备到武器栏",func():s.equip_weapon("" if id==weapon else id);inventory(h,tab,id))
 elif e.good and s.Economy.GOODS[id].effect!="":action(h,detail,"使用一份",func():h.toast(s.Economy.consume(s,id));inventory(h,tab,id))
 elif id=="portable_radio":action(h,detail,"收听随身收音机",func():h.world.public_radio.open_controls(true))
 var pieces=pack.pieces.filter(func(p):return p.id==id)
 if not pieces.is_empty():
  var matching=pieces.filter(func(p):return p.key==h.get_meta("bag_selected_key",""));var piece=matching[0] if not matching.is_empty() else pieces[0]
  action(h,detail,"旋转占格",func():
   if not Bag.move_piece(s,piece.key,piece.at,true):h.toast("旋转后放不下，请先腾出相邻格子。")
   inventory(h,tab,id))
 if e.good or id in Bag.ORDINARY_ITEMS:action(h,detail,"丢弃一份",func():load("res://scripts/raid_loot.gd").discard(h.world,id);inventory(h,tab,id))
 else:words(h,detail,"任务文件与纪念物随身保护。",15,DIM)

static func journal(h,tab:String="tasks",shown_floor:String="",selected:String=""):
 var title={"tasks":"任务手记","closed":"任务手记","leads":"任务手记","map":"区域地图","collection":"书刊收藏","lore":"见闻百科","history":"经历记录"}.get(tab,"任务手记")
 var content=shell(h,title,"ЗАПИСИ  /  伊万的个人记录","tasks" if tab in ["closed","leads"] else tab)
 if tab=="map":map_screen(h,content,shown_floor);return
 if tab=="collection":collection(h,content);return
 if tab in ["lore","history"]:records(h,content,tab);return
 var tabs=row(content)
 for pair in [["tasks","进行中的任务"],["leads","留意的事"],["closed","完成与失败"]]:
  var id:String=pair[0];action(h,tabs,pair[1],func():journal(h,id),true,tab==id)
 var entries:Array=[]
 if tab=="leads":
  for i in Journal.leads(h.world.story).size():entries.append({"id":str(i),"name":"留意的事 %02d"%(i+1),"step":Journal.leads(h.world.story)[i]})
 else:entries=Journal.tasks(h.world.story).filter(func(t):return (t.done or t.failed) if tab=="closed" else not t.done and not t.failed)
 if selected=="" and not h.has_meta("task_selection_"+tab):selected=String(h.world.story.flags.get("tracked_quest",""))
 if selected!="":
  for i in entries.size():
   if entries[i].id==selected:h.set_meta("task_page_"+tab,floori(i/7.0))
 selected=choose(h,entries,"task_selection_"+tab,selected)
 var main=row(content,20);main.size_flags_vertical=Control.SIZE_EXPAND_FILL
 var list=panel(h,main,370);list.get_parent().get_parent().size_flags_horizontal=0
 words(h,list,"已接取的委托" if tab=="tasks" else title,16,GOLD)
 var page_key="task_page_"+tab;var index=clampi(int(h.get_meta(page_key,0)),0,maxi(0,ceili(entries.size()/7.0)-1))
 if selected!="" and not entries.slice(index*7,index*7+7).any(func(e):return e.id==selected):selected=String(entries[index*7].id);h.set_meta("task_selection_"+tab,selected)
 for task in entries.slice(index*7,index*7+7):
  var id:String=task.id;var prefix="主线 · " if task.get("kind","")=="主线" else ("支线 · " if task.has("kind") else "")
  var b=action(h,list,("▸ " if id==h.world.story.flags.get("tracked_quest","") else "")+prefix+task.name,func():journal(h,tab,"",id),true,id==selected);b.custom_minimum_size.y=61
 gap(list);page(h,list,page_key,entries.size(),7,func():journal(h,tab))
 var detail=panel(h,main)
 if selected=="":words(h,detail,"目前没有这一类记录。",23,DIM);return
 var task:Dictionary=entries.filter(func(e):return e.id==selected)[0]
 words(h,detail,task.get("kind","线索")+"  /  "+task.get("status","尚未接取"),14,GOLD);words(h,detail,task.name,30);line(detail)
 text_panel(h,detail,"当前目标" if tab=="tasks" else ("任务结果" if tab=="closed" else "记录"),task.step)
 if tab!="leads":
  var place=place_name(h,task.place);words(h,detail,place+" · "+task.area,17,GOLD)
  line(detail);text_panel(h,detail,"事情的经过",task.background)
  gap(detail)
  if not task.done and not task.failed:
   var buttons=row(detail)
   var id:String=task.id;action(h,buttons,"正在追踪" if h.world.story.flags.get("tracked_quest","")==id else "追踪这个任务",func():Journal.track(h.world.story,id);journal(h,tab,"",id))
   action(h,buttons,"在地图上查看",func():journal(h,"map",task.place))
 else:gap(detail);words(h,detail,"这还不是答应过的事。见到相关的人时，可以再问一问。",16,DIM)
static func place_name(h,id:String)->String:return {"life":"D-6生活层","labor":"D-6作业层"}.get(id,h.world.story.Campaign.NAMES.get(id,id))

static func map_screen(h,content,shown_floor:String):
 var requested=shown_floor if shown_floor!="" else h.world.floor_id
 var bar=row(content);var selector=OptionButton.new();selector.custom_minimum_size=Vector2(340,44);selector.add_theme_font_size_override("font_size",20);bar.add_child(selector)
 var floors=["life","labor"]+h.world.story.Campaign.NAMES.keys().filter(func(id):return h.world.story.f("visited_"+id) or h.world.floor_id==id)
 for i in floors.size():
  selector.add_item(place_name(h,floors[i]))
  if floors[i]==requested:selector.select(i)
 selector.item_selected.connect(func(i):journal(h,"map",floors[i]))
 words(h,bar,"当前位置："+h.world.floor_name(),16,DIM)
 var main=row(content,18);main.size_flags_vertical=Control.SIZE_EXPAND_FILL
 var map=load("res://scripts/minimap.gd").new();map.name="FixedMapCanvas";map.custom_minimum_size=Vector2(720,580);map.size_flags_horizontal=Control.SIZE_EXPAND_FILL;map.size_flags_vertical=Control.SIZE_EXPAND_FILL;map.world=h.world;map.expanded=true;map.display_floor=requested;main.add_child(map);h.map_large=map
 var stored:Dictionary=h.get_meta("map_view_"+requested,{})
 map.map_zoom=float(stored.get("zoom",1));map.map_pan=stored.get("pan",Vector2.ZERO)
 var detail=panel(h,main,290);detail.get_parent().get_parent().size_flags_horizontal=0
 words(h,detail,"地图与方向",20,GOLD);line(detail)
 var task=Journal.active(h.world.story)
 if not task.is_empty() and task.place==requested:text_panel(h,detail,"当前跟进",task.name);words(h,detail,task.step,17)
 else:words(h,detail,"选择一项任务，可以在地图上查看下一步所在区域。",18,DIM)
 gap(detail)
 if requested=="east_district":
  words(h,detail,"浅色  已踏查\n暗色  待探索\n金点  已发现设施\n蓝标  自定目的地",16,DIM)
  action(h,detail,"重置地图视图",func():map.map_zoom=1;map.map_pan=Vector2.ZERO;map.queue_redraw())
 else:
  var zones=h.world.facility_zones(requested).filter(func(z):return z.code not in ["00","L0"])
  var key="map_legend_"+requested;var index=clampi(int(h.get_meta(key,0)),0,maxi(0,ceili(zones.size()/7.0)-1))
  for zone in zones.slice(index*7,index*7+7):words(h,detail,zone.code+"  "+zone.name,15,DIM)
  page(h,detail,key,zones.size(),7,func():journal(h,"map",requested))
 h.modal_hint.text="滚轮缩放地图 · 中键拖动 · 左键标记 · 右键清除 · Esc 返回" if requested=="east_district" else "金色标记为任务所在区域 · 地图编号对应右侧设施目录 · Esc 返回"

static func shop(h,message:String="",tab:String=""):
 if tab!="":h.shop_tab=tab
 var content=shell(h,"第七供应点" if h.shop_actor=="supply" else "聚落物资交易","СНАБЖЕНИЕ  /  制式子弹结算","shop");var s=h.world.story
 var tabs=row(content);action(h,tabs,"购买物资",func():shop(h,"","buy"),true,h.shop_tab=="buy");action(h,tabs,"出售随身物资",func():shop(h,"","sell"),true,h.shop_tab=="sell")
 words(h,tabs,"可用制式弹  %d"%s.economy.military,20,GOLD)
 var status=words(h,content,message if message!="" else "选择物品查看价格和用途。任务文件与个人纪念物不出售。",17,DIM);status.custom_minimum_size.y=28
 var ids=s.Economy.GOODS.keys().filter(func(id):return s.Economy.GOODS[id].get("purchase",true)) if h.shop_tab=="buy" else s.items.duplicate()
 if h.shop_tab=="sell":
  for id in s.economy.goods:
   if int(s.economy.goods[id])>0:ids.append(id)
 var entries=ids.map(func(id):return {"id":id});var key="shop_selection_"+h.shop_tab;var selected=choose(h,entries,key)
 var main=row(content,22);main.size_flags_vertical=Control.SIZE_EXPAND_FILL
 var list=column(main,650);var grid=GridContainer.new();grid.columns=3;grid.add_theme_constant_override("h_separation",12);grid.add_theme_constant_override("v_separation",12);list.add_child(grid)
 var page_key="shop_page_"+h.shop_tab;var index=clampi(int(h.get_meta(page_key,0)),0,maxi(0,ceili(ids.size()/6.0)-1))
 for id in ids.slice(index*6,index*6+6):
  var item:String=id;var c=panel(h,grid,205);c.get_parent().get_parent().size_flags_vertical=0;c.get_parent().get_parent().custom_minimum_size.y=160
  var r=row(c);r.add_child(h.icon_rect(h.item_icon(id),56));words(h,r,"×%d"%(s.economy.stock.get(id,0) if h.shop_tab=="buy" else Bag.count(s,id)),16,DIM)
  var b=action(h,c,Bag.name_of(s,id),func():h.set_meta(key,item);shop(h),true,id==selected);b.custom_minimum_size.x=160
  var price=int(s.Economy.GOODS[id].price) if h.shop_tab=="buy" else s.Economy.sale_price(s,id);words(h,c,"%d 发制式弹"%price if price>0 else "不能出售",14,GOLD if price>0 else DIM)
 gap(list);page(h,list,page_key,ids.size(),6,func():shop(h))
 var detail=panel(h,main)
 if selected!="":
  detail.add_child(h.icon_rect(h.item_icon(selected),120));words(h,detail,Bag.name_of(s,selected),28);line(detail)
  words(h,detail,s.Economy.GOODS[selected].detail if s.Economy.GOODS.has(selected) else s.ITEMS[selected][1],19)
  gap(detail);var id:String=selected
  if h.shop_tab=="buy":
   var g:Dictionary=s.Economy.GOODS[id];var enough=s.economy.military>=g.price;var stock=int(s.economy.stock.get(id,0));var fits=Bag.can_add(s,id)
   words(h,detail,"价格  %d 发\n库存  %d  /  已有 %d"%[g.price,stock,Bag.count(s,id)],20,GOLD)
   if not enough or stock<=0 or not fits:words(h,detail,"制式弹不足" if not enough else ("暂时缺货" if stock<=0 else "背包放不下或已经持有"),16,RED)
   action(h,detail,"购买一份",func():h.shop_buy(id),enough and stock>0 and fits)
  else:
   var price=s.Economy.sale_price(s,id);words(h,detail,"收购价  %d 发 / 件"%price if price>0 else "任务物品或个人装备，不收购。",19,GOLD)
   action(h,detail,"出售一件" if price>0 else "不能出售",func():h.shop_sell(id),price>0)
 else:words(h,detail,"没有可以展示的物品。",20,DIM)
 action(h,detail,"返回交谈",func():h.show_dialogue(h.shop_actor))

static func collection(h,content):
 var s=h.world.story;var series_bar=row(content)
 var select=OptionButton.new();select.custom_minimum_size=Vector2(320,42);select.add_theme_font_size_override("font_size",19);series_bar.add_child(select);select.add_item("全部系列")
 var filter:String=h.get_meta("collection_series","")
 for series in Books.data().series:
  select.add_item(series.name)
  if filter==series.id:select.select(select.item_count-1)
 select.item_selected.connect(func(i):h.set_meta("collection_series","" if i==0 else Books.data().series[i-1].id);h.set_meta("collection_page",0);journal(h,"collection"))
 words(h,series_bar,"已收录  %02d / %02d"%[Books.count(s),Books.data().entries.size()],20,GOLD)
 var entries=Books.data().entries.filter(func(b):return filter=="" or b.series==filter)
 var index=clampi(int(h.get_meta("collection_page",0)),0,maxi(0,ceili(entries.size()/6.0)-1))
 var grid=GridContainer.new();grid.columns=3;grid.add_theme_constant_override("h_separation",18);grid.add_theme_constant_override("v_separation",18);content.add_child(grid)
 for book in entries.slice(index*6,index*6+6):
  var found=Books.owned(s,book.id);var c=panel(h,grid,386);c.get_parent().get_parent().custom_minimum_size.y=255;c.get_parent().get_parent().size_flags_vertical=0;c.get_parent().get_parent().tooltip_text=book.hint if not found else book.author
  var r=row(c);var icon=h.icon_rect("",82);icon.texture=Books.icon(book);r.add_child(icon)
  var mat=ShaderMaterial.new();mat.shader=load("res://assets/visual/publication_icon.gdshader");mat.set_shader_parameter("unknown",not found);icon.material=mat
  var info=column(r);info.size_flags_horizontal=Control.SIZE_EXPAND_FILL;words(h,info,book.title if found else "？ 未收录",22,PAPER if found else DIM);words(h,info,"第 %02d 册"%int(book.issue),14,GOLD)
  if found:words(h,c,book.author,15,DIM);var id:String=book.id;action(h,c,"翻开阅读",func():reader(h,id))
  else:words(h,c,"鼠标停留，回想可能的线索。",15,DIM)
 gap(content);page(h,content,"collection_page",entries.size(),6,func():journal(h,"collection"))

static func split_text(h,text:String,width:float,height:float,font_size:int=22)->Array:
 var pages=[];var current=""
 for character in text:
  var candidate=current+character
  var extent=h.serif.get_multiline_string_size(candidate,HORIZONTAL_ALIGNMENT_LEFT,width,font_size,-1,TextServer.BREAK_MANDATORY|TextServer.BREAK_WORD_BOUND|TextServer.BREAK_GRAPHEME_BOUND)
  if extent.y>height and current!="":pages.append(current);current=character
  else:current=candidate
 if current!="" or pages.is_empty():pages.append(current)
 return pages
static func reader(h,id:String,index:int=0):
 var book=Books.read(h.world.story,id)
 if book.is_empty():return
 h.world.autosave();var content=shell(h,book.title,"ЧТЕНИЕ  /  书刊阅读","collection")
 var main=row(content,28);main.size_flags_vertical=Control.SIZE_EXPAND_FILL
 var info=column(main,250);info.add_child(h.icon_rect("",140));info.get_child(0).texture=Books.icon(book);words(h,info,book.author,21);words(h,info,book.date,16,DIM);gap(info);action(h,info,"合上书 · 返回收藏",func():journal(h,"collection"))
 var paper=PanelContainer.new();paper.size_flags_horizontal=Control.SIZE_EXPAND_FILL;paper.size_flags_vertical=Control.SIZE_EXPAND_FILL;paper.add_theme_stylebox_override("panel",h.style(Color("c8c0a9"),Color("8e8b76"),1,0));main.add_child(paper)
 var inset=h.margin_box(paper,36,28);var pages=split_text(h,book.body,790,530);index=clampi(index,0,pages.size()-1)
 var text=words(h,inset,pages[index],22,Color("29352e"));text.add_theme_font_override("font",h.serif);text.add_theme_constant_override("line_spacing",6);gap(inset)
 var controls=row(inset);action(h,controls,"‹ 上一页",func():reader(h,id,index-1),index>0);words(h,controls,"%d / %d"%[index+1,pages.size()],15,Color("47554a")).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;action(h,controls,"下一页 ›",func():reader(h,id,index+1),index+1<pages.size())
 h.modal_hint.text="点击页码按钮翻页 · 合上书返回收藏 · Esc 返回游戏"

static func records(h,content,tab:String):
 var entries=[]
 if tab=="lore":
  for e in Journal.encyclopedia(h.world.story):entries.append({"id":str(entries.size()),"name":e[0],"text":e[1]})
 else:
  for e in h.world.story.intel:entries.append({"id":str(entries.size()),"name":String(e).get_slice("：",0).left(22),"text":e})
  for e in h.world.story.flags.get("comic_records",[]):entries.append({"id":str(entries.size()),"name":e.title,"text":e.body+("\n\n伊万："+e.choice if e.choice!="" else "")})
 var main=row(content,20);main.size_flags_vertical=Control.SIZE_EXPAND_FILL;var list=panel(h,main,330);list.get_parent().get_parent().size_flags_horizontal=0
 var page_key=tab+"_list_page";var index=clampi(int(h.get_meta(page_key,0)),0,maxi(0,ceili(entries.size()/8.0)-1))
 var selected=choose(h,entries,tab+"_selection")
 for e in entries.slice(index*8,index*8+8):
  var id:String=e.id;action(h,list,e.name,func():h.set_meta(tab+"_selection",id);h.set_meta(tab+"_text_page",0);journal(h,tab),true,id==selected).custom_minimum_size.y=54
 gap(list);page(h,list,page_key,entries.size(),8,func():journal(h,tab))
 var detail=panel(h,main)
 if selected=="":words(h,detail,"还没有留下记录。",22,DIM);return
 var e:Dictionary=entries.filter(func(item):return item.id==selected)[0];words(h,detail,e.name,27,GOLD);line(detail)
 var pages=split_text(h,e.text,740,430,21);var text_index=clampi(int(h.get_meta(tab+"_text_page",0)),0,pages.size()-1)
 words(h,detail,pages[text_index],21);gap(detail);page(h,detail,tab+"_text_page",pages.size(),1,func():journal(h,tab))

static func settings(h):
 var content=shell(h,"设置","НАСТРОЙКИ  /  画面与声音","settings")
 var controls=load("res://scripts/ui_settings.gd").new();content.add_child(controls);controls.setup(h.world.get_node("/root/Session"))
 gap(content);action(h,content,"返回暂停菜单",func():h.show_comic_pause() if h.comic_active else pause(h))
 h.modal_hint.text="画面修改后确认保留 · 声音即时保存 · Esc 返回游戏"
static func health(h):
 var content=shell(h,"身体状态","СОСТОЯНИЕ  /  伤势、补给与污染","inventory");var s=h.world.story
 words(h,content,"生命 %d / 100     饱食 %d / 100     辐射 %d / 100"%[s.economy.health,s.economy.food,s.economy.radiation],25,GOLD)
 words(h,content,s.Economy.Radiation.describe(s),19)
 var grid=GridContainer.new();grid.columns=3;grid.add_theme_constant_override("h_separation",14);grid.add_theme_constant_override("v_separation",14);content.add_child(grid)
 var tiers=s.Economy.Radiation.TIERS
 for i in tiers.size():
  var c=panel(h,grid,392);c.get_parent().get_parent().custom_minimum_size.y=170;c.get_parent().get_parent().size_flags_vertical=0
  words(h,c,"%d–%d  %s"%[tiers[i].min,tiers[i+1].min-1 if i+1<tiers.size() else 100,tiers[i].name],20,GOLD if i==s.Economy.Radiation.index(int(s.economy.radiation)) else DIM)
  words(h,c,tiers[i].detail,17)
 gap(content);action(h,content,"返回背包",func():h.show_inventory())
static func pause(h):
 var content=shell(h,"现场记录","ПАУЗА  /  游戏已暂停","pause")
 var main=row(content,28);main.size_flags_vertical=Control.SIZE_EXPAND_FILL
 var menu=column(main,480)
 for entry in [["继续探索",func():h.close()],["保存游戏  [F5]",func():h.show_saves(true)],["读取存档  [F9]",func():h.show_saves(false)],["画面与声音",func():settings(h)],["返回主界面",func():h.show_menu_confirm()],["重新开始",func():h.show_restart_confirm()]]:action(h,menu,entry[0],entry[1])
 if is_instance_valid(h.world.combat) and h.world.combat.active and not load("res://scripts/raid_loot.gd").active(h.world):action(h,menu,"重试本场战斗",func():h.world.combat.retry())
 var detail=panel(h,main);words(h,detail,"当前行程",25,GOLD)
 var task=Journal.active(h.world.story)
 if not task.is_empty():words(h,detail,task.name,24);words(h,detail,task.step,20)
 gap(detail);line(detail);words(h,detail,"WASD / 方向键    移动\nE    与选中目标互动\nI    装备与背包       J    手记\nM / Tab    地图\n1    拔枪 / 收枪       R    换弹\nCtrl    轻步潜行\n滚轮    切换附近目标 / 近景缩放",18,DIM)
static func saves(h,saving:bool,return_to_menu:bool=false,group:String="manual"):
 h.saves_return_menu=return_to_menu
 var content=shell(h,"保存游戏" if saving else "读取存档","СОХРАНЕНИЯ  /  六个独立手动档位","saves")
 if not saving:
  var tabs=row(content);action(h,tabs,"手动存档",func():saves(h,false,return_to_menu,"manual"),true,group=="manual");action(h,tabs,"自动与旧版存档",func():saves(h,false,return_to_menu,"auto"),true,group=="auto")
 var store=h.world.SaveStore;var paths:Array=store.manual_paths() if saving or group=="manual" else store.automatic_paths()+[store.QUICK]
 var grid=GridContainer.new();grid.columns=2;grid.add_theme_constant_override("h_separation",16);grid.add_theme_constant_override("v_separation",16);content.add_child(grid)
 for path in paths:
  var data:Dictionary=store.read(path);var c=panel(h,grid,600);c.get_parent().get_parent().size_flags_vertical=0;c.get_parent().get_parent().custom_minimum_size.y=190
  words(h,c,store.title(path),22,GOLD);words(h,c,store.description(path),16,DIM);gap(c)
  var slot:String=path;var metadata:Dictionary=data;action(h,c,"保存到此档位" if saving else "读取",func():h.confirm_slot(slot,saving,metadata),saving or not data.is_empty())
 gap(content);action(h,content,"返回",func():h.show_comic_pause() if h.comic_active else pause(h))
 h.modal_hint.text="档位互不覆盖 · 覆盖已有进度前会再次确认 · Esc 返回游戏"

static func transfer(h,storage:bool,target:String=""):
 var w=h.world;var s=w.story;var stash=load("res://scripts/supply_storage.gd");var raid=load("res://scripts/raid_loot.gd")
 var record:Dictionary={}
 if storage:
  if not stash.accessible(w):h.toast("请先走到寄存柜旁。");return
 else:
  if not w.targets.has(target) or w.player.position.distance_to(w.targets[target].pos)>2.3 or not raid.safe(w):h.toast("需要在安全位置靠近容器。");return
  record=s.flags.raid_containers.get(raid.record_key(w,target.trim_prefix("raid_container_")),{})
  if record.is_empty() or not record.searched:return
 var content=shell(h,stash.NAMES[w.floor_id] if storage else record.title,"ПЕРЕДАЧА  /  物资转移","transfer")
 var main=row(content,22);main.size_flags_vertical=Control.SIZE_EXPAND_FILL
 for side in [0,1]:
  var left=side==0;var c=panel(h,main)
  words(h,c,"随身物资" if left else ("聚落寄存" if storage else "容器内的物品"),24,GOLD)
  var source:Dictionary=s.economy.goods.duplicate() if left else (s.economy.stashes.get(w.floor_id,{}) if storage else record.loot)
  if left:
   for id in Bag.ORDINARY_ITEMS:
    if s.has(id):source[id]=1
   if storage:
    for id in ["military","handmade"]:
     if s.economy[id]>0:source[id]=s.economy[id]
  var ids=source.keys().filter(func(id):return int(source[id])>0)
  var key=("stash" if storage else target)+str(side)+"_page";var index=clampi(int(h.get_meta(key,0)),0,maxi(0,ceili(ids.size()/7.0)-1))
  if ids.is_empty():words(h,c,"没有可转移的物品。" if storage else ("背包暂时没有物资。" if left else "已经搜空。"),19,DIM)
  for id in ids.slice(index*7,index*7+7):
   var item:String=id;var amount:int=source[id];var r=row(c,10);r.add_child(h.icon_rect(h.item_icon(id),38));words(h,r,Bag.name_of(s,id)+" ×%d"%amount,17)
   if storage:
    var deposit:bool=left
    for amount_value in ([1,amount] if amount>1 else [1]):
     var quantity:int=amount_value
     action(h,r,"全部" if quantity>1 else ("存入" if left else "取回"),func():
      if stash.accessible(w) and stash.move(s,w.floor_id,item,quantity,deposit):w.autosave()
      else:h.toast("背包放不下或无法转移这件装备。")
      transfer(h,true),true)
   elif not left:action(h,r,"收取",func():
    if not raid.take(w,target,item):h.toast("背包放不下，剩余物品留在原处。")
    transfer(h,false,target))
  gap(c);page(h,c,key,ids.size(),7,func():transfer(h,storage,target))
  if not left and not storage:action(h,c,"收取能放下的全部物品",func():raid.take_all(w,target))
 words(h,content,"背包 %d / 48 格 · 任务文件随身保护"%Bag.pack(s).used,17,GOLD)
 if storage and s.flags.get("raid_last_result","")=="lost" and (not s.has("mask") or not s.has("filter") or (not s.has("revolver") and not s.has("grey_carbine"))):
  action(h,content,"借用基础外勤装备 · 撤回后偿还 8 发制式弹",func():
   if not s.has("revolver") and not s.has("grey_carbine"):s.give("revolver");s.equip_weapon("revolver")
   if not s.has("mask"):s.give("mask")
   if not s.has("filter"):s.give("filter")
   s.economy.handmade=maxi(8,int(s.economy.handmade));s.flags.raid_loan=maxi(8,int(s.flags.get("raid_loan",0)));w.autosave();transfer(h,true))
 h.modal_hint.text="左右分栏转移物品 · 寄存物资留在当前聚落" if storage else "背包放不下的物品继续留在容器中 · Esc 返回"

static func raid_debrief(h):
 var s=h.world.story;s.flags.raid_debrief_pending=false;s.flags.tracked_quest="raid_recovery"
 var content=shell(h,"重新准备","ВОЗВРАЩЕНИЕ  /  地表行动已结束","recovery")
 var main=row(content,24);main.size_flags_vertical=Control.SIZE_EXPAND_FILL
 var losses=panel(h,main,480);losses.get_parent().get_parent().size_flags_horizontal=0
 words(h,losses,"未能带回的物资",23,RED)
 var entries:Array=s.flags.get("raid_losses",[]);var key="losses_page";var index=clampi(int(h.get_meta(key,0)),0,maxi(0,ceili(entries.size()/9.0)-1))
 for item in entries.slice(index*9,index*9+9):words(h,losses,item,18,DIM)
 gap(losses);page(h,losses,key,entries.size(),9,func():raid_debrief(h))
 var next=panel(h,main);words(h,next,"你已经回到"+h.world.floor_name(),26,GOLD)
 words(h,next,"任务进度、关键物品和已寄存的物资仍然保留。准备好以后，可以再次前往地表。",21)
 line(next);text_panel(h,next,"01  取回装备","先到聚落的个人寄存柜。没有备用装备时，可以借用一套基础外勤装备。")
 text_panel(h,next,"02  检查补给","装备武器，确认带上面具与滤毒罐；从寄存柜取出需要的补给，其余物资可以留在柜内。")
 text_panel(h,next,"03  再次出发","到出站口与值守或接送人员交谈，选择地表行动。无需重新接取已经接受的任务。")
 gap(next);action(h,next,"在地图上查看寄存柜",func():journal(h,"map",h.world.floor_id));action(h,next,"继续 · 跟进准备任务",func():h.close())
 h.world.autosave()

static func dialogue(h,id:String,first_new:int,part:int=0,choice_page:int=0,animate:bool=true):
 var s=h.world.story;var view=s.view(id);var content=shell(h,view.name,view.role+"  /  "+h.world.floor_name(),"dialogue");h.dialogue_id=id
 var entries:Array=s.conversations.get(id,[]).slice(first_new)
 if entries.is_empty():animate=false
 if entries.is_empty():entries=s.Conversation.split_text(view.body,id)
 var pieces=[]
 for entry in entries:
  for text in split_text(h,entry.text,650,160,21):
   var fragment:Dictionary=entry.duplicate();fragment.text=text;pieces.append(fragment)
 var count=maxi(1,ceili(pieces.size()/2.0));part=clampi(part,0,count-1)
 var main=row(content,22);main.size_flags_vertical=Control.SIZE_EXPAND_FILL
 var speech=panel(h,main);var heading=row(speech,18)
 var portrait_path=load("res://scripts/ui_dialogue.gd").portrait(h,id)
 if ResourceLoader.exists(portrait_path):heading.add_child(h.icon_rect(portrait_path,96))
 words(h,heading,view.name,26,GOLD);line(speech)
 for entry in pieces.slice(part*2,part*2+2):
  var group=column(speech);var narrator=entry.speaker=="narrator";var mine=entry.speaker=="ivan"
  words(h,group,"旁白" if narrator else ("伊万" if mine else entry.get("name",view.name)),14,DIM if narrator else GOLD)
  var speaker_id=h.dialogue_id
  if not animate or mine:h.dialogue_id=""
  var text=h.prose(entry.text if narrator else "「"+entry.text+"」",21,group);h.dialogue_id=speaker_id
  if not mine and animate:
   if h.typing.is_empty() or h.typing[-1].label!=text:
    text.visible_characters=0;h.typing.append({"label":text,"total":text.get_total_character_count(),"elapsed":0.0,"rate":48.0,"root":group})
   else:h.typing[-1].root=group
   group.visible=false
 gap(speech)
 var controls=row(speech)
 if part>0:action(h,controls,"‹ 前一段",func():dialogue(h,id,first_new,part-1,choice_page))
 words(h,controls,"%d / %d"%[part+1,count],14,DIM).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 if part+1<count:
  var next=action(h,controls,"继续阅读 ›",func():dialogue(h,id,first_new,part+1,choice_page));h.speech_buttons.append(next)
 var choices=panel(h,main,400);choices.get_parent().get_parent().size_flags_horizontal=0
 words(h,choices,"选择回应" if h.world.npcs.has(id) else "可以采取的行动",20,GOLD);line(choices)
 if part+1<count:words(h,choices,"读完当前回应后，可以继续交谈。",18,DIM)
 else:
  var options:Array=view.options.filter(func(o):return o.enabled)
  choice_page=clampi(choice_page,0,maxi(0,ceili(options.size()/4.0)-1))
  for option in options.slice(choice_page*4,choice_page*4+4):
   var o:Dictionary=option;var category:String=o.get("category","调查");var colors={"任务":GOLD,"决定":RED,"闲聊":DIM,"调查":PAPER}
   words(h,choices,category+(" · "+o.check.tier+" "+str(o.check.chance)+"%" if o.has("check") else ""),13,colors.get(category,PAPER))
   var b=action(h,choices,o.text,func():h.last_choice=o.text;h.world.perform(o.key,id));b.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;b.add_theme_color_override("font_color",colors.get(category,PAPER));h.speech_buttons.append(b)
  gap(choices)
  if options.size()>4:
   var pages=row(choices)
   action(h,pages,"‹",func():dialogue(h,id,first_new,part,choice_page-1,false),choice_page>0)
   words(h,pages,"话题 %d / %d"%[choice_page+1,ceili(options.size()/4.0)],14,DIM).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
   action(h,pages,"›",func():dialogue(h,id,first_new,part,choice_page+1,false),(choice_page+1)*4<options.size())
 gap(choices);line(choices)
 action(h,choices,"查看本次交谈记录",func():conversation_history(h,id))
 action(h,choices,"结束交谈" if h.world.npcs.has(id) else "收起调查",func():h.close())
 for button in h.speech_buttons:button.disabled=not h.typing.is_empty()
 h.modal_hint.text="空格 / Enter 显示当前段全文 · 话题按页切换 · 旧记录可单独查看 · Esc 返回"
static func conversation_history(h,id:String,index:int=0):
 var view=h.world.story.view(id);var content=shell(h,"交谈记录",view.name+" / 已经说过的话","history")
 var full=""
 for entry in h.world.story.conversations.get(id,[]):
  full+=("旁白" if entry.speaker=="narrator" else ("伊万" if entry.speaker=="ivan" else entry.get("name",view.name)))+"：\n"+entry.text+"\n\n"
 var pages=split_text(h,full,1050,450,21);index=clampi(index,0,pages.size()-1)
 words(h,content,pages[index],21);gap(content);var controls=row(content)
 action(h,controls,"‹ 前一页",func():conversation_history(h,id,index-1),index>0);words(h,controls,"%d / %d"%[index+1,pages.size()],16,DIM).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;action(h,controls,"下一页 ›",func():conversation_history(h,id,index+1),index+1<pages.size())
 action(h,content,"返回交谈",func():h.show_dialogue(id))
