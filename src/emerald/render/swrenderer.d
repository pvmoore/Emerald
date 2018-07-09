module emerald.render.swrenderer;

import emerald.all;

@fastmath:

final class SWRenderer {
private:
    const SAMPS         = 10;
    const INV_SAMPS     = 1.0/SAMPS;
    immutable Vec BLACK = Vec(0,0,0);
    uint width;
    uint height;
    OpenGL gl;
    Model model;
    PixelBuffer pixels;
    Ray cam;
    immutable Vec cx;
    immutable Vec cy;
    Vec[] colours;
    Vec[] colourTotals;
    uint iterations;
    Thread thread;
    bool running = true;
    double totalMsamplesPerSecond = 0;
    double msamplesPerSecond = 0;
    uint lastScreenShotSPP;
    uint screenshotId;
public:
    @property uint samplesPerPixel() { return iterations*SAMPS*4; }
    @property double averageMSPP() { return totalMsamplesPerSecond/iterations; }

    this(OpenGL gl, Model model, uint width, uint height) {
        this.gl     = gl;
        this.model  = model;
        this.width  = width;
        this.height = height;
        this.pixels = new PixelBuffer(gl, Vector2(0,0), width, height);
        this.colours.length = width*height;
        this.colourTotals.length = width*height;

        this.thread = new Thread(&generateImage);
        thread.isDaemon = false;
        thread.start();

        cam = Ray(Vec(50,52,295.6), (Vec(0,-0.042612, -1)).normalised());
        cx  = Vec(width*0.5135/height, 0, 0);
        cy  = (cx.cross(cam.direction)).normalised()*0.5135;
    }
    void destroy() {
        running = false;
        pixels.destroy();
    }
    void writeBMP() {
        if(lastScreenShotSPP==samplesPerPixel) return;
        if(lastScreenShotSPP==0) {
            screenshotId = cast(uint)(getRandom()*100000);
        }
        lastScreenShotSPP = samplesPerPixel;

        BMP bmp = BMP.create_RGB888(
            width, height, cast(ubyte[])pixels.pixels);
        string filename = "screenshots/%s-%s.bmp".
            format(screenshotId, samplesPerPixel);
        bmp.write(filename);
    }
    // this runs in a different thread
    void generateImage() {
        while(running) {
            StopWatch watch; watch.start();
            // run lines in parallel
            foreach(y; parallel(iota(0, height))) {
                if(running) {
                    rayTraceLine(y);
                }
            }
            watch.stop();
            iterations++;

//            writefln("rays created: %s destroyed:%s",
//                raysCreated, raysDestroyed);
//            raysCreated = 0;
//            raysDestroyed = 0;

            uint spp500 = samplesPerPixel/500;
            if((lastScreenShotSPP/500)<spp500) {
                writeBMP();
            }

            auto numSamples = width*height*SAMPS*4;
            auto seconds = watch.peek().total!"nsecs"/1_000_000_000.0;
            msamplesPerSecond = (numSamples/seconds)/1_000_000.0;
            totalMsamplesPerSecond += msamplesPerSecond;

            for(auto i=0; i<colours.length; i++) {
                colours[i] = colourTotals[i] / iterations;
            }
        }
    }
    void render() {
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
        pixels.blitToScreen();

        gl.setWindowTitle("Emerald "~VERSION~
            "  (spp="~to!string(samplesPerPixel)~
            ", average msps=%.2f".format(averageMSPP)~")"~
            (iterations==0?" (wait a few seconds...)":"")
        );
    }
private:
    void rayTraceLine(uint y) {
    	for(int x=0; x<width; x++) {
            rayTracePixel(x, y);
    	}
    }
    void rayTracePixel(uint x, uint y) {
        Vec colour = Vec(0,0,0);
        // 2x2 supersample
        for(int sy=0; sy<2; sy++)
        for(int sx=0; sx<2; sx++) {
            colour += sample(x,y, sx, sy)*0.25f;
        }
        colourTotals[x+(y*width)] += colour;
    }
    Vec sample(uint x, uint y, uint sx, uint sy) {
        Vec r = Vec(0,0,0);
        for(int s=0; s<SAMPS; s++) {
            float dx = tentFilter.next();
            float dy = tentFilter.next();

            Vec d = cam.direction;
            d += cx*( ( (sx-0.5 + dx)/2 + x)/width - 0.5) +
                 cy*( ( (sy-0.5 + dy)/2 + y)/height - 0.5);

            // Camera rays are pushed forward 140 to start in interior
            Ray ray = Ray(cam.origin+d*140, d.normalised());
            r += radiance(ray,0)*INV_SAMPS;
        }
        return r.clamp();
    }
    Vec radiance(ref Ray r, uint depth) {
    	float t;      // distance to intersection
    	uint id = 0;  // id of intersected object
    	if(!intersect(r, t, id)) {
    	    // if miss, return black
    	    return BLACK;
    	}

        // the hit object
    	auto obj      = model.spheres[id];
    	Material mat  = obj.data;
    	Vec f         = mat.colour;
        float maxRefl = max(f.x, f.y, f.z);

        if(depth++==9 || getRandom() >= maxRefl) {
            return mat.emission;
        }

        f *= (1/maxRefl);

    	// ray intersection point
    	Vec intersectPoint  = r.origin + r.direction*t;
    	// sphere normal
        Vec norm  = (intersectPoint-obj.pos).normalised();
        float reflectAngle = norm.dot(r.direction);
        // properly oriented surface normal
        Vec nl = reflectAngle<0 ? norm : norm*-1;

        pragma(inline,true)
        Vec reflect() {
            Ray ray = Ray(intersectPoint,r.direction-norm*2*reflectAngle);
            Vec q = radiance(ray, depth);
            return q;
        }
        pragma(inline,true)
        Vec roughen() {
            Vec e = mat.emission;
            if(mat.roughness==0) return e;

            float p = noise.get(intersectPoint);
            e -= p*mat.roughness;
            e += 0.5*mat.roughness;
            return e;
        }

        // Ideal SPECULAR reflection
        pragma(inline,true)
        Vec specular() {
            return roughen() + f * reflect();
        }
        // Ideal DIFFUSE reflection
        pragma(inline,true)
        Vec diffuse() {
            float r1  = 2*PI*getRandom();
            float r2  = getRandom();
            float r2s = sqrt(r2);
            Vec w = nl;
            Vec u = ((fabs(w.x)>0.1 ? Vec(0,1,0) : Vec(1,0,0)).cross(w)).normalised();
            Vec v = w.cross(u);
            Vec d = u*cos(r1)*r2s + v*sin(r1)*r2s + w*sqrt(1-r2);
            d.normalise();

            Ray ray = Ray(intersectPoint,d);
            Vec q = roughen() +
                f * (radiance(ray, depth));
            return q;
        }
        // Ideal dielectric REFRACTION
        pragma(inline,true)
        Vec refraction() {
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
            Vec tdir = (r.direction*nnt - norm*((into?1:-1)*(ddn*nnt+sqrt(cos2t)))).normalised();
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
                Vec q = mat.emission + f *
                       radiance(ray,depth)*(Tr/(1-P));
                return q;
            }
            // reflect and refract
            Ray ray = Ray(intersectPoint,tdir);
            Vec q = mat.emission + f *
                   reflect()*Re +
                   radiance(ray,depth)*Tr;
            return q;
        }

        Vec col;
        float factor = 0;
        if(mat.isReflective) {
            col    += mat.reflectance*specular();
            factor += mat.reflectance;
        }
        if(mat.isRefractive) {
            col    += refraction();
            factor += 1;
        }
        if(mat.isDiffuse) {
            col    += mat.diffusePower * diffuse();
            factor += mat.diffusePower;
        }
        return (1/factor)*col;
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
