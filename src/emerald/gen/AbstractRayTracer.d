module emerald.gen.AbstractRayTracer;

import emerald.all;

enum AccelerationStructure { NONE, BVH, BIH }
enum ACCELERATION_STRUCTURE = AccelerationStructure.BVH;

@fastmath:
abstract class AbstractRayTracer {
protected:
    enum PARALLEL       = true;
    enum SUPERSAMPLES   = 2;
    enum MAX_THREADS    = 16;    // if PARALLEL == true
    enum SAMPS          = 1;
    enum INV_SAMPS      = 1.0/SAMPS;
    enum MAX_DEPTH      = 5;    // min=3, smallpt uses ~5
    enum BLACK          = float3(0,0,0);
    enum WHITE          = float3(1,1,1);
    enum Y_DIR          = float3(0,1,0);
    enum X_DIR          = float3(1,0,0);

    Scene scene;
    Camera camera;
    uint width, height;

    float3[] colours;
    Mutex mutex;

    bool running        = true;
    uint iterations     = 0;
    double totalMegaSPP = 0;
    double megaSPP      = 0;
    uint numThreads;
    Thread thread;

    // Updated asynchronously
    static struct Row {
        float3[] colours;
        IntersectInfo ii;
    }
    Row[] rowData;
public:
    final uint samplesPerPixel()  { return iterations*SAMPS*SUPERSAMPLES*SUPERSAMPLES; }
    final double averageMegaSPP() { return iterations == 0 ? 0 : totalMegaSPP/iterations; }
    final uint getIterations()    { return iterations; }
    final uint getNumThreads()    { return numThreads; }
    final uint getMaxDepth()      { return MAX_DEPTH; }

    final float3[] getColours()   {
        mutex.lock();
        scope(exit) mutex.unlock();

        return colours.dup;
    }

    this(Scene scene, uint width, uint height) {
        this.scene               = scene;
        this.camera              = scene.getCamera();
        this.width               = width;
        this.height              = height;
        this.mutex               = new Mutex;
        this.colours.length      = width*height;
        this.rowData.length      = height;

        for(auto i=0; i<height; i++) {
            rowData[i].colours.length = width;
            rowData[i].ii             = new IntersectInfo;
        }

        static if(PARALLEL) {
            this.numThreads = min(MAX_THREADS, totalCPUs());
            defaultPoolThreads(this.numThreads);
        } else {
            numThreads = 1;
        }

        this.thread          = new Thread(&trace);
        this.thread.isDaemon = false;

        this.thread.start();
    }
    final void destroy() {
        if(thread) {
            running = false;
            From!"core.atomic".atomicFence();
            thread.join();
        }
    }
    final void trace() {
        StopWatch watch;
        while(running) {
            watch.reset();
            watch.start();

            static if(PARALLEL) {

                foreach(y; parallel(iota(0, height))) {
                    if(running) {
                        rayTraceLine(y);
                    }
                }
            } else {
                foreach(y; 0..height) {
                    if(running) {
                        rayTraceLine(y);
                    }
                }
            }
            watch.stop();
            iterations++;

            auto numSamples = width*height*SAMPS*SUPERSAMPLES*SUPERSAMPLES;
            auto seconds    = watch.peek().total!"nsecs"/1_000_000_000.0;

            megaSPP       = (numSamples/seconds)/1_000_000.0;
            totalMegaSPP += megaSPP;

            {
                mutex.lock();
                scope(exit) mutex.unlock();

                auto tempColours = new float3[colours.length];
                uint dest = 0;
                foreach(ref r; rowData) {

                    for(auto i=0; i<width; i++) {
                        tempColours[dest+i] = r.colours[i] / iterations;
                    }

                    dest += width;
                }

                colours = tempColours;
            }
        }
    }
    final void rayTraceLine(uint y) {
        for(int x=0; x<width; x++) {
            rayTracePixel(x, y);
        }
    }
    final void rayTracePixel(int x, int y) {
        float3 colour = BLACK;

        /* 2x2 supersample */
        enum INV = 1f / (SUPERSAMPLES*SUPERSAMPLES);
        for(int sy=0; sy<SUPERSAMPLES; sy++) {
            for(int sx=0; sx<SUPERSAMPLES; sx++) {
                colour += sample(x, y, sx, sy);
            }
        }
        rowData[y].colours[x] += (colour*INV);
    }
    final float3 sample(int x, int y, float sx, float sy) {

        float3 result = BLACK;

        for(auto s=0; s<SAMPS; s++) {
            auto ray = camera.makeRay(x,y, sx,sy);
            result += clampLo(radiance(ray, y, 0));
        }

        return result * INV_SAMPS;
    }
    final bool intersectRayWithWorld(ref Ray r, IntersectInfo ii) {
        ii.reset();

        static if(ACCELERATION_STRUCTURE==AccelerationStructure.NONE) {
            foreach(shape; scene.getShapes()) {
                shape.intersect(r, ii);
            }
        } else static if(ACCELERATION_STRUCTURE==AccelerationStructure.BVH) {
            scene.getBVH().intersect(r, ii);
        } else static if(ACCELERATION_STRUCTURE==AccelerationStructure.BIH) {
            static assert(false);
        } else {
            static assert(false);
        }

        return ii.intersected();
    }
    abstract float3 radiance(ref Ray r, uint row, uint depth);
}