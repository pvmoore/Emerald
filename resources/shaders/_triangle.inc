/*
struct Triangle {
    [0] type_tri
    [1] vec3 aabb.a;
    [2]
    [3]
    [4] vec3 aabb.b;
    [5]
    [6]

    [7] vec3 p0;
    [8]
    [9]
    [10] vec3 p1;
    [11]
    [12]
    [13] vec3 p2;
    [14]
    [15]
    [16] vec3 n0;
    [17]
    [18]
    [19] vec3 n1;
    [20]
    [21]
    [22] vec3 n2;
    [23]
    [24]
    [25] uint material;
};
*/

#define TRI_p0(i)   vec3(shapes[i+7],  shapes[i+8],  shapes[i+9])
#define TRI_p1(i)   vec3(shapes[i+10], shapes[i+11], shapes[i+12])
#define TRI_p2(i)   vec3(shapes[i+13], shapes[i+14], shapes[i+15])
#define TRI_n0(i)   vec3(shapes[i+16], shapes[i+17], shapes[i+18])
#define TRI_n1(i)   vec3(shapes[i+19], shapes[i+20], shapes[i+21])
#define TRI_n2(i)   vec3(shapes[i+22], shapes[i+23], shapes[i+24])
#define TRI_mat(i)  int(shapes[i+25])

// vec3 getNormal(float u, float v) {
//     if(hasVertexNormals) {
//         //
//         // +----+ u
//         // |   /
//         // |  /
//         // | /
//         // |/
//         // +
//         // v
//         float p0Dist = 1 - (u+v);
//         float p1Dist = u;
//         float p2Dist = v;

//         return (n0 * p0Dist +
//                 n1 * p1Dist +
//                 n2 * p2Dist).normalised();
//     }
//     return (p1-p0).cross(p2-p0).normalised();;
// }

vec2 calculateUV(float u, float v) {
    return vec2(u,v);
}

vec3 triVertexNormal(uint shape, float u, float v) {
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

    vec3 n0 = TRI_n0(shape);
    vec3 n1 = TRI_n1(shape);
    vec3 n2 = TRI_n2(shape);

    return normalize(n0 * p0Dist +
                     n1 * p1Dist +
                     n2 * p2Dist);
}

bool tri_intersect(uint shape, Ray ray, inout IntersectInfo ii) {
    // float tNear, tFar;
    // AABB aabb = SHAPE_aabb(shape);
    // if(!(intersect(aabb, ray, tNear, tFar))) {
    //      return false;
    // }
    // tmin = min(tNear, tmin);

    float E    = 0.00001f;
    vec3 p0    = TRI_p0(shape);
    vec3 edge1 = TRI_p1(shape) - p0;
    vec3 edge2 = TRI_p2(shape) - p0;

    vec3 h  = cross(ray.dir, edge2);
    float a = dot(edge1, h);
    // Exit if the ray is parallel to the triangle
    if(a >= -E && a <= E) return false;

    float f = 1.0 / a;
    vec3 s  = ray.origin - p0;
    float u = f * dot(s, h);
    if(u <= 0 || u >= 1) return false;

    vec3 q  = cross(s, edge1);
    float v = f * dot(ray.dir, q);
    if(v<=0 || u+v >= 1) return false;

    float t = f * dot(edge2, q);

    if(t >= TMIN && t < ii.t) {
        ii.t        = t;
        ii.hitPoint = ray.origin + ray.dir*t;
        ii.material = TRI_mat(shape);

        //ii.uv       = calculateUV(u, v);

        //ii.normal   = normalize(cross(edge1, edge2));
        ii.normal = triVertexNormal(shape, u, v);
        return true;
    }

    return false;
}
