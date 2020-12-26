module emerald.scenes.SuzanneScene;

import emerald.all;

final class SuzanneScene : Scene {
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

        shapes ~= new TriangleMesh("resources/models/suzanne.obj.txt", Material.diffuse(float3(1,1,1)))
            .scale(float3(28,28,28))
            .translate(float3(20,40,50))
            .rotate(0.degrees, 45.degrees, 0.degrees)
            .build();

        // shapes ~= new TriangleMesh("resources/models/suzanne.obj.txt", Material.diffuse(float3(1,1,1)).refr(2))
        //     .scale(float3(28.05,28.05,28.05))
        //     .translate(float3(20,40,50))
        //     .rotate(0.degrees, 45.degrees, 0.degrees)
        //     .build();

        shapes ~= new TriangleMesh("resources/models/suzanne.obj.txt", Material.diffuse(float3(1,1,1)), true)
            .scale(float3(28,28,28))
            .translate(float3(80,40,50))
            .rotate(0.degrees, (-45).degrees, 0.degrees)
            .build();

        // shapes ~= new TriangleMesh("resources/models/suzanne.obj.txt", Material.diffuse(float3(1,1,1)).refr(1.6), true)
        //     .scale(float3(28.05,28.05,28.05))
        //     .translate(float3(80,40,50))
        //     .rotate(0.degrees, (-45).degrees, 0.degrees)
        //     .build();
    }
}