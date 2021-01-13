
struct AABB {
    vec3 a;
    vec3 b;
};

bool aabb_intersect(AABB aabb, Ray ray) { //, out float minT, out float maxT) {
	vec3 tNearV = (aabb.a-ray.origin) * ray.invDir;
    vec3 tFarV  = (aabb.b-ray.origin) * ray.invDir;
    vec3 tNear  = min(tNearV, tFarV);
    vec3 tFar   = max(tNearV, tFarV);

    float minT = max(tNear.x, max(tNear.y, tNear.z));
    float maxT = min(tFar.x, min(tFar.y, tFar.z));

	return maxT >= max(minT, 0);
}
