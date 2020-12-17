module emerald.scenes.CornellBox;

import emerald.all;

final class CornellBox : Scene {
private:
public:
    this(uint width, uint height) {
        super(new Camera(
            float3(50,52,295.6),        // origin
            float3(0,-0.042612, -1),    // direction
            width,
            height
        ));

        loadTextures();
        createScene();
    }
    void loadTextures() {

    }
    void createScene() {
        shapes ~= [
        //         radius,	position,				    material
        new Sphere(1e4,		float3(1e4+1,40.8,81.6),    Material.diffuse(float3(.75,.25,.25))),//Left
        new Sphere(1e4,		float3(-1e4+99,40.8,81.6),	Material.diffuse(float3(.25,.25,.75))),//Rght
        new Sphere(1e4,		float3(50,40.8, 1e4),		Material.diffuse(float3(.25,.75,.25))),//Back
        new Sphere(1e4,		float3(50,40.8,-1e4+170),	Material.diffuse(float3(0,0,0))),//Frnt
        new Sphere(1e4,		float3(50, 1e4, 81.6),		Material.diffuse(float3(.75,.75,.75))),//Botm
        new Sphere(1e4,		float3(50,-1e4+81.6,81.6),	Material.diffuse(float3(.75,.75,.75))),//Top

        new Sphere(16.5,	float3(27,16.5,47),		    MIRROR),
        new Sphere(16.5,	float3(73,16.5,78),		    GLASS),

        new Sphere(600,		float3(50,681.6-.27,81.6),	LIGHT)
        ];
    }
}