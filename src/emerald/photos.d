module emerald.photos;

import emerald.all;

final class Photographer {
private:
    RayTracer rayTracer;
    uint width, height;
    int lastScreenShotIteration = -1;
public:
    this(RayTracer rayTracer, uint width, uint height) {
        this.rayTracer  = rayTracer;
        this.width      = width;
        this.height     = height;
    }
    void takeSnapshot(ubyte[] pixels) {
        if(lastScreenShotIteration==rayTracer.getIterations()) return;
        lastScreenShotIteration = rayTracer.getIterations();

        auto screenshotId = cast(uint)(getRandom()*100000);

        BMP bmp = BMP.create_RGB888(width, height, pixels);

        auto filename = "screenshots/%s-%s.bmp".format(screenshotId, rayTracer.samplesPerPixel());
        bmp.write(filename);
    }
}