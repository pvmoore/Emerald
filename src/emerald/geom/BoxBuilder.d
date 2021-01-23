module emerald.geom.BoxBuilder;

import emerald.all;

final class BoxBuilder {
private:
    AABB aabb;
    Triangle[] triangles;
    float3 _translate, _scale;
    Angle!float _rotateX, _rotateY, _rotateZ;
    float2 uvScale;
public:
    enum Side { FRONT, BACK, TOP, BOTTOM, LEFT, RIGHT }

    this() {
        this._translate = float3(0,0,0);
        this._scale     = float3(1,1,1);
        this._rotateX   = 0.radians;
        this._rotateY   = 0.radians;
        this._rotateZ   = 0.radians;
        this.uvScale    = float2(1,1);
    }
    auto sides(Material mat, Side[] sides...) {
        foreach(s; sides) {
            addSide(s, mat);
        }
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
    /**
     * Call this before adding sides.
     * 0  1
     * +--+
     * |  |
     * |  |
     * +--+
     * 3  2
     */
    auto setUVScale(float2 uv) {
        expect(triangles.length == 0, "Call this before adding sides");
        this.uvScale = uv;
        return this;
    }
    Shape[] build() {
        expect(triangles.length > 0);

        // translate, scale and rotate the triangles

        mat4 t1 = mat4.translate(_translate);
        mat4 t2 = mat4.rotate(_rotateX, _rotateY, _rotateZ);
        mat4 t3 = mat4.scale(_scale);

        foreach(t; triangles) {
            t.generateVertexNormals();
            t.transform(t1 * t2 * t3);
        }

        return triangles[0..$].map!(it=>it.as!Shape).array;
    }
private:
    void addSide(Side side, Material mat) {

        float3 p0 = float3(-0.5, 0.5, -0.5);
        float3 p1 = p0 + float3(1, 0, 0);
        float3 p2 = p0 + float3(0, 0, 1);
        float3 p3 = p0 + float3(1, 0, 1);

        float3 p4 = p2 + float3(0, -1, 0);
        float3 p5 = p3 + float3(0, -1, 0);
        float3 p6 = p0 + float3(0, -1, 0);
        float3 p7 = p1 + float3(0, -1, 0);

        final switch(side) with(Side) {
            case FRONT:
                triangles ~= new Triangle(p2, p3, p4, mat).setUVScale(uvScale);
                triangles ~= new Triangle(p5, p4, p3, mat).swapUVs().setUVScale(uvScale);
                break;
            case BACK:
                triangles ~= new Triangle(p1, p0, p7, mat).setUVScale(uvScale);
                triangles ~= new Triangle(p6, p7, p0, mat).swapUVs().setUVScale(uvScale);
                break;
            case LEFT:
                triangles ~= new Triangle(p0, p2, p6, mat).setUVScale(uvScale);
                triangles ~= new Triangle(p4, p6, p2, mat).swapUVs().setUVScale(uvScale);
                break;
            case RIGHT:
                triangles ~= new Triangle(p3, p1, p5, mat).setUVScale(uvScale);
                triangles ~= new Triangle(p7, p5, p1, mat).swapUVs().setUVScale(uvScale);
                break;
            case TOP:
                triangles ~= new Triangle(p0, p1, p2, mat).setUVScale(uvScale);
                triangles ~= new Triangle(p3, p2, p1, mat).swapUVs().setUVScale(uvScale);
                break;
            case BOTTOM:
                triangles ~= new Triangle(p4, p5, p6, mat).setUVScale(uvScale);
                triangles ~= new Triangle(p7, p6, p5, mat).swapUVs().setUVScale(uvScale);
                break;
        }
    }
}