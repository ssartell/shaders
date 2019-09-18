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
	float mx = max(resolution.x, resolution.y);
	vec2 uv = gl_FragCoord.xy / resolution;
	vec2 st = uv;
	vec2 center = resolution / mx * .5;
	st -= center;
	st *= 20.;
	vec3 color = vec3(0.);

	color += .05 * texture2D(cameraFront, vec2(-uv.x, uv.y) * cameraOrientation).xyz;

	uv += .005 * (vec2(fbm(st + vec2(0., time)), fbm(st + vec2(5.7,12.3 + time))) * 2. - 1.);
	color += .95 * texture2D(backbuffer, uv).xyz;

	gl_FragColor = vec4(color, 1.0);
}
