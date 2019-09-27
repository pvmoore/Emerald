module emerald.util.util;

import emerald.all;

pragma(inline,true):

float clamp(float x) pure {
    return x<0 ? 0 : x>1 ? 1 : x;
}

float3 clamp(ref float3 v) pure {
    v.x = clamp(v.x);
    v.y = clamp(v.y);
    v.z = clamp(v.z);
    return v;
}

float gamma(float x) pure {
    return pow(clamp(x), 1.0/2.2);
}