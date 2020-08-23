module emerald.emerald;

import emerald.all;

final class Emerald : ApplicationListenerAdapter {
private:
    OpenGL gl;
    Scene scene;
    RayTracer rayTracer;
    SWRenderer renderer;
    Photographer photographer;
public:
    enum WIDTH 	= 1000;
    enum HEIGHT = 700;

    this() {
        this.gl = new OpenGL(this, (h) {
            h.width      = WIDTH;
            h.height     = HEIGHT;
            h.title      = "Emerald "~VERSION;
            h.windowed   = true;
            h.showWindow = false;
            h.samples    = 0;
        });
        initialise();

        gl.showWindow(true);
    }
    void initialise() {
        this.scene        = new Scene(WIDTH, HEIGHT);
        this.rayTracer    = new RayTracer(scene, WIDTH, HEIGHT);
        this.renderer     = new SWRenderer(gl, rayTracer, WIDTH,HEIGHT);
        this.photographer = new Photographer(rayTracer, WIDTH, HEIGHT);
    }
    void destroy() {
        log("Destroying...");
        renderer.destroy();
        rayTracer.destroy();
        gl.destroy();
    }
    void run() {
        gl.enterMainLoop();
    }
    override void keyPress(uint keyCode, uint scanCode, bool down, uint mods) nothrow {
        if(!down) return;
        try{
            enum GLFW_KEY_PRINT_SCREEN = 283;
            enum GLFW_KEY_PAUSE = 284;

            switch(keyCode) {
                case GLFW_KEY_PRINT_SCREEN:
                    photographer.takeSnapshot(renderer.getPixelData());
                    break;
                case GLFW_KEY_PAUSE:
                    break;
                default: break;
            }
        }catch(Throwable t) {}
    }
    /// always called on the main thread
    override void render(ulong frameNumber, float seconds, float perSecond) {
        renderer.render();
    }
private:
    void update() {

    }
}

