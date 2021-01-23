/*
    [0] type_sphere
    [1] vec3 aabb.a;
    [2]
    [3]
    [4] vec3 aabb.b;
    [5]
    [6]

    [7] radius
    [8] centre
    [9]
    [10]
    [11-26] transformation (16 floats)
    [27]
*/

#define sphere_radius(i)         shapes[i+7]
#define sphere_centre(i)         vec3(shapes[i+8], shapes[i+9], shapes[i+10])
#define sphere_transformation(i) mat4(shapes[i+11], shapes[i+12], shapes[i+13], shapes[i+14], \
                                      shapes[i+15], shapes[i+16], shapes[i+17], shapes[i+18], \
                                      shapes[i+19], shapes[i+20], shapes[i+21], shapes[i+22], \
                                      shapes[i+23], shapes[i+24], shapes[i+25], shapes[i+26])
#define sphere_mat(i)            int(shapes[i+27])

/**
 * Map 3D hit point on the sphere to 2D UV texture coordinates.
 */
vec2 calculateUV(uint shape, vec3 normal) {
    float invPI  = 1.0 / PI;
    float inv2PI = 1.0 / (PI*2);
    mat4 transformation = sphere_transformation(shape);

    vec4 t = vec4(normal, 0) * transformation;

    float u = 1 - (0.5 + (atan(t.z, t.x) * inv2PI)); // atan2
    float v = 1 - ((asin(t.y)+PI_2) * invPI);

    return vec2(clamp(u, 0,1), clamp(v, 0,1));
}


bool sphere_intersect(uint shape, Ray ray, inout IntersectInfo ii) {
    float radius = sphere_radius(shape);
    vec3 centre  = sphere_centre(shape);
    vec3 op      = centre - ray.origin;
    float b      = dot(op, ray.dir);
    float det    = (b*b) - dot(op,op) + radius*radius;

    if(det<0) return false;

    det = sqrt(det);

    float t;
    bool hit = false;

    if((t=b-det) > TMIN) {
        hit = t < ii.t;
    } else if((t=b+det) > TMIN) {
        hit = t < ii.t;
    }

    if(hit) {
        ii.t        = t;
        ii.hitPoint = ray.origin + ray.dir*t;
        ii.material = sphere_mat(shape);
        ii.normal   = normalize(ii.hitPoint - centre);
        ii.uv       = mat_hasTexture(ii.material) ? calculateUV(shape, ii.normal) : vec2(0,0);
    }
    return hit;
}