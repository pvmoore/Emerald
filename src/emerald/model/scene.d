module emerald.model.scene;

import emerald.all;

/**
 *  +y
 *   |
 *   |
 *   |
 *   ------> +x
 *
 *  z increases pointing out of the screen
 */
final class Scene {
public:
    enum GREEN = float3(0,1,0);

    Camera camera;
	Shape[] shapes;
    Shape bvh;

    Texture marbleTex;
    Texture brickTex;
    Texture rock4Tex;
    Texture rock8Tex;
    Texture redWhiteTex;
    Texture uvsTex;
    Texture earthTex;
    Texture floorTex;
    Texture wood2Tex;

	this(uint width, uint height) {

        this.camera = new Camera(
            float3(50,52,295.6),        // origin
            float3(0,-0.042612, -1),    // direction
            width,
            height
        );

        this.marbleTex   = new Texture("C:/pvmoore/_assets/images/png/marble.png");
        this.brickTex    = new Texture("C:/pvmoore/_assets/images/png/brick.png");
        this.rock4Tex    = new Texture("C:/pvmoore/_assets/images/png/rock4.png");
        this.rock8Tex    = new Texture("C:/pvmoore/_assets/images/png/rock8.png");
        this.redWhiteTex = new Texture("C:/pvmoore/_assets/images/png/red_white.png");
        this.uvsTex      = new Texture("C:/pvmoore/_assets/images/png/uvs.png");
        this.earthTex    = new Texture("C:/pvmoore/_assets/images/png/earth.png");
        this.floorTex    = new Texture("C:/pvmoore/_assets/images/png/floor.png");
        this.wood2Tex    = new Texture("C:/pvmoore/_assets/images/seamless/wood2.png");

		//cornellBox();
		//scene2();
		//scene3();
		//manyBallScene();
        //oneSphere();
        manySpheres();

        this.bvh = BVH.build(shapes);
        log("bvh = \n%s", bvh.dump(""));
	}

private:
    void oneSphere() {

        mat4 rotY = mat4.rotateY((-45).degrees);
        mat4 rotX = mat4.rotateX((45).degrees);

        mat4 rotXY = rotY * rotX;

        addlargeRoom();
        shapes ~= [
        //         radius,  position,                   material
        new Sphere(40,      float3(50,40,40),           Material.diffuse(float3(1.0, 1.0, 1.0))
                                                                .tex(floorTex))
                                                                .transform(rotXY),

        new Sphere(600,	    float3(50,681.6-.27,81.6),	LIGHT)
        ];
    }
    void manySpheres() {

        addlargeRoom();

        mat4 rotY = mat4.rotateY((-45).degrees);
        mat4 rotZ = mat4.rotateZ((-60).degrees);

        mat4 Y45 = mat4.rotateX((45).degrees);
        mat4 Y90 = mat4.rotateX((90).degrees);

        auto Ym45 = mat4.rotateX((-45).degrees);

        mat4 rotXY  = rotY * Y90;
        mat4 rotXYZ = rotZ * rotY * Y45;

        mat4 brickTrans = Ym45 * rotY;
        mat4 earthTrans = mat4.rotateY((-90).degrees);

        auto glass = Material.refract(1.333);
        auto red   = Material.diffuse(float3(1,1,1)).tex(brickTex);
        auto green = Material.diffuse(float3(0,1,0));
        auto blue = Material.diffuse(float3(0,0,1));
        auto white = Material.diffuse(float3(1,1,1));//.tex(uvsTex);

        //addBox(float3(8,  12.2, 88), float3(16,16,16), red);
        with(Box.Side) {
            shapes ~= new Box()
                .setUVScale(float2(0.25, 0.25))
                .sides(red, BACK, FRONT)
                .sides(green, TOP, BOTTOM)
                .sides(blue, LEFT, RIGHT)
                .scale(float3(16,16,16))
                .translate(float3(8,  12.2, 88))
                .rotate(0.degrees, 45.radians, 45.radians)
                .build();
            shapes ~= new Box()
                .sides(glass, BACK, FRONT, TOP, BOTTOM, LEFT, RIGHT)
                .scale(float3(16,16,16))
                .translate(float3(38, 12.2, 88))
                .rotate(0.degrees, 15.degrees, 0.degrees)
                .build();
            shapes ~= new Box()
                .sides(white, BACK, FRONT, BOTTOM, LEFT, RIGHT)
                .scale(float3(16,16,16))
                .translate(float3(98, 15, 95))
                .rotate(50.degrees, 35.degrees, 25.degrees)
                .build();
        }

        shapes ~= new Sphere(8, float3(98,15,95), Material.diffuse(float3(1.0, 0.8, 0)));

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
        new Sphere(18,      float3(-5,22,60),   Material.diffuse(float3(1.0, 1.0, 1.0))
                                                        .tex(rock8Tex)),
        new Sphere(18,      float3(31,22,60),   Material.diffuse(float3(1.0, 1.0, 1.0))
                                                        .tex(earthTex)).transform(earthTrans),

        new Sphere(18,      float3(67,22,60),  glass),

        new Sphere(18,      float3(103,22,60),  Material.diffuse(float3(1.0, 1.0, 1.0))
                                                        .tex(redWhiteTex)
                                                        .refl(1))
                                                        .transform(rotXYZ),


        // top
        new Sphere(18,      float3(-5,58,60),   Material.diffuse(float3(1.0, 1.0, 1.0))
                                                        .tex(brickTex)).transform(brickTrans),
        new Sphere(18,      float3(31,58,60),   Material.mirror(1)),

        new Sphere(18,      float3(67,58,60),   Material.diffuse(float3(1.0, 1.0, 1.0))
                                                        .tex(marbleTex)).transform(rotXY),

        new Sphere(18,      float3(103,58,60),   Material.diffuse(float3(1.0, 1.0, 1.0))
                                                        .tex(uvsTex)).transform(rotXY),


        // inside glass
        new Sphere(5,       float3(67,22,60),  Material.diffuse(float3(1, 1, 1))
                                                        .tex(uvsTex)).transform(rotXYZ),

        // light
        new Sphere(600,	    float3(50,681.6-.27,81.6),	LIGHT)
        ];
    }
    void addlargeRoom() {
        shapes ~= [
        //         radius,  position,                   material
        new Sphere(1e4,		float3(1e4-30,40.8,81.6),	Material.diffuse(float3(.75,.25,.25))),//Left
        new Sphere(1e4,		float3(-1e4+129,40.8,81.6), Material.diffuse(float3(.25,.25,.75))),//Rght
        new Sphere(1e4,		float3(50,40.8, 1e4),		Material.diffuse(float3(.25,.75,.25))),//Back
        new Sphere(1e4,		float3(50,40.8,-1e4+170),	Material.diffuse(float3(0,0,0))),//Frnt
        new Sphere(1e4,		float3(50, 1e4, 81.6),		Material.diffuse(float3(.75,.75,.75))),//Botm
        new Sphere(1e4,		float3(50,-1e4+81.6,81.6),	Material.diffuse(float3(.75,.75,.75)))//Top
        ];
    }
    void cornellBox() {
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
    void scene2() {
        addlargeRoom();
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
    void scene3() {
        addlargeRoom();
        shapes ~= [
        //         radius,  position,                   material
        // specular diffuse
        new Sphere(8,		float3(-10,10,50),			Material.diffuse(float3(1,0.7,0.2))),
        new Sphere(8,		float3(10,10,50),			Material.diffuse(float3(1,0.7,0.2)).refl(0.03)),
        new Sphere(8,		float3(30,10,50),			Material.diffuse(float3(1,0.7,0.2)).refl(0.2)),
        new Sphere(8,		float3(50,10,50),			Material.diffuse(float3(1,0.7,0.2)).refl(0.6)),
        new Sphere(8,		float3(70,10,50),			Material.diffuse(float3(1,0.7,0.2)).refl(1.2)),
        new Sphere(8,		float3(90,10,50),			Material.diffuse(float3(1,0.7,0.2)).refl(3)),
        new Sphere(8,		float3(110,10,50),			Material.diffuse(float3(1,0.7,0.2)).refl(8)),

        // refractive indexes
        new Sphere(8,		float3(-10,30,50),			Material.refract(1.333)),
        new Sphere(8,		float3(10,30,50),			Material.refract(1.52)),
        new Sphere(8,		float3(30,30,50),			Material.refract(1.77)),
        new Sphere(8,		float3(50,30,50),			Material.refract(2.419)),

        // diffuse yellow glass
        new Sphere(8,		float3(-10,50,50),			Material.diffuse(float3(1,0.7,0.2),0.25).refr(1.5)),


        // Top light
        new Sphere(600,	float3(50,681.6-.27,81.6),	LIGHT)
        ];
    }
    void manyBallScene() {
        addlargeRoom();
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
    void addBox(float3 p0, float3 dim, Material mat) {
        with(Box.Side)
        shapes ~= new Box()
            .sides(mat, TOP, BOTTOM, BACK, FRONT, LEFT, RIGHT)
            .scale(dim)
            .translate(p0)
            .rotate((-0).degrees, 0.radians, 0.radians)
            .build();
    }
    // void addOpenBox(float3 p0, float3 dim, Material mat) {
    //     shapes ~= new Box()
    //         .side(Box.Side.BOTTOM, mat)
    //         .side(Box.Side.FRONT, mat)
    //         .side(Box.Side.BACK, mat)
    //         .side(Box.Side.LEFT, mat)
    //         .side(Box.Side.RIGHT, mat)
    //         .scale(dim)
    //         .translate(p0)
    //         .build();
    // }
}