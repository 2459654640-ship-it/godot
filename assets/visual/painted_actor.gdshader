shader_type spatial;
render_mode unshaded, cull_disabled;
uniform sampler2D painted_map : source_color, filter_linear_mipmap, repeat_disable;
uniform vec2 frame_origin = vec2(0.0);
uniform vec2 frame_size = vec2(0.2,1.0);
uniform vec2 texel_size = vec2(0.001);
uniform bool mirror = false;
uniform float focus : hint_range(0.0,1.0) = 0.0;
uniform vec3 light_tint : source_color = vec3(0.91,0.89,0.82);
uniform float gait = 0.0;
uniform float motion = 0.0;
uniform float reaction = 0.0;
uniform int part = 0;
uniform float hem = 0.60;
uniform bool side_view = false;
uniform vec2 stride_axis = vec2(0.0,1.0);
uniform float step_length = 0.18;
uniform float down_amount = 0.0;
uniform float frame_pixels = 240.0;

void vertex() {
	// A vertical Y-locked billboard has genuine geometric body depth.
	// Screen-facing quads tilt through walls; fragment DEPTH overrides can
	// self-fight with the renderer's depth prepass/MSAA. Neither is needed.
	vec3 right=normalize(vec3(INV_VIEW_MATRIX[0].x,0.0,INV_VIEW_MATRIX[0].z));
	vec3 up=vec3(0.0,1.0,0.0);
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(vec4(right,0.0),vec4(up,0.0),vec4(cross(right,up),0.0),MODEL_MATRIX[3]);
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
	if(part!=0) {
		float phase=gait+(part<0 ? 3.14159265 : 0.0);
		float weight=smoothstep(hem,0.96,UV.y);
		float knee=sin(clamp((UV.y-hem)/(0.98-hem),0.0,1.0)*3.14159265);
		float mirror_sign=mirror ? -1.0 : 1.0;
		VERTEX.x+=sin(phase)*weight*stride_axis.x*step_length*mirror_sign;
		VERTEX.y+=sin(phase)*weight*stride_axis.y*0.075;
		VERTEX.y+=max(0.0,sin(phase))*weight*0.055+knee*max(0.0,sin(phase))*0.025;
		// Side views share one consistent trouser/boot drawing for both legs.
		VERTEX.z+=part<0 ? -0.004 : 0.004;
	}
	if(part==0 && motion>0.1) {
		float arm=(1.0-smoothstep(0.30,0.44,UV.x)+smoothstep(0.56,0.70,UV.x))*smoothstep(0.30,0.49,UV.y)*(1.0-smoothstep(0.58,0.65,UV.y));
		float phase=gait+(UV.x<0.5 ? 0.0 : 3.14159265);
		VERTEX.y+=sin(phase)*arm*0.018;
	}
	if(down_amount>0.1) {
		float x=VERTEX.x;
		VERTEX.x=VERTEX.y*0.82+x*0.35;
		VERTEX.y=0.09+x*0.22;
	}
	float upper=1.0-smoothstep(0.15,0.65,UV.y);
	VERTEX.x+=sin(abs(reaction)*18.0)*upper*0.018*max(-reaction,0.0);
	VERTEX.y-=abs(sin(reaction*14.0))*upper*0.020*max(reaction,0.0);
}

vec4 sample_frame(vec2 uv) {
	uv=clamp(uv,vec2(0.003),vec2(0.997));
	if (mirror) uv.x=1.0-uv.x;
	return texture(painted_map,frame_origin+uv*frame_size);
}

void fragment() {
	if (motion>0.1) {
		if(part==0 && UV.y>hem) discard;
		if(part!=0) {
			if(UV.y<hem-0.012) discard;
			float x=mirror ? 1.0-UV.x : UV.x;
			if(!side_view && ((part<0 && x>0.5) || (part>0 && x<=0.5))) discard;
			// A profile idle already contains a second, raised far boot. Both
			// articulated legs reuse the lowest planted leg, excluding that boot.
			if(side_view && UV.y>0.80 && UV.y<0.925) {
				float edge=mix(32.0,16.0,smoothstep(0.80,0.885,UV.y));
				edge=mix(edge,90.0,smoothstep(0.885,0.925,UV.y));
				if((x-0.5)*frame_pixels>edge) discard;
			}
		}
	} else if(part!=0) discard;
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
		ALBEDO=paint.rgb*light_tint*(part<0 && side_view ? 0.82 : 1.0);
	}
}
