precision mediump float;

uniform float u_time;
uniform vec2 u_resolution;

float sphereSDF(vec3 p, float radius) {
    return length(p) - radius;
}

float repeatingSphereSDF(vec3 p, vec3 repeatVec, float radius) {
    vec3 q = mod(p, repeatVec) - 0.5 * repeatVec;
    return sphereSDF(q, radius);
}

vec3 calculateNormalSpheres(vec3 p, float radius) {
    const float eps = 0.0001;
    return normalize(vec3(
        sphereSDF(p + vec3(eps, 0.0, 0.0), radius) - sphereSDF(p - vec3(eps, 0.0, 0.0), radius),
        sphereSDF(p + vec3(0.0, eps, 0.0), radius) - sphereSDF(p - vec3(0.0, eps, 0.0), radius),
        sphereSDF(p + vec3(0.0, 0.0, eps), radius) - sphereSDF(p - vec3(0.0, 0.0, eps), radius)
    ));
}

float opDisplaceSphere(vec3 p, float radius) {
    float d1 = repeatingSphereSDF(p, vec3(3.0, 3.0, 3.0), radius);
    return d1;
}

float opBendSphere(vec3 p, float r, float factor){
    float k = factor; // or some other amount
    float c = cos(k*p.x);
    float s = sin(k*p.x);
    mat2  m = mat2(c,-s,s,c);
    vec3  q = vec3(m*p.xy,p.z);
    return opDisplaceSphere(q, r);
}

float opTwistSphere(vec3 p , float r, float factor){
    float k = factor; // or some other amount
    float c = cos(k*p.y);
    float s = sin(k*p.y);
    mat2  m = mat2(c,-s,s,c);
    vec3  q = vec3(m*p.xz,p.y);
    return opDisplaceSphere(q, r);
}


void main() {
    vec2 uv = (gl_FragCoord.xy - 0.5 * u_resolution.xy) / min(u_resolution.y, u_resolution.x);
    uv *= 2.0;
    vec3 color = vec3(0.0);

    
    float angle = u_time;
    float radius = 3.0;
    
    vec3 rayOrigin = vec3(radius+ -3. , -angle , 1.*angle + radius - 20.0);
    vec3 rayDir = normalize(vec3(uv, 1.0));
    
    // Ray-sphere and ray-box intersection
    vec3 p = rayOrigin;

   
    for(int i = 0; i < 64; i++) {
        
       
        vec3 normal;
        float diffuse;
        float radius = 0.5;
        // Könnt gerne beides angucken, müsst nur eins auskommentieren
        //float dist = opTwistSphere(p, radius, 0.05*sin(u_time));
        float dist = opBendSphere(p, radius, 0.01*sin(u_time));
        if(dist < 0.01) {
            normal = calculateNormalSpheres(p, 0.50);
            diffuse = max(dot(normal, rayDir), 0.0);
            color = mix(vec3(0.6784, 0.6549, 0.4235), vec3(0.0, 0.0, 0.0), diffuse);
            break;    
        }
        
        p += dist * rayDir;

    }

    gl_FragColor = vec4(color, 1.0);
}