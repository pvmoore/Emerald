module emerald.gen.raytracer;

import emerald.all;

enum AccelerationStructure { NONE, BVH, BIH }
enum ACCELERATION_STRUCTURE = AccelerationStructure.BVH;

@fastmath:
final class RayTracer {
private:
    enum PARALLEL       = true;
    enum SAMPS          = 1;
    enum INV_SAMPS      = 1.0/SAMPS;
    enum MAX_DEPTH      = 9;    // min=3, smallpt uses ~5

    immutable float3 BLACK = float3(0,0,0);

    Scene scene;
    uint width, height;

    float3[] colours;
    Mutex mutex;

    bool running        = true;
    uint iterations     = 0;
    double totalMegaSPP = 0;
    double megaSPP      = 0;
    Thread thread;

    // Updated asynchronously
    struct Row {
        float3[] colours;
        IntersectInfo ii;
    }
    Row[] rowData;
public:
    uint samplesPerPixel()  { return iterations*SAMPS*4; }
    double averageMegaSPP() { return iterations == 0 ? 0 : totalMegaSPP/iterations; }
    uint getIterations()    { return iterations; }
    float3[] getColours()   {
        mutex.lock();
        scope(exit) mutex.unlock();

        return colours.dup;
    }

    this(Scene scene, uint width, uint height) {
        this.scene               = scene;
        this.width               = width;
        this.height              = height;
        this.mutex               = new Mutex;
        this.colours.length      = width*height;
        this.rowData.length      = height;

        for(auto i=0; i<height; i++) {
            rowData[i].colours.length = width;
            rowData[i].ii             = new IntersectInfo;
        }

        this.thread          = new Thread(&trace);
        this.thread.isDaemon = false;

        this.thread.start();
    }
    void destroy() {
        if(thread) {
            running = false;
            From!"core.atomic".atomicFence();
            thread.join();
        }
    }
    void trace() {
        StopWatch watch;
        while(running) {
            watch.reset();
            watch.start();

            static if(PARALLEL) {
                //defaultPoolThreads(2);
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

            auto numSamples = width*height*SAMPS*4;
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
    void rayTraceLine(uint y) {
        for(int x=0; x<width; x++) {
            rayTracePixel(x, y);
        }
    }
    void rayTracePixel(int x, int y) {
        float3 colour = float3(0,0,0);

        /* 2x2 supersample */
        for(int sy=0; sy<2; sy++) {
            for(int sx=0; sx<2; sx++) {
                colour += sample(x, y, sx, sy);
            }
        }
        rowData[y].colours[x] += (colour*0.25f);
    }
    float3 sample(int x, int y, int sx, int sy) {

        float3 result = float3(0,0,0);

        for(auto s=0; s<SAMPS; s++) {
            auto ray = scene.camera.makeRay(x,y, sx,sy);
            result += clampLo(radiance(ray, y, 0));
        }

        return result * INV_SAMPS;
    }
    float3 radiance(ref Ray r, uint row, uint depth) {

        auto ii = rowData[row].ii;
        if(!intersectRayWithWorld(r, ii)) {
            // if miss, return black
            return BLACK;
        }

        // we hit this object
        auto obj = ii.shape;
        auto mat = obj.getMaterial();

        if(depth++==MAX_DEPTH || getRandom() >= mat.maxReflectance) {
            return mat.emission;
        }

        const f = mat.normalisedColour;

        const intersectPoint  = ii.hitPoint;
        const norm            = ii.normal;
        const reflectAngle    = norm.dot(r.direction);

        // properly oriented surface normal
        float3 nl = reflectAngle<0 ? norm : norm*-1;

        float3 _reflect() {
            Ray ray = Ray(intersectPoint, r.direction - norm*2*reflectAngle);
            return radiance(ray, row, depth);
        }
        float3 _speckle() {
            float3 e = mat.emission;
            if(mat.specklePower==0) return e;

            float p = mat.specklePower * (perlin.get(intersectPoint) + 0.5);

            e -= mat.speckleColour*p;

            //e -= p;
            //e += mat.speckleColour*0.2; // 0.5*mat.specklePower
            return e;
        }
        // Ideal SPECULAR reflection
        float3 _specular() {
            return _speckle() + f * _reflect();
        }
        // Ideal DIFFUSE reflection
        float3 _diffuse() {
            float r1  = 2*PI*getRandom();
            float r2  = getRandom();
            float r2s = sqrt(r2);
            float3 w  = nl;
            float3 u  = ((fabs(w.x)>0.1 ? float3(0,1,0) : float3(1,0,0)).cross(w)).normalised();
            float3 v  = w.cross(u);
            float3 d  = u*cos(r1)*r2s + v*sin(r1)*r2s + w*sqrt(1-r2);
            d.normalise();

            Ray ray = Ray(intersectPoint,d);
            return _speckle() + f * (radiance(ray, row, depth));
        }
        // Ideal dielectric REFRACTION
        float3 _refraction() {
            // Ray from outside going in?
            bool into = norm.dot(nl)>0;

            // refractive index
            float fromRI = 1;   // air
            float toRI   = mat.refractIndex;
            float nnt    = into ? fromRI/toRI : toRI/fromRI;
            float ddn    = r.direction.dot(nl);
            float cos2t  = 1-nnt*nnt*(1-ddn*ddn);

            if(cos2t<0) {
                // Total internal reflection
                return _speckle() + f * _reflect();
            }
            // choose reflection or refraction
            const tdir = (r.direction*nnt - norm*((into?1:-1)*(ddn*nnt+sqrt(cos2t)))).normalised();
            float a    = toRI-fromRI;
            float b    = toRI+fromRI;
            float R0   = (a*a)/(b*b);
            float c    = 1.0-(into ? -ddn:tdir.dot(norm));
            float Re   = R0+(1.0-R0)*c*c*c*c*c;
            float Tr   = 1.0-Re;

            // Russian roulette
            if(depth>2) {
                float P = 0.25 + 0.5*Re;
                if(getRandom()<P) {
                    // reflect
                    return mat.emission + f*_reflect()*(Re/P);
                }
                // refract
                Ray ray  = Ray(intersectPoint, tdir);
                return mat.emission + f*radiance(ray, row, depth)*(Tr/(1-P));
            }
            // reflect and refract
            Ray ray = Ray(intersectPoint, tdir);
            return mat.emission + f*_reflect()*Re + radiance(ray, row, depth)*Tr;
        }

        float3 col;
        float factor = 0;
        if(mat.isReflective) {
            col    += _specular()*mat.reflectance;
            factor += mat.reflectance;
        }
        if(mat.isRefractive) {
            col    += _refraction();
            factor += 1;
        }
        if(mat.isDiffuse) {
            col    += _diffuse() * mat.diffusePower;
            factor += mat.diffusePower;
        }
        return col * (1.0/factor);
    }
    bool intersectRayWithWorld(ref Ray r, IntersectInfo ii) {
        ii.reset();

        static if(ACCELERATION_STRUCTURE==AccelerationStructure.NONE) {
            // 1.15
            foreach(shape; scene.shapes) {
                shape.intersect(r, ii);
            }
        } else static if(ACCELERATION_STRUCTURE==AccelerationStructure.BVH) {
            // 1.6
            scene.bvh.intersect(r, ii);
        } else static if(ACCELERATION_STRUCTURE==AccelerationStructure.BIH) {
            //
            assert(false);
        } else {
            static assert(false);
        }

        return ii.intersected();
    }
}