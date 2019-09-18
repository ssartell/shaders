#ifdef GL_FRAGMENT_PRECISION_HIGH
precision highp float;
#else
precision mediump float;
#endif

uniform vec2 resolution;
uniform float time;
uniform vec3 pointers[10];
uniform int pointerCount;
uniform sampler2D bump;
uniform vec3 orientation;

float PI = 3.14159;
vec3  UP = vec3(0.0,1.0,0.0);

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
	vec3 q2 = vec3(p.x, p.y + (sin(p.x) + sin(p.z)) * 0.1, p.z);
	float d2 = q2.y + 0.15;

	return min(d, d2);
	//return smin(d, d2, 0.2);
}

float calcOcclusion( in vec3 pos, in vec3 nor)
{
	float occ = 0.0;
  float sca = 1.0;
  for( int i=0; i<5; i++ )
  {
     float h = 0.01 + 0.11 * float(i) / 4.0;
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
	for(int i = 0; i < 1000; i++) {
		vec3 pos = ro + t * rd;
		float h = map(pos);
		if (abs(h) < 0.001 * t) break;
		t += h;
		if (t > 20.0) break;
	}
	if (t > 20.0) t = 0.0;

	return t;
}

float softShadow(vec3 ro, vec3 nor, vec3 l, float k) {
	float ndotl = dot(nor, l);
	if (ndotl < 0.0) return 0.0;
	ro = ro + nor * 0.001;
	float res = 1.0;
	float t = 0.0;
	for(int i = 0; i < 100; i++) {
		vec3 pos = ro + t * l;
		float h = map(pos);
		res = min(res, k*h/t);
		if (abs(res) < 0.0001 * t) {
			res = 0.0;
			break;
		}
		t += h;
		if (t > 20.0) break;
	}
	return clamp(res, 0.0, 1.0);
}

float D_GGX(float NoH, float a) {
	float a2 = a * a;
	float f = (NoH * a2 - NoH) * NoH + 1.0;
	return a2 / (PI * f * f);
}

vec3 F_Schlick(float VoH, vec3 f0) {
	return f0 + (vec3(1.0) - f0) * pow(1.0 - VoH, 5.0);
}

float V_SmithGGXCorrelated(float NoV, float NoL, float a) {
	float a2 = a * a;
	float GGXL = NoV * sqrt(NoL * NoL * (1.0 - a) + a);
	float GGXV = NoL * sqrt(NoV * NoV * (1.0 - a2) + a);
	return 0.5 / (GGXV + GGXL);
}

float Fd_Lambert() {
	return 1.0 / PI;
}

vec3 BRDF(vec3 n, vec3 v, vec3 l, float Kd, float Ks, float f0, float a) {
	vec3 h = normalize(v + l);

	float NoV = abs(dot(n,v)) + 1e-5;
	float NoL = clamp(dot(n,l),0.0,1.0);
	float NoH = clamp(dot(n,h),0.0,1.0);
	float VoH = clamp(dot(v,h),0.0,1.0);

	a = a * a;

	//if (NoV < 0.0 || NoL < 0.0) return vec3(0.0);

	float D = D_GGX(NoH, a);
	float V = V_SmithGGXCorrelated(NoV, NoL, a);
	vec3  F = F_Schlick(VoH, vec3(f0));

	return (D * V) * F;
}

void main(void) {
	vec2 p = (2.0 * gl_FragCoord.xy - resolution.xy) / resolution.y;

	float tx = time / 2.0;
	float ty = 0.3;
	if (pointerCount > 0) {
		tx = pointers[0].x / resolution.x * 3.1416 * 3.0 + 3.14;
		ty = pointers[0].y / resolution.y - 0.1;
	}

	vec3 ro = vec3(cos(tx), ty, sin(tx));
	vec3 ta = vec3(0.0, 0.0, 0.0);

	// camera axes
	vec3 ww = normalize(ta - ro);
	vec3 uu = normalize(cross(ww, vec3(0,1,0)));
	vec3 vv = normalize(cross(uu, ww));

	vec3 rd = normalize(p.x*uu + p.y*vv + 1.5*ww);

	float t = castRay(ro, rd);

	vec3 sun_dir = normalize(vec3(1.0, 0.3, 0.4));
	float vdotl = dot(sun_dir, rd);

	// sky
	vec3 col = vec3(0.4, 0.8, 1.0) - 0.7 * rd.y;
	col = mix(col, vec3(0.7, 0.9, 0.9), exp(-15.0 * rd.y));
	col = mix(col, 1.1 * vec3(0.5, 0.9, 1.0), vec3(exp(-30.0 * (1.0 - vdotl))));
	col = mix(col, vec3(1.0, 0.9, 0.85), vec3(smoothstep(0.9993	, 0.9997, vdotl)));

	if (t > 0.0) {
		vec3 pos = ro + t * rd;
		vec3 nor = calcNormal(pos);

		vec3 ref = reflect(rd, nor);

		vec3 mat = vec3(0.05,0.09,0.02);
		float ks = 0.2;

		float occ = calcOcclusion(pos, nor);

		float sun_dif = clamp(dot(nor, sun_dir), 0.0, 1.0);
		vec3  sun_hal = normalize(sun_dir - rd);
		float sun_spe = pow(clamp(dot(nor,sun_hal),0.0,1.0),50.0);
		float sun_sha = softShadow(pos, nor, sun_dir, 16.0);//1.0 - step(0.0, castRay(pos + 0.001 * nor, sun_dir));
		vec3  sky_dir = normalize(vec3(ref.x, max(0.0, ref.y), ref.z));
		float sky_dif = clamp(0.5 + 0.5 * dot(nor, vec3(0.0,1.0,0.0)), 0.0, 1.0);
		float sky_spe = smoothstep(-0.25, 0.25, ref.y);
		float bou_dif = clamp(0.5 + 0.5 * dot(nor, vec3(0.0, -1.0, 0.0)), 0.0, 1.0);

		vec3 lin = vec3(0.0);

		//occ = min(sun_sha * sun_dif, occ);
		//occ = sun_sha * sun_dif;
		occ = max(sun_sha, occ);

		lin += sun_dif * vec3(8.0, 6.0, 4.0) * sun_sha * occ;
		lin += sky_dif * vec3(1.0, 1.4, 2.0) * occ;
		lin += bou_dif * vec3(0.4, 0.3, 0.2) * occ;

		col = mat * lin;

		float ior = 0.04;
		float roughness = 0.5;

		col += vec3(8.0, 6.0, 4.0)
		* BRDF(nor,-rd,sun_dir,0.0,0.0,ior,roughness)
		* sun_sha
		* sun_dif;

		col += vec3(0.5, 0.7, 1.0) * 0.01
		* BRDF(nor,-rd,sky_dir,0.0,0.0,ior,roughness)
		* occ;

		col = clamp(col, 0.0, 1.0);

		col = pow(col,vec3(0.8,0.9,1.0) );

		// fog
		col = mix(col, vec3(0.7, 0.9, 0.9), 1.0 - exp(-0.0005*t*t*t));
		//col = vec3(occ);
	}

	col = pow(col, vec3(0.4545));

	gl_FragColor = vec4(col, 1.0);
}
