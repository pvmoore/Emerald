module emerald.emerald;

import emerald.all;

const WIDTH 	= 820;
const HEIGHT 	= 620;
const VERSION 	= "0.3";

final class Emerald : ApplicationListenerAdapter {
    OpenGL gl;
    SWRenderer renderer;

    this() {
        this.gl = new OpenGL(this, (h) {
            h.width      = WIDTH;
            h.height     = HEIGHT;
            h.title      = "Emerald "~VERSION;
            h.windowed   = true;
            h.showWindow = false;
            h.samples    = 0;
        });
        renderer = new SWRenderer(gl, new Model(), WIDTH, HEIGHT);

        gl.showWindow(true);
    }
    void destroy() {
        log("Destroying...");
        renderer.destroy();
        gl.destroy();
    }
    void run() {
        gl.enterMainLoop();
    }
    override void keyPress(uint keyCode, uint scanCode, bool down, uint mods) nothrow {
        try{
            if(keyCode==283) {
                // print screen
                renderer.writeBMP();
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

