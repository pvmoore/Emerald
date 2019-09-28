module emerald.gen.raytracer;

import emerald.all;

@fastmath:
final class RayTracer {
private:
    enum PARALLEL       = true;
    enum SAMPS          = 10;
    enum INV_SAMPS      = 1.0/SAMPS;

    immutable float3 BLACK = float3(0,0,0);
    immutable float3 cx;
    immutable float3 cy;

    Model model;
    const uint width, height;
    float3[] colours;

    Ray cam;
    bool running = true;
    uint iterations;
    double totalMegaSPP = 0;
    double megaSPP = 0;
    Thread thread;

    // Updated asynchronously
    float3[] colourTotals;
public:
    uint samplesPerPixel()  { return iterations*SAMPS*4; }
    double averageMegaSPP() { return iterations == 0 ? 0 : totalMegaSPP/iterations; }
    float3[] getColours()   { return colours; }
    uint getIterations()    { return iterations; }

    this(Model model, uint width, uint height) {
        this.model  = model;
        this.width  = width;
        this.height = height;
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
        while(running) {
            StopWatch watch; watch.start();

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

            auto numSamples = width*height*SAMPS*4;
            auto seconds    = watch.peek().total!"nsecs"/1_000_000_000.0;

            megaSPP       = (numSamples/seconds)/1_000_000.0;
            totalMegaSPP += megaSPP;

            for(auto i=0; i<colours.length; i++) {
                colours[i] = colourTotals[i] / iterations;
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
                colour += sample(x,y, sx, sy)*0.25f;
            }
        }
        colourTotals[x+(y*width)] += colour;
    }
    float3 sample(uint x, uint y, uint sx, uint sy) {
        float3 r = float3(0,0,0);
        for(int s=0; s<SAMPS; s++) {
            float dx = tentFilter.next();
            float dy = tentFilter.next();

            float3 d = cam.direction;
            d += cx*( ( (sx-0.5 + dx)/2 + x)/width - 0.5) +
                    cy*( ( (sy-0.5 + dy)/2 + y)/height - 0.5);

            // Camera rays are pushed forward 140 to start in interior
            Ray ray = Ray(cam.origin+d*140, d.normalised());
            r += radiance(ray,0)*INV_SAMPS;
        }
        return r.clamp();
    }
    float3 radiance(ref Ray r, uint depth) {
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
        float3 intersectPoint  = r.origin + r.direction*t;
        // sphere normal
        float3 norm  = (intersectPoint-obj.pos).normalised();
        float reflectAngle = norm.dot(r.direction);
        // properly oriented surface normal
        float3 nl = reflectAngle<0 ? norm : norm*-1;

        pragma(inline,true)
        float3 reflect() {
            Ray ray = Ray(intersectPoint,r.direction-norm*2*reflectAngle);
            float3 q = radiance(ray, depth);
            return q;
        }
        pragma(inline,true)
        float3 roughen() {
            float3 e = mat.emission;
            if(mat.roughness==0) return e;

            float p = noise.get(intersectPoint);
            e -= p*mat.roughness;
            e += 0.5*mat.roughness;
            return e;
        }

        // Ideal SPECULAR reflection
        pragma(inline,true)
        float3 specular() {
            return roughen() + f * reflect();
        }
        // Ideal DIFFUSE reflection
        pragma(inline,true)
        float3 diffuse() {
            float r1  = 2*PI*getRandom();
            float r2  = getRandom();
            float r2s = sqrt(r2);
            float3 w = nl;
            float3 u = ((fabs(w.x)>0.1 ? float3(0,1,0) : float3(1,0,0)).cross(w)).normalised();
            float3 v = w.cross(u);
            float3 d = u*cos(r1)*r2s + v*sin(r1)*r2s + w*sqrt(1-r2);
            d.normalise();

            Ray ray = Ray(intersectPoint,d);
            float3 q = roughen() +
                f * (radiance(ray, depth));
            return q;
        }
        // Ideal dielectric REFRACTION
        pragma(inline,true)
        float3 refraction() {
            // Ray from outside going in?
            bool into    = norm.dot(nl)>0;
            // refractive index
            float fromRI = 1;   // air
            float toRI   = mat.refractIndex;
            float nnt    = into ? fromRI/toRI :
                                    toRI/fromRI;
            float ddn    = r.direction.dot(nl);
            float cos2t  = 1-nnt*nnt*(1-ddn*ddn);

            if(cos2t<0) {
                // Total internal reflection
                return roughen() + f * reflect();
            }
            // choose reflection or refraction
            float3 tdir = (r.direction*nnt - norm*((into?1:-1)*(ddn*nnt+sqrt(cos2t)))).normalised();
            float a  = toRI-fromRI;
            float b  = toRI+fromRI;
            float R0 = (a*a)/(b*b);
            float c  = 1-(into ? -ddn:tdir.dot(norm));
            float Re = R0+(1-R0)*c*c*c*c*c;
            float Tr = 1-Re;

            // Russian roulette
            if(depth>2) {
                float P  = 0.25 + 0.5*Re;
                if(getRandom()<P) {
                    // reflect
                    return mat.emission + f * reflect() * (Re/P);
                }
                // refract
                Ray ray = Ray(intersectPoint,tdir);
                float3 q = mat.emission + f *
                        radiance(ray,depth)*(Tr/(1-P));
                return q;
            }
            // reflect and refract
            Ray ray = Ray(intersectPoint,tdir);
            float3 q = mat.emission + f *
                    reflect()*Re +
                    radiance(ray,depth)*Tr;
            return q;
        }

        float3 col;
        float factor = 0;
        if(mat.isReflective) {
            col    += specular()*mat.reflectance;
            factor += mat.reflectance;
        }
        if(mat.isRefractive) {
            col    += refraction();
            factor += 1;
        }
        if(mat.isDiffuse) {
            col    += diffuse() * mat.diffusePower;
            factor += mat.diffusePower;
        }
        return col * (1/factor);
    }
    bool intersect(ref Ray r, ref float t, ref uint id) {
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