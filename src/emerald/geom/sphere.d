module emerald.geom.sphere;

import emerald.all;

final class Sphere : Shape {
private:
    static __gshared uint ids = 0;
    float radiusSquared;
    AABB aabb;
    Material material;
public:
    uint id;
    float3 centre;
    float radius;
    mat4 transformation;

    this(float radius, float3 centre, Material m) {
        this.id             = ids++;
        this.radiusSquared  = radius*radius;
        this.radius         = radius;
        this.centre         = centre;
        this.aabb           = AABB(centre-radius, centre+radius);
        this.material       = m;
        this.transformation = mat4.identity();
    }
    auto transform(mat4 t) {
        this.transformation = t;
        return this;
    }

    override AABB getAABB()         { return aabb; }
    override Material getMaterial() { return material; }

    /**
     * Map 3D hit point on the sphere to 2D UV texture coordinates.
     */
    override float2 toUV(float3 hitPoint) {
        import std.math : asin, atan2, PI, PI_2;
        enum invPI  = 1.0 / PI;
        enum inv2PI = 1.0 / (PI*2);

        auto normal = (hitPoint - centre).normalised();

        auto t = float4(normal,0) * transformation;

        auto u = 1 - (0.5 + (atan2(t.z, t.x) * inv2PI));
        auto v = 1 - ((asin(t.y)+PI_2) * invPI);

        return float2(u.clamp(0,1), v.clamp(0,1));
    }
    /**
     * Solve t^2*d.d + 2*t*(o-p).d + (o-p).(o-p)-R^2 = 0
     *
     * @param t = hit point
     */
    override bool intersect(ref Ray r, IntersectInfo ii, float tmin) {
        float t;
        if(getIntersect(r, t, tmin, ii.t)) {
            ii.t          = t;
			ii.hitPoint   = r.origin + r.direction*t;
			ii.normal     = (ii.hitPoint - centre).normalised();
			ii.shape      = this;
            return true;
        }
        return false;
    }
    override string dump(string padding) {
		return "%sSphere(%s)".format(padding, aabb);
    }
private:
    bool getIntersect(ref Ray r, ref float t, float tmin, float tmax) {
        float3 op = centre - r.origin;
        float b   = op.dot(r.direction);
        float det = (b*b)-op.dot(op) + radiusSquared;

        if(det<0) return false;

        det = sqrt(det);

        if((t=b-det)>tmin) {
            return t<tmax;
        }
        if((t=b+det)>tmin) {
            return t<tmax;
        }
        return false;
    }
}