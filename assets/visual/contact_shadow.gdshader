shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled;
void fragment() {
	float r=length((UV-vec2(0.5))*2.0);
	ALBEDO=vec3(0.025,0.030,0.026);
	ALPHA=(1.0-smoothstep(0.15,1.0,r))*0.36;
}
