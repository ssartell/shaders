#version 300 es
#extension GL_OES_EGL_image_external_essl3 : enable
#ifdef GL_FRAGMENT_PRECISION_HIGH
precision highp float;
precision highp uint;
#else
precision mediump float;
precision mediump uint;
#endif

uniform vec2 resolution;
uniform samplerExternalOES cameraFront;
uniform mat2 cameraOrientation;
out vec4 fragmentColor;

vec3 camera(vec2 uv) {
	uv = vec2(-uv.x, uv.y) * cameraOrientation;
	return texture(cameraFront, uv).xyz;
}

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

void main(void) {
	vec2 mx = (1024. / resolution);
	vec2 uv = gl_FragCoord.xy * mx;
	uint d = xy2d(uv);

	vec3 col = camera(d2xy(d) / 1024.);

	for(int i = 0; i <= 10; i++) {
		int j = 2 * i;
		d = d >> j << j;
		vec3 col1 = camera(d2xy(d) / 1024.);
		float diff = length(col - col1);
		if (diff > .1) {
			break;
		}
		col = col1;
	}

	fragmentColor = vec4(col, 1.0);
}
