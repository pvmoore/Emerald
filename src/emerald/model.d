module emerald.model;

import emerald.all;

final class Model {
public:
	Sphere!Material[] spheres;
	
	this() {
		//cornellBox();
		//scene2();
		//scene3();
		roughnessScene();
	}
private:
    void addlargeRoom() {
        spheres ~= [
        //         radius,  position,               material
        new Sphere!Material(1e4,		Vec(1e4-30,40.8,81.6),	Material.diffuse(Vec(.75,.25,.25))),//Left
        new Sphere!Material(1e4,		Vec(-1e4+129,40.8,81.6),Material.diffuse(Vec(.25,.25,.75))),//Rght
        new Sphere!Material(1e4,		Vec(50,40.8, 1e4),		Material.diffuse(Vec(.25,.75,.25))),//Back
        new Sphere!Material(1e4,		Vec(50,40.8,-1e4+170),	Material.diffuse(Vec(0,0,0))),//Frnt
        new Sphere!Material(1e4,		Vec(50, 1e4, 81.6),		Material.diffuse(Vec(.75,.75,.75))),//Botm
        new Sphere!Material(1e4,		Vec(50,-1e4+81.6,81.6),	Material.diffuse(Vec(.75,.75,.75)))//Top
        ];
    }
    void cornellBox() {
        spheres ~= [
        //         radius,	position,				material
        new Sphere!Material(1e4,		Vec(1e4+1,40.8,81.6),   Material.diffuse(Vec(.75,.25,.25))),//Left
        new Sphere!Material(1e4,		Vec(-1e4+99,40.8,81.6),	Material.diffuse(Vec(.25,.25,.75))),//Rght
        new Sphere!Material(1e4,		Vec(50,40.8, 1e4),		Material.diffuse(Vec(.25,.75,.25))),//Back
        new Sphere!Material(1e4,		Vec(50,40.8,-1e4+170),	Material.diffuse(Vec(0,0,0))),//Frnt
        new Sphere!Material(1e4,		Vec(50, 1e4, 81.6),		Material.diffuse(Vec(.75,.75,.75))),//Botm
        new Sphere!Material(1e4,		Vec(50,-1e4+81.6,81.6),	Material.diffuse(Vec(.75,.75,.75))),//Top

        new Sphere!Material(16.5,	Vec(27,16.5,47),		MIRROR),
        new Sphere!Material(16.5,	Vec(73,16.5,78),		GLASS),

        new Sphere!Material(600,		Vec(50,681.6-.27,81.6),	LIGHT)
        ];
    }
    void scene2() {
        addlargeRoom();
        spheres ~= [
        //         radius,  position,               material
        // mirror balls
        new Sphere!Material(16.5,	Vec(27,16.5,47),		MIRROR),
        new Sphere!Material(16.5,	Vec(73,16.5,47),		MIRROR),
        new Sphere!Material(16.5,	Vec(27,60,47),		    Material.mirror(1).c(Vec(1,0.5,0.5))),
        new Sphere!Material(16.5,	Vec(73,60,47),		    Material.mirror(1).c(Vec(1,0.5,1))),

        // glass ball combo (left)
        new Sphere!Material(15,	    Vec(0,40,80),		    GLASS),
        new Sphere!Material(6,	    Vec(0,40,80),		    new Material().c(Vec(1,0,0)).refl(1)),

        // glass ball combo (right)
        new Sphere!Material(15,	    Vec(100,40,80),		    GLASS),
        new Sphere!Material(6,	    Vec(100,40,80),		    Material.diffuse(Vec(0,0,1))),

        // brass diffuse ball
        new Sphere!Material(10,		Vec(17,10,80),			Material.diffuse(Vec(0.30, 0.20, 0.10))),


        // specular diffuse
        new Sphere!Material(10,		Vec(50,40,80),			Material.diffuse(Vec(1,0.7,0.2)).refl(0.1)),


        // glass ball
        new Sphere!Material(10,	    Vec(83,10,80),		    GLASS),

        // shiny yellow mirror ball in centre
        new Sphere!Material(10,	    Vec(50,10,80),		    Material.mirror(1).c(Vec(1,0.7,0.2))),

        // small green glass ball
        // with blue emission
        new Sphere!Material(5,	    Vec(-15,5,80),		    Material.refract(1.5).c(Vec(0,1,0)).e(Vec(0,0,0.05))),

        // small blue mirror ball
        // with red emission
        new Sphere!Material(5,	    Vec(-15,5,50),		    Material.mirror(1).c(Vec(0,0,1)).e(Vec(0.05,0,0))),

        // small red ball
        // with green emission
        new Sphere!Material(5,	    Vec(-15,5,20),		    Material.diffuse(Vec(1,0,0)).e(Vec(0,0.05,0))),

        // Top light
        new Sphere!Material(600,		Vec(50,681.6-.27,81.6),	LIGHT)
        ];
    }
    void scene3() {
        addlargeRoom();
        spheres ~= [
        //         radius,  position,               material
        // specular diffuse
        new Sphere!Material(8,		Vec(-10,10,50),			Material.diffuse(Vec(1,0.7,0.2))),
        new Sphere!Material(8,		Vec(10,10,50),			Material.diffuse(Vec(1,0.7,0.2)).refl(0.03)),
        new Sphere!Material(8,		Vec(30,10,50),			Material.diffuse(Vec(1,0.7,0.2)).refl(0.2)),
        new Sphere!Material(8,		Vec(50,10,50),			Material.diffuse(Vec(1,0.7,0.2)).refl(0.6)),
        new Sphere!Material(8,		Vec(70,10,50),			Material.diffuse(Vec(1,0.7,0.2)).refl(1.2)),
        new Sphere!Material(8,		Vec(90,10,50),			Material.diffuse(Vec(1,0.7,0.2)).refl(3)),
        new Sphere!Material(8,		Vec(110,10,50),			Material.diffuse(Vec(1,0.7,0.2)).refl(8)),

        // refractive indexes
        new Sphere!Material(8,		Vec(-10,30,50),			Material.refract(1.333)),
        new Sphere!Material(8,		Vec(10,30,50),			Material.refract(1.52)),
        new Sphere!Material(8,		Vec(30,30,50),			Material.refract(1.77)),
        new Sphere!Material(8,		Vec(50,30,50),			Material.refract(2.419)),

        // diffuse yellow glass
        new Sphere!Material(8,		Vec(-10,50,50),			Material.diffuse(Vec(1,0.7,0.2),0.25).refr(1.5)),


        // Top light
        new Sphere!Material(600,		Vec(50,681.6-.27,81.6),	LIGHT)
        ];
    }
    void roughnessScene() {
        addlargeRoom();
        spheres ~= [
        //         radius,  position,               material
        new Sphere!Material(10,		Vec( 0,10,45),			Material.diffuse(Vec(1,0.8,0.3))),
        new Sphere!Material(10,		Vec(25,10,40),			Material.diffuse(Vec(1,0.8,0.3)).rough(0.2)),
        new Sphere!Material(10,		Vec(50,10,40),			Material.diffuse(Vec(1,0.8,0.3)).rough(0.5)),
        new Sphere!Material(10,		Vec(75,10,40),			Material.diffuse(Vec(1,0.8,0.3)).rough(0.75)),
        new Sphere!Material(10,		Vec(100,10,40),			Material.diffuse(Vec(1,0.8,0.3)).rough(1)),

        new Sphere!Material(10,		Vec( 0,30,40),			Material.diffuse(Vec(1,0.8,0.3)).refl(1)),
        new Sphere!Material(10,		Vec(25,30,40),			Material.diffuse(Vec(1,0.8,0.3)).refl(1).rough(0.2)),
        new Sphere!Material(10,		Vec(50,30,40),			Material.diffuse(Vec(1,0.8,0.3)).refl(1).rough(0.5)),
        new Sphere!Material(10,		Vec(75,30,40),			Material.diffuse(Vec(1,0.8,0.3)).refl(1).rough(0.75)),
        new Sphere!Material(10,		Vec(100,30,40),			Material.diffuse(Vec(1,0.8,0.3)).refl(1).rough(1)),

        new Sphere!Material(10,		Vec( 2,50,40),			Material.mirror(1)),
        new Sphere!Material(10,		Vec(25,50,40),			Material.mirror(1).rough(0.2)),
        new Sphere!Material(10,		Vec(50,50,40),			Material.mirror(1).rough(0.5)),
        new Sphere!Material(10,		Vec(75,50,40),			Material.mirror(1).rough(0.75)),
        new Sphere!Material(10,		Vec(100,50,40),			Material.mirror(1).rough(1)),

        new Sphere!Material(10,		Vec( 2,70,40),			Material.refract(1.5)),
        new Sphere!Material(10,		Vec(25,70,40),			Material.refract(1.5).rough(0.2)),
        new Sphere!Material(10,		Vec(50,70,40),			Material.refract(1.5).rough(0.5)),
        new Sphere!Material(10,		Vec(75,70,40),			Material.refract(1.5).rough(0.75)),
        new Sphere!Material(10,		Vec(100,70,40),			Material.refract(1.5).rough(1)),


        new Sphere!Material(600,		Vec(50,681.6-.27,81.6),	LIGHT)
        ];
    }
}