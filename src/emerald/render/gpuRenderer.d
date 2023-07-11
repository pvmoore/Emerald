module emerald.render.gpuRenderer;

import emerald.all;
import vulkan;

final class GPURenderer {
private:
    __gshared enum {
        TEXT_0 = "Iterations ..... %s",
        TEXT_1 = "Frame Iterations %s",
        TEXT_2 = "Compute time ... %.2f ms"
    }
    @Borrowed Vulkan vk;
    @Borrowed VkDevice device;
    @Borrowed VulkanContext context;
    @Borrowed GPUPathTracer pathTracer;
    uint width;
    uint height;
    Camera2D camera;

    VkSampler linearSampler;
    Quad quad;
    FPS fps;
    Text text;
public:
    this(VulkanContext context, GPUPathTracer pathTracer, uint width, uint height) {
        this.log("GPURenderer");
        this.context = context;
        this.vk = context.vk;
        this.device = context.device;
        this.pathTracer = pathTracer;
        this.width = width;
        this.height = height;
        initialise();
    }
    void destroy() {
        this.log("Destroy");
        if(fps) fps.destroy();
        if(quad) quad.destroy();
        if(text) text.destroy();
        if(linearSampler) device.destroySampler(linearSampler);
    }
    ubyte[] getPixelData() {
        this.log("getPixelData not implemented");
        return new ubyte[width*height*3];
    }
    void render(Frame frame) {

        text.replace(0, TEXT_0.format(pathTracer.getIterations()));
        text.replace(1, TEXT_1.format(pathTracer.getCurrentImageIterations()));
        text.replace(2, TEXT_2.format(pathTracer.getComputeTime() / 1_000_000.0));

        auto computeFinished = pathTracer.compute(frame);

        auto res = frame.resource;
	    auto b = res.adhocCB;
	    b.beginOneTimeSubmit();

        fps.beforeRenderPass(frame, vk.getFPSSnapshot());
        text.beforeRenderPass(frame);

        if(frame.number.value!=0) {
            // acquire the image from compute queue and transform to fragment shader read
            b.pipelineBarrier(
                VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT,
                VK_PIPELINE_STAGE_FRAGMENT_SHADER_BIT,
                0,      // dependency flags
                null,   // memory barriers
                null,   // buffer barriers
                [
                    imageMemoryBarrier(
                        pathTracer.getTargetImage().handle,
                        VK_ACCESS_SHADER_WRITE_BIT,
                        VK_ACCESS_SHADER_READ_BIT,
                        VK_IMAGE_LAYOUT_GENERAL,
                        VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
                        vk.getComputeQueueFamily().index,
                        vk.getGraphicsQueueFamily().index
                    )
                ]
            );
        }

        // begin the render pass
        b.beginRenderPass(
            context.renderPass,
            res.frameBuffer,
            toVkRect2D(0,0, vk.windowSize.toVkExtent2D),
            [ clearColour(0.2f,0,0,1) ],
            VK_SUBPASS_CONTENTS_INLINE
        );

        quad.insideRenderPass(frame);
        fps.insideRenderPass(frame);
        text.insideRenderPass(frame);

        b.endRenderPass();

        // Release the targetImage
        b.pipelineBarrier(
            VK_PIPELINE_STAGE_FRAGMENT_SHADER_BIT,
            VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT,
            0,      // dependency flags
            null,   // memory barriers
            null,   // buffer barriers
            [
                imageMemoryBarrier(
                    pathTracer.getTargetImage().handle,
                    VK_ACCESS_SHADER_READ_BIT,
                    VK_ACCESS_SHADER_WRITE_BIT,
                    VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
                    VK_IMAGE_LAYOUT_GENERAL,
                    vk.getGraphicsQueueFamily().index,
                    vk.getComputeQueueFamily().index
                )
            ]
        );

        b.end();

        auto waitSemaphores = [
            res.imageAvailable, computeFinished
        ];
        uint[] waitStages = [
            VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT, VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT
        ];

        /// Submit our render buffer
        vk.getGraphicsQueue().submit(
            [b],                   // commandBuffers
            waitSemaphores,        // waitSemaphores
            waitStages,            // waitStages
            [res.renderFinished],  // signal semaphores
            res.fence              // fence
        );
    }
private:
    void initialise() {
        this.log("Initialise");
        this.camera = Camera2D.forVulkan(vk.windowSize);

        createSampler();
        createQuad();
        createFps();
        createText();
    }
    void createSampler() {
        this.linearSampler = device.createSampler(samplerCreateInfo());
    }
    void createFps() {
        this.fps = new FPS(context, "comic-mono-bold")
            .size(20)
            .colour(WHITE);
    }
    void createText() {
        this.text = new Text(context, context.fonts().get("comic-mono-bold"), true, 1000)
            .camera(camera)
            .setColour(WHITE)
            .setSize(18);
        this.text
            .add(TEXT_0.format(0), 5, 5);
        this.text
            .add(TEXT_1.format(0), 5, 30);
        this.text
            .add(TEXT_2.format(0f), 5, 55);
    }
    void createQuad() {
        ImageMeta m = {
            image: pathTracer.getTargetImage(),
            format: VK_FORMAT_B8G8R8A8_UNORM
        };
        this.quad = new Quad(context, m, linearSampler);

        auto scale = mat4.scale(float3(width,height,0));
        auto trans = mat4.translate(float3(0,0,0));

        auto transToCentre = mat4.translate(float3(width/2, height/2, 0));
        auto transFromCentre = mat4.translate(float3(-(width.as!int)/2, -(height.as!int)/2, 0));

        auto z180 = mat4.rotateZ(180.degrees);
        auto y180 = mat4.rotateY(180.degrees);

        // flip and rotate the image
        auto flipRotate = transToCentre * y180*z180 * transFromCentre;

        quad.setVP(trans*flipRotate*scale, camera.V, camera.P);
    }
}