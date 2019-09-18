#ifdef GL_FRAGMENT_PRECISION_HIGH
precision highp float;
#else
precision mediump float;
#endif

uniform vec2 resolution;
uniform float time;
uniform vec3 pointers[10];
uniform int pointerCount;

float PI = 3.14159;

float random(vec2 p) {
	return fract(sin(dot(p, vec2(12.75, 8.92))) * 53638.97582);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);

	float a = random(i);
	float b = random(i + vec2(1.0, 0.0));
	float c = random(i + vec2(0.0, 1.0));
	float d = random(i + vec2(1.0, 1.0));

	f = f * f * (3.0 - 2.0 * f);

	return mix(mix(a,b,f.x),mix(c,d,f.x), f.y);
}

float fbm(vec2 p) {
	float a = .5;
	float f = 1.;
	float y = 0.;

	for(int i = 0; i < 6; i++) {
		y += a * noise(f * p + time * sin(f));
		f *= 2.0;
		a *= 0.5;
	}

	return y;
}

float smin( float a, float b, float k ) {
	float h = max( k-abs(a-b), 0.0 )/k;
	return min( a, b ) - h*h*k*(1.0/4.0);
}

float map(vec3 p) {
	vec3 q2 = vec3(p.x, p.y + fbm(p.xz + vec2(0.5)) * 0.2, p.z);
	return q2.y + 0.15;
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
	float t0 = map(p);
	return normalize(vec3(
		map(p + e.xyy) - t0,
		map(p + e.yxy) - t0,
		map(p + e.yyx) - t0));
}

float castRay(vec3 ro, vec3 rd) {
	float bt = (0.3 - ro.y) / rd.y;
	if (bt >= 0.0 && ro.y < 0.3) return 0.0;

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

float sqr(float x) {
	return x * x;
}

float GGX(float NdotH, float alphaG) {
	return alphaG*alphaG / (PI * sqr(NdotH*NdotH*(alphaG*alphaG-1.0) + 1.0));
}

float smithG_GGX(float NdotV, float alphaG) {
	return 2.0/(1.0 + sqrt(1. + alphaG*alphaG * (1.-NdotV*NdotV)/(NdotV*NdotV)));
}

vec3 BRDF(vec3 n, vec3 v, vec3 l, float Kd, float Ks, float f0, float alpha) {
	float NdotV = dot(n,v);
	float NdotL = dot(n,l);

	if (NdotV < 0.0 || NdotL < 0.0) return vec3(0.0);

	vec3 h = normalize(v + l);
	float LdotH = dot(l,h);
	float NdotH = dot(n,h);

	float D = GGX(NdotH, alpha);
	float G = smithG_GGX(NdotL, alpha);

	float fre_exp = pow(1.0 - LdotH, 5.0);
	float F = f0 + (1.0 - f0) * fre_exp;

	float val = Kd/PI + Ks * D *G * F / (4.0 * NdotV);

	return vec3(val);
}

vec3 calcSpec(vec3 col, vec3 v, vec3 l, vec3 n, float shad, float f0) {
	vec3 h = normalize(v + l);
	float spec = pow(clamp(dot(n,h),0.0,1.0),500.0);

	float ndotv = dot(h,v);
	float fre_exp = pow(1.0 - ndotv, 5.0);
	float fre = f0 + (1.0 - f0) * fre_exp;

	return col * fre * shad * spec / (4.0 * ndotv);
}

void main(void) {
	vec2 p = (2.0 * gl_FragCoord.xy - resolution.xy) / resolution.y;

	float tx = 3.5;
	float ty = 0.1;
	if (pointerCount > 0) {
		tx = pointers[0].x / resolution.x * 3.1416 * 1.0 + 1.75;
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
	float vdotl = dot(sun_dir, rd);

	// sky
	vec3 col = vec3(0.5, 0.9, 1.0) - 0.7 * rd.y;
	col = mix(col, vec3(0.7, 0.9, 0.9), exp(-15.0 * rd.y));
	col = mix(col, 1.1 * vec3(0.5, 0.9, 1.0), vec3(exp(-30.0 * (1.0 - vdotl))));
	col = mix(col, vec3(1.0, 0.9, 0.85), vec3(smoothstep(0.9993	, 0.9997, vdotl)));

	if (t > 0.0) {
		vec3 pos = ro + t * rd;
		vec3 nor = calcNormal(pos);
		vec3 ref = reflect(rd, nor);

		float ndotv = dot(nor, -rd);

		vec3 mat = (1.0 - ndotv) * vec3(0.005,0.04,0.08)
			+ ndotv * vec3(0.004,0.05,0.05);

		float sun_dif = clamp(dot(nor, sun_dir), 0.0, 1.0);
		vec3  sky_dir = normalize(vec3(0.0, 1.0, 0.0));
		float sky_dif = clamp(0.5 + 0.5 * dot(nor, sky_dir), 0.0, 1.0);

		vec3 lin = vec3(0.0);

		lin += sun_dif * vec3(8.0, 6.0, 4.0);
		lin += sky_dif * vec3(1.0, 1.4, 2.0);

		col = mat * lin;

		//col += calcSpec(vec3(8.0, 6.0, 4.0), -rd, sun_dir, nor, 1.0, 0.01);
		//col += calcSpec(0.2 * vec3(0.5, 0.7, 1.0), -rd, vec3(ref.x, max(ref.y, 0.0), ref.z), nor, 1.0, 0.04);
		//col += vec3(8.0, 6.0, 4.0)
		//* BRDF(nor,-rd,sun_dir,0.0,0.25,1.33,0.01);
		col += vec3(0.5, 0.7, 1.0)
		* BRDF(nor,-rd,vec3(ref.x, max(ref.y, 0.0), ref.z),0.0,0.0001,1.33,0.01);

		col = clamp(col, 0.0, 1.0);

		col = pow(col,vec3(0.8,0.9,1.0) );

		// fog
		col = mix(col, vec3(0.7, 0.9, 0.9), 1.0 - exp(-0.0005*t*t*t));
	}

	col = pow(col, vec3(0.4545));

	gl_FragColor = vec4(col, 1.0);
}
