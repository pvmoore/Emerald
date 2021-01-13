module emerald.geom.triangle;

import emerald.all;

/**
 * A non axis-aligned triangle. Note that an axis-aligned version of this could
 * be optimised for that use case and would be quicker.
 *
 *  0     1
 *  +----+
 *  |   /
 *  |  /
 *  | /        // top-left quadrant (0,1,2)
 *  |/
 *  +
 *  2    2
 *       +
 *      /|    // bottom-right quadrant (0,1,2)
 *     / |
 *    /  |
 *   /   |
 *  +----+
 *  1    0
 */

final class Triangle : Shape {
private:
    bool swapUV;
    float2 uvMin, uvRange, uvScale;
    bool hasVertexNormals;

    // Computed values
    AABB aabb;
    float3 edge1;
    float3 edge2;
    float3 normal;
public:
    uint id;
    Material material;
    float3 p0, p1, p2;
    float3 n0, n1, n2;

    uint getId() { return id; }

    this(float3 a, float3 b, float3 c, Material m) {
        this.id         = ids++;
        this.p0         = a;
        this.p1         = b;
        this.p2         = c;
        this.material   = m;
        this.uvMin      = float2(0,0);
        this.uvRange    = float2(1,1);
        this.uvScale    = float2(1,1);
        this.swapUV     = false;

        recalculate();
    }
    auto normals(float3 n0, float3 n1, float3 n2) {
        this.n0 = n0; this.n1 = n1; this.n2 = n2;
        this.hasVertexNormals = true;
        return this;
    }
    auto transform(mat4 t) {
        this.p0 = (t * float4(p0,1)).xyz;
        this.p1 = (t * float4(p1,1)).xyz;
        this.p2 = (t * float4(p2,1)).xyz;
        if(hasVertexNormals) {
            this.n0 = (t * float4(n0,0)).xyz;
            this.n1 = (t * float4(n1,0)).xyz;
            this.n2 = (t * float4(n2,0)).xyz;
        }
        recalculate();
        return this;
    }
    auto setUVScale(float2 uv) {
        this.uvScale = uv;
        return this;
    }
    /**
     * Set to a sub-range if you are using a texture atlas.
     * Normal range (0,0 -> 1,1)
     */
    auto setUVRange(float2 uvMin, float2 uvMax) {
        expect(uvMin.allGTE(float2(0,0)));
        expect(uvMax.allLTE(float2(1,1)));
        expect(uvMin.allLTE(uvMax));
        this.uvMin   = uvMin;
        this.uvRange = uvMax-uvMin;
        return this;
    }
    auto swapUVs() {
        this.swapUV = true;
        return this;
    }

    override void recalculate() {
        this.normal = (p1-p0).cross(p2-p0).normalised();
        this.aabb   = AABB(p0, p1, p2);
        this.edge1  = p1 - p0;
        this.edge2  = p2 - p0;
    }
    override AABB getAABB() {
        return aabb;
    }
    override Material getMaterial() {
        return material;
    }
    override float2 getUV(IntersectInfo intersect) {
        return intersect.uv;
    }
    /**
     *  https://en.wikipedia.org/wiki/M%C3%B6ller%E2%80%93Trumbore_intersection_algorithm
     */
    override bool intersect(ref Ray r, IntersectInfo ii) {
        float t;
	    // if(!(aabb.intersect(r, t, TMIN, ii.t))) {
	    //     return false;
	    // }
        //tmin = min(t, tmin);

        auto h = r.direction.cross(edge2);
        auto a = edge1.dot(h);
        // Exit if the ray is parallel to the triangle
        if(a >= -EPSILON && a <= EPSILON) return false;

        auto f = 1 / a;
        auto s = r.origin - p0;
        auto u = f * s.dot(h);
        if(u <= 0 || u >= 1) return false;

        auto q = s.cross(edge1);
        auto v = f * r.direction.dot(q);
        if(v<=0 || u+v >= 1) return false;

        t = f * edge2.dot(q);

        if(t >= TMIN && t < ii.t) {
            ii.t        = t;
			ii.hitPoint = r.origin + r.direction*t;
			ii.normal   = getNormal(u, v);
            ii.uv       = calculateUV(u, v);
			ii.shape    = this;
            return true;
        }

		return false;
    }
    override string dump(string padding) {
		return "%sTriangle[%s](%s)".format(padding, id, aabb);
    }
private:
    float2 calculateUV(float u, float v) {
        float2 uv = float2(u,v);
        if(swapUV) {
            uv = float2(1,1) - uv;
        }
        uv *= uvScale;
        uv.fract();
        uv *= uvRange;
        uv += uvMin;
        return uv;
    }
    float3 getNormal(float u, float v) {
        if(hasVertexNormals) {
            //
            // +----+ u
            // |   /
            // |  /
            // | /
            // |/
            // +
            // v
            float p0Dist = 1 - (u+v);
            float p1Dist = u;
            float p2Dist = v;

            return (n0 * p0Dist +
                    n1 * p1Dist +
                    n2 * p2Dist).normalised();
        }
        return normal;
    }
}