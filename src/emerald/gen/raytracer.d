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
    enum MAX_DEPTH      = 9;

    immutable float3 BLACK = float3(0,0,0);
    immutable float3 cx;
    immutable float3 cy;

    Model model;
    uint width, height;
    float3[] colours;
    Mutex mutex;

    Ray cam;
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

    this(Model model, uint width, uint height) {
        this.model               = model;
        this.width               = width;
        this.height              = height;
        this.mutex               = new Mutex;
        this.colours.length      = width*height;
        this.rowData.length      = height;

        for(auto i=0; i<height; i++) {
            rowData[i].colours.length = width;
            rowData[i].ii             = new IntersectInfo;
        }

        this.cam             = Ray(float3(50,52,295.6), (float3(0,-0.042612, -1)).normalised());
        this.cx              = float3(width*0.5135/height, 0, 0);
        this.cy              = (cx.cross(cam.direction)).normalised()*0.5135;

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
    void rayTracePixel(uint x, uint y) {
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

        for(int s=0; s<SAMPS; s++) {
            float dx = tentFilter.next();
            float dy = tentFilter.next();

            float3 d = cam.direction;
            d += cx*( ( (sx-0.5 + dx)*0.5 + x)/width  - 0.5) +
                 cy*( ( (sy-0.5 + dy)*0.5 + y)/height - 0.5);

            d.normalise();

            // Camera rays are pushed forward 140 to start in interior
            Ray ray = Ray(cam.origin+d*140, d);

            result += clampLo(radiance(ray, y, 0));
        }

        return result * INV_SAMPS;
    }
    float3 radiance(Ray r, uint row, uint depth) {

        auto ii = rowData[row].ii;
        if(!intersectRayWithWorld(r, ii)) {
            // if miss, return black
            return BLACK;
        }

        // the hit object
        auto obj      = ii.shape;
        Material mat  = obj.getMaterial();
        float3 f      = mat.colour;
        float maxRefl = max(f.x, f.y, f.z);

        if(depth++==MAX_DEPTH || getRandom() >= maxRefl) {
            return mat.emission;
        }

        f *= (1/maxRefl);

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

            Ray ray   = Ray(intersectPoint,d);
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
    bool intersectRayWithWorld(Ray r, IntersectInfo ii) {
        ii.reset();

        static if(ACCELERATION_STRUCTURE==AccelerationStructure.NONE) {
            // 1.11
            foreach(shape; model.shapes) {
                shape.intersect(r, ii);
            }
        } else static if(ACCELERATION_STRUCTURE==AccelerationStructure.BVH) {
            // 1.4
            model.bvh.intersect(r, ii);
        } else static if(ACCELERATION_STRUCTURE==AccelerationStructure.BIH) {
            //
            assert(false);
        } else {
            static assert(false);
        }

        return ii.intersected();
    }
}