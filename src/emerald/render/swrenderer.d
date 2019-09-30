module emerald.render.swrenderer;

import emerald.all;

@fastmath:

final class SWRenderer {
private:
    uint width;
    uint height;
    OpenGL gl;

    RayTracer rayTracer;
    PixelBuffer pixels;
    int pixelsIteration = -1;
public:
    ubyte[] getPixelData() {
        return pixels.getRGBData();
    }

    this(OpenGL gl, RayTracer rayTracer, uint width, uint height) {
        this.gl         = gl;
        this.rayTracer  = rayTracer;
        this.width      = width;
        this.height     = height;
        this.pixels     = new PixelBuffer(gl, float2(0,0), width, height);

        gl.setWindowTitle("Emerald "~VERSION~"   (wait a few seconds for the scene to be generated...)");
    }
    void destroy() {
        pixels.destroy();
    }
    void render() {
        if(updatePixels()) {

            auto title = "Emerald %s  [iteration: %s, samples per pixel: %s, samples per sec: %.3s million, threads: %s]"
                .format(VERSION, rayTracer.getIterations(),
                    rayTracer.samplesPerPixel(), rayTracer.averageMegaSPP(),
                    totalCPUs());

            gl.setWindowTitle(title);
        }
        pixels.blitToScreen();
    }
private:
    bool updatePixels() {
        auto iteration = rayTracer.getIterations();

        if(iteration < 1) return false;
        if(iteration == pixelsIteration) return false;

        pixelsIteration = iteration;
        auto colours = rayTracer.getColours();
        int i=0;
        for(auto y=0; y<height; y++) {
            for(auto x=0; x<width; x++) {
                pixels.setPixel(
                    x, height-1-y,
                    gamma(colours[i].x),
                    gamma(colours[i].y),
                    gamma(colours[i].z));
                i++;
            }
        }
        return true;
    }
}
