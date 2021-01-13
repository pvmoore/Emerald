module emerald.photos;

import emerald.all;

final class Photographer {
private:
    AbstractPathTracer pathTracer;
    uint width, height;
    int lastScreenShotIteration = -1;
    uint screenshotId;
public:
    this(AbstractPathTracer pathTracer, uint width, uint height) {
        this.pathTracer      = pathTracer;
        this.width          = width;
        this.height         = height;
        this.screenshotId   = cast(uint)(getRandomFloat()*100000);
    }
    void takeSnapshot(ubyte[] pixels) {
        if(lastScreenShotIteration==pathTracer.getIterations()) return;
        lastScreenShotIteration = pathTracer.getIterations();

        BMP bmp = BMP.create_RGB888(width, height, pixels);

        auto filename = "screenshots/%s-%s.bmp".format(screenshotId, pathTracer.samplesPerPixel());
        bmp.write(filename);
    }
}