#ifdef GL_FRAGMENT_PRECISION_HIGH
precision highp float;
#else
precision mediump float;
#endif

uniform float time;
uniform int pointerCount;
uniform vec3 pointers[10];
uniform vec2 resolution;
uniform samplerExternalOES cameraFront;
uniform sampler2D backbuffer;
uniform vec2 cameraAddent;
uniform mat2 cameraOrientation;

vec3 sample(vec2 uv) {
	return texture2D(cameraFront, uv).xyz;
}

vec3 kernel(vec2 uv, mat3 k) {
	vec3 t = vec3(0.);
	for(int i = 0; i < 3; i++) {
		for(int j = 0; j < 3; j++) {
			vec2 st = vec2(i - 1, j - 1) / resolution;
			vec3 col = sample(uv + st).xyz;
			t += k[i][j] * col;
		}
	}

	return t;
}

float edge(vec2 uv) {
	float gx = 0.;
	return gx;
}

float average(vec3 p) {
	return (p.x + p.y + p.z) / 3.;
}

void main(void) {
	float mx = max(resolution.x, resolution.y);
	vec2 uv = gl_FragCoord.xy / resolution;
	uv = vec2(-uv.x, uv.y) * cameraOrientation;

	vec3 col = vec3(0.);

	col += sample(uv);
	col = vec3(sqrt(average(col)));
	float n = 5.;
	col = floor(col * n) / (n - 1.);

	mat3 gx = mat3(
		-1., 0., 1.,
		-2., 0., 2.,
		-1., 0., 1.);

	mat3 gy = mat3(
		-1., -2., -1.,
		0., 0., 0.,
		1., 2., 1.);

	vec3 ax = kernel(uv, gx);
	vec3 ay = kernel(uv, gy);
	//vec3 g = sqrt(ax * ax + ay * ay);
	vec3 g = ax + ay;
	col *= 1. - 1. * average(g);

	gl_FragColor = vec4(col, 1.0);
}
