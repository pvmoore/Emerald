module emerald.util.random;

import emerald.all;
import std.random : uniform, Random, unpredictableSeed;

__gshared Random rng;
__gshared MyRandom myRandom;
__gshared TentFilter tentFilter;
__gshared RandomNoise3D noise;

__gshared FastRNG fast;

shared static this() {
    rng = Random(unpredictableSeed);
    myRandom   = new MyRandom(50_000);
    tentFilter = new TentFilter(50_000);
    noise      = new RandomNoise3D(1_000);
    fast = new FastRNG();
}

pragma(inline,true)
float getRandom() {
    return myRandom.next();
    //return fast.next();
}

final class MyRandom {
private:
    float[] values;
    uint index;
public:
    this(uint numValues) {
        this.values.length = numValues;
        foreach(ref v; values) {
            v = uniform(0f, 1f, rng);
        }
        this.index = uniform(0, cast(uint)values.length);
    }
    // may be called from different threads
    float next() {
        uint i = index++;
        if(i>=values.length) {
            index = 0;
            i = 0;
        }
        return values[i];
    }
}

/*
final class NoiseFunction {
    float[] values;
    this(uint numValues) {
        this.values.length = numValues;
        foreach(ref v; values) {
            v = uniform(0f, 2f, rng);
        }
    }
    float get(Vec v) {
        uint x = cast(uint)(v.x*10);
        uint y = cast(uint)(v.y*10);
        uint z = cast(uint)(v.z*10);
        //uint hash = x^y^z;
        uint hash = 17;
        hash ^= 31 + x;
        hash *= 31 + y;
        hash ^= 31 + z;
        return values[hash%values.length];
    }
}*/
