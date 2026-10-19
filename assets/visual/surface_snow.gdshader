shader_type spatial;
uniform sampler2D snow_map : source_color, filter_linear_mipmap, repeat_enable;
varying vec3 world_position;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float field(vec2 p){
 vec2 i=floor(p);vec2 f=fract(p);f=f*f*(3.0-2.0*f);
 return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);
}
void vertex(){world_position=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
void fragment(){
 vec2 p=world_position.xz;
 vec3 a=texture(snow_map,p*.075).rgb;
 vec3 b=texture(snow_map,mat2(vec2(.8,-.6),vec2(.6,.8))*p*.12+vec2(.31,.67)).rgb;
 vec3 grain=mix(a,b,.43);
 float drift=mix(.94,1.04,field(p*.11));
 ALBEDO=mix(vec3(.57,.62,.65),grain,.52)*drift;
 ROUGHNESS=.99;
}
