shader_type spatial;
render_mode unshaded, cull_front, shadows_disabled;
uniform vec4 edge_color : source_color = vec4(0.77,0.62,0.35,1.0);
uniform float width = 0.012;
void vertex() { VERTEX += NORMAL * width; }
void fragment() { ALBEDO = edge_color.rgb; }
