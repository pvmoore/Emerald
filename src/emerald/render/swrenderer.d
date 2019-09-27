module emerald.render.swrenderer;

import emerald.all;

@fastmath:

final class SWRenderer {
private:
    uint width;
    uint height;
    OpenGL gl;
    Model model;

    RayTracer rayTracer;
    PixelBuffer pixels;
    int pixelsIteration = -1;
    int lastScreenShotIteration = -1;
public:
    this(OpenGL gl, Model model, uint width, uint height) {
        this.gl         = gl;
        this.model      = model;
        this.width      = width;
        this.height     = height;
        this.pixels     = new PixelBuffer(gl, float2(0,0), width, height);
        this.rayTracer  = new RayTracer(model, width, height);
    }
    void destroy() {
        rayTracer.destroy();
        pixels.destroy();
    }
    void writeBMP() {
        if(lastScreenShotIteration==rayTracer.getIterations()) return;
        lastScreenShotIteration = rayTracer.getIterations();

        auto screenshotId = cast(uint)(getRandom()*100000);

        BMP bmp = BMP.create_RGB888(width, height, cast(ubyte[])pixels.pixels);

        string filename = "screenshots/%s-%s.bmp".format(screenshotId, rayTracer.samplesPerPixel());
        bmp.write(filename);
    }
    void render() {

        updatePixels();
        pixels.blitToScreen();

        gl.setWindowTitle("Emerald "~VERSION~
            "  (spp="~to!string(rayTracer.samplesPerPixel())~
            ", average msps=%.2f".format(rayTracer.averageMegaSPP())~")"~
            (rayTracer.getIterations()==0?" (wait a few seconds...)":"")
        );
    }
private:
    void updatePixels() {
        auto iteration = rayTracer.getIterations();

        // uncomment me after benchmarking
        //if(iteration < 1) return;
        //if(iteration == pixelsIteration) return;

        pixelsIteration = iteration;
        auto colours = rayTracer.getColours();
        int i=0;
        for(auto y=0; y<height; y++)
        for(auto x=0; x<width; x++) {
            pixels.setPixel(
                x, height-1-y,
                gamma(colours[i].x),
                gamma(colours[i].y),
                gamma(colours[i].z));
            i++;
        }
    }
}
