precision mediump float;


uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;


float smin( float a, float b, float k )
{
    float h = max(k-abs(a-b),0.0);
    return min(a, b) - h*h*0.25/k;
}

float smax( float a, float b, float k )
{
    float h = max(k-abs(a-b),0.0);
    return max(a, b) + h*h*0.25/k;
}
float sdCylinder(vec3 p, vec2 h) {
    vec2 d = abs(vec2(length(p.xz),p.y)) - h;
    return smin(max(d.x,d.y),0.0, 0.1) + length(max(d,0.0));
}
float sdSphere( vec3 p, float s )
{
    return length(p)-s;
}
float displacement(vec3 p) {
    return sin(20.*p.x)*sin(20.*p.y)*sin(20.*p.z);
}
float sdTree(vec3 p) {
    float trunk = sdCylinder(p - vec3(0.0, 0.5, 0.0), vec2(0.1, 0.5));
    float canopy = sdSphere(p - vec3(0.0, 1.0, 0.0), 0.6);
    // lässt den baum etwas besser aussehen
    float d = 0.05*displacement(p);
    return smin((1.2*d)+trunk, canopy+d, 0.1);
}
float sdEllipsoid( in vec3 p, in vec3 r )
{
    float k0 = length(p/r);
    float k1 = length(p/(r*r));
    return k0*(k0-1.0)/k1;
}
// stabiler twister
float opTwistEllipsoid(vec3 p , vec3 r){
    const float k = 12.0; 
    float c = cos(k*p.y);
    float s = sin(k*p.y);
    mat2  m = mat2(c,-s,s,c);
    vec3  q = vec3(m*p.xz,p.y);
    return sdEllipsoid(q, r);
}

vec2 sdStick(vec3 p, vec3 a, vec3 b, float r1, float r2)
{
    vec3 pa = p-a, ba = b-a;
	float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
	return vec2( length( pa - ba*h ) - mix(r1,r2,h*h*(3.0-2.0*h)), h );
}

vec2 opUnionVec2( vec2 d1, vec2 d2 )
{
	return (d1.x<d2.x) ? d1 : d2;
}

vec2 map( in vec3 pos, float atime )
{
    float t1 = fract(atime);

    float p = 4.0*t1*(1.0-t1);
    float pp = 4.0*(1.0-2.0*t1);

    float itime = floor(atime);
    float ftime = fract(atime);

    float x =-1.0+ 2.0* abs(fract(atime* 0.5)- 0.5)/0.5;

    vec3 cen = vec3( x*0.5,
                     pow(p,2.0-p) + 0.1,
                     itime + pow(ftime, 0.7));
    // Körper
    vec2 uu = normalize(vec2( 1.0, -pp ));
    vec2 vv = vec2(-uu.y, uu.x);
    
    float sy = 0.5 + 0.5*p;
    float compress = 1.0-smoothstep(0.0,0.4,p);
    sy = sy*(1.0-compress) + compress;
    float sz = 1.0/sy;
    // ref coords
    vec3 q = pos - cen;
    // hier kann man jumping angle einstellen
    //float ro = 0.5*3.1416*ftime;
    float ro = x* .30;
    float cc = cos(ro);
    float ss = sin(ro);
    q.yz = mat2(cc, ss, -ss, cc)* q.yz;


    vec3 r = q;
	
    q.yz = vec2( dot(uu,q.yz), dot(vv,q.yz) );
    
    vec2 res = vec2( opTwistEllipsoid( q, vec3(0.25, 0.25*sy, 0.25*sz) ), 2.0 );

    float t2 = fract(atime+0.8);
    float p2 = 0.5-0.5*cos(6.2831*t2);
    r.z += 0.05-0.2*p2;
    r.y += 0.2*sy-0.2;
    vec3 sq = vec3( abs(r.x), r.yz );

	// Kopf
    vec3 h = r;
    vec3 hq = vec3( abs(h.x), h.yz );

	float d = opTwistEllipsoid( h-vec3(0.0,0.21,-0.1), vec3(0.20,0.2,0.20) );
	
    res.x = smin( res.x, d, 0.1 );

    // Arme
    {
    float la = sign(q.x)*cos(3.14159*atime+0.5);
    float ccc = cos(la * 10.0) ;
    float sss = sin(la * 10.0);
    vec3 base = vec3(0.2,0.2,-0.05);
    vec2 arms = sdStick( sq,base , base + vec3(0.8,-ccc,sss)*0.2, 0.04, 0.07 );
    res.x = smin( res.x, arms.x, 0.01+0.04*(1.0-arms.y)*(1.0-arms.y)*(1.0-arms.y) );
    }

    // Beine
    {
    float la = sign(q.x)*cos(3.14159*atime+0.5);
    float ccc = cos(la);
    float sss = sin(la);
    vec3 base = vec3(0.12, -0.07, -0.1);
    base.y -= 0.1/sy;
    vec2 legs = sdStick( sq, base, base+ vec3(0.2,-ccc,sss)*0.2, 0.04, 0.07);
    res.x = smin( res.x, legs.x, 0.03);
    }

    // Ohren
    {
    float t3 = fract(atime+0.9);
    float p3 = 4.0*t3*(1.0-t3);
    vec2 ear = sdStick( hq, vec3(0.15,0.32,-0.05), vec3(0.30 - 0.2* sin(u_time)+0.05*p3,0.2+0.2*p3,-0.07), 0.051, 0.02 );
    res.x = smin( res.x, ear.x, 0.01 );
    }
    
    // Mund
    {
   	d = sdEllipsoid( h-vec3(0.0,0.015+4.0*-hq.x*hq.x,0.15), vec3(0.1,0.08 - 0.1*sin(u_time) ,0.2) );
    res.x = smax( res.x, -d, 0.03 );
    }
        
    // Augen
    {
    float blink = pow(0.5+0.5*sin(2.1*u_time),20.0);
    float eyeball = sdSphere(hq-vec3(0.08,0.27,0.06),0.065+0.02*blink);
    res.x = smin( res.x, eyeball, 0.03 );
    
    vec3 cq = hq-vec3(0.1,0.34,0.08);
    cq.xy = mat2(1,-0.06,-1.,0.8)*cq.xy;
    d = sdEllipsoid( cq, vec3(0.06,0.03,0.03) );
    res.x = smin( res.x, d, 0.03 );

    res = opUnionVec2( res, vec2(sdSphere(hq-vec3(0.08,0.28,0.08),0.060),3.0));
    res = opUnionVec2( res, vec2(sdSphere(hq-vec3(0.075,0.28,0.102),0.0395),4.0));
    }
        
    // Boden und Boden berührung
    float fh = -0.1 - 0.05*(sin(pos.x*2.0)+sin(pos.z*2.0));
    float gt = fract(atime);
    float l = length((pos-cen).xz);
    fh -= 0.1*
          sin(gt*10.0+ l *3.0)*
          exp(-1.0*l*l)*
          exp(-1.0*gt)*
          smoothstep(0.0,0.1,gt);

    d = pos.y - fh;

    
    // Bäume 
    {
    vec3 vp = vec3( mod(abs(pos.x),3.0),pos.y,mod(pos.z+1.5,3.0)-1.5);
    float d2 = sdTree(vp-vec3(2.0,0.,0.0));
    d2 *= 0.6;
    d2 = min(d2,2.0);
    d = smin( d, d2, 0.32 );
    if( d<res.x ) res = vec2(d,1.0);
    }
    
    return res;
}

vec2 castRay( in vec3 ro, in vec3 rd, float time )
{
    vec2 res = vec2(-1.0,-1.0);

    float tmin = 0.5;
    float tmax = 20.0;
    
    float t = tmin;
    for (int i = 0; (i < 512); i++)
    {
        if(t < tmax){
            vec2 h = map( ro+rd*t, time );
            if( abs(h.x)<(0.0005*t) )
            { 
                res = vec2(t,h.y); 
                break;
            }
            t += h.x;
        }

    }
    
    return res;
}

vec3 calcNormal( in vec3 pos, float time )
{

    vec2 e = vec2(0.0005,0.0);
    return normalize( vec3( 
        map( pos + e.xyy, time ).x - map( pos - e.xyy, time ).x,
		map( pos + e.yxy, time ).x - map( pos - e.yxy, time ).x,
		map( pos + e.yyx, time ).x - map( pos - e.yyx, time ).x ));
}



vec3 render( in vec3 ro, in vec3 rd, float time )
{ 
    // Himmel
    vec3 col = vec3(0.902, 0.502, 0.6706) - max(rd.y,0.0)*0.5;
    vec2 uv = rd.xz/rd.y;
    // Wolken
    float clouds = 1.0*(sin(uv.x) + sin(uv.y))+
                   0.5*(sin(2.0*uv.x)+sin(2.0*uv.y));

    col = mix(col, vec3(0.3137, 0.5412, 0.4471),smoothstep(-0.1, 0.1,-0.5+clouds));
    
    col = mix(col, vec3(0.7, 0.8, .9), exp(-10.0*rd.y));
    
    vec2 res = castRay(ro,rd, time);

    if( res.y>-0.5 )
    {
        float t = res.x;
        vec3 pos = ro + t*rd; // pos von ray zu objekt
        // normalen vektor für oberfläche von objekten
        vec3 nor = calcNormal( pos, time ); 
        
		col = vec3(0.2);
        float ks = 1.0;

        if( res.y>3.5 ) { 
            col = vec3(1.0, 1.0, 1.0);
        } 
        else if( res.y>2.5 ) { 
            col = vec3(0.0, 0.0, 0.0);
        } 
        else if( res.y>1.5 ) { 
            col = vec3(0.098, 0.1922, 0.1294);
        }else if(res.y > 0.5){// umgebung
            col = vec3(0.0235, 0.0941, 0.0824);
            float f = 0.2*(-1.0+2.0*smoothstep(-0.2,0.2,sin(8.0*pos.x)+sin(8.0*pos.y)+sin(8.0*pos.z)));
            col += f*vec3(0.098, 0.2078, 0.0784);
            ks = 0.5 + pos.y*0.15;
        }else{
            col = vec3(0.0);
        }
        
        // lighting
        vec3  sun = normalize( vec3(0.6, 0.35, 0.5) );
        float sun_dif = clamp(dot( nor, sun ), 0.0, 1.0 );
        vec3  sun_hal = normalize( sun-rd );
        float sun_shadow = step(castRay( pos+0.001*nor, sun,time ).y,0.0);
		float sun_spe = ks*pow(clamp(dot(nor,sun_hal),0.0,1.0),8.0)*sun_dif*(0.04+0.96*pow(clamp(1.0+dot(sun_hal,rd),0.0,1.0),5.0));
		float sky_dif = sqrt(clamp( 0.5+0.5*nor.y, 0.0, 1.0 ));
        float bou_dif = sqrt(clamp( 0.1-0.9*nor.y, 0.0, 1.0 ))*clamp(1.0-0.1*pos.y,0.0,1.0);

		vec3 fac = vec3(0.0);
        fac += sun_dif*vec3(8.10,6.00,4.20)*sun_shadow;
        fac += sky_dif*vec3(0.50,0.70,1.00);
        fac += bou_dif*vec3(0.40,1.00,0.40);
		col = col*fac;
		col += sun_spe*vec3(8.10,6.00,4.20)*sun_shadow;
        
        col = mix( col, vec3(0.5,0.7,0.9), 1.0-exp( -0.0001*t*t*t ) );
    }

    return col;
}

mat3 setCamera( in vec3 ro, in vec3 ta, float cr )
{
	vec3 cw = normalize(ta-ro);
	vec3 cp = vec3(sin(cr), cos(cr),0.0);
	vec3 cu = normalize( cross(cw,cp) );
	vec3 cv = cross(cu,cw);
    return mat3( cu, cv, cw );
}

void main(){
    vec2 p = (-u_resolution.xy + 2.0*gl_FragCoord.xy)/u_resolution.y;
    float time = u_time;

    time *= 0.9;

    // camera	
    float cd = sin(0.5*time);
    float an = 10.57*u_mouse.x/u_resolution.x;
    vec3  ta = vec3( 0.0, 0.65, 01.4 + cd + time);
    vec3  ro = ta + vec3( 1.3*cos(an), -0.250, 1.3*sin(an) );

    mat3 ca = setCamera( ro, ta, 0.0 );

    vec3 rd = ca * normalize( vec3(p,1.8) );

    vec3 col = render( ro, rd, time );

    col = pow( col, vec3(0.75) );

    gl_FragColor = vec4( col, 1.0 );
}