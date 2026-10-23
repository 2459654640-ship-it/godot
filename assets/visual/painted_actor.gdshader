shader_type spatial;
render_mode unshaded, cull_disabled;
uniform sampler2D painted_map : source_color, filter_linear_mipmap, repeat_disable;
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
uniform float puppet_stride = 0.0;
uniform float gait_scale = 1.0;
uniform vec2 puppet_direction = vec2(0.0);
uniform float idle_time = 0.0;
uniform float idle_amount = 0.0;
uniform float idle_members = 1.0;
uniform float crowd_motion = 0.0;

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
	// Deform the leg mesh itself, preserving every painted pixel. Moving UVs
	// across the centre seam clips a boot on narrow side views.
	float leg=(1.0-2.0*smoothstep(.46,.54,UV.x))*(mirror ? -1.0 : 1.0);
	float phase=puppet_stride*leg;
	float lower=smoothstep(.61,.96,UV.y);
	float knee=sin(clamp((UV.y-.61)/.35,0.0,1.0)*3.14159265);
	// Step along the facing axis, including actual depth for front/back views.
	// A lateral knee wave makes straight walking look bow-legged; never add it.
	VERTEX.x+=phase*puppet_direction.x*.075*lower*gait_scale;
	VERTEX.z+=phase*puppet_direction.y*.095*lower*gait_scale;
	VERTEX.y+=max(0.0,phase)*(.030*lower+.008*knee)*gait_scale;
	// Small independent breaths, with feet fixed. Subdivided crowd quads let
	// neighbours move on different rhythms instead of swaying as one card.
	float member=floor(min(UV.x,.999)*idle_members);
	float breath=sin(idle_time*(1.55+member*.13)+member*2.37);
	float resting=(1.0-smoothstep(.48,.94,UV.y))*idle_amount;
	VERTEX.y+=breath*mix(.006,.020,crowd_motion)*resting;
	VERTEX.x+=sin(idle_time*.71+member*1.83)*mix(.005,.014,crowd_motion)*resting;
	// Background residents occasionally turn their head or adjust a hand.
	// Feet, seats and chair backs stay anchored; only the figure's upper mesh moves.
	float head=1.0-smoothstep(.23,.40,UV.y);
	float glance=sin(idle_time*.47+member*2.1);
	VERTEX.x+=glance*.018*head*crowd_motion;
	float gesture=pow(max(0.0,sin(idle_time*.63+member*2.7)),8.0);
	float hands=smoothstep(.40,.49,UV.y)*(1.0-smoothstep(.64,.73,UV.y));
	VERTEX.y+=gesture*.018*hands*crowd_motion;
}

vec4 sample_frame(vec2 uv) {
	uv=clamp(uv,vec2(0.003),vec2(0.997));
	if (mirror) uv.x=1.0-uv.x;

	vec4 paint=texture(painted_map,frame_origin+uv*frame_size);
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
