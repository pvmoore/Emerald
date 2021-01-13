module emerald.geom.shape;

import emerald.all;

__gshared uint ids = 0;

interface Shape {
    uint getId();
    AABB getAABB();
    Material getMaterial();
    void recalculate();
    bool intersect(ref Ray r, IntersectInfo intersect);
    float2 getUV(IntersectInfo intersect);
    string dump(string padding);
}