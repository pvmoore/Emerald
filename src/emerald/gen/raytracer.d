module emerald.gen.raytracer;

import emerald.all;

@fastmath:
final class RayTracer {
private:
    enum PARALLEL       = true;
    enum SAMPS          = 1;
    enum INV_SAMPS      = 1.0/SAMPS;

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
    float3[] colourTotals;
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
        this.model  = model;
        this.width  = width;
        this.height = height;
        this.mutex  = new Mutex;
        this.colours.length      = width*height;
        this.colourTotals.length = width*height;

        this.cam = Ray(float3(50,52,295.6), (float3(0,-0.042612, -1)).normalised());
        this.cx  = float3(width*0.5135/height, 0, 0);
        this.cy  = (cx.cross(cam.direction)).normalised()*0.5135;

        this.thread = new Thread(&trace);
        thread.isDaemon = false;
        thread.start();
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
                defaultPoolThreads(2);
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
                for(auto i=0; i<colours.length; i++) {
                    tempColours[i] = colourTotals[i] / iterations;
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
        colourTotals[x+(y*width)] += (colour*0.25f);
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

            result += clampLo(radiance(ray, 0));
        }

        return result * INV_SAMPS;
    }
    float3 radiance(Ray r, uint depth) {
        float t;      // distance to intersection
        uint id = 0;  // id of intersected object
        if(!intersect(r, t, id)) {
            // if miss, return black
            return BLACK;
        }

        // the hit object
        auto obj      = model.spheres[id];
        Material mat  = obj.data;
        float3 f      = mat.colour;
        float maxRefl = max(f.x, f.y, f.z);

        if(depth++==9 || getRandom() >= maxRefl) {
            return mat.emission;
        }

        f *= (1/maxRefl);

        // ray intersection point
        const intersectPoint  = r.origin + r.direction*t;

        // sphere normal
        float3 norm = (intersectPoint-obj.pos).normalised();

        const reflectAngle = norm.dot(r.direction);

        // properly oriented surface normal
        float3 nl = reflectAngle<0 ? norm : norm*-1;

        float3 _reflect() {
            Ray ray = Ray(intersectPoint, r.direction - norm*2*reflectAngle);
            return radiance(ray, depth);
        }
        float3 _roughen() {
            float3 e = mat.emission;
            if(mat.roughness==0) return e;

            float p = noise.get(intersectPoint);
            e -= p*mat.roughness;
            e += 0.5*mat.roughness;
            return e;
        }
        // Ideal SPECULAR reflection
        float3 _specular() {
            return _roughen() + f * _reflect();
        }
        // Ideal DIFFUSE reflection
        float3 _diffuse() {
            float r1  = 2*PI*getRandom();
            float r2  = getRandom();
            float r2s = sqrt(r2);
            float3 w = nl;
            float3 u = ((fabs(w.x)>0.1 ? float3(0,1,0) : float3(1,0,0)).cross(w)).normalised();
            float3 v = w.cross(u);
            float3 d = u*cos(r1)*r2s + v*sin(r1)*r2s + w*sqrt(1-r2);
            d.normalise();

            Ray ray  = Ray(intersectPoint,d);
            float3 q = _roughen() + f * (radiance(ray, depth));
            return q;
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
                return _roughen() + f * _reflect();
            }
            // choose reflection or refraction
            const tdir = (r.direction*nnt - norm*((into?1:-1)*(ddn*nnt+sqrt(cos2t)))).normalised();
            float a  = toRI-fromRI;
            float b  = toRI+fromRI;
            float R0 = (a*a)/(b*b);
            float c  = 1.0-(into ? -ddn:tdir.dot(norm));
            float Re = R0+(1.0-R0)*c*c*c*c*c;
            float Tr = 1.0-Re;

            // Russian roulette
            if(depth>2) {
                float P = 0.25 + 0.5*Re;
                if(getRandom()<P) {
                    // reflect
                    return mat.emission + f*_reflect()*(Re/P);
                }
                // refract
                Ray ray  = Ray(intersectPoint, tdir);
                return mat.emission + f*radiance(ray,depth)*(Tr/(1-P));
            }
            // reflect and refract
            Ray ray = Ray(intersectPoint, tdir);
            return mat.emission + f*_reflect()*Re + radiance(ray,depth)*Tr;
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
    bool intersect(Ray r, ref float t, ref uint id) {
        t = float.max;
        float d;
        uint num = cast(int)model.spheres.length;
        for(uint i=num; i--; ) {
            if(model.spheres[i].intersect(r, d) && d<t) {
                t  = d;
                id = i;
            }
        }
        return t < float.max;
    }
}