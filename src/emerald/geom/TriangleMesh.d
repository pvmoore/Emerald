module emerald.geom.TriangleMesh;

import emerald.all;

final class TriangleMesh : Shape {
private:
    Shape[] triangles;
    float3 _translate, _scale;
    Angle!float _rotateX, _rotateY, _rotateZ;
    Material material;
    Shape bvh;
    bool forceSurfaceNormals;

    // Computed values
    AABB aabb;
public:
    uint id;

    this(string filename, Material mat, bool forceSurfaceNormals = false) {
        this.id         = ids++;
        this._translate = float3(0,0,0);
        this._scale     = float3(1,1,1);
        this._rotateX   = 0.radians;
        this._rotateY   = 0.radians;
        this._rotateZ   = 0.radians;
        this.material   = mat;
        this.forceSurfaceNormals = forceSurfaceNormals;

        loadAndConvert(filename);
    }
    auto build() {
        expect(triangles.length > 0);

        // translate, scale and rotate the triangles

        mat4 t1 = mat4.translate(_translate);
        mat4 t2 = mat4.rotate(_rotateX, _rotateY, _rotateZ);
        mat4 t3 = mat4.scale(_scale);

        foreach(t; triangles) {
            t.as!Triangle.transform(t1 * t2 * t3);
        }

        this.bvh = BVH.build(triangles);

        recalculateAABB();
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
    override AABB getAABB() {
        return aabb;
    }
    override Material getMaterial() {
        expect(false); assert(false);
    }
    override float2 getUV(IntersectInfo intersect) {
        expect(false); assert(false);
    }
    override void recalculate() {
        foreach(t; triangles) {
            t.recalculate();
        }
        recalculateAABB();
    }
    override bool intersect(ref Ray r, IntersectInfo ii, float tmin) {
        float t;
	    if(!(aabb.intersect(r, t, tmin, ii.t))) {
	        return false;
	    }
        tmin = min(t, tmin);

        return bvh.intersect(r, ii, tmin);
    }
    override string dump(string padding) {
        return "%sTriangleMesh(%s)".format(padding, aabb);
    }
private:
    void recalculateAABB() {
        this.aabb = triangles[0].getAABB();
        foreach(t; triangles[1..$]) {
            aabb.enclose(t.getAABB());
        }
    }
    void loadAndConvert(string filename) {
        ModelData data = Obj.read(filename);
        // float3[] vertices;
        // float3[] normals;
        // float2[] uvs;
        // Face[] faces;
        // struct Face {
        //     int[3] iVertices;
        //     int[3] iUvs;
        //     int[3] iNormals;
        //     float4[3] colours;

        //     bool hasNormals() { return iNormals[0] != -1; }
        //     bool hasUvs() { return iUvs[0] != -1; }
        // }
        foreach(ref f; data.faces) {
            float3 v0 = data.vertex(f, 0);
            float3 v1 = data.vertex(f, 1);
            float3 v2 = data.vertex(f, 2);

            // normals at points
            // if(f.hasNormals()) {
            //     v0.vertexNormal_modelspace = data.normal(f, 0);
            //     v1.vertexNormal_modelspace = data.normal(f, 1);
            //     v2.vertexNormal_modelspace = data.normal(f, 2);
            // }

            //data.colour(f, 0)

            // if(f.hasUvs()) {
            //     v0.vertexUV = data.uv(f, 0);
            //     v1.vertexUV = data.uv(f, 1);
            //     v2.vertexUV = data.uv(f, 2);
            //}

            auto t = new Triangle(v0, v1, v2, material);

            if(!forceSurfaceNormals && f.hasNormals()) {
                float3 n0 = data.normal(f, 0);
                float3 n1 = data.normal(f, 1);
                float3 n2 = data.normal(f, 2);
                t.normals(n0, n1, n2);
            }

            triangles ~= t;
        }
    }
}
