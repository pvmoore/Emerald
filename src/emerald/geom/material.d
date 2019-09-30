module emerald.geom.material;

import emerald.all;

/**
 * https://en.wikipedia.org/wiki/List_of_refractive_indices
 * ETA
 *      ice         1.31
 *      water       1.333
 *      ethanol     1.36
 *      olive oil   1.47
 *      glass       1.52
 *      amber       1.55
 *      sapphire    1.762–1.778 (1.77)
 *      diamond     2.419
 */
__gshared Material GLASS  = Material.refract(1.5);
__gshared Material MIRROR = Material.mirror(1);
__gshared Material LIGHT  = Material.light(float3(12,12,12));

final class Material {
    float3 colour      = float3(1,1,1);
    float3 emission    = float3(0,0,0);
    float diffusePower = 0;
    float reflectance  = 0;
    float refractIndex = 0;

    float3 speckleColour = float3(0,0,0);
    float specklePower = 0;

    bool isDiffuse;
    bool isReflective;
    bool isRefractive;

    static Material diffuse(float3 c, float power=1) {
        Material m     = new Material();
        m.colour       = c;
        m.isDiffuse    = true;
        m.diffusePower = power;
        return m;
    }
    static Material light(float3 emission) {
        Material m  = new Material();
        m.colour    = float3(0,0,0);
        m.emission  = emission;
        m.isDiffuse = true;
        return m;
    }
    static Material mirror(float r) {
        Material m     = new Material();
        m.reflectance  = r;
        m.isReflective = true;
        return m;
    }
    static Material refract(float eta) {
        Material m     = new Material();
        m.refractIndex = eta;
        m.isRefractive = true;
        return m;
    }

    auto c(float3 colour) {
        this.colour = colour;
        return this;
    }
    auto e(float3 emission) {
        this.emission = emission;
        return this;
    }
    auto refl(float r) {
        this.reflectance = r;
        this.isReflective = true;
        return this;
    }
    auto refr(float eta) {
        this.refractIndex = eta;
        this.isRefractive = true;
        return this;
    }
    auto speckle(float3 c, float r) {
        this.speckleColour = c;
        this.specklePower  = r;
        return this;
    }
}

