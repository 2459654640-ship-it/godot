shader_type spatial;
render_mode blend_mix, depth_draw_always, cull_back, specular_disabled;

uniform sampler2D albedo_map : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D normal_map : hint_normal, filter_linear_mipmap, repeat_enable;
uniform float normal_strength = 0.45;
uniform float visibility : hint_range(0.0, 1.0) = 1.0;
uniform vec4 base_color : source_color = vec4(1.0);
uniform bool has_texture = true;
uniform bool triplanar = false;
uniform vec3 map_scale = vec3(1.0);
uniform vec3 emission_color : source_color = vec3(0.0);
uniform bool commune_finish = false;
uniform bool factory_finish = false;
uniform sampler2D factory_blue : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D factory_tile : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D factory_archive : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D finish_plaster : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D finish_tile : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D finish_cement : source_color, filter_linear_mipmap, repeat_enable;
varying float finish_style;
varying float world_height;
varying vec3 world_position;
varying vec3 world_normal;

void vertex() {
	finish_style=UV2.x;
	world_height = (MODEL_MATRIX * vec4(VERTEX, 1.0)).y;
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
}

void fragment() {
	// One real solid shell, with fixed orthographic depth ordering and depth
	// writes. No overlapping transparent skin or frame-dependent noise.
	float coverage = mix(1.0,visibility,smoothstep(0.18,0.48,world_height));
	ALPHA=coverage;
	vec3 texel = vec3(1.0);
	if (has_texture) {
		if (triplanar) {
			vec3 weight = pow(abs(world_normal),vec3(6.0));
			weight /= max(dot(weight,vec3(1.0)),0.001);
			vec3 p = world_position * map_scale;
			texel = texture(albedo_map,p.zy).rgb*weight.x+texture(albedo_map,p.xz).rgb*weight.y+texture(albedo_map,p.xy).rgb*weight.z;
		} else {texel = texture(albedo_map,UV).rgb;}
	}
	ALBEDO = texel * base_color.rgb;
	if (commune_finish && finish_style>0.5) {
		float style=floor(finish_style+0.5);
		vec3 plaster=texture(finish_plaster,UV).rgb;
		vec3 finish=plaster;
		vec3 paint=vec3(0.73,0.69,0.59);
		float dado=1.05;
		if(style<1.5) { paint=vec3(0.39,0.22,0.19);dado=1.10; }
		else if(style<2.5) {
			finish=texture(finish_cement,UV).rgb*vec3(0.79,0.87,0.79);
			paint=vec3(0.30,0.39,0.34);dado=.62;
		} else if(style<3.5) { paint=vec3(0.58,0.48,0.31);dado=1.32; }
		else if(style<4.5) {
			finish=mix(texture(finish_tile,UV).rgb,plaster,smoothstep(1.48,1.52,world_height));
			paint=vec3(0.80,0.84,0.76);dado=.14;
		} else { paint=vec3(0.54,0.55,0.43);dado=.75; }
		ALBEDO=finish*mix(paint,vec3(1.0),smoothstep(dado-.025,dado+.025,world_height));
		if(abs(world_height-dado)<.018 && style!=4.0)ALBEDO*=.65;
	}
	ROUGHNESS = 0.94;
	if(factory_finish && finish_style>10.5) {
		vec3 dry=texture(factory_archive,UV).rgb;
		vec3 wet=texture(factory_tile,UV*vec2(1.6,1.0)).rgb;
		vec3 blue=texture(factory_blue,UV).rgb;
		float style=floor(finish_style+.5);
		if(style<11.5) ALBEDO=mix(blue,dry*.76,smoothstep(1.55,1.58,world_height));
		else if(style<12.5) ALBEDO=mix(dry*vec3(.47,.56,.48),dry,smoothstep(1.02,1.05,world_height));
		else ALBEDO=mix(wet,dry,smoothstep(1.65,1.68,world_height));
	}
	EMISSION = emission_color;
	if (normal_strength>0.0) {
		NORMAL_MAP = texture(normal_map,UV).rgb;
		NORMAL_MAP_DEPTH = normal_strength;
	}
}
