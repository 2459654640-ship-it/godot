shader_type spatial;
render_mode unshaded;
void fragment() {
	vec2 p = UV;
	float grid_x = 1.0 - smoothstep(0.018, 0.035, abs(fract(p.x * 10.0) - 0.5));
	float grid_y = 1.0 - smoothstep(0.018, 0.035, abs(fract(p.y * 5.0) - 0.5));
	float line_y = 0.5 + sin(p.x * 18.0) * 0.11 + sin(p.x * 43.0) * 0.025;
	float trace = 1.0 - smoothstep(0.009, 0.024, abs(p.y - line_y));
	float scan = 0.93 + 0.07 * sin(p.y * 400.0);
	float edge = smoothstep(0.0, 0.12, p.x) * smoothstep(0.0, 0.12, 1.0-p.x);
	ALBEDO = (vec3(0.025, 0.07, 0.055) + vec3(0.05, 0.13, 0.08) * max(grid_x,grid_y) + vec3(0.32,0.52,0.24) * trace) * scan * edge;
}
