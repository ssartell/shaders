#ifdef GL_FRAGMENT_PRECISION_HIGH
precision highp float;
#else
precision mediump float;
#endif

uniform vec2 resolution;
uniform float time;
uniform vec3 pointers[10];
uniform int pointerCount;

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

	f = f * f * (3.0 - 2.0 * f);

	return mix(mix(a,b,f.x),mix(c,d,f.x), f.y);
}

float fbm(vec2 p) {
	float a = .5;
	float f = 1.;
	float y = 0.;

	for(int i = 0; i < 6; i++) {
		y += a * noise(f * (p + time * sin(f) / f));
		f *= 2.;
		a *= .5;
	}

	return y;
}

float smin( float a, float b, float k ) {
	float h = max( k-abs(a-b), 0.0 )/k;
	return min( a, b ) - h*h*k*(1.0/4.0);
}

float map(vec3 p) {
	vec3 q = vec3(
		mod(p.x + 1.0, 2.0) - 1.0,
		p.y,
		mod(p.z + 1.0, 2.0) - 1.0);

	float d = length(q) - 0.15;
	vec3 q2 = vec3(p.x, p.y + fbm(p.xz + vec2(0.5)) * 0.2, p.z);
	float d2 = q2.y + 0.15;

	return d2;
	//return smin(d, d2, 0.2);
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
        sca *= 0.9;
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

float softShadow(vec3 ro, vec3 nor, vec3 rd, float k) {
	if (dot(nor, rd) < 0.0) return 0.0;
	ro = ro + nor * 0.001;
	float res = 1.0;
	float t = 0.0;
	for(int i = 0; i < 100; i++) {
		vec3 pos = ro + t * rd;
		float h = map(pos);
		res = min(res, k*max(h, 0.0)/t);
		if (abs(res) < 0.001) break;
		t += h;
		if (t > 20.0) break;
	}
	return clamp(res, 0.0, 1.0);
}

vec3 calcSpec(vec3 col, vec3 v, vec3 l, vec3 n, float shad, float f0) {
	vec3 h = normalize(v + l);
	float spec = pow(clamp(dot(n,h),0.0,1.0),200.0);

	float ndotv = dot(h,v);
	float fre_exp = pow(1.0 - ndotv, 5.0);
	float fre = f0 + (1.0 - f0) * fre_exp;

	return col * fre * shad * spec / (4.0 * ndotv);
}

void main(void) {
	vec2 p = (2.0 * gl_FragCoord.xy - resolution.xy) / resolution.y;

	float tx = 0.0 * time / 4.0 + 3.5;
	float ty = 0.1;
	if (pointerCount > 0) {
		tx = pointers[0].x / resolution.x * 3.1416 * 3.0 + 3.14;
		ty = pointers[0].y / resolution.y - 0.4;
	}

	vec3 ro = vec3(cos(tx), ty, sin(tx));
	vec3 ta = vec3(0.0, 0.0, 0.0);

	// camera axes
	vec3 ww = normalize(ta - ro);
	vec3 uu = normalize(cross(ww, vec3(0,1,0)));
	vec3 vv = normalize(cross(uu, ww));

	vec3 rd = normalize(p.x*uu + p.y*vv + 1.5*ww);

	float t = castRay(ro, rd);

	vec3 sun_dir = normalize(vec3(1.0, 0.35, 0.4));
	vec3 hor = vec3(rd.x, 0.0, rd.z);
	float vdotl = dot(sun_dir, rd);
	float vdoth = dot(hor, rd);

	// sky
	vec3 col = vec3(0.5, 0.9, 1.0) - 0.7 * rd.y;
	//col = mix(col, vec3(0.7, 0.9, 0.9), exp(-15.0 * rd.y));
	//col = mix(col, vec3(0.7, 0.9, 1.0), vec3(smoothstep(0.9, 1.0, vdotl)));
	col = mix(col, vec3(0.7, 0.9, 1.0), vec3(exp(-50.0 * (1.0 - max(vdoth, vdotl)))));
	col = mix(col, vec3(1.0), vec3(smoothstep(0.9995, 0.9997, vdotl)));

	if (t > 0.0) {
		vec3 pos = ro + t * rd;
		vec3 nor = calcNormal(pos);
		vec3 ref = reflect(rd, nor);

		float ndotv = dot(nor, -rd);

		vec3 mat = (1.0 - ndotv) * vec3(0.005,0.04,0.08)
			+ ndotv * vec3(0.004,0.05,0.05);
		float ks = 0.2;

		float occ = 1.0;//calcOcclusion(pos, nor);
		//float fre_exp = pow(clamp(1.0 - dot(nor, -rd), 0.0, 1.0), 5.0);
		//float f0 = 0.04;
		//float fre = f0 + (1.0 - f0) * fre_exp;


		float sun_dif = clamp(dot(nor, sun_dir), 0.0, 1.0);
		vec3  sun_hal = normalize(sun_dir - rd);
		float sun_spe = pow(clamp(dot(nor,sun_hal),0.0,1.0),50.0);
		float sun_sha = 1.0;//softShadow(pos, nor, sun_dir, 16.0);//1.0 - step(0.0, castRay(pos + 0.001 * nor, sun_dir));
		vec3  sky_dir = normalize(vec3(0.0, 1.0, 0.0));
		float sky_dif = clamp(0.5 + 0.5 * dot(nor, sky_dir), 0.0, 1.0);
		//vec3  sky_hal = -normalize (vec3(rd.x, max(rd.y,0.0), rd.z) + rd);
		float sky_spe = smoothstep(-0.25, 0.25, ref.y);
		//float bou_dif = clamp(0.5 + 0.5 * dot(nor, vec3(0.0, -1.0, 0.0)), 0.0, 1.0);
		//float sss_dif = fre*sky_dif*(0.25+0.75*sun_dif*sun_sha);

		vec3 lin = vec3(0.0);

		//occ = min(sun_sha * sun_dif, occ);
		//occ = sun_sha * sun_dif;
		//occ = max(sun_sha, occ);

		lin += sun_dif * vec3(8.0, 6.0, 4.0) * sun_sha * occ;
		lin += sky_dif * vec3(1.0, 1.4, 2.0) * occ;
		//lin += bou_dif * vec3(0.4, 0.3, 0.2) * occ;
		//lin *= 0.5 + 0.5*pow(occ, 0.5);
		//lin += sss_dif * vec3(3.2, 2.7, 2.5) * occ;

		//lin += vec3(1.0, 0.7, 0.5) * fre * sun_dif * 1.0;

		//col = vec3(sun_sha);

		col = mat * lin;

		//col += vec3(8.0, 6.0, 4.0) * fre * sun_sha * sun_spe / (4.0 * ndotv);
		//col += sky_spe * vec3(0.5, 0.7, 1.0) * fre * occ;
		//col += (1.0 - sky_spe) * vec3(0.3, 0.5, 0.2) * fre * occ;
		col += calcSpec(vec3(8.0, 6.0, 4.0), -rd, sun_dir, nor, sun_sha, 0.01);
		col += calcSpec(0.2 * vec3(0.5, 0.7, 1.0), -rd, vec3(ref.x, max(ref.y, 0.0), ref.z), nor, occ, 0.04);
		//col += calcSpec(vec3(0.05,0.09,0.02), -rd, vec3(ref.x, min(ref.y, 0.0), ref.z), nor, occ, 0.04);
		col = clamp(col, 0.0, 1.0);

		col = pow(col,vec3(0.8,0.9,1.0) );

		// fog
		col = mix(col, vec3(0.7, 0.9, 0.9), 1.0 - exp(-0.0005*t*t*t));
		//col = vec3(max(sun_sha, occ));
	}

	col = pow(col, vec3(0.4545));

	gl_FragColor = vec4(col, 1.0);
}
