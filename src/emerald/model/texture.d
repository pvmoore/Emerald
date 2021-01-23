module emerald.model.texture;

import emerald.all;

final class Texture {
private:
    enum prefix = "resources/images/";
    float3[] data;
    uint width, height;
    struct _ID { uint id; string name; }
    _ID id;
public:
    enum ID {
        UVS      = _ID(0, "uvs.png"),
        BRICK    = _ID(1, "brick.png"),
        REDWHITE = _ID(2, "red_white.png"),
        EARTH    = _ID(3, "earth.png"),
        ROCK     = _ID(4, "rock.png"),
        MARBLE   = _ID(5, "marble.png")
    }
    uint getIndex() {
        return id.id;
    }

    this(ID id) {
        this.id = id;
        this.readImage(prefix ~ id.name);
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

