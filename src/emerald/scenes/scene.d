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
public:
    final Camera getCamera() { return camera; }
    final Shape getBVH() { return bvh; }
    final Shape[] getShapes() { return shapes; }

	this(Camera camera) {
        this.camera = camera;
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
        shapes ~= new RectangleBuilder(Material.diffuse(float3(.75,.25,.25)))
            .rotate(0.degrees, 0.degrees, 90.degrees)
            .scale(float3(300,300,300))
            .translate(float3(-30,0,0))
            .build();
        // right
        shapes ~= new RectangleBuilder(Material.diffuse(float3(.25,.25,.75)))
            .rotate(0.degrees, 0.degrees, 90.degrees)
            .scale(float3(300,300,300))
            .translate(float3(130,0,0))
            .build();

        // floor
        shapes ~= new RectangleBuilder(Material.diffuse(float3(.75,.75,.75)))
            .rotate(0.degrees, 0.degrees, 0.degrees)
            .scale(float3(500,500,500))
            .translate(float3(0,0,0))
            .build();
        // ceiling
        shapes ~= new RectangleBuilder(Material.diffuse(float3(.75,.75,.75)))
            .rotate(0.degrees, 0.degrees, 0.degrees)
            .scale(float3(500,500,500))
            .translate(float3(0,81.6,0))
            .build();

        // back
        shapes ~= new RectangleBuilder(Material.diffuse(float3(.25,.75,.25)))
            .rotate(90.degrees, 0.degrees, 0.degrees)
            .scale(float3(500,500,500))
            .translate(float3(0,0,-7))
            .build();
        // front (behind camera)
        shapes ~= new RectangleBuilder(Material.diffuse(float3(0,0,0)))
            .rotate(90.degrees, 0.degrees, 0.degrees)
            .scale(float3(500,500,500))
            .translate(float3(0,0,170))
            .build();
    }

    final void addlargeRoomUsingSpheres() {
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