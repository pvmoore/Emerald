module emerald.photos;

import emerald.all;

final class Photographer {
private:
    RayTracer rayTracer;
    uint width, height;
    int lastScreenShotIteration = -1;
    uint screenshotId;
public:
    this(RayTracer rayTracer, uint width, uint height) {
        this.rayTracer      = rayTracer;
        this.width          = width;
        this.height         = height;
        this.screenshotId   = cast(uint)(getRandom()*100000);
    }
    void takeSnapshot(ubyte[] pixels) {
        if(lastScreenShotIteration==rayTracer.getIterations()) return;
        lastScreenShotIteration = rayTracer.getIterations();

        BMP bmp = BMP.create_RGB888(width, height, pixels);

        auto filename = "screenshots/%s-%s.bmp".format(screenshotId, rayTracer.samplesPerPixel());
        bmp.write(filename);
    }
}