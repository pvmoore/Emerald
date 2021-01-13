#define RANDOM_MASK     ((1024*1024)-1)
#define TENTFILTER_MASK ((1024*1024)-1)

uint randomIndex = 0;
uint tentFilterIndex = 0;


float getRandomFloat() {
    uint i = g_index + randomIndex;

    i += int(RANDOM_MASK * pc.random0);

    randomIndex += int(pc.random1 * 256) + 1;

    float r = random[i & RANDOM_MASK];

    return r;
}

float getRandomFloat(float rr) {
    uint i = g_index + randomIndex;

    i += int(RANDOM_MASK * rr);

    randomIndex += int(pc.random1 * 1024) + 1;

    float r = random[i & RANDOM_MASK];

    return r;
}

void getTentFilter(out float a, out float b) {
    uint i = g_index + tentFilterIndex;

    i += int(TENTFILTER_MASK * pc.random0);

    tentFilterIndex += int(pc.random1 * 1024) + 2;

    a = tentFilter[i & TENTFILTER_MASK];
    b = tentFilter[(i+1) & TENTFILTER_MASK];
}

vec3 gamma(vec3 c) {
    float p = 1.0/1.8;
    c = clamp(c, 0, 1);
    return vec3(pow(c.x, p), pow(c.y, p), pow(c.z, p));
}

Ray makeRay(vec3 o, vec3 d) {
    d = normalize(d);
    return Ray(o, d, 1/d);
}

Ray makeRay(vec3 o, vec3 d, bool normalised) {
    return Ray(o, d, 1/d);
}

Ray makeRay(float sx, float sy) {

    vec3 cx = vec3(SIZE.x*0.5135/SIZE.y, 0, 0);
    vec3 cy = normalize((cross(cx, ubo.cameraDirection))) * 0.5135;

    float dx;
    float dy;
    getTentFilter(dx, dy);

    vec3 d = ubo.cameraDirection;
    d += cx*( ( (sx-0.5 + dx)*0.5 + g_pos.x) / SIZE.x - 0.5) +
         cy*( ( (sy-0.5 + dy)*0.5 + g_pos.y) / SIZE.y - 0.5);

    d = normalize(d);

    // Camera rays are pushed forward 140 to start in interior
    return makeRay(ubo.cameraPosition + d*140, d, true);
}