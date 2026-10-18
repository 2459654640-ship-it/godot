shader_type spatial;
render_mode unshaded, cull_disabled;
uniform sampler2D painted_map : source_color, filter_linear_mipmap, repeat_disable;
uniform sampler2D axial_legs_map : source_color, filter_linear_mipmap, repeat_disable;
uniform bool axial_legs = false;
uniform vec2 axial_legs_origin = vec2(0.0);
uniform float axial_legs_width = 1.0;
uniform float axial_legs_exposure = 1.0;
uniform vec2 frame_origin = vec2(0.0);
uniform vec2 frame_size = vec2(0.2,1.0);
uniform vec2 texel_size = vec2(0.001);
uniform bool mirror = false;
uniform float focus : hint_range(0.0,1.0) = 0.0;
uniform vec3 light_tint : source_color = vec3(0.91,0.89,0.82);
uniform float reaction = 0.0;
uniform float down_amount = 0.0;
uniform float shot_recoil = 0.0;
uniform vec2 aim_screen=vec2(0.0);

void vertex() {
	// A vertical Y-locked billboard has genuine geometric body depth.
	// Screen-facing quads tilt through walls; fragment DEPTH overrides can
	// self-fight with the renderer's depth prepass/MSAA. Neither is needed.
	vec3 right=normalize(vec3(INV_VIEW_MATRIX[0].x,0.0,INV_VIEW_MATRIX[0].z));
	vec3 up=vec3(0.0,1.0,0.0);
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(vec4(right,0.0),vec4(up,0.0),vec4(cross(right,up),0.0),MODEL_MATRIX[3]);
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
	if(down_amount>0.1) {
		float x=VERTEX.x;
		VERTEX.x=VERTEX.y*0.82+x*0.35;
		VERTEX.y=0.09+x*0.22;
	}
	float upper=1.0-smoothstep(0.15,0.65,UV.y);
	VERTEX.x+=sin(abs(reaction)*18.0)*upper*0.018*max(-reaction,0.0);
	VERTEX.y-=abs(sin(reaction*14.0))*upper*0.020*max(reaction,0.0);
	// A small upper-body recoil is independent of the lower-body gait.
	float recoil=sin(clamp(shot_recoil,0.0,1.0)*3.14159265);
	float chest=1.0-smoothstep(.38,.65,UV.y);
	VERTEX.xy+=vec2(-aim_screen.x*.025,aim_screen.y*.012)*recoil*chest;
}

vec4 sample_frame(vec2 uv) {
	uv=clamp(uv,vec2(0.003),vec2(0.997));
	if (mirror) uv.x=1.0-uv.x;
	vec4 paint=texture(painted_map,frame_origin+uv*frame_size);
	if(axial_legs && uv.y>.615) {
		vec2 legs_uv=vec2((uv.x-.5)*axial_legs_width+.5,uv.y);
		vec4 legs=texture(axial_legs_map,axial_legs_origin+clamp(legs_uv,vec2(.003),vec2(.997))*vec2(.5,1.0/3.0));
		legs.rgb*=axial_legs_exposure;
		if(legs_uv.x<0.0 || legs_uv.x>1.0)legs=vec4(0.0);
		paint=mix(paint,legs,smoothstep(.615,.64,uv.y));
	}
	return paint;
}

void fragment() {
	vec4 paint=sample_frame(UV);
	if (paint.a < 0.36) {
		vec2 step_uv=texel_size/frame_size*1.6;
		float edge=0.0;
		edge=max(edge,sample_frame(UV+vec2(step_uv.x,0.0)).a);
		edge=max(edge,sample_frame(UV-vec2(step_uv.x,0.0)).a);
		edge=max(edge,sample_frame(UV+vec2(0.0,step_uv.y)).a);
		edge=max(edge,sample_frame(UV-vec2(0.0,step_uv.y)).a);
		if (edge*focus < 0.42) discard;
		ALBEDO=vec3(0.67,0.53,0.30);
	} else {
		ALBEDO=paint.rgb*light_tint;
	}
}
