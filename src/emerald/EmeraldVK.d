module emerald.EmeraldVK;

import emerald.all;
import vulkan;

final class EmeraldVK : Emerald, IVulkanApplication {
private:
    Vulkan vk;
    VkDevice device;
    VulkanContext context;
    VkRenderPass renderPass;
    VkRenderer renderer;
public:
    this() {
        WindowProperties wprops = {
            width:        WIDTH,
            height:       HEIGHT,
            fullscreen:   false,
            vsync:        true,
            title:        "Emerald "~VERSION,
            icon:         "/pvmoore/_assets/icons/3dshapes.png",
            showWindow:   false,
            frameBuffers: 2
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

        this.renderer = new VkRenderer(context, rayTracer, WIDTH,HEIGHT);

        vk.showWindow();
    }
    override void destroy() {
        this.log("destroy");
        if(!vk) return;
	    if(device) {
	        vkDeviceWaitIdle(device);

            super.destroy();

            if(context) context.dumpMemory();

            if(renderer) renderer.destroy();
	        if(renderPass) device.destroyRenderPass(renderPass);

            if(context) context.destroy();
	    }
		vk.destroy();
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
    override void keyPress(uint keyCode, uint scanCode, KeyAction action, uint mods) {
        if(action!=KeyAction.PRESS) return;

        switch(keyCode) {
            case GLFW_KEY_PRINT_SCREEN:
                photographer.takeSnapshot(renderer.getPixelData());
                break;
            case GLFW_KEY_PAUSE:
                break;
            default: break;
        }
    }
    override void mouseButton(MouseButton button, float x, float y, bool down, uint mods) {

    }
    override void mouseMoved(float x, float y) {

    }
    override void mouseWheel(float xdelta, float ydelta, float x, float y) {

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
            .withMemory(MemID.STAGING, mem.allocStdStagingUpload("Emerald_Staging", 128.MB));

        context.withBuffer(MemID.LOCAL, BufID.VERTEX, VBufferUsage.VERTEX | VBufferUsage.TRANSFER_DST, 1.MB)
               .withBuffer(MemID.LOCAL, BufID.INDEX, VBufferUsage.INDEX | VBufferUsage.TRANSFER_DST, 1.MB)
               .withBuffer(MemID.LOCAL, BufID.UNIFORM, VBufferUsage.UNIFORM | VBufferUsage.TRANSFER_DST, 1.MB)
               .withBuffer(MemID.STAGING, BufID.STAGING, VBufferUsage.TRANSFER_SRC, 128.MB);

        context.withFonts("resources/fonts")
               .withImages("resources/images")
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