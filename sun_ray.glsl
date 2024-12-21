precision mediump float;

uniform float u_time;
uniform vec2 u_resolution;

float sdTorus( vec3 p, vec2 t )
{
  vec2 q = vec2(length(p.xz)-t.x,p.y);
  return length(q)-t.y;
}

float spiralRadius = 20.0; 
float spiralPitch = -.5; 

float map(vec3 p) {
  float sphereDist = length(p) - 1.0;

  vec3 spiralPos = vec3(
    spiralRadius * sin(u_time + p.x),
    spiralPitch * p.y,
    spiralRadius * cos(u_time + p.y)
  );


  float spiralDist = sdTorus(p-spiralPos, vec2(3.));

    
  return min(sphereDist, spiralDist);
}

// raymarching
float raymarch(vec3 o, vec3 r){ 
  float t = 0.0; 
  const int maxSteps = 64; 
  for (int i = 0; i < maxSteps; i++){ 
    float d;
    vec3 p = o + r * t;
    d = map(p); 
    if(d<0.001)
    break;
    t += d * 0.5; 
  }
  return t; 
}


void main() {
  // Normalisieren
  vec2 uv = gl_FragCoord.xy / u_resolution;
  uv = uv*2. - 1.;
  uv.x *= u_resolution.x  / u_resolution.y;
    
  vec3 r = normalize(vec3(uv, 1.0)); // ray
  vec3 o = vec3(0.0,0.0,-3); 

  float t = raymarch(o,r); 
   
  gl_FragColor = vec4(vec3(100000000./t), 1.0);
}