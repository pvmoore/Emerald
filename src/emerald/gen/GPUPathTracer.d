module emerald.gen.GPUPathTracer;

import emerald.all;
import vulkan;

final class GPUPathTracer : IPathTracerStats {
private:
    static struct PushConstants {
        float frameNumber;
        float imageIteration;
        float imageState;   // 0 = continue, 1 = restart
        float random0;
        float random1;
        float random2;
        float random3;
    }
    static struct UBO {
        float3 cameraPosition;
        float _pad1;
        float3 cameraDirection; // normalised
        float _pad2;
    }
    enum DEBUG = false;

    @Borrowed VulkanContext context;
    @Borrowed VkDevice device;
    @Borrowed Vulkan vk;
    @Borrowed Scene scene;
    @Borrowed VkCommandBuffer cmd;
    @Borrowed ImageMeta texture;

    Mt19937 rng;

    const uint width;
    const uint height;
    int iterations;
    PushConstants pushConstants;
    ulong computeTime;

    ShaderPrintf shaderPrintf;
    Descriptors descriptors;
    ComputePipeline pipeline;
    StaticGPUData!float randomBuffer;
    StaticGPUData!float tentFilterBuffer;
    StaticGPUData!float materialData;
    GPUData!float shapeData;
    GPUData!UBO ubo;
    DeviceImage targetImage;
    DeviceBuffer accumulatedColours;
    VkSampler textureSampler;
    VkCommandPool computeCP;
    VkSemaphore computeFinished;
    VkQueryPool queryPool;
public:
    DeviceImage getTargetImage() {
        return targetImage;
    }
    int getIterations() {
        return iterations;
    }
    int getCurrentImageIterations() {
        return pushConstants.imageIteration.as!int;
    }
    uint samplesPerPixel() {
        return 1;
    }
    ulong getComputeTime() {
        return computeTime;
    }

    this(VulkanContext context, Scene scene, uint width, uint height) {
        this.context = context;
        this.device = context.device;
        this.vk = context.vk;
        this.scene = scene;
        this.width = width;
        this.height = height;
        rng.seed(RANDOM_SEED);

        initialise();
    }
    void destroy() {
        this.log("Destroying");

        if(queryPool) device.destroyQueryPool(queryPool);
        if(shaderPrintf) shaderPrintf.destroy();
        if(computeCP) device.destroyCommandPool(computeCP);
        if(descriptors) descriptors.destroy();
        if(pipeline) pipeline.destroy();
        if(randomBuffer) randomBuffer.destroy();
        if(tentFilterBuffer) tentFilterBuffer.destroy();
        if(shapeData) shapeData.destroy();
        if(materialData) materialData.destroy();
        if(ubo) ubo.destroy();
        if(accumulatedColours) accumulatedColours.destroy();
        if(textureSampler) device.destroySampler(textureSampler);
        if(computeFinished) device.destroySemaphore(computeFinished);
    }
    VkSemaphore compute(Frame frame) {
        return computeFrame(frame);
    }
private:
    void initialise() {
        this.log("Initialising");
        createLinearSampler();
        createAccumulatedColoursBuffer();
        createTargetImage();
        createShapeData();
        createMaterialData();
        loadTextures();
        createRandomBuffer();
        createTentFilterBuffer();
        createUBO();
        createCommandPools();
        createQueryPool();
        createCommandBuffer();
        createSemaphore();
        createShaderPrintf();
        createDescriptors();
        createPipeline();

        iterations = -1;

        pushConstants.frameNumber = -1;
        pushConstants.imageIteration = 0;
        pushConstants.imageState = 1;

        this.log("Ready");
    }
    void createLinearSampler() {
        this.textureSampler = device.createSampler(samplerCreateInfo());
    }
    void createAccumulatedColoursBuffer() {
        this.accumulatedColours = context.memory(MemID.LOCAL).allocBuffer("AccumulatedColours",
                           width*height*float4.sizeof,
                           VBufferUsage.STORAGE);
    }
    void createTargetImage() {
        this.targetImage = context.memory(MemID.LOCAL).allocImage("TargetImage",
                           [width, height],
                           VImageUsage.STORAGE | VImageUsage.SAMPLED ,
                           VFormat.B8G8R8A8_UNORM,
                           (info) {});
        this.targetImage.createView(VFormat.B8G8R8A8_UNORM, VImageViewType._2D, VImageAspect.COLOR);
    }
    void createShapeData() {
        enum SHAPE_DATA_LENGTH = 1024*1024;
        this.shapeData = new GPUData!float(context, BufID.STORAGE, true, SHAPE_DATA_LENGTH*float.sizeof).initialise();

        // Convert shape data so that it contains only BVH or Triangle
        float[] data = new float[SHAPE_DATA_LENGTH];
        /*
        Shape
        [0] type_bvh or type_tri
        [1] vec3 aabb.a;
        [2]
        [3]
        [4] vec3 aabb.b;
        [5]
        [6]

        BVH
        [7] uint left;     // index of left shape
        [8] uint right;    // index of right shape

        Triangle
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
        [26] swapUV (0 or 1)
        [27] uvScale
        [28]
        [29] uvRange
        [30]
        [31] uvMin
        [32]

        Sphere
        [7] radius
        [8] centre
        [9]
        [10]
        [11-26] transformation
        [27] uint material
        */

        enum Type { BVH = 0, TRI = 1, SPHERE  = 2 }
        enum Size { BVH = 9, TRI = 33, SPHERE = 28 }
        uint nextFree = 0;
        float* nextFreePtr = cast(float*)&nextFree;

        uint[uint] id2index;

        //import Sphere2 = emerald.all : Sphere;

        void _recurse(Shape s) {
            uint i = nextFree;
            if(s.isA!BVH) {
                auto bvh = s.as!BVH;
                nextFree += Size.BVH;

                id2index[s.getId()] = i;

                data[i++] = Type.BVH;
                data[i++] = bvh.aabb.min().x;
                data[i++] = bvh.aabb.min().y;
                data[i++] = bvh.aabb.min().z;
                data[i++] = bvh.aabb.max().x;
                data[i++] = bvh.aabb.max().y;
                data[i++] = bvh.aabb.max().z;

                data[i++] = *nextFreePtr;
                _recurse(bvh.left);

                data[i++] = *nextFreePtr;
                _recurse(bvh.right);

            } else if(s.isA!Triangle) {
                auto t = s.as!Triangle;
                nextFree += Size.TRI;

                id2index[s.getId()] = i;

                data[i++] = Type.TRI;
                data[i++] = t.getAABB().min().x;
                data[i++] = t.getAABB().min().y;
                data[i++] = t.getAABB().min().z;
                data[i++] = t.getAABB().max().x;
                data[i++] = t.getAABB().max().y;
                data[i++] = t.getAABB().max().z;

                data[i++] = t.p0.x;
                data[i++] = t.p0.y;
                data[i++] = t.p0.z;
                data[i++] = t.p1.x;
                data[i++] = t.p1.y;
                data[i++] = t.p1.z;
                data[i++] = t.p2.x;
                data[i++] = t.p2.y;
                data[i++] = t.p2.z;

                data[i++] = t.n0.x;
                data[i++] = t.n0.y;
                data[i++] = t.n0.z;
                data[i++] = t.n1.x;
                data[i++] = t.n1.y;
                data[i++] = t.n1.z;
                data[i++] = t.n2.x;
                data[i++] = t.n2.y;
                data[i++] = t.n2.z;

                // material
                data[i++] = t.material.id * 9;

                // [26] swapUV (0 or 1)
                // [27] uvScale
                // [28]
                // [29] uvRange
                // [30]
                // [31] uvMin
                // [32]

                data[i++] = t.swapUV ? 1 : 0;
                data[i++] = t.uvScale.x;
                data[i++] = t.uvScale.y;
                data[i++] = t.uvRange.x;
                data[i++] = t.uvRange.y;
                data[i++] = t.uvMin.x;
                data[i++] = t.uvMin.y;

            } else if(s.isA!Sphere) {
                auto t = s.as!Sphere;
                nextFree += Size.SPHERE;

                id2index[s.getId()] = i;

                data[i++] = Type.SPHERE;
                data[i++] = t.getAABB().min().x;
                data[i++] = t.getAABB().min().y;
                data[i++] = t.getAABB().min().z;
                data[i++] = t.getAABB().max().x;
                data[i++] = t.getAABB().max().y;
                data[i++] = t.getAABB().max().z;

                data[i++] = t.radius;
                data[i++] = t.centre.x;
                data[i++] = t.centre.y;
                data[i++] = t.centre.z;

                data[i++] = t.transformation[0][0];
                data[i++] = t.transformation[0][1];
                data[i++] = t.transformation[0][2];
                data[i++] = t.transformation[0][3];
                data[i++] = t.transformation[1][0];
                data[i++] = t.transformation[1][1];
                data[i++] = t.transformation[1][2];
                data[i++] = t.transformation[1][3];
                data[i++] = t.transformation[2][0];
                data[i++] = t.transformation[2][1];
                data[i++] = t.transformation[2][2];
                data[i++] = t.transformation[2][3];
                data[i++] = t.transformation[3][0];
                data[i++] = t.transformation[3][1];
                data[i++] = t.transformation[3][2];
                data[i++] = t.transformation[3][3];

                data[i++] = t.material.id * 9;

            } else if(s.isA!TriangleMesh) {
                auto mesh = s.as!TriangleMesh;

                _recurse(mesh.bvh);

            } else {
                todo("Handle Shape %s".format(s));
            }
        }

        this.log("Generating shapeData");
        _recurse(scene.getBVH());

        this.log("shapeData = (%s floats) %s", nextFree, data[0..16]);

        foreach(id; [8, 9, 3886, 3887, 3888]) {
            auto p = id in id2index;
             this.log("%s = %s", id, p ? *p : -1);
        }

        shapeData.write(data[0..nextFree]);
    }
    void createMaterialData() {
        /*
            [0] reflectance     // 0 = not reflective
            [1] refractiveIndex // 0 = not refractive
            [2] Diffuse RGB
            [3]
            [4]
            [5] Emission RGB
            [6]
            [7]
            [8] texture
        */

        this.log("There are %s materials:", Material.getAllMaterials().length);
        float[] materials;
        foreach(i, m; Material.getAllMaterials()) {
            auto g = m.getForGPU();
            materials ~=g;
            this.log("  [%s] %s", i, g);
        }

        this.materialData = new StaticGPUData!float(context, 10000)
            .uploadData(materials);
    }
    void loadTextures() {
        /*
            There is a single texture which contains 16 sub-textures:

            | uvs   | brick   | redWhite | earth
            | rock  | marble  |    2,1   |  3,1
            |  0,2  |   1,2   |    2,2   |  3,2
            |  0,3  |   1,3   |    2,3   |  3,3

        */
        this.texture = context.images().get("4096x4096.png");
    }
    void createRandomBuffer() {
        enum NUM_RANDOMS = 1024*1024*1;
        float[] data = new float[NUM_RANDOMS];
        rng.seed(RANDOM_SEED);
        foreach(i; 0..NUM_RANDOMS) {
            data[i] = uniform(0f, 1f, rng);
        }

        this.randomBuffer = new StaticGPUData!float(context, NUM_RANDOMS)
            .uploadData(data);
    }
    void createTentFilterBuffer() {
        enum NUM_RANDOMS = 1024*1024;
        float[] data = new float[NUM_RANDOMS];
        rng.seed(RANDOM_SEED);
        foreach(i; 0..NUM_RANDOMS) {
            float r = uniform(0f, 2f, rng);
            data[i] = r<1 ? sqrt(r)-1 : 1-sqrt(2-r);
        }

        this.tentFilterBuffer = new StaticGPUData!float(context, NUM_RANDOMS)
            .uploadData(data);
    }
    void createUBO() {
        ubo = new GPUData!UBO(context, BufID.UNIFORM, true).initialise();
        ubo.write((u) {
            u.cameraPosition = scene.getCamera().position;
            u.cameraDirection = scene.getCamera().direction.normalised();
        });
    }
    void createCommandPools() {
        this.computeCP = device.createCommandPool(
            vk.getComputeQueueFamily().index,
            VCommandPoolCreate.TRANSIENT | VCommandPoolCreate.RESET_COMMAND_BUFFER
        );
    }
    void createQueryPool() {
        this.queryPool = device.createQueryPool(
            VQueryType.TIMESTAMP,       // queryType
            vk.swapchain.numImages*2    // num queries
        );
    }
    void createCommandBuffer() {
        this.cmd = device.allocFrom(computeCP);
    }
    void createSemaphore() {
        this.computeFinished = device.createSemaphore();
    }
    void createShaderPrintf() {
        if(DEBUG) {
            this.shaderPrintf = new ShaderPrintf(context);
        }
    }
    void createDescriptors() {
        /**
         * 0 - Random data
         * 1 - TentFilter data
         * 2 - Shape data
         * 3 - Material data
         * 4 - Accumulated colours
         * 5 - Texture
         * 6 - Target image
         * 7 - UBO
         */
        this.descriptors = new Descriptors(context)
            .createLayout()
                .storageBuffer(VShaderStage.COMPUTE)
                .storageBuffer(VShaderStage.COMPUTE)
                .storageBuffer(VShaderStage.COMPUTE)
                .storageBuffer(VShaderStage.COMPUTE)
                .storageBuffer(VShaderStage.COMPUTE)
                .combinedImageSampler(VShaderStage.COMPUTE)
                .storageImage(VShaderStage.COMPUTE)
                .uniformBuffer(VShaderStage.COMPUTE)
                .sets(1);

        if(DEBUG) {
            shaderPrintf.createLayout(descriptors, VShaderStage.COMPUTE);
        }
        descriptors.build();

        descriptors
            .createSetFromLayout(0)
                .add(randomBuffer)
                .add(tentFilterBuffer)
                .add(shapeData)
                .add(materialData)
                .add(accumulatedColours)
                .add(textureSampler,
                     texture.image.view(texture.format, VImageViewType._2D),
                     VImageLayout.SHADER_READ_ONLY_OPTIMAL)
                .add(targetImage.view(), VImageLayout.GENERAL)
                .add(ubo)
                .write();

        if(DEBUG) {
            shaderPrintf.createDescriptorSet(descriptors, 1);
        }
    }
    void createPipeline() {
        this.pipeline = new ComputePipeline(context)
            .withDSLayouts(descriptors.getAllLayouts())
            .withShader(context.shaderCompiler().getModule("pathtracer.comp"))
            .withPushConstantRange!PushConstants()
            .build();
    }
    VkSemaphore computeFrame(Frame frame) {

        if(DEBUG) {
            //shaderPrintf.reset();
        }

        uint index = frame.resource.index;

        int dispatchX = width/8;
        int dispatchY = height/8;

        iterations++;
        pushConstants.frameNumber++;
        pushConstants.imageIteration++;
        pushConstants.random0 = uniform(0f, 1f, rng);
        pushConstants.random1 = uniform(0f, 1f, rng);
        pushConstants.random2 = uniform(0f, 1f, rng);
        pushConstants.random3 = uniform(0f, 1f, rng);

        ulong[2] queryData;
        if(VkResult.VK_SUCCESS==device.getQueryPoolResults(queryPool, index*2, 2, 16, queryData.ptr, 8, VQueryResult._64_BIT)) {
            computeTime = cast(ulong)((queryData[1]-queryData[0])*vk.limits.timestampPeriod);
        }

        // Setup compute buffer
        cmd.beginOneTimeSubmit();

        cmd.resetQueryPool(queryPool,
            index*2,    // firstQuery
            2);         // queryCount
        cmd.writeTimestamp(VPipelineStage.TOP_OF_PIPE,
            queryPool,
            index*2); // query

        // Acquire the targetImage from graphics queue
        cmd.pipelineBarrier(
            VPipelineStage.FRAGMENT_SHADER,
            VPipelineStage.COMPUTE_SHADER,
            0,      // dependency flags
            null,   // memory barriers
            null,   // buffer barriers
            [
                imageMemoryBarrier(
                    targetImage.handle,
                    VAccess.NONE,
                    VAccess.SHADER_WRITE,
                    VImageLayout.UNDEFINED,
                    VImageLayout.GENERAL,
                    vk.getGraphicsQueueFamily().index,
                    vk.getComputeQueueFamily().index
                )
            ]
        );

        shapeData.upload(cmd);
        ubo.upload(cmd);

        cmd.bindPipeline(pipeline);

        cmd.bindDescriptorSets(
            VPipelineBindPoint.COMPUTE,
            pipeline.layout,
            0, // set 0
            [descriptors.getSet(0,0)],  // layout 0, set 0
            null
        );
        if(DEBUG) {
            cmd.bindDescriptorSets(
                VPipelineBindPoint.COMPUTE,
                pipeline.layout,
                1, // set 1
                [descriptors.getSet(1,0)],  // layout 1, set 0
                null
            );
        }

        cmd.pushConstants(
            pipeline.layout,
            VShaderStage.COMPUTE,
            0,
            PushConstants.sizeof,
            &pushConstants
        );

        // Dispatch compute
        cmd.dispatch(dispatchX, dispatchY, 1);

        // Release the targetImage
        cmd.pipelineBarrier(
            VPipelineStage.COMPUTE_SHADER,
            VPipelineStage.FRAGMENT_SHADER,
            0,      // dependency flags
            null,   // memory barriers
            null,   // buffer barriers
            [
                imageMemoryBarrier(
                    targetImage.handle,
                    VAccess.SHADER_WRITE,
                    VAccess.SHADER_READ,
                    VImageLayout.GENERAL,
                    VImageLayout.GENERAL,
                    vk.getComputeQueueFamily().index,
                    vk.getGraphicsQueueFamily().index
                )
            ]
        );

        cmd.writeTimestamp(VPipelineStage.BOTTOM_OF_PIPE,
            queryPool,
            index*2+1); // query

        cmd.end();

        vk.getComputeQueue().submit(
            [cmd],              // cmdBuffers
            null,               // waitSemaphores
            null,               // waitStages
            [computeFinished],  // signalSemaphores
            null                // fence
        );

        if(DEBUG) {
            auto str = shaderPrintf.getDebugString();
            if(str) {
                log("\nShader debug output:");
                log("===========================");
                log("%s", shaderPrintf.getDebugString());
                log("\n===========================\n");
            }
        }

        // Set the image state to continue
        pushConstants.imageState = 0;

        return computeFinished;
    }
}
