module emerald.scenes.Scene2;

import emerald.all;

final class Scene2 : Scene {
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
        //          radius, position,               material
        // mirror balls
        new Sphere(16.5,	float3(27,16.5,47),     MIRROR),
        new Sphere(16.5,	float3(73,16.5,47),		MIRROR),
        new Sphere(16.5,	float3(27,60,47),		Material.mirror(1).c(float3(1,0.5,0.5))),
        new Sphere(16.5,	float3(73,60,47),		Material.mirror(1).c(float3(1,0.5,1))),

        // glass ball combo (left)
        new Sphere(15,	    float3(0,40,80),		GLASS),
        new Sphere(6,	    float3(0,40,80),		new Material().c(float3(1,0,0)).refl(1)),

        // glass ball combo (right)
        new Sphere(15,	    float3(100,40,80),		GLASS),
        new Sphere(6,	    float3(100,40,80),		Material.diffuse(float3(0,0,1))),

        // brass diffuse ball
        new Sphere(10,		float3(17,10,80),		Material.diffuse(float3(0.30, 0.20, 0.10))),


        // specular diffuse
        new Sphere(10,		float3(50,40,80),		Material.diffuse(float3(1,0.7,0.2)).refl(0.1)),


        // glass ball
        new Sphere(10,	    float3(83,10,80),		GLASS),

        // shiny yellow mirror ball in centre
        new Sphere(10,	    float3(50,10,80),		Material.mirror(1).c(float3(1,0.7,0.2))),

        // small green glass ball
        // with blue emission
        new Sphere(5,	    float3(-15,5,80),		Material.refract(1.5).c(float3(0,1,0)).e(float3(0,0,0.05))),

        // small blue mirror ball
        // with red emission
        new Sphere(5,	    float3(-15,5,50),		Material.mirror(1).c(float3(0,0,1)).e(float3(0.05,0,0))),

        // small red ball
        // with green emission
        new Sphere(5,	    float3(-15,5,20),		Material.diffuse(float3(1,0,0)).e(float3(0,0.05,0))),

        // Top light
        new Sphere(600,	float3(50,681.6-.27,81.6),	LIGHT)
        ];
    }
}