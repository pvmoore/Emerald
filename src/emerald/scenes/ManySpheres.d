module emerald.scenes.ManySpheres;

import emerald.all;

final class ManySpheres : Scene {
private:
    Texture marbleTex;
    Texture brickTex;
    Texture rock8Tex;
    Texture redWhiteTex;
    Texture uvsTex;
    Texture earthTex;
public:
    this(uint width, uint height) {
        super(new Camera(
            float3(50, 52, 295.6),      // origin
            float3(0, -0.042612, -1),   // direction
            width,
            height
        ));

        loadTextures();
        createScene();
    }
    void loadTextures() {
        this.marbleTex   = new Texture(Texture.ID.MARBLE);
        this.brickTex    = new Texture(Texture.ID.BRICK);
        this.rock8Tex    = new Texture(Texture.ID.ROCK);
        this.redWhiteTex = new Texture(Texture.ID.REDWHITE);
        this.uvsTex      = new Texture(Texture.ID.UVS);
        this.earthTex    = new Texture(Texture.ID.EARTH);
    }
    void createScene() {

        addlargeRoomUsingRectangles();

        mat4 rotY = mat4.rotateY((-45).degrees);
        mat4 rotZ = mat4.rotateZ((-60).degrees);

        mat4 Y45 = mat4.rotateX((45).degrees);
        mat4 Y90 = mat4.rotateX((90).degrees);

        auto Ym45 = mat4.rotateX((-45).degrees);

        mat4 rotXY  = rotY * Y90;
        mat4 rotXYZ = rotZ * rotY * Y45;

        mat4 brickTrans = Ym45 * rotY;
        mat4 earthTrans = mat4.rotateY((-90).degrees);

        auto glass = new Material().setRefraction(1.52);
        auto red   = new Material().setDiffuse(float3(1,1,1))
                                   .setTexture(brickTex);
        auto green = new Material().setDiffuse(float3(0,1,0));
        auto blue = new Material().setDiffuse(float3(0,0,1));
        auto white = new Material().setDiffuse(float3(1,1,1));
                                //.setTexture(uvsTex);

        with(BoxBuilder.Side) {
            shapes ~= new BoxBuilder()
                .setUVScale(float2(0.25, 0.25))
                .sides(red, BACK, FRONT)
                .sides(green, TOP, BOTTOM)
                .sides(blue, LEFT, RIGHT)
                .scale(float3(16,16,16))
                .translate(float3(8,  12.2, 88))
                .rotate(0.degrees, 45.radians, 45.radians)
                .build();
            shapes ~= new BoxBuilder()
                .sides(glass, BACK, FRONT, TOP, BOTTOM, LEFT, RIGHT)
                .scale(float3(16,16,16))
                .translate(float3(38, 12.2, 88))
                .rotate(0.degrees, 15.degrees, 0.degrees)
                .build();
            shapes ~= new BoxBuilder()
                .sides(white, BACK, FRONT, BOTTOM, LEFT, RIGHT)
                .scale(float3(16,16,16))
                .translate(float3(98, 15, 95))
                .rotate(50.degrees, 35.degrees, 25.degrees)
                .build();
        }

        shapes ~= new Sphere(8, float3(98,15,95), new Material().setDiffuse(float3(1.0, 0.8, 0)));

        // auto p0 = float3(40, 80, 80);
        // auto p1 = float3(100, 80, 80);
        // auto p2 = float3(40, 40, 80);
        // auto p3 = float3(100, 40, 80);
        // shapes ~= [
        //     new Triangle(p0, p1, p2, white),
        //     new Triangle(p3, p2, p1, white).swapUVs()
        // ];


        shapes ~= [
        //         radius,  position,           material

        // bottom
        new Sphere(18,      float3(-5,22,60),   new Material().setDiffuse(float3(1.0, 1.0, 1.0))
                                                        .setTexture(rock8Tex)),
        new Sphere(18,      float3(31,22,60),   new Material().setDiffuse(float3(1.0, 1.0, 1.0))
                                                        .setTexture(earthTex))
                                                        .transform(earthTrans),

        new Sphere(18,      float3(67,22,60),  glass),

        new Sphere(18,      float3(103,22,60),  new Material().setDiffuse(float3(1.0, 1.0, 1.0))
                                                        .setTexture(redWhiteTex)
                                                        .setReflection(0.5))
                                                        .transform(rotXYZ),


        // top
        new Sphere(18,      float3(-5,58,60),   new Material().setDiffuse(float3(1.0, 1.0, 1.0))
                                                        .setTexture(brickTex))
                                                        .transform(brickTrans),
        new Sphere(18,      float3(31,58,60),   new Material().setReflection(1)),

        new Sphere(18,      float3(67,58,60),   new Material().setDiffuse(float3(1.0, 1.0, 1.0))
                                                        .setTexture(marbleTex))
                                                        .transform(rotXY),

        new Sphere(18,      float3(103,58,60),   new Material().setDiffuse(float3(1.0, 1.0, 1.0))
                                                        .setTexture(uvsTex))
                                                        .transform(rotXY),


        // inside glass
        new Sphere(5,       float3(67,22,60),  new Material().setDiffuse(float3(1, 1, 1))
                                                        .setTexture(uvsTex))
                                                        .transform(rotXYZ),

        // light
        new Sphere(600,	    float3(50,681.6-.27,81.6),	LIGHT)
        ];
    }
}