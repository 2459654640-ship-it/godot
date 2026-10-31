extends Control
const Bag=preload("res://scripts/backpack.gd")
var h
var selected=""
var cell=75.0
var columns=Bag.WIDTH
var tab="all"
func setup(hud,selected_id:String,current_tab:String):
 h=hud;selected=selected_id;tab=current_tab;name="InventoryGrid";custom_minimum_size=Vector2(cell*Bag.WIDTH,cell*Bag.HEIGHT)
 var packed=Bag.pack(h.world.story,{},true)
 var categories=load("res://scripts/ui_inventory.gd").entries(h.world.story)
 for piece in packed.pieces:
  var b=preload("res://scripts/inventory_piece.gd").new();b.grid=self;b.piece=piece;b.name="InventoryCell_"+piece.id;b.position=Vector2(piece.at)*cell+Vector2.ONE*2;b.size=Vector2(piece.size)*cell-Vector2.ONE*4
  var caption=Bag.name_of(h.world.story,piece.id)
  b.text="";b.add_theme_stylebox_override("normal",h.style(Color("27362f"),h.amber if piece.id==selected else Color("5c6858"),1,2));b.tooltip_text=caption+" ×%d"%piece.count+"\n拖动调整位置；选中后可旋转占格。"
  b.clip_contents=true
  if tab!="all" and not categories.any(func(e):return e.id==piece.id and e.category==tab):b.modulate=Color(.45,.5,.47,.65)
  var icon=TextureRect.new();icon.texture=load(h.item_icon(piece.id));icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;icon.mouse_filter=Control.MOUSE_FILTER_IGNORE
  b.add_child(icon);icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);icon.offset_left=6;icon.offset_right=-6;icon.offset_top=5;icon.offset_bottom=-22
  var title=Label.new();title.text=caption;title.add_theme_font_override("font",h.font);title.add_theme_font_size_override("font_size",12);title.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;title.clip_text=true;title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;title.mouse_filter=Control.MOUSE_FILTER_IGNORE
  b.add_child(title);title.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE);title.offset_left=3;title.offset_right=-3;title.offset_top=-22;title.offset_bottom=-3
  if piece.count>1:
   var count=Label.new();count.text=str(piece.count);count.add_theme_font_size_override("font_size",14);count.add_theme_color_override("font_color",h.amber);count.mouse_filter=Control.MOUSE_FILTER_IGNORE;b.add_child(count);count.position=Vector2(b.size.x-21,4)
  var id:String=piece.id;b.pressed.connect(func():h.set_meta("bag_selected_key",piece.key);load("res://scripts/ui_inventory.gd").render(h,tab,id));add_child(b)
func _draw():
 for x in Bag.WIDTH:
  for y in Bag.HEIGHT:
   var r=Rect2(x*cell+1,y*cell+1,cell-2,cell-2);draw_rect(r,Color("101b19"));draw_rect(r,Color("38463d"),false,1)
func _can_drop_data(at,data):
 if not data is Dictionary or not data.has("bag_piece"):return false
 var s=h.world.story;var pieces=Bag.pack(s).pieces;var used={};var sz=Vector2i.ZERO
 for p in pieces:
  if p.key==data.bag_piece:sz=p.size
  else:Bag.occupy(used,p.at,p.size)
 return sz!=Vector2i.ZERO and Bag.fits(Vector2i(at/cell),sz,used)
func _drop_data(at,data):
 if Bag.move_piece(h.world.story,data.bag_piece,Vector2i(at/cell)):h.world.autosave();load("res://scripts/ui_inventory.gd").render(h,tab,selected)
