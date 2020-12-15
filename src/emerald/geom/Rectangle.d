module emerald.geom.Rectangle;

import emerald.all;

/**
 *  Rectangle where all points are on the same plane.
 *
 *  0    1
 *  +----+
 *  |\   |  0 -> 1
 *  | \  |  0 -> 2
 *  |  \ |  0 -> 3
 *  |   \|
 *  +----+
 *  2    3
 */
final class Rectangle : Shape {
private:
    Triangle[2] triangles;
    float3 _translate, _scale;
    Angle!float _rotateX, _rotateY, _rotateZ;
    float2 uvScale, uvMin, uvMax;
    Material material;

    // Computed values
    AABB aabb;
public:
    uint id;

    this(Material mat) {
        this.id         = ids++;
        this.material   = mat;
        this.uvScale    = float2(1,1);
        this.uvMin      = float2(0,0);
        this.uvMax      = float2(1,1);
        this._translate = float3(0,0,0);
        this._scale     = float3(1,1,1);
        this._rotateX   = 0.radians;
        this._rotateY   = 0.radians;
        this._rotateZ   = 0.radians;
    }
    auto build() {

        /**
         * Creates a rectangle on the Y-axis (y=0).
         *
         * 0  1
         * +--+
         * | /|
         * |/ |
         * +--+
         * 3  2
         */
        float3 p0 =      float3(-0.5, 0, -0.5);
        float3 p1 = p0 + float3(   1, 0,    0);
        float3 p2 = p0 + float3(   1, 0,    1);
        float3 p3 = p0 + float3(   0, 0,    1);

        this.triangles[0] = new Triangle(p0, p1, p3, material)
            .setUVScale(uvScale)
            .setUVRange(uvMin, uvMax);

        this.triangles[1] = new Triangle(p2, p3, p1, material)
            .swapUVs()
            .setUVScale(uvScale)
            .setUVRange(uvMin, uvMax);

        mat4 t1 = mat4.translate(_translate);
        mat4 t2 = mat4.rotate(_rotateX, _rotateY, _rotateZ);
        mat4 t3 = mat4.scale(_scale);

        triangles[0].transform(t1 * t2 * t3);
        triangles[1].transform(t1 * t2 * t3);

        recalculateAABB();
        return this;
    }
    auto setUVScale(float2 uv) {
        this.uvScale = uv;
        return this;
    }
    auto setUVRange(float2 uvMin, float2 uvMax) {
        expect(uvMin.allGTE(float2(0,0)));
        expect(uvMax.allLTE(float2(1,1)));
        expect(uvMin.allLTE(uvMax));
        this.uvMin = uvMin;
        this.uvMax = uvMax;
        return this;
    }
    auto translate(float3 t) {
        this._translate = t;
        return this;
    }
    auto scale(float3 t) {
        this._scale = t;
        return this;
    }
    auto rotate(Angle!float x, Angle!float y, Angle!float z) {
        this._rotateX = x;
        this._rotateY = y;
        this._rotateZ = z;
        return this;
    }
    override void recalculate() {
        triangles[0].recalculate();
        triangles[1].recalculate();
        recalculateAABB();
    }
    override AABB getAABB() {
        return aabb;
    }
    override Material getMaterial() {
        expect(false); assert(false);
    }
    override float2 getUV(IntersectInfo intersect) {
        expect(false); assert(false);
    }
    override bool intersect(ref Ray r, IntersectInfo ii, float tmin) {
        float t;
	    if(!(aabb.intersect(r, t, tmin, ii.t))) {
	        return false;
	    }
        tmin = min(t, tmin);

        bool hit = triangles[0].intersect(r, ii, tmin);
            hit |= triangles[1].intersect(r, ii, tmin);
        return hit;
    }
    override string dump(string padding) {
		return "%sRectangle(%s)".format(padding, aabb);
    }
private:
    void recalculateAABB() {
        this.aabb = triangles[0].getAABB().enclose(triangles[1].getAABB());
    }
}