/*
struct BVH {
    [0] type_bvh
    [1] vec3 aabb.a;
    [2]
    [3]
    [4] vec3 aabb.b;
    [5]
    [6]

    [7] uint left;     // index of left shape
    [8] uint right;    // index of right shape
};
*/

#define BVH_left(i)   floatBitsToUint(shapes[i+7])
#define BVH_right(i)  floatBitsToUint(shapes[i+8])

// bool bvh_intersect(uint i, Ray ray, inout IntersectInfo ii, float tmin) {
//     float tNear, tFar;
//     AABB aabb = BVH_aabb(i);
//     if(!(intersect(aabb, ray, tNear, tFar))) {
//          return false;
//     }
//     tmin = min(tNear, tmin);

//     uint left  = BVH_left(i);
//     uint right = BVH_right(i);

//     // Call hit on both branches to get the minimum intersection
//     bool isahit1 = isBvh(left)
//         ? bvh_intersect(left, ray, ii, tmin)
//         : tri_intersect(left, ray, ii, tmin);

//     bool isahit2 = isBvh(right)
//         ? bvh_intersect(right, ray, ii, tmin)
//         : tri_intersect(right, ray, ii, tmin);

//     return isahit1 || isahit2;
// }
