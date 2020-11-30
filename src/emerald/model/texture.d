module emerald.model.texture;

import emerald.all;

final class Texture {
private:
    string filename;
    float3[] data;
    uint width, height;
public:
    this(string filename) {
        this.filename = filename;
        this.readImage(filename);
    }
    /**
     * top-left to bottom-right, 0.0 -> 1.0
     */
    float3 sample(float2 uv) {
        // Restrict to 0.0 to 1.0 range
        uv.fract();

        auto x = (uv.x * width).as!int;
        auto y = (uv.y * height).as!int;

        return data[x + y*width];
    }
private:
    void readImage(string filename) {
        auto img = Image.read(filename);
        data.length = img.width*img.height;
        this.width = img.width;
        this.height = img.height;

        enum _1_div_255 = 1.0 / 255.0;

        for(auto i=0; i<data.length; i++) {

            auto n = i*img.bytesPerPixel;

            data[i] = float3(
                _1_div_255*img.data[n],
                _1_div_255*img.data[n+1],
                _1_div_255*img.data[n+2]
            );
        }
    }
}

