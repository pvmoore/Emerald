module emerald.scenes.Scene3;

import emerald.all;

final class Scene3 : Scene {
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
        addlargeRoomUsingSpheres();
        shapes ~= [
        //         radius,  position,                   material
        // specular diffuse
        new Sphere(8,		float3(-10,10,50),			new Material().setDiffuse(float3(1,0.7,0.2))),
        new Sphere(8,		float3(10,10,50),			new Material().setDiffuse(float3(1,0.7,0.2))
                                                                      .setReflection(0.03)),
        new Sphere(8,		float3(30,10,50),			new Material().setDiffuse(float3(1,0.7,0.2))
                                                                      .setReflection(0.2)),
        new Sphere(8,		float3(50,10,50),			new Material().setDiffuse(float3(1,0.7,0.2))
                                                                      .setReflection(0.6)),
        new Sphere(8,		float3(70,10,50),			new Material().setDiffuse(float3(1,0.7,0.2))
                                                                      .setReflection(1.2)),
        new Sphere(8,		float3(90,10,50),			new Material().setDiffuse(float3(1,0.7,0.2))
                                                                      .setReflection(3)),
        new Sphere(8,		float3(110,10,50),			new Material().setDiffuse(float3(1,0.7,0.2))
                                                                      .setReflection(8)),

        // refractive indexes
        new Sphere(8,		float3(-10,30,50),			new Material().setRefraction(1.333)),
        new Sphere(8,		float3(10,30,50),			new Material().setRefraction(1.52)),
        new Sphere(8,		float3(30,30,50),			new Material().setRefraction(1.77)),
        new Sphere(8,		float3(50,30,50),			new Material().setRefraction(2.419)),

        // diffuse yellow glass
        new Sphere(8,		float3(-10,50,50),			new Material().setDiffuse(float3(1,0.7,0.2))
                                                                      .setRefraction(1.5)),


        // Top light
        new Sphere(600,	float3(50,681.6-.27,81.6),	LIGHT)
        ];
    }
}