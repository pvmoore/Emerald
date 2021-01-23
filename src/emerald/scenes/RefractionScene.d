module emerald.scenes.RefractionScene;

import emerald.all;

final class RefractionScene : Scene {
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
        addlargeRoomUsingRectangles();

        // light
        shapes ~= new Sphere(600,	    float3(50,681.6-.27,81.6),	LIGHT);

        shapes ~= [
            // Diffuse
            new Sphere(8, float3( -10,15,45),	new Material().setDiffuse(float3(1,0.8,0.3))),

            new Sphere(8, float3(   8,15,45),	new Material().setDiffuse(float3(1,0.8,0.3))),
            new Sphere(9, float3(   8,15,45),	new Material().setRefraction(1.52)
                                                              .setDiffuse(float3(1.0,1.0,1.0))),

            new Sphere(8, float3(  28, 15,45),	new Material().setDiffuse(float3(1,0.8,0.3))),
            new Sphere(10, float3( 28,15,45),	new Material().setRefraction(1.52)
                                                              .setDiffuse(float3(1.0,1.0,1.0))),

            new Sphere(8, float3(  50, 15,45),	new Material().setDiffuse(float3(1,0.8,0.3))),
            new Sphere(11, float3( 50,15,45),	new Material().setRefraction(1.52)
                                                              .setDiffuse(float3(1.0,1.0,1.0))),

            new Sphere(8, float3(  76, 15,45),	new Material().setDiffuse(float3(1,0.8,0.3))),
            new Sphere(11, float3( 76, 15,45),	new Material().setRefraction(1.52)
                                                              .setDiffuse(float3(1,0.8,0.3))),

            // Mirror



            // new Sphere(10, float3(  5, 10,45),	Material.mirror(1).c(float3(1,0.8,0.3))),
            // new Sphere(10, float3( -20,32,45),	Material.diffuse(float3(1,0.8,0.3))),
            // new Sphere(10, float3(  5, 32,45),	Material.mirror(1).c(float3(1,0.8,0.3))),

            // new Sphere(11, float3( 5, 10,45),	Material.refract(1.333).c(float3(1.0,1.0,1.0))),


            // new Sphere(10, float3( 30,10,45),	Material.refract(1.333).c(float3(1.0,0.75,0.75))),
            // new Sphere(10, float3( 55,10,45),	Material.refract(1.333).c(float3(1.0,0.75,0.75))),
            // new Sphere(10, float3( 80,10,45),	Material.refract(1.333).c(float3(1,0,0.0)))

        ];
    }
}