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

vec3 kernel(vec2 uv, mat3 k) {
	vec3 t = vec3(0.);
	for(int i = 0; i < 3; i++) {
		for(int j = 0; j < 3; j++) {
			vec2 st = vec2(i - 1, j - 1) / resolution;
			vec3 col = texture2D(cameraFront, uv + st).xyz;
			t += k[i][j] * col;
		}
	}

	//t = texture2D(img, uv + vec2(500) / resolution).xyz;
	return t;
}

float edge(vec2 uv) {
	float gx = 0.;
	return gx;
}

void main(void) {
	float mx = max(resolution.x, resolution.y);
	vec2 uv = gl_FragCoord.xy / resolution;
	uv = vec2(-uv.x, uv.y) * cameraOrientation;

	vec3 col = vec3(0.);

	//col += texture2D(cameraFront, uv).xyz;

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

	col = vec3(sqrt(ax * ax + ay * ay));

	//float avg = (col.x + col.y + col.z) / 3.;
	//float n = 5.;
	//col = floor(vec3(avg) * n) / (n - 1.);

	gl_FragColor = vec4(col, 1.0);
}
