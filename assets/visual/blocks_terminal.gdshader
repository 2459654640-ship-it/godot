shader_type spatial;
render_mode unshaded;
void fragment(){
	vec2 cell=floor(UV*vec2(10.,14.));
	float block=step(8.-mod(cell.x*7.,4.),cell.y);
	block=max(block,step(abs(cell.x-5.),.5)*step(abs(cell.y-3.),1.5));
	float seams=step(.08,fract(UV.x*10.))*step(.08,fract(UV.y*14.));
	float scan=.95+.05*sin(UV.y*350.);
	ALBEDO=(vec3(.014,.045,.035)+vec3(.15,.34,.19)*block*seams)*scan;
}
