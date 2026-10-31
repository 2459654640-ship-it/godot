extends RefCounted
## Drive the same explicit reading and topic-page controls as a player.
static func option(h,text:String):
 for attempt in 30:
  h.finish_typing()
  var buttons=h.modal.find_children("*","Button",true,false)
  for b in buttons:
   if b.text==text:return b
  var next=buttons.filter(func(b):return not b.disabled and b.text=="继续阅读 ›")
  if next.is_empty():next=buttons.filter(func(b):return not b.disabled and b.text=="›")
  if next.is_empty():return null
  next[0].pressed.emit()
 return null
