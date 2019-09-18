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

float voronoi(vec2 p, out vec3 p1, out vec3 p2) {
	p1 = vec3(999.);
	p2 = vec3(999.);
	vec2 c0 = floor(p);
	vec2 c1;
	float d1;
	for(int y = -1; y <= 1; y++) {
		for(int x = -1; x <= 1; x++) {
			vec2 c = c0 + vec2(x, y);
			vec2 uv = c + vec2(random(c), random(c.yx));
			float d = length (uv - p);
			if (d < p1.z) {
				p1 = vec3(uv, d);
				c1 = c;
				d1 = d;
			}
		}
	}

	float d2 = 999.;
	for(int y = -1; y <= 1; y++) {
		for(int x = -1; x <= 1; x++) {
			vec2 c = c1 + vec2(x, y);
			vec2 uv = c + vec2(random(c), random(c.yx));
			float d = dot(uv - (p1.xy + uv.xy) * .5, normalize(uv.xy - p1.xy));
			d2 = min(d2, d);
		}
	}
	return d2;
}

void main(void) {
	float mx = max(resolution.x, resolution.y);
	vec2 uv = gl_FragCoord.xy / mx;
	uv *= 20.;

	vec3 color = vec3(0.);

	vec3 p1;
	vec3 p2;

	float dd = voronoi(uv, p1, p2);
	if (length(p1.xy - vec2(5, 10)) < 4.) {
		//color += step(.75, fract(p1.z * 4.));
	}

	//float d = dot(uv - (p1.xy + p2.xy) * .5, normalize(p1.xy - p2.xy));
	color += vec3(1. - step(.05, dd));

	//color = vec3(dd);

	gl_FragColor = vec4(color, 1.0);
}
