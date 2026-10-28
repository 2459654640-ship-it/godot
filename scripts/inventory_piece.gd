extends Button
var grid
var piece:Dictionary
func _get_drag_data(_at):
 var preview=Label.new();preview.text=tooltip_text.get_slice("\n",0);preview.add_theme_font_size_override("font_size",18);set_drag_preview(preview)
 return {"bag_piece":piece.key}
