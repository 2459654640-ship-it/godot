shader_type spatial;
render_mode cull_disabled, specular_disabled;
uniform sampler2D color_atlas : source_color, filter_linear_mipmap, repeat_disable;
// Raw RGBA data: view normals in RGB, signed geometric depth encoded in A.
uniform sampler2D normal_atlas : filter_linear_mipmap, repeat_disable;
uniform vec2 frame_origin = vec2(0.0);
uniform vec2 frame_size = vec2(0.125,0.041666667);
uniform float depth_range = 3.0;
void vertex() {
 // Match the camera used for baking. Geometry depth is restored per pixel.
 vec3 right=INV_VIEW_MATRIX[0].xyz;
 vec3 up=INV_VIEW_MATRIX[1].xyz;
 vec3 back=INV_VIEW_MATRIX[2].xyz;
 MODELVIEW_MATRIX=VIEW_MATRIX*mat4(vec4(right,0.0),vec4(up,0.0),vec4(back,0.0),MODEL_MATRIX[3]);
 MODELVIEW_NORMAL_MATRIX=mat3(MODELVIEW_MATRIX);
}
void fragment() {
 vec2 uv=frame_origin+clamp(UV,vec2(0.002),vec2(0.998))*frame_size;
 vec4 paint=texture(color_atlas,uv);
 if(paint.a<0.5)discard;
 vec4 surface=texture(normal_atlas,uv);
 ALBEDO=paint.rgb;
 NORMAL=normalize(surface.rgb*2.0-1.0);
 vec3 model_position=VERTEX+vec3(0.0,0.0,(surface.a-0.5)*depth_range);
 LIGHT_VERTEX=model_position;
 vec4 projected=PROJECTION_MATRIX*vec4(model_position,1.0);
 // GL Compatibility uses the OpenGL [-1,1] clip-space depth interval.
 DEPTH=projected.z/projected.w*0.5+0.5;
 ROUGHNESS=0.96;SPECULAR=0.0;
}
