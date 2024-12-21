precision mediump float;

uniform float u_time;
uniform vec2 u_resolution;

float sdSphere( vec3 p, float s )
{
  return length(p)-s;
}

float sdBox( vec3 p, vec3 b )
{
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}
float opSmoothUnion( float d1, float d2, float k )
{
    float h = max(k-abs(d1-d2),0.0);
    return min(d1, d2) - h*h*0.25/k;
}
float opSmoothSubtraction( float d1, float d2, float k )
{
    float h = clamp( 0.5 - 0.5*(d2+d1)/k, 0.0, 1.0 );
    return mix( d2, -d1, h ) + k*h*(1.0-h);
}
vec3 calculateNormal(vec3 p) {
    float delta = 0.001; 
    vec2 h = vec2(delta, 0.0);
    vec3 p_x = vec3(p.x + delta, p.y, p.z);
    vec3 p_y = vec3(p.x, p.y + delta, p.z);
    vec3 p_z = vec3(p.x, p.y, p.z + delta);

    return normalize(vec3(
        sdSphere(p_x, 1.0) - sdSphere(p - h.xyy, 1.0),
        sdSphere(p_y, 1.0) - sdSphere(p - h.yxy, 1.0),
        sdSphere(p_z, 1.0) - sdSphere(p - h.yyx, 1.0)
    ));
}
void main() {
    vec2 uv = (gl_FragCoord.xy - 0.5 * u_resolution.xy) / min(u_resolution.y, u_resolution.x);
    uv *= 2.0;
    vec3 color = vec3(0.17, 0.23, 0.25);

    // Ray origin and direction
    float angle = u_time;
    float radius = 3.0;
   // vec3 rayOrigin = vec3(radius * cos(angle), 0.0, radius * sin(angle) - 15.0);
    vec3 rayOrigin = vec3(radius+ -3. , 1.0,  radius - 20.0);
    vec3 rayDir = normalize(vec3(uv, 1.0));
    
    // Ray-sphere and ray-box intersection
    vec3 p = rayOrigin;

    vec3 spherePos1 = vec3(.50,1.-sin(u_time*0.2),-15.0);
    vec3 boxPos1 = vec3(.50,0.0,-15.0);
    vec3 spherePos2 = vec3(-.50,1.-sin(u_time*0.2),-15.0);
    vec3 boxPos2 = vec3(-.50,0.0,-15.0);

    vec3 spherePos3 = vec3(1.50,1.-sin(u_time*0.2),-15.0);
    vec3 boxPos3 = vec3(1.50,0.0,-15.0);
    vec3 spherePos4 = vec3(-1.50,1.-sin(u_time*0.2),-15.0);
    vec3 boxPos4 = vec3(-1.50,0.0,-15.0);

    for(int i = 0; i < 64; i++) {
        
        vec3 lightDir = normalize(vec3(0.3, 0.5, 1.0));
        vec3 normal;
        float diffuse;
        float dist;
        float distSphere1 = sdSphere(p - spherePos1 , 0.10);
        float distBox1 = sdBox(p - boxPos1, vec3(0.25, 0.25, 0.2));
        float distSphere2 = sdSphere(p - spherePos2 , 0.10);
        float distBox2 = sdBox(p - boxPos2, vec3(0.25, 0.25, 0.2));
        float dist1, dist2;
        //box
        // für verschieden k sieht man wie die oberfläche erweitert wird bis die objekte sich treffen
        // 
        float k = .4;
       
        dist1 = opSmoothUnion(distSphere1, distBox1, k);
        dist2 = opSmoothSubtraction(distSphere2, distBox2, k);
        dist = min(dist1, dist2);

        float distSphere3 = sdSphere(p - spherePos3 , 0.10);
        float distBox3 = sdBox(p - boxPos3, vec3(0.25, 0.25, 0.2));
        float distSphere4 = sdSphere(p - spherePos4 , 0.10);
        float distBox4 = sdBox(p - boxPos4, vec3(0.25, 0.25, 0.2));
        float dist3, dist4;

        dist3 = min(distSphere3, distBox3);
        dist4 = max(-distSphere4, distBox4);
        dist = min(min(dist1, dist2), min(dist3, dist4));

        if(dist < 0.01) {
            if(distSphere1 < distBox1){ 
                normal = calculateNormal(p - spherePos1);
                diffuse = clamp(dot(normal, lightDir),0.0,1.0);
                color = mix(vec3(0.8275, 0.7765, 0.7765), vec3(0.7216, 0.6941, 0.6941), sin(diffuse));
            }else {
                normal = calculateNormal(p  - boxPos1);
                diffuse = max(0.0, dot(normal, lightDir));
                color = mix(vec3(0.8941, 0.8431, 0.8431), vec3(0.5333, 0.4863, 0.4863), diffuse);
            }

            if(distSphere2 < distBox2){ 
                normal = calculateNormal(p - spherePos2);
                diffuse = clamp(dot(normal, lightDir),0.0,1.0);
                color = mix(vec3(0.6314, 0.6, 0.6), vec3(0.6588, 0.5373, 0.5373), sin(diffuse));
            }else {
                normal = calculateNormal(p  - boxPos2);
                diffuse = max(0.0, dot(normal, lightDir));
                color = mix(vec3(0.8941, 0.8784, 0.8784), vec3(0.5333, 0.4863, 0.4863), diffuse);
            }

            if(distSphere3 < distBox3){ 
                normal = calculateNormal(p - spherePos3);
                diffuse = clamp(dot(normal, lightDir),0.0,1.0);
                color = mix(vec3(0.7255, 0.6706, 0.6706), vec3(0.6588, 0.5373, 0.5373), sin(diffuse));
            }else {
                normal = calculateNormal(p  - boxPos3);
                diffuse = max(0.0, dot(normal, lightDir));
                color = mix(vec3(0.7333, 0.702, 0.702), vec3(0.5333, 0.4863, 0.4863), diffuse);
            }

            if(distSphere4 < distBox4){ 
                normal = calculateNormal(p - spherePos4);
                diffuse = clamp(dot(normal, lightDir),0.0,1.0);
                color = mix(vec3(0.5608, 0.5373, 0.5373), vec3(0.6588, 0.5373, 0.5373), sin(diffuse));
            }else {
                normal = calculateNormal(p  - boxPos4);
                diffuse = max(0.0, dot(normal, lightDir));
                color = mix(vec3(0.4667, 0.4471, 0.4471), vec3(0.0, 0.0, 0.0), diffuse);
            }

            break;       
        }

        p += dist * rayDir;
    }

    gl_FragColor = vec4(color, 1.0);
}