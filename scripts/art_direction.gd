extends RefCounted
## Exposure is authored per place. No screen-wide tint alters portraits or UI.
const OUTDOORS=["surface","starcity","east_district"]
const PROFILES={
	"life":["87968d",.32,"b3b6a4",.23],
	"labor":["88938e",.29,"a1b2ae",.22],
	"commune":["b7aa91",.27,"c7c3ae",.12],
	"sech":["9eaaa5",.32,"b3bfbe",.20],
	"coal":["86958e",.29,"9badb0",.18],
	"waterworks":["9aaeb3",.38,"b4c5cb",.22],
	"railfront":["899b9c",.30,"a0b3b9",.18],
	"surface":["a4b7c1",.35,"d1d7d5",.32],
	"starcity":["a4b7c1",.35,"d1d7d5",.32],
	"east_district":["9cabb2",.28,"d6d1bd",.62]
}
static func environment(w,e:Environment,sun:DirectionalLight3D):
	var p:Array=PROFILES.get(w.floor_id,PROFILES.life)
	e.ambient_light_color=Color(p[0]);e.ambient_light_energy=p[1]
	sun.light_color=Color(p[2]);sun.light_energy=p[3]
	sun.rotation_degrees=Vector3(-48,-32,0)
	if w.floor_id in OUTDOORS:
		e.background_color=Color("a4b2b8")
		e.fog_enabled=true;e.fog_density=.0018;e.fog_light_color=Color("a4b2b8")
		e.fog_light_energy=.65
		if w.floor_id=="east_district":e.fog_density=.0012
	sun.directional_shadow_max_distance=75 if w.floor_id in OUTDOORS else 45
	sun.shadow_blur=1.3

static func refine(w):
	# Material identity matters at play scale: calm floors, contrast on fixtures.
	# Lamps retain their real positions and shadows, with less clipped yellow spill.
	for node in w.find_children("*","OmniLight3D",true,false):
		if w.floor_id=="commune":
			node.light_color=Color("efc991");node.light_energy*=.74
		elif w.floor_id in ["life","sech"]:node.light_energy*=.86
		if node.shadow_enabled:node.shadow_blur=1.3
