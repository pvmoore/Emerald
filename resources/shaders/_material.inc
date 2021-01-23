 /*
    [0] reflectance     // 0 = not reflective
    [1] refractiveIndex // 0 = not refractive
    [2] Diffuse RGB
    [3]
    [4]
    [5] Emission RGB
    [6]
    [7]
    [8] texture


*/

#define mat_reflectance(i)      materials[i]
#define mat_refractiveIndex(i)  materials[i+1]
#define mat_diffuse(i)          vec3(materials[i+2], materials[i+3], materials[i+4])
#define mat_emission(i)         vec3(materials[i+5], materials[i+6], materials[i+7])
#define mat_texture(i)          int(materials[i+8])
#define mat_hasTexture(i)       (materials[i+8] >= 0)

/**
 * | uvs   | brick   | redWhite | earth
 * | rock  | marble  |    2,1   |  3,1
 * |  0,2  |   1,2   |    2,2   |  3,2
 * |  0,3  |   1,3   |    2,3   |  3,3
 *
 *  Convert to 4x4 uv value.
 */
vec2 convertUV(uint texture, vec2 uv) {
    vec2 offset = vec2(texture%4, texture/4);
    return (offset + uv) * 0.25;
}