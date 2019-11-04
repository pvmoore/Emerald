module emerald.geom.shape;

import emerald.all;

interface Shape {
    AABB getAABB();
    Material getMaterial();
    bool intersect(ref Ray r, IntersectInfo intersect, float tmin = 0.01);
    string dump(string padding);
    float2 toUV(float3 hitPoint);
}