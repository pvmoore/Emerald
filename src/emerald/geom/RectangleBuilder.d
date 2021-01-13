module emerald.geom.RectangleBuilder;

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
final class RectangleBuilder {
private:
    float3 _translate, _scale;
    Angle!float _rotateX, _rotateY, _rotateZ;
    float2 uvScale, uvMin, uvMax;
    Material material;
public:
    this(Material mat) {
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
    Shape[] build() {

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

        Triangle[2] triangles;

        float3 p0 =      float3(-0.5, 0, -0.5);
        float3 p1 = p0 + float3(   1, 0,    0);
        float3 p2 = p0 + float3(   1, 0,    1);
        float3 p3 = p0 + float3(   0, 0,    1);

        triangles[0] = new Triangle(p0, p1, p3, material)
            .setUVScale(uvScale)
            .setUVRange(uvMin, uvMax);

        triangles[1] = new Triangle(p2, p3, p1, material)
            .swapUVs()
            .setUVScale(uvScale)
            .setUVRange(uvMin, uvMax);

        triangles[0].normals(
            (p1-p0).cross(p3-p0).normalised(),
            (p1-p0).cross(p3-p0).normalised(),
            (p1-p0).cross(p3-p0).normalised()
        );
        triangles[1].normals(
            (p3-p2).cross(p1-p2).normalised(),
            (p3-p2).cross(p1-p2).normalised(),
            (p3-p2).cross(p1-p2).normalised()
        );

        mat4 t1 = mat4.translate(_translate);
        mat4 t2 = mat4.rotate(_rotateX, _rotateY, _rotateZ);
        mat4 t3 = mat4.scale(_scale);

        triangles[0].transform(t1 * t2 * t3);
        triangles[1].transform(t1 * t2 * t3);

        triangles[0].recalculate();
        triangles[1].recalculate();

        return triangles[0..$].map!(it=>it.as!Shape).array;
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
}