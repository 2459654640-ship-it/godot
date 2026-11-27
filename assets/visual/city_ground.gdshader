shader_type spatial;
uniform sampler2D snow_map : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D asphalt_map : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D paving_map : source_color, filter_linear_mipmap, repeat_enable;
uniform int road_count=0;
uniform vec4 segments[48];
uniform float widths[48];
uniform float road_surfaces[48];
uniform vec2 impact_center;
uniform vec2 impact_radii=vec2(7.8,6.7);
varying vec3 wp;
float hash21(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise2(vec2 p){vec2 i=floor(p),f=fract(p);f=f*f*(3.0-2.0*f);return mix(mix(hash21(i),hash21(i+vec2(1,0)),f.x),mix(hash21(i+vec2(0,1)),hash21(i+vec2(1)),f.x),f.y);}
float line_distance(vec2 p,vec4 s){vec2 ba=s.zw-s.xy;return length(p-s.xy-ba*clamp(dot(p-s.xy,ba)/dot(ba,ba),0.0,1.0));}
void vertex(){wp=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
void fragment(){
 vec2 p=wp.xz;float d=10000.0;float second=10000.0;float centre=10000.0;float along=0.0;float road_surface=0.0;
 for(int i=0;i<48;i++){if(i>=road_count){break;}float c=line_distance(p,segments[i]);float edge=c-widths[i]*0.5;if(edge<d){second=d;d=edge;centre=c;road_surface=road_surfaces[i];along=dot(p-segments[i].xy,normalize(segments[i].zw-segments[i].xy));}else{second=min(second,edge);}}
 float grain=noise2(p*2.3);float patch=noise2(p*.12);float snow_edge=smoothstep(-.38,.18,d+(grain-.5)*.16);
 vec3 snow=texture(snow_map,p*.26).rgb;float l=dot(snow,vec3(.299,.587,.114));snow=mix(vec3(.37,.41,.42),vec3(.73,.77,.77),smoothstep(.12,.85,l))*(.84+.16*patch);
 vec3 asphalt=texture(asphalt_map,p*.37).rgb*.70;asphalt=mix(asphalt,snow*.58,smoothstep(.67,.94,patch)*.28);
 vec3 pavement=texture(paving_map,p*.30).rgb*.71;float walk=(1.0-smoothstep(.25+1.45*road_surface,.42+1.45*road_surface,d))*smoothstep(.15,.55,road_surface);vec3 verge=mix(snow,pavement,walk*.9);
 float ash=smoothstep(.43,.72,noise2(p*.09+vec2(13.7,4.2)))*smoothstep(.6,2.6,d);
 verge=mix(verge,mix(asphalt*.9,snow*.72,.35),ash*.62);
 float stripe=(1.0-smoothstep(.035,.07,centre))*step(.1,mod(along,3.0))*step(mod(along,3.0),1.15)*smoothstep(-1.0,.2,second)*step(.48,grain);
 asphalt=mix(pavement*.91,asphalt,smoothstep(.0,.35,road_surface));
 asphalt=mix(asphalt,vec3(.48,.46,.39),stripe*.65*step(.9,road_surface));
 float salted=1.0-smoothstep(.3,1.4,abs(d));
 asphalt=mix(asphalt,snow*.73,salted*smoothstep(.43,.78,noise2(p*.78))*.44);
 float scar_distance=length((p-impact_center)/impact_radii);
 float scar=(1.0-smoothstep(.17,1.03,scar_distance+(noise2(p*.82)-.5)*.25));
 scar*=.8+.20*noise2(p*1.8);
 vec3 earth=mix(snow*.58,texture(asphalt_map,p*.65).rgb*.96,.49);
 ALBEDO=mix(mix(asphalt,verge,snow_edge),earth,scar*.93);ROUGHNESS=.94;SPECULAR=.12;
}
