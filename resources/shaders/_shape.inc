/*
struct Triangle | BVH {
    [0] type_bvh or type_tri
    [1] vec3 aabb.a;
    [2]
    [3]
    [4] vec3 aabb.b;
    [5]
    [6]
*/

// Supported shape types (the type is always the first float)
#define type_bvh (0)
#define type_tri (1)
#define type_sphere (2)

#define isBvh(i)    (int(shapes[i]) == 0)
#define isTri(i)    (int(shapes[i]) == 1)
#define isSphere(i) (int(shapes[i]) == 2)

#define SHAPE_type(i) int(shapes[i])
#define SHAPE_aabb(i) AABB(vec3(shapes[i+1], shapes[i+2], shapes[i+3]), \
                         vec3(shapes[i+4], shapes[i+5], shapes[i+6]))

bool shape_intersect(Ray ray, inout IntersectInfo ii) {

    // Set closest distance to maximum
    ii.t = TMAX;

    uint stack[32];
    int sp = 0;
    bool hit = false;

    stack[0] = 0; // shape 0

    int count = 0;

    while(sp >= 0) {

        count++;

        uint shape = stack[sp--];

        AABB aabb = SHAPE_aabb(shape);

        if(aabb_intersect(aabb, ray)) {

            if(isBvh(shape)) {

                uint left  = BVH_left(shape);
                uint right = BVH_right(shape);

                stack[++sp] = left;
                stack[++sp] = right;
            } else if(isTri(shape)) {
                hit = tri_intersect(shape, ray, ii) || hit;
            } else {
                hit = sphere_intersect(shape, ray, ii) || hit;
            }
        }
    }

    // if(true && g_index == 0 && depth==0 && printBarrier()) {
    //     printu(count);
    //     printu(hit ? 1 : 0);
    // }

    return hit;
}