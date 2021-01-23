module emerald.scenes.OneSphere;


import emerald.all;

final class OneSphere : Scene {
private:
    Texture floorTex;
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
        this.floorTex = new Texture(Texture.ID.REDWHITE);
    }
    void createScene() {
        addlargeRoomUsingSpheres();

        mat4 rotY = mat4.rotateY((-45).degrees);
        mat4 rotX = mat4.rotateX((45).degrees);

        mat4 rotXY = rotY * rotX;

        shapes ~= [
        //         radius,  position,                   material
        new Sphere(40,      float3(50,40,40),           new Material().setDiffuse(float3(1.0, 1.0, 1.0))
                                                                .setTexture(floorTex))
                                                                .transform(rotXY),

        new Sphere(600,	    float3(50,681.6-.27,81.6),	LIGHT)
        ];
    }
}