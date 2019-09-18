#ifdef GL_FRAGMENT_PRECISION_HIGH
precision highp float;
#else
precision mediump float;
#endif

uniform vec2 resolution;
uniform sampler2D backbuffer;
uniform vec2 touch;

float random(vec2 p) {
	return fract(sin(dot(p, vec2(12.75, 8.92))) * 53638.97582);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);

	float a = random(i);
	float b = random(i + vec2(1., 0.));
	float c = random(i + vec2(0., 1.));
	float d = random(i + vec2(1., 1.));

	f = f * f * (3. - 2. * f);

	return mix(mix(a,b,f.x),mix(c,d,f.x), f.y);
}

float fbm(vec2 p) {
	float a = .5;
	float f = 1.;
	float y = 0.;

	for(int i = 0; i < 8; i++) {
		y += a * noise(f * p);
		f *= 2.;
		a *= .5;
	}

	return y;
}

void main(void) {
	vec2 uv = gl_FragCoord.xy;
	vec2 st = gl_FragCoord.xy / resolution;

	vec3 col = vec3(0.);

	col = texture2D(backbuffer, st + vec2(0., 1. / resolution.y)).xyz;

	if (length(touch - uv) < 1.) {
		col += vec3(1.);
	}

	gl_FragColor = vec4(col, 1.0);
}
