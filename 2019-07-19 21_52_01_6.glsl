#version 300 es
#ifdef GL_FRAGMENT_PRECISION_HIGH
precision highp float;
precision highp uint;
#else
precision mediump float;
#endif

uniform vec2 resolution;
uniform int frame;
out vec4 fragmentColor;

uint part1by1(uint n) {
	n &= 0x0000ffffu;
	n = (n | (n << 8)) & 0x00FF00FFu;
	n = (n | (n << 4)) & 0x0F0F0F0Fu;
	n = (n | (n << 2)) & 0x33333333u;
	n = (n | (n << 1)) & 0x55555555u;
	return n;
}

uint xy2d(vec2 uv) {
	return part1by1(uint(uv.x)) | (part1by1(uint(uv.y)) << 1);
}

void main(void) {
	float mx = max(resolution.x, resolution.y);
	vec2 uv = gl_FragCoord.xy / mx;
	vec2 center = resolution / mx * .5;
	uv -= center;
	uv *= 1024.;
	uv = abs(uv);
	uv = pow(uv, vec2(1.4));

	float m = pow(2., 20.);
	float t = float(frame) * 2000.;
	float r = mod(float(xy2d(uv)) - t, m) / m;
	float g = mod(float(xy2d(uv)) - t + m / 3., m) / m;
	float b = mod(float(xy2d(uv)) - t + m * 2. / 3., m) / m;

	fragmentColor = vec4(r, g, b, 1.0);
}
