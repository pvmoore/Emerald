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
    AABB aabb;
    Material material;
    float3 p0, p1, p2;
    float3 normal;
    float2 uvMin, uvRange, uvScale;
    bool swapUV;
    // Computed values
    float3 p0p1;// = p0 - p1;
    float3 p0p2;// = p0 - p2;
public:
    uint id;

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
    auto transform(mat4 t) {
        this.p0 = (t * float4(p0,1)).xyz;
        this.p1 = (t * float4(p1,1)).xyz;
        this.p2 = (t * float4(p2,1)).xyz;
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
    override bool intersect(ref Ray r, IntersectInfo ii, float tmin) {
        enum E     = 0.00001f;
        auto edge1 = p1 - p0;
        auto edge2 = p2 - p0;
        auto h     = r.direction.cross(edge2);
        auto a     = edge1.dot(h);
        if(a >= -E && a <= E) return false;

        auto f = 1f / a;
        auto s = r.origin - p0;
        auto u = f * s.dot(h);
        if(u <= 0 || u >= 1) return false;

        auto q = s.cross(edge1);
        auto v = f * r.direction.dot(q);
        if(v<=0 || u+v >= 1) return false;

        auto t = f * edge2.dot(q);

        if(t >= tmin && t < ii.t) {
            ii.t        = t;
			ii.hitPoint = r.origin + r.direction*t;
			ii.normal   = normal;
            ii.uv       = calculateUV(u, v);
			ii.shape    = this;
            return true;
        }

		return false;
    }
/*
    override bool intersect(ref Ray r, IntersectInfo ii, float tmin) {
        float A = p0.x - p1.x;
		float B = p0.y - p1.y;
		float C = p0.z - p1.z;
		float D = p0.x - p2.x;
		float E = p0.y - p2.y;
		float F = p0.z - p2.z;

        float J = p0.x - r.origin.x;
		float K = p0.y - r.origin.y;
		float L = p0.z - r.origin.z;

		float G = r.direction.x;
		float H = r.direction.y;
		float I = r.direction.z;

        // float3 JKL = p0 - r.origin;
        // float3 GHI = r.direction;

		float EIHF = E*I - F*H;
		float GFDI = F*G - D*I;
		float DHEG = D*H - E*G;

		float AKJB = A*K - J*B;
		float JCAL = C*J - L*A;
		float BLKC = B*L - K*C;

		float denom = (A*EIHF + B*GFDI + C*DHEG);
		float denomReciprocal = 1f / denom;

		float u = (J*EIHF + K*GFDI + L*DHEG) * denomReciprocal;

		if(u <= 0 || u >= 1) return false;

		float v = (I*AKJB + H*JCAL + G*BLKC) * denomReciprocal;

		if(v <= 0 || u + v >= 1) return false;

		float M = -(F*AKJB + E*JCAL + D*BLKC);
		float t = M * denomReciprocal;

        if(t >= tmin && t < ii.t) {
            ii.t        = t;
			ii.hitPoint = r.origin + r.direction*t;
			ii.normal   = normal;
            ii.uv       = calculateUV(u, v);
			ii.shape    = this;
            return true;
        }

		return false;
    }
    */
    override string dump(string padding) {
		return "%sTriangle(%s)".format(padding, aabb);
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
}