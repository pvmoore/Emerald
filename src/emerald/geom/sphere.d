module emerald.geom.sphere;

import emerald.all;

final class Sphere : Shape {
public:
    float3 centre;
    float radius;
    float radiusSquared;
    AABB aabb;
    Material material;

    this(float radius, float3 centre, Material m) {
        this.radiusSquared = radius*radius;
        this.radius        = radius;
        this.centre        = centre;
        this.aabb          = AABB(centre-radius, centre+radius);
        this.material      = m;
    }

    override AABB getAABB()         { return aabb; }
    override Material getMaterial() { return material; }

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