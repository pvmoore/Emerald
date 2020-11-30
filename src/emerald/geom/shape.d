module emerald.geom.shape;

import emerald.all;

__gshared uint ids = 0;

interface Shape {
    AABB getAABB();
    Material getMaterial();
    void recalculate();
    bool intersect(ref Ray r, IntersectInfo intersect, float tmin = 0.01);
    float2 getUV(IntersectInfo intersect);
    string dump(string padding);
}