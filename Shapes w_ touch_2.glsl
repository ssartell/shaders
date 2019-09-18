#ifdef GL_FRAGMENT_PRECISION_HIGH
precision highp float;
#else
precision mediump float;
#endif
#define PI 3.141592653
#define TWO_PI 6.28318530

uniform vec2 resolution;
uniform int pointerCount;

void main(void) {
	float mx = max(resolution.x, resolution.y);
	vec2 uv = gl_FragCoord.xy / mx;
	vec2 center = resolution / mx * .5;
	uv -= center;

	vec3 col = vec3(0.);

	float a = atan(uv.y, uv.x) + PI / 2.;
  float l = length(uv);
  float n = float(pointerCount) + 3.;
  float k = TWO_PI / n;

  col += 1. - step(.1, l * cos(floor(a / k + .5) * k - a));

	gl_FragColor = vec4(col, 1.0);
}
