shader_type spatial;
render_mode specular_disabled;
uniform sampler2D albedo_map:source_color,filter_linear_mipmap,repeat_enable;
uniform float map_scale=.24;
uniform vec4 base_color:source_color=vec4(1.0);
varying vec3 world_position;
void vertex(){world_position=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
vec3 surface(vec2 coordinates){
	vec2 uv=fract(coordinates);
	vec2 edge=smoothstep(vec2(.32),vec2(.49),abs(uv-vec2(.5)));
	vec3 a=texture(albedo_map,uv).rgb;
	vec3 b=texture(albedo_map,fract(uv+vec2(.5,0.0))).rgb;
	vec3 c=texture(albedo_map,fract(uv+vec2(0.0,.5))).rgb;
	vec3 d=texture(albedo_map,fract(uv+vec2(.5,.5))).rgb;
	return mix(mix(a,b,edge.x),mix(c,d,edge.x),edge.y);
}
vec2 offset_for(vec2 cell){
	return fract(sin(vec2(dot(cell,vec2(127.1,311.7)),dot(cell,vec2(269.5,183.3))))*43758.5453);
}
void fragment(){
	vec2 uv=world_position.xz*map_scale;
	// Blend three stable, differently offset samples on a triangular grid.
	// A regular square blend repeated the photograph's light/dark patches.
	vec2 grid=vec2(uv.x-uv.y*.57735027,uv.y*1.15470054);
	vec2 cell=floor(grid);vec2 f=fract(grid);
	vec2 a=cell;vec2 b=cell+vec2(1.0,0.0);vec2 c=cell+vec2(0.0,1.0);
	vec3 weights=vec3(1.0-f.x-f.y,f.x,f.y);
	if(f.x+f.y>1.0){a=cell+vec2(1.0);weights=vec3(f.x+f.y-1.0,1.0-f.y,1.0-f.x);}
	weights=weights*weights;weights/=dot(weights,vec3(1.0));
	ALBEDO=(surface(uv+offset_for(a))*weights.x+surface(uv+offset_for(b))*weights.y+surface(uv+offset_for(c))*weights.z)*base_color.rgb;
	ROUGHNESS=.97;
}
