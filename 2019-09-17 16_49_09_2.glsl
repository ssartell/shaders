#ifdef GL_FRAGMENT_PRECISION_HIGH
precision highp float;
#else
precision mediump float;
#endif

uniform vec2 resolution;

void main(void) {
	float mx = min(resolution.x, resolution.y) * .5;
	vec2 uv = gl_FragCoord.xy / mx;
	vec2 center = resolution / mx * .5;
	uv -= center;

	vec3 col = vec3(step(0.5, length(uv)));

	col = clamp(col, 0.0, 1.0);

	gl_FragColor = vec4(col, 1.0);
}
