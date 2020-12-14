module emerald.util.random;

import emerald.all;
import std.random : unpredictableSeed, Mt19937, uniform;

/* This one is shared otherwise banding artifacts appear. I haven't worked out why ?? */
__gshared RandomNumbers randomNumbers;

/* All of these are thread local */
TentFilter tentFilter;
RandomNoise3D noise;
ImprovedPerlin perlin;

static this() {
    tentFilter   = new TentFilter(65536);
    noise        = new RandomNoise3D(1024);
    perlin       = new ImprovedPerlin(50);  // every thread has the same seed
}
__gshared static this() {
    randomNumbers = new RandomNumbers(65536);
}

Random getRandom() {
    return randomNumbers.next();
}
float getRandomFloat() {
    return randomNumbers.nextFloat();
}


struct Random {
    float value;            // random number between 0 and 1
    float sqrtRand;         // sqrt(value)
    float sqrt_1_sub_rand;  // sqrt(1-value)

    float _2_PI_rand;       // 2*PI*value
    float sin2PIRand;       // sin(_2_PI_rand)
    float cos2PIRand;       // cos(_2_PI_rand)
}

/**
 *  Generates and stores random numbers between 0.0 and 1.0
 */
final class RandomNumbers {
private:
    Random[] values;
    uint index;
    const uint mask;
public:
    this(uint numValues, uint seed = unpredictableSeed()) {
        import core.bitop : popcnt;
        assert(numValues!=0, "Num values must not be 0");
        assert(popcnt(numValues)==1, "Num values must be a power of 2");

        this.mask          = numValues-1;
        this.values.length = numValues;
        auto rng = Mt19937(seed);

        foreach(ref v; values) {
            v.value           = uniform(0f, 1f, rng);
            v.sqrtRand        = sqrt(v.value);
            v.sqrt_1_sub_rand = sqrt(1.0 - v.value);
            v._2_PI_rand      = 2*PI*v.value;
            v.sin2PIRand      = sin(v._2_PI_rand);
            v.cos2PIRand      = cos(v._2_PI_rand);
        }
    }
    Random next() {
        uint i = index++;
        return values[i&mask];
    }
    float nextFloat() {
        uint i = index++;
        return values[i&mask].value;
    }
}