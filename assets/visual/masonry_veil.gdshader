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
varying float world_height;
varying vec3 world_position;
varying vec3 world_normal;

void vertex() {
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
	ROUGHNESS = 0.94;
	EMISSION = emission_color;
	if (normal_strength>0.0) {
		NORMAL_MAP = texture(normal_map,UV).rgb;
		NORMAL_MAP_DEPTH = normal_strength;
	}
}
