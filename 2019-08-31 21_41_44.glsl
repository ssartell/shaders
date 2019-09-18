#ifdef GL_FRAGMENT_PRECISION_HIGH
precision highp float;
#else
precision mediump float;
#endif

uniform float time;
uniform int pointerCount;
uniform vec3 pointers[10];
uniform vec2 resolution;

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

void voronoi(vec2 p, out vec3 p1, out vec3 p2) {
	p1 = vec3(999.);
	p2 = vec3(999.);
	vec2 p0 = floor(p) + vec2(.5);
	for(int y = -2; y <= 2; y++) {
		for(int x = -2; x <= 2; x++) {
			vec2 st = vec2(x, y);
			vec2 uv = p0 + st;
			uv = uv + vec2(random(uv) - .5, random(uv.yx) - .5);
			float d = length (uv - p);
			if (d < p1.z) {
				p2 = p1;
				p1 = vec3(uv, d);
			} else if (d < p2.z) {
				p2 = vec3(uv, d);
			}
		}
	}
}

void main(void) {
	float mx = max(resolution.x, resolution.y);
	vec2 uv = gl_FragCoord.xy / mx;
	uv *= 20.;

	vec3 color = vec3(0.);

	vec3 p1;
	vec3 p2;

	voronoi(uv, p1, p2);
	if (length(p1.xy - vec2(5, 10)) < 4.) {
		//color += step(.75, fract(p1.z * 4.));
	}
	color += 1. - step(.05, p1.z);

	float d = dot(uv - (p1.xy + p2.xy) * .5, normalize(p1.xy - p2.xy));
	color += vec3(1. - step(.02, d));

	//color = vec3(d);

	gl_FragColor = vec4(color, 1.0);
}
