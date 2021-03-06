module emerald.version_;

enum VERSION = "0.13";

/**
 * ##################################################################
 * HISTORY
 * ##################################################################
 *
 * To fix: Fix this error by creating one GPUPathTracer per frame.
 *         Or possibly it only requires one targetImage per frame.
 *   [ERROR] Validation Error: [ UNASSIGNED-CoreValidation-DrawState-InvalidImageLayout ] Object 0: handle = 0x20566ebe0a8, type = VK_OBJECT_TYPE_COMMAND_BUFFER; | MessageID = 0x4dae5635 | Submitted command buffer expects VkImage 0x203fc60000000023[] (subresource: aspectMask 0x1 array layer 0, mip level 0) to be in layout VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL--instead, current layout is VK_IMAGE_LAYOUT_GENERAL.
 *
 *
 * 0.13 - TBC
 * 0.12 - Enable Spheres and materials for GPU path tracer
 * 0.11 - Optimise software path tracer slightly
 *      - Start to implement GPU path tracer
 * 0.10 - Convert to Vulkan
 * 0.9  - Add Rectangle
 *      - Add TriangleMesh
 *      - Modify ManySpheres scene to use rectangles for the walls instead of spheres.
 * 0.8  - Rewrite ray trace radiance method so that it does not recurse.
 * 0.7  - Change max depth to 5 (instead of 9)
        - Add triangles
 * 0.6  - Reduce gamma slightly.
 * 0.5  - Add sphere texturing.
 * 0.4  - Add bounding volume hierarchy (BVH) data structure.
 *
 * ##################################################################
 * TODO
 * ##################################################################
 * - Add a skybox (and add an outdoor scene to demonstrate it)
 * - Run averaging pass every few iterations
 * - Add multisample to GPU path tracer
 *
 * - Acceleration structure for GPU
 *   ------------------------------
 *   Divide the world space into blocks. Each block contains a pointer to a list of shapes
 *   that have some part of their geometry inside that block. We will need to use ray marching
 *   to march through the blocks and test each shape in that block. We can also mark each shape
 *   that has already been tested so that we don't do any shape twice.
 *   We may end up testing more shapes this way but it might be faster due to not having to
 *   navigate a BVH tree.
 */
