module emerald.emerald;

import emerald.all;

abstract class Emerald {
protected:
    Scene scene;
    AbstractPathTracer pathTracer;
    Photographer photographer;
public:
    enum WIDTH 	= 1024;
    enum HEIGHT = 800;

    void initialise() {
        this.scene        = createScene();
        //this.pathTracer    = new RecursivePathTracer(scene, WIDTH, HEIGHT);
        this.pathTracer    = new LoopPathTracer(scene, WIDTH, HEIGHT);
        this.photographer = new Photographer(pathTracer, WIDTH, HEIGHT);
    }
    void destroy() {
        this.log("Destroying...");

        if(pathTracer) pathTracer.destroy();
    }

    abstract void run();

protected:
    Scene createScene() {
        enum S = -5;

        if(S == 0) {
            return new CornellBox(WIDTH, HEIGHT).initialise();
        } else if(S==1) {
            return new OneSphere(WIDTH, HEIGHT).initialise();
        } else if(S==2) {
            return new Scene2(WIDTH, HEIGHT).initialise();
        } else if(S==3) {
            return new Scene3(WIDTH, HEIGHT).initialise();
        } else if(S==4) {
            return new Scene4(WIDTH, HEIGHT).initialise();
        } else if(S==5) {
            return new SuzanneScene(WIDTH, HEIGHT).initialise();
        } else if(S==6) {
            return new RefractionScene(WIDTH, HEIGHT).initialise();
        } else {
            return new ManySpheres(WIDTH, HEIGHT).initialise();
        }
    }
}

