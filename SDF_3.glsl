#ifdef GL_FRAGMENT_PRECISION_HIGH
precision highp float;
#else
precision mediump float;
#endif

uniform vec2 resolution;
uniform float time;
uniform vec3 pointers[10];
uniform int pointerCount;

float smin( float a, float b, float k ) {
	float h = max( k-abs(a-b), 0.0 )/k;
	return min( a, b ) - h*h*k*(1.0/4.0);
}

float map(vec3 p) {
	vec3 q = vec3(
		mod(p.x + 0.25, 0.5) - 0.25,
		p.y,
		mod(p.z + 0.25, 0.5) - 0.25);
	float d = length(q) - 0.15;

	vec3 q2 = vec3(
		p.x,
		p.y + sin(p.x) * 0.1 + sin(p.z) * 0.1,
		p.z);
	float d2 = q2.y + 0.0;

	//return smin(d, d2, 0.2);
	return min(d, d2);
}

float calcOcclusion( in vec3 pos, in vec3 nor)
{
	float occ = 0.0;
    float sca = 1.0;
    for( int i=0; i<5; i++ )
    {
        float h = 0.01 + 0.11*float(i)/4.0;
        vec3 opos = pos + h*nor;
        float d = map( opos );
        occ += (h-d)*sca;
        sca *= 0.95;
    }
    return clamp( 1.0 - 2.0*occ, 0.0, 1.0 );
}

vec3 calcNormal(vec3 p) {
	vec2 e = vec2(0.0001, 0.0);
	return normalize (vec3(
		map(p + e.xyy) - map(p - e.xyy),
		map(p + e.yxy) - map(p - e.yxy),
		map(p + e.yyx) - map(p - e.yyx)));
}

float castRay(vec3 ro, vec3 rd) {
	float t = 0.0;
	for(int i = 0; i < 100; i++) {
		vec3 pos = ro + t * rd;
		float h = map(pos);
		if (abs(h) < 0.001 * t) break;
		t += h;
		if (t > 20.0) break;
	}
	if (t > 20.0) t = 0.0;

	return t;
}

float softShadow(vec3 ro, vec3 rd, float k) {
	float res = 1.0;
	float t = 0.0;
	for(int i = 0; i < 100; i++) {
		vec3 pos = ro + t * rd;
		float h = map(pos);
		res = min(res, k*h/t);
		if (abs(res) < 0.001 * t) break;
		t += h;
		if (t > 20.0) break;
	}
	return clamp(res, 0.0, 1.0);
}

void main(void) {
	vec2 p = (2.0 * gl_FragCoord.xy - resolution.xy) / resolution.y;

	float ti = time / 2.0;
	if (pointerCount > 0) {
		ti = pointers[0].x / resolution.x * 3.1416 * 2.0;
	}

	vec3 ro = vec3(cos(ti), 0.3, sin(ti));
	vec3 ta = vec3(0.0, 0.0, 0.0);

	// camera axes
	vec3 ww = normalize(ta - ro);
	vec3 uu = normalize(cross(ww, vec3(0,1,0)));
	vec3 vv = normalize(cross(uu, ww));

	vec3 rd = normalize(p.x*uu + p.y*vv + 1.5*ww);

	float t = castRay(ro, rd);

	// sky
	vec3 col = vec3(0.4, 0.8, 1.0) - 0.7 * rd.y;
	col = mix(col, vec3(0.7, 0.9, 0.9), exp(-15.0 * rd.y));

	if (t > 0.0) {
		vec3 pos = ro + t * rd;
		vec3 nor = calcNormal(pos);
		vec3 ref = reflect(rd, nor);

		vec3 mat = vec3(0.05,0.09,0.02);
		float ks = 0.05;

		float occ = calcOcclusion(pos,   nor);
		float fre = clamp(1.0 - dot(nor, -rd), 0.0, 1.0);

		vec3  sun_dir = normalize(vec3(1.0, 0.5, 0.4));
		float sun_dif = clamp(dot(nor, sun_dir), 0.0, 1.0);
		vec3  sun_hal = normalize( sun_dir - rd );
		float sun_spe = ks*pow(clamp(dot(nor,sun_hal),0.0,1.0),32.0) * sun_dif;
		float sun_sha = softShadow(pos + 0.001 * nor, sun_dir, 16.0);//1.0 - step(0.0, castRay(pos + 0.001 * nor, sun_dir));
		vec3  sky_dir = normalize(vec3(0.0, 1.0, 0.0));
		float sky_dif = clamp(0.5 + 0.5 * dot(nor, sky_dir), 0.0, 1.0);
		float sky_spe = smoothstep(0.0, 0.5, ref.y);
		float bou_dif = clamp(0.5 + 0.5 * dot(nor, vec3(0.0, -1.0, 0.0)), 0.0, 1.0);
		float sss_dif = fre*sky_dif*(0.25+0.75*sun_dif*sun_sha);

		vec3 lin = vec3(0.0);

		lin += sun_dif * vec3(8.0, 6.0, 4.0) * sun_sha;
		lin += sky_dif * vec3(0.5, 0.7, 1.0) * 2.0 * occ;
		lin += bou_dif * vec3(0.4, 0.3, 0.2) * occ;
		lin += sss_dif * vec3(3.2, 2.7, 2.5) * occ;

		//lin += vec3(1.0, 0.7, 0.5) * fre * sun_dif * 1.0;

		//col = vec3(sun_sha);

		col = mat * lin;

		col += sun_spe*vec3(8.0, 6.0, 4.0) * sun_sha;
		col += sky_spe*vec3(0.5, 0.7, 1.0) * 0.2 * occ * fre;

		col = pow(col,vec3(0.8,0.9,1.0) );

		// fog
		col = mix(col, vec3(0.7, 0.9, 0.9), 1.0-exp(-0.0005*t*t*t));
		//col = vec3(sky_spe);
	}

	col = pow(col, vec3(0.4545));

	gl_FragColor = vec4(col, 1.0);
}
