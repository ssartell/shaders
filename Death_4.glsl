#ifdef GL_FRAGMENT_PRECISION_HIGH
precision highp float;
#else
precision mediump float;
#endif

uniform vec2 resolution;

void main(void) {
	float mx = max(resolution.x, resolution.y);
	vec2 uv = gl_FragCoord.xy / mx;
	vec2 center = resolution / mx * .5;
	uv -= center;

	vec3 col = vec3(0.);

	col += step(-uv.x, uv.y);

	//col = vec3(uv, 0.);

	gl_FragColor = vec4(col, 1.0);
}
