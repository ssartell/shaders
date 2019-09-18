#ifdef GL_FRAGMENT_PRECISION_HIGH
precision highp float;
#else
precision mediump float;
#endif

uniform vec2 resolution;
uniform vec3 rotationVector;
uniform vec3 gravity;
uniform float startRandom;
uniform vec3 orientation;

float PI = 3.14159;

void main(void) {
	vec2 uv = gl_FragCoord.xy / resolution.xy;

	vec3 dir = normalize(vec3(
		sin(orientation.x) * cos(orientation.y),
		sin(orientation.y),
		cos(orientation.x) * cos(orientation.y)
	));
	vec3 north = vec3(0.0, 0.0, 1.0);
	vec3 col = vec3(dot(dir, north) / 2.0 + 0.5);
	col = vec3(step(0.75, cos(orientation.x)));
	gl_FragColor = vec4(col, 1.0);
}
