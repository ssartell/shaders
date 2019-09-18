#ifdef GL_FRAGMENT_PRECISION_HIGH
precision highp float;
#else
precision mediump float;
#endif

uniform vec2 resolution;
uniform samplerExternalOES cameraBack;
uniform mat2 cameraOrientation;
uniform sampler2D backbuffer;

void main(void) {
	float mx = max(resolution.x, resolution.y);
	vec2 uv = gl_FragCoord.xy / resolution;

	vec3 color = vec3(0.);

	float v = .04;

	color += (1. - v) * texture2D(backbuffer, uv).xyz;
	color += v * texture2D(cameraBack, vec2(uv.x, uv.y) * cameraOrientation).xyz;


	gl_FragColor = vec4(color, 1.0);
}
