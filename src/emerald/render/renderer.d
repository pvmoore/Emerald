module emerald.render.renderer;

import emerald.all;
import vulkan;

final class Renderer {
private:
    const uint width;
    const uint height;
    int pixelsIteration = -1;

    @Borrowed Vulkan vk;
    @Borrowed VkDevice device;
    @Borrowed VulkanContext context;
    @Borrowed AbstractPathTracer pathTracer;

    Camera2D camera;
    VkSampler sampler;
    UpdateableImage!(VK_FORMAT_R8G8B8A8_UNORM) pixels;
    Quad quad;
public:
    this(VulkanContext context, AbstractPathTracer pathTracer, uint width, uint height) {
        this.context   = context;
        this.vk        = context.vk;
        this.device    = context.device;
        this.pathTracer = pathTracer;
        this.width     = width;
        this.height    = height;

        initialise();
    }
    void destroy() {
        if(quad) quad.destroy();
        if(pixels) pixels.destroy();
        if(sampler) device.destroySampler(sampler);
	}
    ubyte[] getPixelData() {
        ubyte[] tempData = new ubyte[width*height*3];
        RGBAb* src = pixels.map();
        RGBb* dest = cast(RGBb*)tempData.ptr;

        foreach(i; 0..width*height) {
            dest[i].r = src[i].r;
            dest[i].g = src[i].g;
            dest[i].b = src[i].b;
        }

        return tempData;
    }
    void render(Frame frame) {
        auto res = frame.resource;
	    auto b = res.adhocCB;
	    b.beginOneTimeSubmit();

        if(updatePixels()) {

            auto title = "Emerald %s [Max depth %s, iteration: %s, samples per pixel: %s, samples per sec: %.3s million, threads: %s]"
                .format(VERSION,
                    pathTracer.getMaxDepth(),
                    pathTracer.getIterations(),
                    pathTracer.samplesPerPixel(),
                    pathTracer.averageMegaSPP(),
                    pathTracer.getNumThreads());

            context.vk.setWindowTitle(title);

            pixels.upload(b);
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

        b.endRenderPass();
        b.end();

        /// Submit our render buffer
        vk.getGraphicsQueue().submit(
            [b],
            [res.imageAvailable],
            [VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT],
            [res.renderFinished],  // signal semaphores
            res.fence              // fence
        );
    }
private:
    void initialise() {
        this.camera = Camera2D.forVulkan(vk.windowSize);

        createSampler();
        createUpdateableImage();
        createQuad();
    }
    void createSampler() {
        this.sampler = device.createSampler(samplerCreateInfo());
    }
    void createUpdateableImage() {
        this.pixels = new UpdateableImage!(VK_FORMAT_R8G8B8A8_UNORM)
            (context, width, height, VK_IMAGE_USAGE_SAMPLED_BIT, VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL);

        this.pixels
            .image.createView(VK_FORMAT_R8G8B8A8_UNORM, VK_IMAGE_VIEW_TYPE_2D, VK_IMAGE_ASPECT_COLOR_BIT);

        this.pixels.clear(RGBAb(0,0,0,255));
    }
    void createQuad() {
        this.quad = new Quad(context, pixels.getImageMeta(), sampler);
        auto scale = mat4.scale(float3(width,height,0));
        auto trans = mat4.translate(float3(0,0,0));
        quad.setVP(trans*scale, camera.V, camera.P);
    }
    bool updatePixels() {
        auto iteration = pathTracer.getIterations();

        if(iteration < 1) return false;
        if(iteration == pixelsIteration) return false;

        this.pixelsIteration = iteration;

        //auto colours = getAveragedPixels(pathTracer.getColours());
        auto colours = pathTracer.getColours();

        float3* src = colours.ptr;

        // Swap the Y

        void _copyLine(RGBAb* dest) {
            for(auto x=0; x<width; x++) {
                dest[x].r = cast(ubyte)(255 * gamma(src.x));
                dest[x].g = cast(ubyte)(255 * gamma(src.y));
                dest[x].b = cast(ubyte)(255 * gamma(src.z));
                src++;
            }
        }

        RGBAb* dest = pixels.map() + (height-1) * width;

        for(auto y=0; y<height; y++) {
            _copyLine(dest);
            dest -= width;
        }

        pixels.setDirty();

        return true;
    }
    float3[] getAveragedPixels(float3[] c) {
        float3[] averaged = new float3[c.length];

        auto i = width+1;

        foreach(y; 1..height-1) {
            foreach(x; 1..width-1) {
                //
                // TL T TR
                // L  C  R
                // BL B BR
                //
                const C  = 0;
                const TL = -(width+1);
                const T  = -width;
                const TR = -(width-1);
                const L  = -1;
                const R  = 1;
                const BL = width-1;
                const B  = width;
                const BR = width+1;

                float3 total =
                    c[i+TL] +
                    c[i+T]*2 +
                    c[i+TR] +
                    c[i+L]*2 +
                    c[i+C]*8 +
                    c[i+R]*2 +
                    c[i+BL] +
                    c[i+B]*2 +
                    c[i+BR];

                averaged[i] = total / 20;
                i++;
            }
            i += 2;
        }

        return averaged;
    }
}