module emerald.model.camera;

import emerald.all;

final class Camera {
public:
    float3 position;
    float3 direction;   // normalised
    uint width;
    uint height;
    float oneDivWidth, oneDivHeight;
    float3 cx;
    float3 cy;

    this(float3 position, float3 direction, uint width, uint height) {
        this.position     = position;
        this.direction    = direction.normalised();
        this.width        = width;
        this.height       = height;
        this.oneDivWidth  = 1.0 / width;
        this.oneDivHeight = 1.0 / height;
        this.cx           = float3(width*0.5135/height, 0, 0);
        this.cy           = (cx.cross(this.direction)).normalised()*0.5135;
    }

    Ray makeRay(int x, int y, int sx, int sy) {
        float dx = tentFilter.next();
        float dy = tentFilter.next();

        float3 d = direction;
        d += cx*( ( (sx-0.5 + dx)*0.5 + x)*oneDivWidth  - 0.5) +
             cy*( ( (sy-0.5 + dy)*0.5 + y)*oneDivHeight - 0.5);

        d.normalise();

        // Camera rays are pushed forward 140 to start in interior
        return Ray(position+d*140, d);
    }
}