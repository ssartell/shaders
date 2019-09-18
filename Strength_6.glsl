#ifdef GL_FRAGMENT_PRECISION_HIGH
precision highp float;
#else
precision mediump float;
#endif

uniform vec2 resolution;

void main(void) {
	vec2 uv = gl_FragCoord.xy / resolution;

	vec3 col = vec3(0.);
	col += step(.5 + .25 * sin(uv.y * 2. * 3.14159), uv.x);

	gl_FragColor = vec4(col, 1.0);
}
