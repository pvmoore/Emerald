module emerald.model.material;

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

final class Material {
private:
    __gshared static Material[] materials;
public:
    uint id;
    float3 emission         = float3(0,0,0);
    float3 colour           = float3(1,1,1);
    float reflectance       = 0;
    float refractIndex      = 0;
    float3 normalisedColour = float3(1,1,1);
    float maxReflectance    = 1;
    Texture texture;
    bool isDiffuse;
    bool isReflective;
    bool isEmissive;

    static auto getAllMaterials() {
        return materials;
    }

    this() {
        this.id = materials.length.as!uint;
        materials ~= this;
    }
    auto setDiffuse(float3 c) {
        this.isDiffuse        = true;
        this.colour           = c;
        this.maxReflectance   = c.max();
        this.normalisedColour = c / this.maxReflectance;
        return this;
    }
    auto setEmission(float3 e) {
        this.isEmissive       = true;
        this.emission         = e;
        return this;
    }
    auto setReflection(float r) {
        this.isReflective = true;
        this.reflectance  = r;
        return this;
    }
    auto setRefraction(float eta) {
        this.refractIndex = eta;
        return this;
    }
    auto setTexture(Texture t) {
        this.texture = t;
        return this;
    }
    float[] getForGPU() {
        return [
            reflectance,
            refractIndex,
            colour.x,
            colour.y,
            colour.z,
            emission.x,
            emission.y,
            emission.z,
            texture is null ? -1f : texture.getIndex().as!float
        ];
    }
}

