module emerald.gen.LoopPathTracer;

import emerald.all;

final class LoopPathTracer : AbstractPathTracer {
private:

public:
    this(Scene scene, uint width, uint height) {
        super(scene, width, height);
    }
protected:
    override float3 radiance(ref Ray r, uint x, uint row, uint depth) {
        auto ii          = rowData[row].ii;
        auto colour      = BLACK;
        auto reflectance = WHITE;

        while(true) {

            //ii.pos = uint2(x,row);

            if(!intersectRayWithWorld(r, ii)) {
                // If miss, return current colour
                // TODO - use a skybox if supplied
                return colour;
            }

            // We hit something
            auto mat = ii.shape.getMaterial();

            // Add some light
            colour += reflectance * mat.emission;

            // Bail if we hit max depth or the material is too dark
            if(depth++==MAX_DEPTH || getRandomFloat() >= mat.maxReflectance) {
                return colour;
            }

            const intersectPoint  = ii.hitPoint;
            const norm            = ii.normal;
            const reflectAngle    = norm.dot(r.direction);

            float3 f = mat.texture
                ? mat.texture.sample(ii.getUV()) * mat.colour
                : mat.normalisedColour;

            reflectance *= f;

            // properly oriented surface normal
            float3 nl = reflectAngle<0 ? norm : norm*-1;

            if(mat.isReflective && mat.reflectance > getRandomFloat()) {
                // Ideal SPECULAR reflection

                r = Ray(intersectPoint, (r.direction - norm*2*reflectAngle).normalised());

            } else if(mat.isRefractive) {
                // Ideal dielectric REFRACTION

                // Ray from outside going in?
                bool into = norm.dot(nl)>0;

                // refractive index
                const fromRI = 1;   // air
                const toRI   = mat.refractIndex;
                const nnt    = into ? fromRI/toRI : toRI/fromRI;
                const ddn    = r.direction.dot(nl);
                const cos2t  = 1-nnt*nnt*(1-ddn*ddn);

                if(cos2t<0) {
                    // Total internal reflection
                    r = Ray(intersectPoint, (r.direction - norm*2*reflectAngle).normalised());
                } else {
                    // Choose reflection or refraction
                    const tdir = (r.direction*nnt - norm*((into?1:-1)*(ddn*nnt+sqrt(cos2t)))).normalised();
                    const a    = toRI-fromRI;
                    const b    = toRI+fromRI;
                    const R0   = (a*a)/(b*b);
                    const c    = 1.0-(into ? -ddn : tdir.dot(norm));
                    const Re   = R0+(1.0-R0)*c*c*c*c*c;
                    const Tr   = 1.0-Re;

                    const P = 0.25 + 0.5*Re;
                    if(getRandomFloat()<P) {
                        // reflect
                        reflectance *= Re/P;
                        r = Ray(intersectPoint, (r.direction - norm*2*reflectAngle).normalised());
                    } else {
                        // refract
                        reflectance *= Tr/(1.0-P);
                        r = Ray(intersectPoint, tdir);
                    }
                }
            } else {
                // Ideal DIFFUSE reflection

                const r1 = getRandom();
                const r2 = getRandom();

                const w  = nl;
                const u  = ((fabs(w.x)>0.1 ? Y_DIR : X_DIR).cross(w)).normalised();
                const v  = w.cross(u);
                const d  = u*r1.cos2PIRand*r2.sqrtRand +
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

                r = Ray(intersectPoint, d.normalised());
            }
        }
    }
}