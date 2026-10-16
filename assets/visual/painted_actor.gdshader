shader_type spatial;
render_mode unshaded, cull_disabled;
uniform sampler2D painted_map : source_color, filter_linear_mipmap, repeat_disable;
uniform vec2 frame_origin = vec2(0.0);
uniform vec2 frame_size = vec2(0.2,1.0);
uniform vec2 texel_size = vec2(0.001);
uniform bool mirror = false;
uniform float focus : hint_range(0.0,1.0) = 0.0;
uniform vec3 light_tint : source_color = vec3(0.91,0.89,0.82);
uniform float gait = 0.0;
uniform float motion = 0.0;

void vertex() {
	// Pixel-art figure lies on a true depth-tested billboard, foot anchored.
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0],INV_VIEW_MATRIX[1],INV_VIEW_MATRIX[2],MODEL_MATRIX[3]);
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
	float leg = smoothstep(0.56,0.92,UV.y);
	VERTEX.x += sin(gait + (UV.x < 0.5 ? 0.0 : 3.14159))*leg*motion*0.018;
	VERTEX.y += max(0.0,sin(gait+(UV.x < 0.5 ? 0.0 : 3.14159)))*leg*motion*0.035;
}

vec4 sample_frame(vec2 uv) {
	uv=clamp(uv,vec2(0.003),vec2(0.997));
	if (mirror) uv.x=1.0-uv.x;
	return texture(painted_map,frame_origin+uv*frame_size);
}

void fragment() {
	vec4 paint=sample_frame(UV);
	if (paint.a < 0.36) {
		vec2 step_uv=texel_size/frame_size*1.6;
		float edge=0.0;
		edge=max(edge,sample_frame(UV+vec2(step_uv.x,0.0)).a);
		edge=max(edge,sample_frame(UV-vec2(step_uv.x,0.0)).a);
		edge=max(edge,sample_frame(UV+vec2(0.0,step_uv.y)).a);
		edge=max(edge,sample_frame(UV-vec2(0.0,step_uv.y)).a);
		if (edge*focus < 0.42) discard;
		ALBEDO=vec3(0.67,0.53,0.30);
	} else {
		ALBEDO=paint.rgb*light_tint;
	}
}
