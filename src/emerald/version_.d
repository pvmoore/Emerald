module emerald.version_;

enum VERSION = "0.9";

/**
 * ##################################################################
 * HISTORY
 * ##################################################################
 *
 * 0.9 - Add Rectangle
 *     - Modify ManySpheres scene to use rectangles for the walls instead of spheres.
 * 0.8 - Rewrite ray trace radiance method so that it does not recurse.
 * 0.7 - Change max depth to 5 (instead of 9)
       - Add triangles
 * 0.6 - Reduce gamma slightly.
 * 0.5 - Add sphere texturing.
 * 0.4 - Add bounding volume hierarchy (BVH) data structure.
 *
 * ##################################################################
 * TODO
 * ##################################################################
 * - Create a bubble sphere with eta=1 (same as air)
 * - Add a skybox (for an outdoor scene)
 * - Use triangles instead of spheres for the walls. Is this faster?
 */
