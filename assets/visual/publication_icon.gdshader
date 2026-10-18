shader_type canvas_item;
uniform bool unknown=false;
void fragment(){
	vec4 paper=texture(TEXTURE,UV);
	COLOR=unknown ? vec4(vec3(.10,.14,.13),paper.a) : paper;
}
