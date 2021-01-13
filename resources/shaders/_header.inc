
ivec2 SIZE   = imageSize(imageOut);
ivec2 g_pos  = ivec2(gl_GlobalInvocationID.xy);
uint g_index = g_pos.x + g_pos.y*SIZE.x;

//ivec2 l_pos  = ivec2(gl_LocalInvocationID.xy);
//uint l_index = gl_LocalInvocationIndex;

const float PI       = 3.14159265359f;
const float EPSILON  = 0.00001f;
const float TMIN     = 0.00005f;
const float TMAX     = 100000000.0f;
const uint MAX_DEPTH = 5;

struct Ray {
    vec3 origin;
    vec3 dir;
    vec3 invDir;
};

struct IntersectInfo {
    float t;
    vec3 hitPoint;
    vec3 normal;
    uint material;
    vec2 uv;
};

