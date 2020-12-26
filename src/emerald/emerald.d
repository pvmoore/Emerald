module emerald.emerald;

import emerald.all;

abstract class Emerald {
protected:
    Scene scene;
    AbstractRayTracer rayTracer;
    Photographer photographer;
public:
    enum WIDTH 	= 1000;
    enum HEIGHT = 700;

    void initialise() {
        this.scene        = createScene();
        //this.rayTracer    = new RecursiveRayTracer(scene, WIDTH, HEIGHT);
        this.rayTracer    = new LoopRayTracer(scene, WIDTH, HEIGHT);
        this.photographer = new Photographer(rayTracer, WIDTH, HEIGHT);
    }
    void destroy() {
        this.log("Destroying...");

        if(rayTracer) rayTracer.destroy();
    }

    abstract void run();

private:
    Scene createScene() {
        enum S = 5;

        static if(S == 0) {
            return new CornellBox(WIDTH, HEIGHT).initialise();
        } else static if(S==1) {
            return new OneSphere(WIDTH, HEIGHT).initialise();
        } else static if(S==2) {
            return new Scene2(WIDTH, HEIGHT).initialise();
        } else static if(S==3) {
            return new Scene3(WIDTH, HEIGHT).initialise();
        } else static if(S==4) {
            return new Scene4(WIDTH, HEIGHT).initialise();
        } else static if(S==5) {
            return new SuzanneScene(WIDTH, HEIGHT).initialise();
        } else static if(S==6) {
            return new RefractionScene(WIDTH, HEIGHT).initialise();
        } else {
            return new ManySpheres(WIDTH, HEIGHT).initialise();
        }
    }
    void update() {

    }
}

