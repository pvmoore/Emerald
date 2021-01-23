module emerald.scenes.scene;

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
abstract class Scene {
protected:
    Camera camera;
    Shape[] shapes;
    Shape bvh;

    Material GLASS;
    Material MIRROR;
    Material LIGHT;
    Material red;
    Material green;
    Material blue;
    Material dullwhite;
    Material black;
public:
    final Camera getCamera() { return camera; }
    final Shape getBVH() { return bvh; }
    final Shape[] getShapes() { return shapes; }

	this(Camera camera) {
        this.camera = camera;
        this.GLASS = new Material().setRefraction(1.5);
        this.MIRROR = new Material().setReflection(1);
        this.LIGHT = new Material().setEmission(float3(12,12,12));
        this.red = new Material().setDiffuse(float3(.75,.25,.25));
        this.green = new Material().setDiffuse(float3(.25,.75,.25));
        this.blue = new Material().setDiffuse(float3(.25,.25,.75));
        this.dullwhite = new Material().setDiffuse(float3(.75,.75,.75));
        this.black = new Material().setDiffuse(float3(0,0,0));
	}
    final Scene initialise() {
        this.bvh = BVH.build(shapes);
        log("BVH = \n%s", bvh.dump(""));
        if(bvh.isA!BVH) {
            log("BVH max depth = %s", bvh.as!BVH.getMaxDepth());
        }
        return this;
    }
protected:
    final void addlargeRoomUsingRectangles() {


        // left
        shapes ~= new RectangleBuilder(red)
            .rotate(0.degrees, 0.degrees, 90.degrees)
            .scale(float3(300,300,300))
            .translate(float3(-30,0,0))
            .build();
        // right
        shapes ~= new RectangleBuilder(blue)
            .rotate(0.degrees, 0.degrees, 90.degrees)
            .scale(float3(300,300,300))
            .translate(float3(130,0,0))
            .build();

        // floor
        shapes ~= new RectangleBuilder(dullwhite)
            .rotate(0.degrees, 0.degrees, 0.degrees)
            .scale(float3(500,500,500))
            .translate(float3(0,0,0))
            .build();
        // ceiling
        shapes ~= new RectangleBuilder(dullwhite)
            .rotate(0.degrees, 0.degrees, 0.degrees)
            .scale(float3(500,500,500))
            .translate(float3(0,81.6,0))
            .build();

        // back
        shapes ~= new RectangleBuilder(green)
            .rotate(90.degrees, 0.degrees, 0.degrees)
            .scale(float3(500,500,500))
            .translate(float3(0,0,-7))
            .build();
        // front (behind camera)
        shapes ~= new RectangleBuilder(black)
            .rotate(90.degrees, 0.degrees, 0.degrees)
            .scale(float3(500,500,500))
            .translate(float3(0,0,170))
            .build();
    }

    final void addlargeRoomUsingSpheres() {
        shapes ~= [
        //         radius,  position,                   material
        new Sphere(1e4,		float3(1e4-30,40.8,81.6),	red),//Left
        new Sphere(1e4,		float3(-1e4+129,40.8,81.6), blue),//Rght
        new Sphere(1e4,		float3(50,40.8, 1e4),		green),//Back
        new Sphere(1e4,		float3(50,40.8,-1e4+170),	black),//Frnt
        new Sphere(1e4,		float3(50, 1e4, 81.6),		dullwhite),//Botm
        new Sphere(1e4,		float3(50,-1e4+81.6,81.6),	dullwhite)//Top
        ];
    }
    // void addBox(float3 p0, float3 dim, Material mat) {
    //     with(Box.Side)
    //     shapes ~= new Box()
    //         .sides(mat, TOP, BOTTOM, BACK, FRONT, LEFT, RIGHT)
    //         .scale(dim)
    //         .translate(p0)
    //         .rotate((-0).degrees, 0.radians, 0.radians)
    //         .build();
    // }
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