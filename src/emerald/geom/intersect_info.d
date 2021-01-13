module emerald.geom.intersect_info;

import emerald.all;

final class IntersectInfo {
    float t;
    float3 hitPoint;
    float3 normal;
    Shape shape;
    float2 uv;      // set by Triangle

    //uint2 pos;

    bool intersected() {
        return shape !is null;
    }
    void reset() {
        shape = null;
        t     = float.max;
    }
    float2 getUV() {
        return shape.getUV(this);
    }
}