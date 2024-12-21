precision mediump float;

uniform float u_time;
uniform vec2 u_resolution;

float boxSDF(vec3 p, vec3 b) {
    vec3 d = abs(p) - b;
    return length(max(d, 0.0)) + min(max(d.x, max(d.y, d.z)), 0.0);
}

float repeatingBoxSDF(vec3 p, vec3 repeatVec, vec3 b) {
    vec3 q = mod(p, repeatVec) - 0.5 * repeatVec;
    return boxSDF(q, b);
}

vec3 calculateNormalBoxes(vec3 p, vec3 b) {
    const float eps = 0.0001;
    return normalize(vec3(
        boxSDF(p + vec3(eps, 0.0, 0.0), b) - boxSDF(p - vec3(eps, 0.0, 0.0), b),
        boxSDF(p + vec3(0.0, eps, 0.0), b) - boxSDF(p - vec3(0.0, eps, 0.0), b),
        boxSDF(p + vec3(0.0, 0.0, eps), b) - boxSDF(p - vec3(0.0, 0.0, eps), b)
    ));
}

float opDisplaceBox(vec3 p, vec3 b) {
    float d1 = repeatingBoxSDF(p, vec3(3.0, 3.0, 3.0), b);
    return d1;
}

float opCheapBend(vec3 p, vec3 boxSize, float factor){
    float k = factor; 
    float c = cos(k*p.x);
    float s = sin(k*p.x);
    mat2  m = mat2(c,-s,s,c);
    vec3  q = vec3(m*p.xy,p.z);
    return opDisplaceBox(q, boxSize);
}

float opTwistBox(vec3 p , vec3 boxSize, float factor){
    float k = factor; 
    float c = cos(k*p.y);
    float s = sin(k*p.y);
    mat2  m = mat2(c,-s,s,c);
    vec3  q = vec3(m*p.xz,p.y);
    return opDisplaceBox(q, boxSize);
}

void main() {
    vec2 uv = (gl_FragCoord.xy - 0.5 * u_resolution.xy) / min(u_resolution.y, u_resolution.x);
    uv *= 2.0;
    vec3 color = vec3(0.0);

   
    float angle = u_time;
    float radius = 3.0;

    vec3 rayOrigin = vec3(radius+ -3. , -angle, angle + radius - 20.0);
    vec3 rayDir = normalize(vec3(uv, 1.0));
    
  
    vec3 p = rayOrigin;

   
    for(int i = 0; i < 64; i++) {
        
        vec3 normal;
        float diffuse;
        vec3 boxSize = vec3(0.50, 0.50, 0.50);

        // Könnt gerne beides angucken, müsst nur eins auskommentieren
        //float dist = opCheapBend(p, boxSize, 0.02*sin(u_time));  // man kann gut den bend effekt in der gesamten szene sehen
        float dist = opTwistBox(p, boxSize,0.01*sin(u_time)); // man kann gut den twist effekt in der gesamten szene sehen
        if(dist < 0.01) {
            normal = calculateNormalBoxes(p, boxSize);
            diffuse = max(dot(normal, rayDir), 0.0);
            color = mix(vec3(0.0667, 0.0549, 0.0549), vec3(0.5882, 0.5765, 0.6196), diffuse);
            break;    
        }
        
        p += dist * rayDir;

    }

    gl_FragColor = vec4(color, 1.0);
}