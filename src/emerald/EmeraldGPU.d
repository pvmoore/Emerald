module emerald.EmeraldGPU;

import emerald.all;
import vulkan;

final class EmeraldGPU : EmeraldVK {
private:
    GPUPathTracer pathTracer;
    GPURenderer renderer;
public:
    override void initialise() {
        this.log("initialise");

        this.scene = createScene();

        this.pathTracer = new GPUPathTracer(context, scene, WIDTH, HEIGHT);

        this.renderer = new GPURenderer(context, pathTracer, WIDTH, HEIGHT);

        //this.photographer = new Photographer(pathTracer, WIDTH, HEIGHT);

        vk.showWindow();
    }
    override void destroyDeviceObjects() {
        super.destroyDeviceObjects();

        if(renderer) renderer.destroy();
        if(pathTracer) pathTracer.destroy();
    }
    override void render(Frame frame) {
        if(renderer) renderer.render(frame);
    }
}