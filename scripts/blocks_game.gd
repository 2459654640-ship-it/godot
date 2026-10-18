extends Control
## Local falling-block puzzle. No economy rewards or network dependency.
signal record_changed(value:int)
signal leave_requested
const WIDTH=10
const HEIGHT=20
const CELL=22
const ORIGIN=Vector2(154,38)
const SHAPES=[
	[Vector2i(0,1),Vector2i(1,1),Vector2i(2,1),Vector2i(3,1)],
	[Vector2i(1,0),Vector2i(2,0),Vector2i(1,1),Vector2i(2,1)],
	[Vector2i(1,0),Vector2i(0,1),Vector2i(1,1),Vector2i(2,1)],
	[Vector2i(1,0),Vector2i(2,0),Vector2i(0,1),Vector2i(1,1)],
	[Vector2i(0,0),Vector2i(1,0),Vector2i(1,1),Vector2i(2,1)],
	[Vector2i(0,0),Vector2i(0,1),Vector2i(1,1),Vector2i(2,1)],
	[Vector2i(2,0),Vector2i(0,1),Vector2i(1,1),Vector2i(2,1)]]
const COLORS=[Color("87b9ac"),Color("d2b574"),Color("b296c3"),Color("90aa73"),Color("bd8070"),Color("7f9eb6"),Color("c69a70")]
var board:Array=[]
var bag:Array=[]
var shape=0
var next_shape=0
var piece_rotation=0
var position_cell=Vector2i(3,-1)
var score=0
var best=0
var lines=0
var fall_clock=0.0
var lock_clock=0.0
var paused=false
var over=false
var started=false
var font:Font
var rng=RandomNumberGenerator.new()

func _ready():
	custom_minimum_size=Vector2(680,535)
	focus_mode=Control.FOCUS_ALL
	font=get_theme_font("font")
	rng.randomize()
	restart()
	grab_focus()

func restart():
	board.clear()
	for y in HEIGHT:
		var row:Array=[];row.resize(WIDTH);row.fill(-1);board.append(row)
	bag.clear();score=0;lines=0;paused=false;over=false;started=false
	fall_clock=0;lock_clock=0;next_shape=take_bag();spawn();queue_redraw()

func take_bag()->int:
	if bag.is_empty():
		bag.assign(range(7))
		for i in range(6,0,-1):
			var j=rng.randi_range(0,i);var value=bag[i];bag[i]=bag[j];bag[j]=value
	return int(bag.pop_back())

func cells(piece:int,turn:int)->Array[Vector2i]:
	var output:Array[Vector2i]=[]
	for original in SHAPES[piece]:
		var p:Vector2i=original
		if piece!=1:
			for step in posmod(turn,4):p=Vector2i((3 if piece==0 else 2)-p.y,p.x)
		output.append(p)
	return output

func valid(at:Vector2i,turn:int)->bool:
	for p in cells(shape,turn):
		var q=p+at
		if q.x<0 or q.x>=WIDTH or q.y>=HEIGHT:return false
		if q.y>=0 and board[q.y][q.x]>=0:return false
	return true

func spawn():
	shape=next_shape;next_shape=take_bag();piece_rotation=0;position_cell=Vector2i(3,-1)
	fall_clock=0;lock_clock=0
	if not valid(position_cell,piece_rotation):over=true;save_record()

func translate(by:Vector2i)->bool:
	if not valid(position_cell+by,piece_rotation):return false
	position_cell+=by
	return true

func turn(direction:int=1):
	var desired=posmod(piece_rotation+direction,4)
	for kick in [0,-1,1,-2,2]:
		var at=position_cell+Vector2i(kick,0)
		if valid(at,desired):piece_rotation=desired;position_cell=at;return

func hard_drop():
	while translate(Vector2i.DOWN):score+=2
	lock_piece()

func clear_rows()->int:
	var kept:Array=[]
	for row in board:
		if row.has(-1):kept.append(row)
	var count=HEIGHT-kept.size()
	while kept.size()<HEIGHT:
		var row:Array=[];row.resize(WIDTH);row.fill(-1);kept.push_front(row)
	board=kept
	return count

func lock_piece():
	for p in cells(shape,piece_rotation):
		var q=p+position_cell
		if q.y<0:over=true;save_record();return
		board[q.y][q.x]=shape
	var count=clear_rows()
	score+=[0,100,300,500,800][count]*(1+lines/10)
	lines+=count;save_record();spawn();queue_redraw()

func save_record():
	if score>best:best=score;record_changed.emit(best)

func _process(delta):
	if not is_visible_in_tree() or paused or over or not started:return
	fall_clock+=delta
	var interval=maxf(.12,.78-pow(float(lines/10),.8)*.095)
	if fall_clock>=interval:
		fall_clock=0
		translate(Vector2i.DOWN)
	if not valid(position_cell+Vector2i.DOWN,piece_rotation):
		lock_clock+=delta
		if lock_clock>=.36:lock_piece()
	else:lock_clock=0
	queue_redraw()

func _input(event):
	if not is_visible_in_tree() or not event is InputEventKey or not event.pressed:return
	var key=event.physical_keycode if event.physical_keycode!=0 else event.keycode
	if key not in [KEY_LEFT,KEY_RIGHT,KEY_DOWN,KEY_UP,KEY_Z,KEY_X,KEY_SPACE,KEY_ENTER,KEY_P,KEY_R,KEY_ESCAPE]:return
	get_viewport().set_input_as_handled()
	if key==KEY_ESCAPE:save_record();leave_requested.emit();return
	if key==KEY_R and not event.echo:restart();return
	if key==KEY_P and not event.echo:paused=not paused;queue_redraw();return
	if over or paused:return
	if not started:
		if key in [KEY_ENTER,KEY_SPACE]:started=true;queue_redraw()
		return
	match key:
		KEY_LEFT:translate(Vector2i.LEFT)
		KEY_RIGHT:translate(Vector2i.RIGHT)
		KEY_DOWN:
			if translate(Vector2i.DOWN):score+=1;fall_clock=0
		KEY_UP,KEY_X:
			if not event.echo:turn()
		KEY_Z:
			if not event.echo:turn(-1)
		KEY_SPACE:
			if not event.echo:hard_drop()
	queue_redraw()

func block(at:Vector2,color:Color,ghost:bool=false):
	var rect=Rect2(at+Vector2.ONE,Vector2.ONE*(CELL-2))
	if ghost:draw_rect(rect,color.darkened(.2),false,1.0);return
	draw_rect(rect,color.darkened(.2));draw_rect(Rect2(rect.position+Vector2(2,2),rect.size-Vector2(4,4)),color)
	draw_line(rect.position,rect.position+Vector2(rect.size.x,0),color.lightened(.3),1)

func text(at:Vector2,words:String,size:int=17,color:Color=Color("b6c9ae")):
	draw_string(font,at,words,HORIZONTAL_ALIGNMENT_LEFT,-1,size,color)

func _draw():
	if not font:return
	draw_rect(Rect2(ORIGIN-Vector2(9,9),Vector2(WIDTH*CELL+18,HEIGHT*CELL+18)),Color("596754"),false,2)
	draw_rect(Rect2(ORIGIN,Vector2(WIDTH*CELL,HEIGHT*CELL)),Color("091310"))
	for y in HEIGHT:
		for x in WIDTH:
			var at=ORIGIN+Vector2(x,y)*CELL
			draw_rect(Rect2(at,Vector2.ONE*CELL),Color("15231c"),false,.6)
			if not board.is_empty() and board[y][x]>=0:block(at,COLORS[board[y][x]])
	if not over:
		var landing=position_cell
		while valid(landing+Vector2i.DOWN,piece_rotation):landing+=Vector2i.DOWN
		for p in cells(shape,piece_rotation):
			if (p+landing).y>=0:block(ORIGIN+Vector2(p+landing)*CELL,COLORS[shape]*Color(1,1,1,.6),true)
			if (p+position_cell).y>=0:block(ORIGIN+Vector2(p+position_cell)*CELL,COLORS[shape])
	text(Vector2(410,58),"下一块",18)
	for p in cells(next_shape,0):block(Vector2(410,78)+Vector2(p)*CELL,COLORS[next_shape])
	text(Vector2(410,174),"得分  %06d"%score,20)
	text(Vector2(410,208),"纪录  %06d"%best,18)
	text(Vector2(410,242),"消行  %d"%lines,18)
	for i in 6:text(Vector2(410,300+i*27),["← →  移动","↑ / X  旋转","↓  加速下落","空格  直接落下","P  暂停","R  重新开始"][i],16)
	text(Vector2(154,516),"排满横行即可消除。虚线框标记落点。",16,Color("8b9c87"))
	var message=""
	if over:message="本局结束 · R  再来一局"
	elif paused:message="已暂停 · P  继续"
	elif not started:message="回车 / 空格  开始"
	if message!="":
		draw_rect(Rect2(ORIGIN+Vector2(-5,180),Vector2(230,70)),Color(.04,.09,.065,.96))
		text(ORIGIN+Vector2(8,222),message,17,Color("e0cb8d"))
