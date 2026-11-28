extends RefCounted
## Exposure is authored per place. No screen-wide tint alters portraits or UI.
const OUTDOORS=["relay","surface","starcity","east_district"]
const PROFILES={
	"junction":["879b9a",.25,"b1bcb5",.12],
	"star_interior":["89a7aa",.26,"b7c9c5",.13],
	"relay":["9baeb9",.31,"c8d0d4",.58],
	"life":["87968d",.32,"b3b6a4",.23],
	"labor":["88938e",.29,"a1b2ae",.22],
	"commune":["8f9e9c",.25,"c7c3ae",.12],
	"sech":["9eaaa5",.32,"b3bfbe",.20],
	"coal":["86958e",.29,"9badb0",.18],
	"waterworks":["839ba7",.27,"c0ced0",.16],
	"railfront":["899b9c",.30,"a0b3b9",.18],
	"surface":["a4b7c1",.35,"d1d7d5",.32],
	"starcity":["a4b7c1",.35,"d1d7d5",.32],
	"east_district":["a7b4bf",.40,"e3ded3",.92]
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
		if w.floor_id=="east_district":east_district_light(e,sun)
	sun.directional_shadow_max_distance=75 if w.floor_id in OUTDOORS else 45
	sun.shadow_blur=1.3

static func east_district_light(e:Environment,sun:DirectionalLight3D):
	# The road reflects a diffuse winter sky. Local amber comes from lit
	# fixtures, so it still indicates an occupied or powered place.
	var overcast=ProceduralSkyMaterial.new()
	overcast.sky_top_color=Color("667b8c")
	overcast.sky_horizon_color=Color("b8c3c9")
	overcast.ground_horizon_color=Color("81949f")
	overcast.ground_bottom_color=Color("4f5558")
	overcast.sun_angle_max=0.0
	var reflected_sky=Sky.new()
	reflected_sky.radiance_size=Sky.RADIANCE_SIZE_128
	reflected_sky.sky_material=overcast
	e.sky=reflected_sky
	e.reflected_light_source=Environment.REFLECTION_SOURCE_SKY
	e.background_color=Color("96a4ac")
	e.fog_density=.00115
	e.fog_light_color=Color("95a6b3")
	e.fog_light_energy=.64
	e.fog_height=.75
	e.fog_height_density=.010
	e.fog_sun_scatter=.075
	e.tonemap_exposure=1.01
	e.adjustment_enabled=true
	e.adjustment_contrast=1.109
	e.adjustment_saturation=.87
	sun.rotation_degrees=Vector3(-33,25,0)
	sun.directional_shadow_mode=DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS

static func refine(w):
	# Material identity matters at play scale: calm floors, contrast on fixtures.
	# Lamps retain their real positions and shadows, with less clipped yellow spill.
	for node in w.find_children("*","OmniLight3D",true,false):
		if w.floor_id=="commune":
			node.light_color=Color("efc991");node.light_energy*=.74
		elif w.floor_id in ["life","sech"]:node.light_energy*=.86
		if node.shadow_enabled:node.shadow_blur=1.3
