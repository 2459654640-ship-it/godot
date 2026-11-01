shader_type spatial;
render_mode cull_back;
uniform sampler2D panel_atlas : source_color, filter_linear_mipmap_anisotropic, repeat_disable;
uniform vec2 atlas_cell = vec2(0.0);
uniform vec3 enamel_tint : source_color = vec3(0.97,0.98,0.93);
void fragment() {
 vec2 local_uv = mix(vec2(0.008),vec2(0.992),UV);
 vec3 face = texture(panel_atlas,(local_uv+atlas_cell)*0.5).rgb;
 ALBEDO=face*enamel_tint;
 ROUGHNESS=0.64;METALLIC=0.18;SPECULAR=0.32;
 float pilot=smoothstep(0.22,0.4,face.r-face.b)*smoothstep(0.5,0.8,face.r);
 EMISSION=face*pilot*0.055;
}
