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
uniform sampler2D rory;

const mat4 index = mat4(
	0, 8, 2, 10,
	12, 4, 14, 6,
	3, 11, 1, 9,
	15, 7, 13, 5);

vec3 sample(vec2 uv) {
	return texture2D(cameraFront, uv).xyz;
}

float average(vec3 p) {
	return .2126 * p.x + .7152 * p.y + .0722 * p.z;
}

float indexValue() {
	int x = int(mod(gl_FragCoord.x, 4.));
	int y = int(mod(gl_FragCoord.y, 4.));
	return index[x][y] / 16.0;
}

float dither(float color) {
	return (color < indexValue()) ? 0. : 1.;
}

void main(void) {
	float mx = max(resolution.x, resolution.y);
	vec2 uv = gl_FragCoord.xy / resolution;
	uv = vec2(-uv.x, uv.y) * cameraOrientation;

	vec3 col = vec3(0.);

	col += vec3(dither(average(sample(uv))));

	gl_FragColor = vec4(col, 1.0);
}
