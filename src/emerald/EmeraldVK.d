module emerald.EmeraldVK;

import emerald.all;
import vulkan;

class EmeraldVK : Emerald, IVulkanApplication {
protected:
    Vulkan vk;
    VkDevice device;
    VulkanContext context;
    VkRenderPass renderPass;
    Renderer renderer;
public:
    this() {
        WindowProperties wprops = {
            width:        WIDTH,
            height:       HEIGHT,
            fullscreen:   false,
            vsync:        false,
            title:        "Emerald "~VERSION,
            icon:         "/pvmoore/_assets/icons/3dshapes.png",
            showWindow:   false,
            frameBuffers: 3
        };
        VulkanProperties vprops = {
            appName: "Emerald "~VERSION
        };

        //vprops.layers ~= "VK_LAYER_LUNARG_monitor".ptr;

		this.vk = new Vulkan(this, wprops, vprops);
        vk.initialise();
    }
    override void initialise() {
        this.log("initialise");
        super.initialise();

        this.renderer = new Renderer(context, pathTracer, WIDTH,HEIGHT);

        vk.addWindowEventListener(new class WindowEventListener {
            override void keyPress(uint keyCode, uint scanCode, KeyAction action, uint mods) {
                if(action!=KeyAction.PRESS) return;

                switch(keyCode) {
                    case GLFW_KEY_PRINT_SCREEN:
                        if(photographer) photographer.takeSnapshot(renderer.getPixelData());
                        break;
                    case GLFW_KEY_PAUSE:
                        break;
                    default: break;
                }
            }
        });

        vk.showWindow();
    }
    override void destroy() {
        this.log("Destroying");
        if(!vk) return;
	    if(device) {
	        vkDeviceWaitIdle(device);
            vkQueueWaitIdle(vk.getGraphicsQueue());
            vkQueueWaitIdle(vk.getComputeQueue());

            this.log("Device is now idle");

            super.destroy();

            destroyDeviceObjects();
	    }
		vk.destroy();
    }
    void destroyDeviceObjects() {
        if(context) context.dumpMemory();

        if(renderer) renderer.destroy();
        if(renderPass) device.destroyRenderPass(renderPass);

        if(context) context.destroy();
    }
    override void deviceReady(VkDevice device, PerFrameResource[] frameResources) {
        this.log("deviceReady");
        this.device = device;

        createContext();
    }
    override VkRenderPass getRenderPass(VkDevice device) {
        return createRenderPass(device);
    }
    override void run() {
        vk.mainLoop();
    }
    override void selectQueueFamilies(QueueManager queueManager) {

    }
    override void render(Frame frame) {
        renderer.render(frame);
    }
private:
    void createContext() {
        this.log("Creating context");
        auto mem = new MemoryAllocator(vk);

        auto maxLocal = mem.builder(0)
                           .withAll(VMemoryProperty.DEVICE_LOCAL)
                           .withoutAll(VMemoryProperty.HOST_VISIBLE)
                           .maxHeapSize();

        this.log("Max local memory = %s MBs", maxLocal / 1.MB);

        this.context = new VulkanContext(vk)
            .withMemory(MemID.LOCAL, mem.allocStdDeviceLocal("Emerald_Local", 512.MB))
            .withMemory(MemID.STAGING, mem.allocStdStagingUpload("Emerald_Staging", 128.MB + 16.MB));

        context.withBuffer(MemID.LOCAL, BufID.VERTEX, VBufferUsage.VERTEX | VBufferUsage.TRANSFER_DST, 1.MB)
               .withBuffer(MemID.LOCAL, BufID.INDEX, VBufferUsage.INDEX | VBufferUsage.TRANSFER_DST, 1.MB)
               .withBuffer(MemID.LOCAL, BufID.UNIFORM, VBufferUsage.UNIFORM | VBufferUsage.TRANSFER_DST, 1.MB)
               .withBuffer(MemID.LOCAL, BufID.STORAGE, VBufferUsage.STORAGE | VBufferUsage.TRANSFER_DST, 128.MB)
               .withBuffer(MemID.STAGING, BufID.STAGING, VBufferUsage.TRANSFER_SRC, 128.MB + 4.MB)
               .withBuffer(MemID.STAGING, BufID.STAGING_DOWN, VBufferUsage.TRANSFER_DST, 4.MB);

        context.withFonts("resources/fonts/")
               .withImages("resources/images/")
               .withShaderCompiler("resources/shaders", "resources/shaders")
               .withRenderPass(renderPass);

        this.log("shared mem available = %s", context.hasMemory(MemID.SHARED));

        this.log("%s", context);
    }
    auto createRenderPass(VkDevice device) {
        this.log("Creating render pass");
        auto colorAttachment    = attachmentDescription(vk.swapchain.colorFormat);
        auto colorAttachmentRef = attachmentReference(0);

        auto subpass = subpassDescription((info) {
            info.colorAttachmentCount = 1;
            info.pColorAttachments    = &colorAttachmentRef;
        });

        this.renderPass = .createRenderPass(
            device,
            [colorAttachment],
            [subpass],
            subpassDependency2()
        );
        return renderPass;
    }
}