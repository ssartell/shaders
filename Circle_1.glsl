#ifdef GL_FRAGMENT_PRECISION_HIGH
precision highp float;
#else
precision mediump float;
#endif

uniform vec2 resolution;

float circle(vec2 uv, vec2 p, float r, float s) {
	float l = length(uv - p);
	return step(r - s, l) - step(r + s, l);
}

float box(vec2 uv, vec2 p, vec2 d) {
	vec2 p1 = p + d;
	return step(p.x, uv.x) * step(p.y, uv.y)
		* (1. - step(p1.x, uv.x))
		* (1. - step(p1.y, uv.y));
}

float box2(vec2 uv, vec2 p, vec2 d) {
	vec2 p0 = p - d;
	return box(uv, p0, d * 2.);
}

void main(void) {
	float mx = min(resolution.x, resolution.y) * .5;
	vec2 uv = gl_FragCoord.xy / mx;
	vec2 center = resolution / mx * .5;
	uv -= center;

  vec3 col = vec3(0);

  //col += circle(uv, vec2(0), .9, .1)
  //	* (1. - circle(uv, vec2(0), .9, .05));

  col += box2(uv, vec2(0), vec2(.5));

	gl_FragColor = vec4(col, 1.0);
}
