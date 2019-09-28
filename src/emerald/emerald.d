module emerald.emerald;

import emerald.all;



final class Emerald : ApplicationListenerAdapter {
private:
    OpenGL gl;
    Model model;
    RayTracer rayTracer;
    SWRenderer renderer;
    Photographer photographer;
public:
    enum WIDTH 	    = 1000;
    enum HEIGHT 	= 700;
    enum VERSION 	= "0.4";

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
        this.model        = new Model();
        this.rayTracer    = new RayTracer(model, WIDTH, HEIGHT);
        this.renderer     = new SWRenderer(gl, rayTracer, WIDTH,HEIGHT );
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
        try{
            if(keyCode==283) {
                // print screen
                photographer.takeSnapshot(renderer.getPixelData());
            }
        }catch(Throwable t) {}
    }
    /// always called on the main thread
    override void render(long frameNumber,
                         long normalisedFrameNumber,
                         float timeDelta)
    {
        renderer.render();
    }
private:
    void update() {

    }
}

