module emerald.emerald;

import emerald.all;

final class Emerald : ApplicationListenerAdapter {
private:
    OpenGL gl;
    Scene scene;
    AbstractRayTracer rayTracer;
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
        this.scene        = createScene();
        //this.rayTracer    = new RecursiveRayTracer(scene, WIDTH, HEIGHT);
        this.rayTracer    = new LoopRayTracer(scene, WIDTH, HEIGHT);
        this.renderer     = new SWRenderer(gl, rayTracer, WIDTH,HEIGHT);
        this.photographer = new Photographer(rayTracer, WIDTH, HEIGHT);
    }
    void destroy() {
        this.log("Destroying...");
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
    Scene createScene() {
        enum S = -1;

        static if(S == 0) {
            return new CornellBox(WIDTH, HEIGHT).initialise();
        } else static if(S==1) {
            return new OneSphere(WIDTH, HEIGHT).initialise();
        } else static if(S==2) {
            return new Scene2(WIDTH, HEIGHT).initialise();
        } else static if(S==3) {
            return new Scene3(WIDTH, HEIGHT).initialise();
        } else static if(S==4) {
            return new Scene4(WIDTH, HEIGHT).initialise();
        } else static if(S==5) {
            return new SuzanneScene(WIDTH, HEIGHT).initialise();
        } else static if(S==6) {
            return new RefractionScene(WIDTH, HEIGHT).initialise();
        } else {
            return new ManySpheres(WIDTH, HEIGHT).initialise();
        }
    }
    void update() {

    }
}

