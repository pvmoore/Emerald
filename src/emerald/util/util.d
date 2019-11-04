module emerald.util.util;

import emerald.all;

pragma(inline,true):

float clamp(float x) {
    return x<0 ? 0 : x>1 ? 1 : x;
}

float3 clamp(float3 v) {
    return float3(clamp(v.x), clamp(v.y), clamp(v.z));
}

float clampLo(float x) {
    return x<0 ? 0 : x;
}
float3 clampLo(float3 v) {
    return float3(clampLo(v.x), clampLo(v.y), clampLo(v.z));
}

float gamma(float x) {
    //enum p = 1.0/2.2; // original value
    enum p = 1.0/1.8;
    return pow(clamp(x), p);
}
