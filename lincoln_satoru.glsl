precision mediump float;

#define EPSILON 0.001
#define PI 3.14159265359

#define THRESHOLD 0.1

uniform float u_time;
uniform vec2 u_resolution;

float sphereSDF(vec3 p, float r) {
    return length(p) - r;
}

float intersect(float a, float b) {
    return max(a, b);
}

float sdPlane(vec3 p, vec3 n) {
    return dot(p, n);
}

float sdCylinder( vec3 p, vec2 h )
{
  vec2 d = abs(vec2(length(p.xz),p.y)) - h;
  return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}
float createEyelid(vec3 p, vec3 eyePos, float eyeRadius) {
    vec3 eyelidPos = eyePos + vec3(0.0, 0.0, eyeRadius * 0.1); 
    float eyelidRadius = eyeRadius * 1.1; 

    float eyelid = sphereSDF(p - eyelidPos, eyelidRadius);
    eyelid = intersect(eyelid, sdPlane(p - eyelidPos, vec3(0.0, -1.0, -.50))); // Cut the sphere in half

    float eyelidEdge = sdCylinder(p - (eyelidPos + vec3(0.0, eyeRadius * .50, 0.0)), vec2(eyelidRadius, eyeRadius * 0.1)); 

    eyelid = min(eyelid, eyelidEdge);

    return eyelid;
}
float sdCapsule( vec3 p, vec3 a, vec3 b, float r ){
  vec3 pa = p - a, ba = b - a;
  float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
  return length( pa - ba*h ) - r;
}
vec3 calculateNormal(vec3 p) {
    float delta = 0.01;
    vec2 h = vec2(delta, 0.0);
    vec3 p_x = vec3(p.x + delta, p.y, p.z);
    vec3 p_y = vec3(p.x, p.y + delta, p.z);
    vec3 p_z = vec3(p.x, p.y, p.z + delta);

    return normalize(vec3(
        sphereSDF(p_x, 1.0) - sphereSDF(p - h.xyy, 1.0),
        sphereSDF(p_y, 1.0) - sphereSDF(p - h.yxy, 1.0),
        sphereSDF(p_z, 1.0) - sphereSDF(p - h.yyx, 1.0)
    ));
}
float boxSDF(vec3 p, vec3 b) {
    vec3 d = abs(p) - b;
    return min(max(d.x, max(d.y, d.z)), 0.0) + length(max(d, 0.0));
}
float roundedBoxSDF(vec3 p, vec3 b, float r) {
    vec3 d = abs(p) - b;
    return min(max(d.x, max(d.y, d.z)), 0.0) + length(max(d, 0.0)) - r;
}

float sdTorus( vec3 p, vec2 t )
{
  vec2 q = vec2(length(p.xz)-t.x,p.y);
  return length(q)-t.y;
}
float cylinderSDF(vec3 p, vec2 size) {
    float d = length(p.xz) - size.x;
    d = max(d, abs(p.y) - size.y);
    return d;
}

vec3 calculateNormalBox(vec3 p) {
    float e = 0.001;
    vec3 b = vec3(1.0);
    float r = 0.1; 
    return normalize(vec3(
        roundedBoxSDF(p + vec3(e, 0.0, 0.0), b, r) - roundedBoxSDF(p - vec3(e, 0.0, 0.0), b, r),
        roundedBoxSDF(p + vec3(0.0, e, 0.0), b, r) - roundedBoxSDF(p - vec3(0.0, e, 0.0), b, r),
        roundedBoxSDF(p + vec3(0.0, 0.0, e), b, r) - roundedBoxSDF(p - vec3(0.0, 0.0, e), b, r)
    ));
}

float sdCutHollowSphere(vec3 p, float r, float h, float t) {
    // Öffnung nach unten
    p.y = -p.y;
    float w = sqrt(r*r - h*h);
    vec2 q = vec2(length(p.xz), p.y);
    return ((h*q.x < w*q.y) ? length(q - vec2(w, h)) : abs(length(q) - r)) - t;
}

float displacement(vec3 p) {
    return sin(20.0 * p.x) * sin(20.0 * p.y) * sin(20.0 * p.z);
}

float opDisplace(vec3 p, float radius) {
    float d1 = sphereSDF(p, radius);
    float d2 = 0.1*sin(u_time)*displacement(p);
    return d1 + d2;
}

float repeatingSphereSDF(vec3 p, vec3 repeatVec, float radius, vec3 minBounds, vec3 maxBounds) {
    if (p.x < minBounds.x || p.y < minBounds.y || p.z < minBounds.z ||
        p.x > maxBounds.x || p.y > maxBounds.y || p.z > maxBounds.z) {
        return 1e6;
    }
    vec3 q = mod(p, repeatVec) - 0.5 * repeatVec;
    return sphereSDF(q, radius);
}

float opDisplaceSphere(vec3 p, vec3 repeated, float radius,  vec3 minBounds, vec3 maxBounds) {
    float d1 = repeatingSphereSDF(p, repeated, radius, minBounds, maxBounds);
    float d2 = 0.3*displacement(p);
    return d1 + d2;
}

void main() {
    vec2 uv = (gl_FragCoord.xy - 0.5 * u_resolution.xy) / min(u_resolution.y, u_resolution.x);
    uv *= 2.0;
   
    vec3 color = vec3(0.26, 0.34, 0.39);
    
    // Sphere position and radius
    vec3 spherePos = vec3(0.0, 0.0, 5.0);
    float sphereRadius =1.6;

    vec3 eyeLeftPos = vec3(.50, 0.50, 4.0);
    vec3 eyeRightPos = vec3(-.50, 0.50, 4.0);
    float eyeRadius = 0.5;


    vec3 pupilLeft =vec3(.570, 0.50, 3.650);
    vec3 pupilRight = vec3(-.570, 0.50, 3.650);
    
   
    vec3 mouthPos = vec3(0.0, -.50, 4.0); 

   //nase 
    vec3 nasePos = spherePos + vec3(0.0, 0.0, sphereRadius + -2.5); 
    
    vec3 noseEnd = vec3(0.0, 0.0, -1.50 -(abs( sin(u_time) * 6.))); 

    vec3 torus = vec3(1.50, 0.0, 5.0);
    vec3 torus2 = vec3(-1.50, 0.0, 5.0);


    vec3 hatPos = spherePos + vec3(0.0, sphereRadius + 0.5, 0.0); 
 

    vec3 neckPos = vec3(0.0,-2.0,5.0);


   
    vec3 torsoPos = vec3(.0, -5.2, 5.);
    vec3 torsoSize = vec3(2, 2.5, .7);

 
    vec3 collarPos = vec3(0.0, -2.1, 5.0); 
    float collarMajorRadius = .85; 
    float collarMinorRadius = 0.1; 

    vec3 whiteHemd = vec3(0.0, -5.12, 4.29);
    vec3 hemdSize = vec3(1., 2.4, .0);

    vec3 connector = vec3(0.0, -2.6, 4.4);
    vec3 connectorSize = vec3(1.1, .45, .6);

    vec3 leftArmSpherePos = vec3(-2.50, -3.0,5.0);
    vec3 rightArmSpherePos = vec3(2.50, -3.0,5.0);

    vec3 leftArmCylPos = leftArmSpherePos +  vec3(-1.0, 0.0, 0.0);
    vec3 rightArmCylPos = rightArmSpherePos + vec3(1.0, 0.0,0.0);

    vec3 leftUnterArmBall = leftArmCylPos + vec3(-0, 0.0, -4.0);
    vec3 rightUnterArmBall = rightArmCylPos + vec3(2.0, 0.0,0.0);

    vec3 leftUnterArm = leftArmCylPos + vec3(0.0, 0.0, 0.0);
    vec3 rightUnterArm = rightArmCylPos + vec3(3.0, 0.0,0.0);

    vec3 leftHand = leftUnterArm + vec3(0.30,0.0,-8.0);
    vec3 rightHand = rightUnterArm + vec3(-1.0,3.0,0.0);

    vec3 umbrellaHandle = rightHand + vec3(0.0, 3.0, 0.);

    vec3 umbrellaHead = umbrellaHandle + vec3(0.0,4.0, 0.0);

    vec3 hair = vec3(0, .0,.0);

    vec3 underBody = vec3(0.0,-8.50,5.0);
    vec3 underBodySize = vec3(2.0, 1.0, .7);

    vec3 oberLegBallRight = vec3(-1.50, -10., 5.0);
    vec3 oberLegBallLeft = vec3(1.50, -10., 5.0);

    vec3 oberLegRight = oberLegBallRight + vec3(0.0,2.0,0.0);
    vec3 oberLegLeft = oberLegBallLeft + vec3(0.0,2.0,0.0);

    vec3 kneeLeft = oberLegLeft + vec3(0.0, -6.5 , 0.0);
    vec3 kneeRight = oberLegRight + vec3(0.0, -6.5 , 0.0);

    vec3 underLegLeft = kneeLeft + vec3(0.0, 1.0, 0.0);
    vec3 underLegRight = kneeRight + vec3(0.0, 1.0, 0.0);

    vec3 leftShoe = underLegLeft + vec3(0.0,-5.0,-.50);
    vec3 rightShoe = underLegRight + vec3(0.0,-5.0,-.50);

    vec3 finger1 = leftHand + vec3(-.250, 0.30, -1.0);
    vec3 finger2 = leftHand + vec3(-.250, 0.0, -1.0);

    vec3 purple = finger1 + vec3(0.0,0.0, -2.0);

    vec3 leftEyeBrow = pupilLeft + vec3(-.50,0.0,-3.360);
    vec3 rightEyeBrow = pupilRight + vec3(.50,0.0,-3.360);

    // Ray origin and direction
    float angle = u_time;
    float radius = 3.0;
    vec3 rayOrigin = vec3(radius * cos(angle), 0.0, radius * sin(angle) - 15.0);
    // vec3 rayOrigin = vec3(radius+ -3. , 0.0, radius - 20.0);
    vec3 rayDir = normalize(vec3(uv, 1.0));
    

    vec3 p = rayOrigin;

   
    for(int i = 0; i < 64; i++) {
        float distSphere = sphereSDF(p - spherePos, sphereRadius);
        float nase = sdCapsule(p - nasePos, vec3(.0, .0, 0.0), noseEnd, .2);
        float eyeLeft = sphereSDF(p - eyeLeftPos, eyeRadius);
        float eyeRight = sphereSDF(p - eyeRightPos, eyeRadius);
   
        float eyelidLeft = createEyelid(p, eyeLeftPos, eyeRadius);
        float eyelidRight = createEyelid(p, eyeRightPos, eyeRadius);
        float dist = min(eyeRight,min(eyeLeft,min(nase,distSphere)));
        dist = min(dist, eyelidLeft);
        dist = min(dist, eyelidRight);
        float pupilLeftDist = sphereSDF(p - (pupilLeft + vec3(cos(u_time), sin(u_time), .0) * 0.09 ), 0.2);
        float pupilRightDist = sphereSDF(p - (pupilRight + vec3(cos(u_time), sin(u_time), .0) * 0.09 ), 0.2);
        dist = min(dist, pupilLeftDist);
        dist = min(dist, pupilRightDist);
       
        float mouth = sphereSDF(p - mouthPos, 0.5); 
       
        dist = min(dist, mouth);

       
        float torusDist = sdTorus(p - torus, vec2(.0, 0.5));
        dist = min(dist, torusDist);

        float torusDist2 = sdTorus(p - torus2, vec2(.0, 0.5));
        dist = min(dist, torusDist2);

        float hatTop = cylinderSDF(p - hatPos, vec2(1., 1.5));
        //  brim of the hat
        float hatBrim = roundedBoxSDF(p - (hatPos + vec3(0.0, -0.755, 0.0)), vec3(1.3, -.2, .8), 0.5); 
        
     
        float hat = min(hatTop, hatBrim);
        
        dist = min(dist, hat);
    
        float neck = cylinderSDF(p - neckPos, vec2(.70, .50)); 

        dist = min(dist, neck);   

        float torsoDist = roundedBoxSDF(p - torsoPos, torsoSize, 0.5); 

        float leftArm = sphereSDF(p - leftArmSpherePos, .6);
        float rightArm = sphereSDF(p - rightArmSpherePos, .6);

        float leftArmDist = sdCapsule(p - leftArmCylPos, vec3(.50, 0.0, .0), vec3(0.0, 0.0,-4.0), .35);
        float rightArmDist = sdCapsule(p - rightArmCylPos, vec3(-.50, 0.0, 0.0), vec3(2.0,  0.0,-0.0), .35);

        float armBallsLeft  = min(leftArm, leftArmDist);
        float armBallsRight = min(rightArm, rightArmDist);

        float armTors = min(rightArm,min(torsoDist,leftArm));
        dist = min(dist, armBallsLeft);
        dist = min(dist, armBallsRight);
        dist = min(dist, armTors);

        float leftUnterArmBallDist = sphereSDF(p - leftUnterArmBall, .6);
        float rightUnterArmBallDist = sphereSDF(p - rightUnterArmBall, .6);

        float unterarmBallDist = min(leftUnterArmBallDist, rightUnterArmBallDist);
        dist = min(dist, unterarmBallDist);

        float leftUnterArmDist = sdCapsule(p - leftUnterArm, vec3(0.0, .0, -4.0), vec3(0.50 ,0.0, -8.0), .35);
        float rightUnterArmDist = sdCapsule(p - rightUnterArm, vec3(-1., 0.0, 0.0), vec3(-1., 3.0, .0), .35);
        dist = min(leftUnterArmDist, min(dist, rightUnterArmDist));

        float collarDist = sdTorus(p - collarPos, vec2(collarMajorRadius, collarMinorRadius));    
        
        dist = min(dist, collarDist);

        float hemdDist = roundedBoxSDF(p - whiteHemd, hemdSize, 0.5); 

       

        float con = boxSDF(p - connector, connectorSize);
        float colConHemd = min(hemdDist,min(collarDist, con));

        dist = min(dist, colConHemd);


     

        float hairdist = sdCapsule(p - hair, vec3(-1.0,1.650,5.0), vec3(-1.50, -1.0, 4.0), 0.2);
        float hairdist2 = sdCapsule(p - hair, vec3(1.0,1.650,5.0), vec3(1.50, -1.0, 4.0), 0.2);
        float beardRep1 = sdCapsule(p - hair, vec3(0.0,1.650,5.0), vec3(1.50, -1.0, 4.0), 0.2);
        float beardRep2 = sdCapsule(p - hair, vec3(0.0,1.650,5.0), vec3(-1.50, -1.0, 4.0), 0.2);

        float beardRep3 = sdCapsule(p - hair, vec3(0.0,1.650,5.0), vec3(-1.0, -1.0, 4.0), 0.2);
        float beardRep4 = sdCapsule(p - hair, vec3(0.0,1.650,5.0), vec3(1.0, -1.0, 4.0), 0.2);
        float beardRep5 = sdCapsule(p - hair, vec3(0.0,1.650,5.0), vec3(-.70, -1.0, 4.0), 0.2);
        float beardRep6 = sdCapsule(p - hair, vec3(0.0,1.650,5.0), vec3(.70, -1.0, 4.0), 0.2);

        float beardMin = min(beardRep3, beardRep4); 
        dist = min(beardMin,min(beardRep2,min(beardRep1,min(hairdist2,min(dist, hairdist)))));
        dist = min(beardRep6,min(dist, beardRep5));



        float palmLeft = roundedBoxSDF(p - leftHand, vec3(0.20, .20, .250), 0.5);
        float palmRight = roundedBoxSDF(p - rightHand, vec3(0.20, .20, .250), 0.5); 

        float palm = min(palmLeft, palmRight);
        dist = min(dist, palm);

        float umbrellaHandleDist = roundedBoxSDF(p - umbrellaHandle, vec3(0.10, 6.50, .10), 0.1); 
        dist = min(dist, umbrellaHandleDist);

        float umbrellaHeadDist = sdCutHollowSphere(p - umbrellaHead, 4.50, 1.005, 0.00001);
        dist = min(dist, umbrellaHeadDist);

        

        float underBodyDist = roundedBoxSDF(p - underBody, underBodySize, 0.5); 
        dist = min(dist, underBodyDist);

        float oberLegBallDistRight = sphereSDF(p - oberLegBallRight, 1.);
        float oberLegBallDistLeft = sphereSDF(p - oberLegBallLeft, 1.);
        dist = min(dist, oberLegBallDistRight);
        dist = min(dist, oberLegBallDistLeft);

        float walkSpeed = 2.0;  // Lustiger faktor zum rumspielen 
        float walkStride = 2.5; 
        float walk = sin(u_time * walkSpeed) * walkStride;

        float oberLegLeftDist = sdCapsule(p - oberLegLeft, vec3(0.0, -2.0, 0.0), vec3(0.0, -6.0, walk), 0.7);
        float oberLegRightDist = sdCapsule(p - oberLegRight, vec3(0.0, -2.0, 0.0), vec3(0.0, -6.0, -walk), 0.7);
    
        dist = min(dist, oberLegLeftDist);
        dist = min(dist, oberLegRightDist);

        float kneeLeftDist = sdCapsule(p - kneeLeft, vec3(0.0, .0250, walk), vec3(0.0, -.250, walk), .6);
        float kneeRightDist = sdCapsule(p - kneeRight, vec3(0.0, .0250, -walk), vec3(0.0, -.250, -walk), .6);

        dist = min(dist, kneeLeftDist);
        dist = min(dist, kneeRightDist);

        float underLegLeftDist = sdCapsule(p - underLegLeft, vec3(0.0, -2.0, walk), vec3(0.0, -4.0, walk), 0.7);
        float underLegRightDist = sdCapsule(p - underLegRight, vec3(0.0, -2.0, -walk), vec3(0.0, -4.0, -walk), 0.7);
        dist = min(dist, underLegLeftDist);
        dist = min(dist, underLegRightDist);

        

        // lauf animation
        leftShoe.z += walk / 15.; 
        rightShoe.z -= walk / 15.; 

        float leftShoeDist = roundedBoxSDF(p - leftShoe, vec3(0.5, 0.50, 0.5), 0.5); 
        float rightShoeDist = roundedBoxSDF(p - rightShoe, vec3(0.5, 0.50, 0.5), 0.5); 
        dist = min(dist, leftShoeDist);
        dist = min(dist, rightShoeDist);

        
        
        float finger1Dist = boxSDF(p - finger1, vec3(0.1, 0.1, .5));
        float finger2Dist = boxSDF(p - finger2, vec3(0.1, 0.1, .5));

        dist = min(dist, finger1Dist);
        dist = min(dist, finger2Dist);

        float leftEyeBrowDist = sdCapsule(p - leftEyeBrow, vec3(-1.0, .750, 3.650), vec3(-.50, 0.50, 3.650), 0.15);
        float rightEyeBrowDist = sdCapsule(p - rightEyeBrow, vec3(1.0, .750, 3.650), vec3(.50, 0.50, 3.650), 0.15);
        dist = min(dist, leftEyeBrowDist);
        dist = min(dist, rightEyeBrowDist);



        float purpleDist = opDisplace(p - purple, 0.5 + 0.25 * sin(u_time*2.));
        dist = min(dist, purpleDist);

        // vorsicht sehr wichtig, limited domain repetition geht jz!!!
        // limited domain repetition mit dicplacement der repetitions
        // HOLLOW PUUUURPLEEEEEEEE
        float distSphere2 = opDisplaceSphere(p-purple, vec3(2.- sin(u_time), 2.0, 3.-(cos(u_time))), .15, vec3(-2.0, -2.0, -2.0), vec3(2.0, 2.0, 2.0));
        dist = min(dist, distSphere2);

        

       
        float groundDist = p.y + 25.; 
        dist = min(dist, groundDist);


        
        if(abs(dist) < 0.005) {
            vec3 normal = calculateNormal( p);
            vec3 lightDir = normalize(vec3(0.3, 0.5, 1.0));
            float diffuse;
            float ks = 1.0;
           
            if(dist == distSphere) {
                normal = calculateNormal(p - spherePos);
                diffuse = max(dot(normal, lightDir), 0.0);
                color = mix(vec3(0.6863, 0.451, 0.451), vec3(1.0, 1.0, 1.0), diffuse);
            }else if(dist == nase) {
                normal = calculateNormal(p - nase);
                diffuse = max(dot(normal, lightDir), 0.0);
                color = mix(vec3(0.7922, 0.3412, 0.3412), vec3(0.8667, 0.5725, 0.5725), diffuse);
            }else if(dist == eyeLeft) {
                normal = calculateNormal(p - nase);
                diffuse = max(dot(normal, lightDir), 0.0);
                color = mix(vec3(0.9176, 0.9216, 0.9451), vec3(0.6196, 0.6588, 0.7608), diffuse);
            }else if(dist == eyeRight) {
                normal = calculateNormal(p - nase);
                diffuse = max(dot(normal, lightDir), 0.0);
                color = mix(vec3(0.9176, 0.9216, 0.9451), vec3(0.6196, 0.6588, 0.7608), diffuse);
            }else if(dist == eyelidLeft) {
                normal = calculateNormal(p - eyeLeftPos);
                diffuse = max(dot(normal, lightDir), 0.0);
                color = mix(vec3(0.8667, 0.5725, 0.5725), vec3(0.6196, 0.6588, 0.7608), diffuse);
            }else if(dist == eyelidRight) {
                normal = calculateNormal(p - eyeRightPos);
                diffuse = max(dot(normal, lightDir), 0.0);
                color = mix(vec3(0.8667, 0.5725, 0.5725), vec3(0.6196, 0.6588, 0.7608), diffuse);
            }else if(dist == torusDist){
                normal = calculateNormal(p - torus);
                diffuse = max(dot(normal, lightDir), 0.0);
                color = mix(vec3(0.8667, 0.5725, 0.5725), vec3(0.6196, 0.6588, 0.7608), diffuse);
            }else if(dist == torusDist2){
                normal = calculateNormal(p - torus2);
                diffuse = max(dot(normal, lightDir), 0.0);
                color = mix(vec3(0.8667, 0.5725, 0.5725), vec3(0.6196, 0.6588, 0.7608), diffuse);
            }else if(dist == hat){
                normal = calculateNormal(p - hatPos);
                diffuse = max(dot(normal, lightDir), 0.0);
            
        
                diffuse = pow(diffuse, 1.40); 
            
                vec3 darkColor = vec3(0.13, 0.12, 0.12); // Darker color
                vec3 lightColor = vec3(1.0); // Lighter color
            
                color = mix(darkColor, lightColor, diffuse);
            }else if(dist == neck){
                normal = calculateNormal(p - neckPos);
                diffuse = max(dot(normal, lightDir), 0.0);
                if(p.y < neckPos.y + 0.3) { 
                    color = mix(vec3(0.5255, 0.3725, 0.3725), vec3(0.6588, 0.4588, 0.4588), diffuse+.60); // Darker color
                } else {
                    color = mix(vec3(0.5255, 0.3725, 0.3725), vec3(1.0, 1.0, 1.0), diffuse); // Normal color
                }
            }else if(dist == torsoDist){
                normal = calculateNormalBox(p - torsoPos);
                diffuse = max(dot(normal, lightDir), .0);
                color = mix(vec3(0.1451, 0.1333, 0.1176), vec3(0.0941, 0.0863, 0.0863), diffuse+.60);
            }else if(dist == collarDist){
                normal = calculateNormal(p - collarPos);
                diffuse = max(dot(normal, lightDir), 0.0);
                color = mix(vec3(0.7882, 0.7294, 0.7294), vec3(0.8314, 0.8392, 0.8588), diffuse);
            }else if(dist == hemdDist){
                normal = calculateNormal(p - whiteHemd);
                diffuse = max(dot(normal, lightDir), 0.0);
                color = mix(vec3(1.0, 1.0, 1.0), vec3(0.8314, 0.8392, 0.8588), diffuse);
            }else if(dist == mouth){
                normal = calculateNormal(p - mouthPos);
                diffuse = max(dot(normal, lightDir), 0.0);
                color = mix(vec3(0.102, 0.0941, 0.0941), vec3(1.0, 1.0, 1.0), diffuse);
            }else if(dist == pupilLeftDist){
                normal = calculateNormal(p - pupilLeft);
                diffuse = max(dot(normal, lightDir), 0.0);
                color = mix(vec3(0.0), vec3(0.0, 0.0, 0.0), diffuse);
            }else if(dist == pupilRightDist){
                normal = calculateNormal(p - pupilRight);
                diffuse = max(dot(normal, lightDir), 0.0);
                color = mix(vec3(0.0), vec3(0.0, 0.0, 0.0), diffuse);
            
            }else if(dist == colConHemd) {
                normal = calculateNormal(p - connector);
                diffuse = max(dot(normal, lightDir), 0.0);
                color = mix(vec3(1.0, 1.0, 1.0), vec3(0.9255, 0.8941, 0.8941), diffuse);
            }else if(dist == leftArm || dist == rightArm){
                normal = calculateNormal(p - leftArmSpherePos);
                diffuse = max(dot(normal, lightDir), 0.0);
                color = mix(vec3(0.1725, 0.1608, 0.1608), vec3(0.0, 0.0, 0.0), diffuse);
            }
            else if(dist == leftArmDist){
                normal = calculateNormal(p - leftArmSpherePos);
                diffuse = max(dot(normal, lightDir), 0.0);
                color = mix(vec3(0.1725, 0.1608, 0.1608), vec3(0.0, 0.0, 0.0), diffuse);
            }else if(dist == rightArmDist){
                normal = calculateNormal(p - rightArmSpherePos);
                diffuse = max(dot(normal, lightDir), 0.0);
                color = mix(vec3(0.1725, 0.1608, 0.1608), vec3(0.0, 0.0, 0.0), diffuse);

            }else if(dist == palm){
                normal = calculateNormal(p - (leftHand +rightHand));
                diffuse = max(dot(normal, lightDir), 0.0);
                color = mix(vec3(0.7255, 0.5529, 0.5529), vec3(0.6, 0.4941, 0.4941), diffuse+.50);
            }else if(dist == umbrellaHandleDist){
                normal = calculateNormal(p - umbrellaHandle);
                diffuse = max(dot(normal, lightDir), 0.0);
                color = mix(vec3(0.4392, 0.4353, 0.4353), vec3(0.1216, 0.1176, 0.1176), diffuse+.50);
            }else if(dist == umbrellaHeadDist){
                normal = calculateNormal(p - umbrellaHead);
                diffuse = max(dot(normal, lightDir), 0.0);
                color = mix(vec3(0.1059, 0.1059, 0.1059), vec3(0.1725, 0.1686, 0.1686), diffuse+.50);
            }else if(dist == underBodyDist){
                normal = calculateNormal(p - underBody);
                diffuse = max(dot(normal, lightDir), 0.0);
                color = mix(vec3(0.1725, 0.1608, 0.1608), vec3(0.0, 0.0, 0.0), diffuse);
            }else if(dist == oberLegBallDistRight || dist == oberLegBallDistLeft){
                normal = calculateNormal(p - (oberLegBallRight + oberLegBallLeft));
                diffuse = max(dot(normal, lightDir), 0.0);
                color = mix(vec3(0.2667, 0.2471, 0.2471), vec3(0.0, 0.0, 0.0), diffuse);
            }else if(dist == kneeLeftDist || dist == kneeRightDist){
                normal = calculateNormal(p - (kneeLeft + kneeRight));
                diffuse = max(dot(normal, lightDir), 0.0);
                color = mix(vec3(0.2667, 0.2471, 0.2471), vec3(0.0, 0.0, 0.0), diffuse);

            }else if(dist == underLegLeftDist || dist == underLegRightDist){
                normal = calculateNormal(p - (underLegLeft + underLegRight));
                diffuse = max(dot(normal, lightDir), 0.0);
                color = mix( vec3(0.0, 0.0, 0.0), vec3(0.0, 0.0, 0.0), diffuse);
            }else if(dist == oberLegLeftDist || dist == oberLegRightDist){

                normal = calculateNormal(p - (oberLegLeft + oberLegRight));
                diffuse = max(dot(normal, lightDir), 0.0);
                color = mix( vec3(0.0, 0.0, 0.0), vec3(0.0, 0.0, 0.0), diffuse);
            }else if(dist == leftShoeDist || dist == rightShoeDist){

                normal = calculateNormal(p - (leftShoe+rightShoe));
                diffuse = max(dot(normal, lightDir), 0.0);
                color = mix( vec3(0.1804, 0.1725, 0.1725), vec3(0.2549, 0.2392, 0.2392), diffuse);
            }else if(dist == finger1Dist || dist == finger2Dist){
                normal = calculateNormal(p - (finger1+finger2));
                diffuse = max(dot(normal, lightDir), 0.0);
                color = mix(vec3(0.7255, 0.5529, 0.5529), vec3(0.6, 0.4941, 0.4941), diffuse+.50);
            }else if(dist == purpleDist){
                normal = calculateNormal(p - purple);
                diffuse = max(dot(normal, lightDir), 0.0);
                color = mix(vec3(1.0, 0.0, 0.0), vec3(0.1608, 0.1882, 0.5804), diffuse+.50);
                
            }else if(dist == distSphere2){
                normal = calculateNormal(p - purple);
                diffuse = max(dot(normal, lightDir), 0.0);
                color = mix(vec3(0.4039, 0.1451, 0.4275), vec3(0.3843, 0.1647, 0.4275), diffuse+.50);
            }else if(dist == groundDist){
                
                color = vec3(0.0);
                float f = sin(8.0*p.x)+sin(8.0*p.y)+sin(8.0*p.z);
                color += f*vec3(1.0);
            }
            else {
                //beard
                normal = calculateNormal(p - hair);
                diffuse = max(dot(normal, lightDir), 0.0);
                color = mix(vec3(0.0, 0.0, 0.0), vec3(0.0, 0.0, 0.0), diffuse);
            }
            
            vec3  sun_lig = normalize( vec3(0.6, 0.35, 0.5) );
            float sun_dif = clamp(dot( normal, sun_lig ), 0.0, 1.0 );
            vec3  sun_hal = normalize( sun_lig-rayDir );
            float sun_sha = step(dist,0.0);
		    float sun_spe = ks*pow(clamp(dot(normal,sun_hal),0.0,1.0),8.0)*sun_dif*(0.04+0.96*pow(clamp(1.0+dot(sun_hal,rayDir),0.0,1.0),5.0));
		    float sky_dif = sqrt(clamp( 0.5+0.5*normal.y, 0.0, 1.0 ));
            float bou_dif = sqrt(clamp( 0.1-0.9*normal.y, 0.0, 1.0 ))*clamp(1.0-0.1*p.y,0.0,1.0);

		    vec3 lin = vec3(0.0);
            lin += sun_dif*vec3(8.10,6.00,4.20)*sun_sha;
            lin += sky_dif*vec3(0.50,0.70,1.00);
            lin += bou_dif*vec3(0.2824, 0.3098, 0.3529);
		    color = color*lin;
		    color += sun_spe*vec3(8.10,6.00,4.20)*sun_sha;

            color = mix( color, vec3(0.5,0.7,0.9), 1.0-exp( -0.0001*dist*dist*dist) );
            break;
        }
        
        p += dist * rayDir;
    }   
    gl_FragColor = vec4(color, 1.0);
}