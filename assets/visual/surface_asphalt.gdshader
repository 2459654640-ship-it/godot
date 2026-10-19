shader_type spatial;
render_mode cull_disabled;
uniform sampler2D asphalt_map : source_color, filter_linear_mipmap, repeat_enable;
varying vec3 world_position;
void vertex(){world_position=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
void fragment(){
 ALBEDO=texture(asphalt_map,world_position.xz*.095).rgb*.92;
 ROUGHNESS=.98;
}
