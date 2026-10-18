extends "res://tools/visual_capture_v9.gd"
func _initialize():
 folder="/tmp/metro1982-review/v16";call_deferred("run")
func run():
 await open_level("d6");w.player.position=Vector3(12.3,.04,-4);camera_at(Vector3(12,1,-4),12)
 w.hud.show_shop();await shot("portable-radio-shop")
 w.story.Economy.buy(w.story,"portable_radio");w.hud.show_inventory();await shot("portable-radio-inventory")
 w.public_radio.open_controls(true);w.public_radio.select_station(0);w.public_radio.select_track(1);await shot("portable-radio-ui");w.public_radio.stop();w.hud.close()
 await dispose();quit()
