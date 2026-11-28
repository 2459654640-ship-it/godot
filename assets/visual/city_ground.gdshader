shader_type spatial;
uniform sampler2D snow_map : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D asphalt_map : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D paving_map : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D weather_field : filter_linear, repeat_disable;
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
 vec2 p=wp.xz;
 float d=10000.0;float second=10000.0;float centre=10000.0;float along=0.0;float road_surface=0.0;
 for(int i=0;i<48;i++){
  if(i>=road_count){break;}
  float c=line_distance(p,segments[i]);float edge=c-widths[i]*0.5;
  if(edge<d){second=d;d=edge;centre=c;road_surface=road_surfaces[i];along=dot(p-segments[i].xy,normalize(segments[i].zw-segments[i].xy));}
  else{second=min(second,edge);}
 }
 // Authored drifts shelter behind masonry and vehicles. Pedestrians have
 // exposed the paving along platforms, doorways and the west access.
 vec3 site=texture(weather_field,(p+vec2(120.0,100.0))/vec2(240.0,200.0)).rgb;
 float grain=noise2(p*3.7);
 float patch=noise2(p*.085+vec2(16.2,4.7));
 float wind=noise2(p*vec2(.54,.24)+vec2(2.1,14.6));
 float edge=d+(grain-.5)*.35+(wind-.5)*.98+site.r*.70;
 float verge_blend=smoothstep(-.48,.76,edge);
 vec3 powder=texture(snow_map,p*.28).rgb;
 float luma=dot(powder,vec3(.299,.587,.114));
 vec3 snow=mix(vec3(.215,.24,.267),vec3(.547,.583,.617),smoothstep(.14,.87,luma));
 snow*=.76+.20*patch+.10*site.r;
 vec3 asphalt=texture(asphalt_map,p*.29).rgb;
 asphalt=mix(asphalt,texture(asphalt_map,p*.103+vec2(.68,.31)).rgb,.30);
 asphalt*=.78+.24*patch;
 vec3 pavement=texture(paving_map,p*.34).rgb*(.72+.19*wind);
 float alley=smoothstep(.17,.57,road_surface);
 float curb=(1.0-smoothstep(.12,1.9,max(d,0.0)))*alley;
 float drifts=smoothstep(.37,.81,wind*.68+patch*.32+site.r*.34);
 float clear_walk=max(curb*(.52+.31*(1.0-drifts)),site.b*.92);
 float snow_cover=verge_blend*(1.0-clear_walk);
 float plow=smoothstep(.08,.39,abs(centre-1.42+(wind-.5)*.29));
 float slush=smoothstep(-1.28,-.08,edge)*smoothstep(.27,.75,wind*.76+grain*.24)*plow;
 snow_cover=max(snow_cover,slush*.51);
 float wet_lane=(1.0-smoothstep(.12,1.12,abs(d+.40)))*(.45+.55*alley);
 float pooling=smoothstep(.52,.67,wind*.57+patch*.31+noise2(p*vec2(.25,.71))*.12);
 float wet=max(wet_lane*pooling,site.b*(.32+pooling*.22))*(1.0-snow_cover);
 float ice=wet*smoothstep(.49,.78,patch)*(1.0-smoothstep(.26,.62,grain));
 asphalt=mix(asphalt,pavement,1.0-smoothstep(.04,.50,road_surface));
 float stripe=(1.0-smoothstep(.04,.10,centre))*step(.1,mod(along,3.0))*step(mod(along,3.0),1.15)*smoothstep(-1.0,.2,second)*step(.55,grain);
 asphalt=mix(asphalt,vec3(.35,.33,.27),stripe*.55*step(.9,road_surface));
 vec3 hard_surface=mix(asphalt,pavement,smoothstep(-.14,.43,d)*max(curb,site.b));
 hard_surface*=1.0-wet*.48;
 hard_surface=mix(hard_surface,vec3(.135,.161,.183),ice*.33);
 vec3 thaw=mix(hard_surface,snow,snow_cover);
 // Low-frequency grit keeps unmaintained open lots from reading as one
 // uniformly white plane even well away from the featured streets.
 float ash=smoothstep(.56,.85,noise2(p*.067+vec2(13.7,4.2)))*smoothstep(1.2,5.6,d)*(1.0-site.r);
 thaw=mix(thaw,mix(asphalt,snow*.65,.60),ash*.63);
 float scar_distance=length((p-impact_center)/impact_radii);
 float scar=(1.0-smoothstep(.17,1.03,scar_distance+(noise2(p*.82)-.5)*.25));
 scar*=.8+.20*noise2(p*1.8);
 vec3 earth=mix(snow*.55,texture(asphalt_map,p*.65).rgb*.94,.58);
 ALBEDO=mix(thaw,earth,scar*.89)*(1.0-site.g*.28);
 AO=1.0-site.g*.37;
 ROUGHNESS=mix(.91,.22,wet*(1.0-scar));
 SPECULAR=mix(.15,.56,wet*(1.0-scar));
}
