#version 300 es
#ifdef GL_FRAGMENT_PRECISION_HIGH
precision highp float;
precision highp uint;
#else
precision mediump float;
#endif

uniform vec2 resolution;
uniform float time;
out vec4 fragmentColor;

uint part1by1(uint n) {
	n &= 0x0000ffffu;
	n = (n | (n << 8)) & 0x00FF00FFu;
	n = (n | (n << 4)) & 0x0F0F0F0Fu;
	n = (n | (n << 2)) & 0x33333333u;
	n = (n | (n << 1)) & 0x55555555u;
	return n;
}

uint unpart1by1(uint n) {
	n &= 0x55555555u;
	n = (n ^ (n >> 1)) & 0x33333333u;
	n = (n ^ (n >> 2)) & 0x0f0f0f0fu;
	n = (n ^ (n >> 4)) & 0x00ff00ffu;
	n = (n ^ (n >> 8)) & 0x0000ffffu;
	return n;
}

uint xy2d(vec2 uv) {
	return part1by1(uint(uv.x)) | (part1by1(uint(uv.y)) << 1);
}

vec2 d2xy(uint n) {
	return vec2(unpart1by1(n), unpart1by1(n >> 1));
}

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
	float mx = min(resolution.x, resolution.y);
	vec2 uv = gl_FragCoord.xy * (1024. / resolution.x);
	float m = pow(4., 10.);
	float r = mod(float(xy2d(uv)), m);

	vec3 col = vec3(0);

	for(float i = 10.; i >= 1.; i--) {
		float factor = pow(4., i);
		float d = floor(r / factor) * factor;
		vec2 st = d2xy(uint(d)) / mx;
		float val = fbm(st * 6. + time);
		col += val * val / (11. - i) * vec3(st, 1.);
	}

	//col /= 10.;

	fragmentColor = vec4(col, 1.0);
}
