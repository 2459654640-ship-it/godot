extends RefCounted
## Receiver controls use the journal's existing cloth, brass and paper palette.
static func render(h):
 var r=h.world.public_radio
 h.start_modal("随身收音机" if r.portable else "公共收音机","居民转播网  /  РАДИОУЗЕЛ",true)
 h.radio_open=true
 h.modal_hint.text="ESC 收起面板 · 耳机随身收听，不额外消耗电池" if r.portable else "ESC 收起面板 · 音乐继续播放，走远后渐弱"
 var stations=HBoxContainer.new();stations.add_theme_constant_override("separation",8);h.modal_box.add_child(stations)
 for i in r.catalog.stations.size():
  var s:Dictionary=r.catalog.stations[i]
  var b=h.button(s.frequency+" МГц\n"+s.name+"\n"+s.ru,func():r.select_station(i),true,true)
  b.size_flags_horizontal=Control.SIZE_EXPAND_FILL;b.add_theme_font_size_override("font_size",15);stations.add_child(b)
  if i==r.station:b.add_theme_color_override("font_color",h.amber)
 h.body(r.current_station().description,17,h.muted)
 h.rule()
 h.body(r.current_track().zh,27,h.amber)
 h.body(r.current_track().ru,19,h.text_color)
 if r.current_track().has("original"):h.body(r.current_track().original,15,h.muted)
 r.status_label=h.label(r.status(),16,h.muted);h.modal_box.add_child(r.status_label)
 var controls=HBoxContainer.new();controls.add_theme_constant_override("separation",9);h.modal_box.add_child(controls)
 for b in [h.button("上一首",func():r.advance(-1),true,true),h.button("继续播放" if r.paused else ("暂停" if r.enabled else "打开收音机"),func():r.toggle(),true,true),h.button("下一首",func():r.advance(1),true,true),h.button("关闭电源",func():r.stop(),r.enabled,true)]:controls.add_child(b)
 var row=HBoxContainer.new();h.modal_box.add_child(row);row.add_child(h.label("收音机音量",16,h.muted))
 var session=h.world.get_node("/root/Session")
 var slider=HSlider.new();slider.name="RadioVolume";slider.min_value=0;slider.max_value=1;slider.step=.05;slider.value=session.volume("Radio");slider.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(slider)
 var readout=h.label(str(roundi(slider.value*100))+"%",16,h.amber);row.add_child(readout)
 slider.value_changed.connect(func(value):session.set_volume("Radio",value);readout.text=str(roundi(value*100))+"%")
 h.rule();h.body("本频道节目单",17,h.amber)
 for i in r.current_station().tracks.size():
  var song:Dictionary=r.catalog.tracks[r.current_station().tracks[i]]
  var b=h.button(("▸ " if i==r.track else "  ")+song.zh+"  /  "+song.ru,func():r.select_track(i),true,true)
  b.add_theme_font_size_override("font_size",17);h.modal_box.add_child(b)
