module emerald.gen.RecursiveRayTracer;

import emerald.all;

final class RecursiveRayTracer : AbstractRayTracer {
private:

public:
    this(Scene scene, uint width, uint height) {
        super(scene, width, height);
    }
    override float3 radiance(ref Ray r, uint row, uint depth) {

        auto ii = rowData[row].ii;

        if(!intersectRayWithWorld(r, ii)) {
            // if miss, return black
            // TODO - use a skybox if supplied
            return BLACK;
        }

        // we hit something
        auto mat = ii.shape.getMaterial();

        if(depth++==MAX_DEPTH || getRandomFloat() >= mat.maxReflectance) {
            return mat.emission;
        }

        const intersectPoint  = ii.hitPoint;
        const norm            = ii.normal;
        const reflectAngle    = norm.dot(r.direction);

        float3 f = mat.texture
            ? mat.texture.sample(ii.getUV()) * mat.colour
            : mat.normalisedColour;

        // properly oriented surface normal
        float3 nl = reflectAngle<0 ? norm : norm*-1;

        float3 _reflect() {
            Ray ray = Ray(intersectPoint, r.direction - norm*2*reflectAngle);
            return radiance(ray, row, depth);
        }

        float3 colour = float3(0,0,0);
        float factor  = 0;

        // Ideal SPECULAR reflection
        if(mat.isReflective) {
            factor += mat.reflectance;
            colour += mat.emission + f * _reflect() * mat.reflectance;
        }

        // Ideal dielectric REFRACTION
        if(mat.isRefractive) {
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
                return mat.emission + f * _reflect();
            }
            // choose reflection or refraction
            const tdir = (r.direction*nnt - norm*((into?1:-1)*(ddn*nnt+sqrt(cos2t)))).normalised();
            float a    = toRI-fromRI;
            float b    = toRI+fromRI;
            float R0   = (a*a)/(b*b);
            float c    = 1.0-(into ? -ddn : tdir.dot(norm));
            float Re   = R0+(1.0-R0)*c*c*c*c*c;
            float Tr   = 1.0-Re;

            // Russian roulette
            if(depth>2) {
                float P = 0.25 + 0.5*Re;
                if(getRandomFloat()<P) {
                    // reflect
                    return mat.emission + f*_reflect()*(Re/P);
                }
                // refract
                Ray ray  = Ray(intersectPoint, tdir);
                return mat.emission + f*radiance(ray, row, depth)*(Tr/(1-P));
            }
            // reflect and refract
            Ray ray = Ray(intersectPoint, tdir);

            factor += 1;
            colour += mat.emission + f*_reflect()*Re + radiance(ray, row, depth)*Tr;
        }

        // Ideal DIFFUSE reflection
        if(mat.isDiffuse) {
            auto r1 = getRandom();
            auto r2 = getRandom();

            float3 w  = nl;
            float3 u  = ((fabs(w.x)>0.1 ? float3(0,1,0) : float3(1,0,0)).cross(w)).normalised();
            float3 v  = w.cross(u);
            float3 d  = u*r1.cos2PIRand*r2.sqrtRand +
                        v*r1.sin2PIRand*r2.sqrtRand +
                        w*r2.sqrt_1_sub_rand;

            // float r1  = 2*PI*getRandomFloat();
            // float r2  = getRandomFloat();
            // float r2s = sqrt(r2);
            // float3 w  = nl;
            // float3 u  = ((fabs(w.x)>0.1 ? float3(0,1,0) : float3(1,0,0)).cross(w)).normalised();
            // float3 v  = w.cross(u);
            // float3 d  = u*cos(r1)*r2s +
            //             v*sin(r1)*r2s +
            //             w*sqrt(1-r2);
            d.normalise();

            Ray ray = Ray(intersectPoint, d);

            factor += 1;
            colour += mat.emission + f * (radiance(ray, row, depth));
        }

        return colour * (1.0/factor);
    }
}