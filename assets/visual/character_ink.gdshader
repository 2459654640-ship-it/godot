shader_type spatial;
render_mode unshaded, cull_front, shadows_disabled;
void vertex() { VERTEX += NORMAL * 0.0035; }
void fragment() { ALBEDO = vec3(0.065,0.070,0.057); }
