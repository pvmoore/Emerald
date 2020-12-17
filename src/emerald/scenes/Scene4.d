module emerald.scenes.Scene4;

import emerald.all;

final class Scene4 : Scene {
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
        //                  radius,  position,                  material
        new Sphere(10,		float3( 0,10,45),			Material.diffuse(float3(1,0.8,0.3))),
        new Sphere(10,		float3(25,10,40),			Material.diffuse(float3(1,0.8,0.3))),
        new Sphere(10,		float3(50,10,40),			Material.diffuse(float3(1,0.8,0.3))),
        new Sphere(10,		float3(75,10,40),			Material.diffuse(float3(1,0.8,0.3))),
        new Sphere(10,		float3(100,10,40),			Material.diffuse(float3(1,0.8,0.3))),

        new Sphere(10,		float3( 0,30,40),			Material.diffuse(float3(1,0.8,0.3)).refl(1)),
        new Sphere(10,		float3(25,30,40),			Material.diffuse(float3(1,0.8,0.3)).refl(1)),
        new Sphere(10,		float3(50,30,40),			Material.diffuse(float3(1,0.8,0.3)).refl(1)),
        new Sphere(10,		float3(75,30,40),			Material.diffuse(float3(1,0.8,0.3)).refl(1)),
        new Sphere(10,		float3(100,30,40),			Material.diffuse(float3(1,0.8,0.3)).refl(1)),

        new Sphere(10,		float3( 2,50,40),			Material.mirror(1)),
        new Sphere(10,		float3(25,50,40),			Material.mirror(1)),
        new Sphere(10,		float3(50,50,40),			Material.mirror(1)),
        new Sphere(10,		float3(75,50,40),			Material.mirror(1)),
        new Sphere(10,		float3(100,50,40),			Material.mirror(1)),

        new Sphere(10,		float3( 2,70,40),			Material.refract(1.5)),
        new Sphere(10,		float3(25,70,40),			Material.refract(1.5)),
        new Sphere(10,		float3(50,70,40),			Material.refract(1.5)),
        new Sphere(10,		float3(75,70,40),			Material.refract(1.5)),
        new Sphere(10,		float3(100,70,40),			Material.refract(1.5)),


        new Sphere(600,	float3(50,681.6-.27,81.6),	LIGHT)
        ];
    }
}