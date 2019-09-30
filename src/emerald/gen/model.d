module emerald.gen.model;

import emerald.all;

final class Model {
public:
    enum GREEN = float3(0,1,0);

	Shape[] shapes;
    Shape bvh;

	this() {
		//cornellBox();
		//scene2();
		//scene3();
		roughnessScene();
        //oneSphere();

        this.bvh = BVH.build(shapes);
        log("bvh = \n%s", bvh.dump(""));
	}
private:
    void oneSphere() {
        addlargeRoom();
        shapes ~= [
        //         radius,  position,                   material
        new Sphere(40,      float3(50,40,40),           Material.diffuse(float3(1,0.8,0.3)).speckle(GREEN, 1)),

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
    void roughnessScene() {
        addlargeRoom();
        shapes ~= [
        //                  radius,  position,                  material
        new Sphere(10,		float3( 0,10,45),			Material.diffuse(float3(1,0.8,0.3))),
        new Sphere(10,		float3(25,10,40),			Material.diffuse(float3(1,0.8,0.3)).speckle(GREEN, 0.2)),
        new Sphere(10,		float3(50,10,40),			Material.diffuse(float3(1,0.8,0.3)).speckle(GREEN, 0.5)),
        new Sphere(10,		float3(75,10,40),			Material.diffuse(float3(1,0.8,0.3)).speckle(GREEN, 0.75)),
        new Sphere(10,		float3(100,10,40),			Material.diffuse(float3(1,0.8,0.3)).speckle(GREEN, 1)),

        new Sphere(10,		float3( 0,30,40),			Material.diffuse(float3(1,0.8,0.3)).refl(1)),
        new Sphere(10,		float3(25,30,40),			Material.diffuse(float3(1,0.8,0.3)).refl(1).speckle(GREEN, 0.2)),
        new Sphere(10,		float3(50,30,40),			Material.diffuse(float3(1,0.8,0.3)).refl(1).speckle(GREEN, 0.5)),
        new Sphere(10,		float3(75,30,40),			Material.diffuse(float3(1,0.8,0.3)).refl(1).speckle(GREEN, 0.75)),
        new Sphere(10,		float3(100,30,40),			Material.diffuse(float3(1,0.8,0.3)).refl(1).speckle(GREEN, 1)),

        new Sphere(10,		float3( 2,50,40),			Material.mirror(1)),
        new Sphere(10,		float3(25,50,40),			Material.mirror(1).speckle(GREEN, 0.2)),
        new Sphere(10,		float3(50,50,40),			Material.mirror(1).speckle(GREEN, 0.5)),
        new Sphere(10,		float3(75,50,40),			Material.mirror(1).speckle(GREEN, 0.75)),
        new Sphere(10,		float3(100,50,40),			Material.mirror(1).speckle(GREEN, 1)),

        new Sphere(10,		float3( 2,70,40),			Material.refract(1.5)),
        new Sphere(10,		float3(25,70,40),			Material.refract(1.5).speckle(GREEN, 0.2)),
        new Sphere(10,		float3(50,70,40),			Material.refract(1.5).speckle(GREEN, 0.5)),
        new Sphere(10,		float3(75,70,40),			Material.refract(1.5).speckle(GREEN, 0.75)),
        new Sphere(10,		float3(100,70,40),			Material.refract(1.5).speckle(GREEN, 1)),


        new Sphere(600,	float3(50,681.6-.27,81.6),	LIGHT)
        ];
    }
}