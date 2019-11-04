module emerald.util.random;

import emerald.all;

/* This one is shared otherwise banding artifacts appear. I haven't worked out why ?? */
__gshared RandomBuffer randomBuffer;

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
    randomBuffer = new RandomBuffer(65536);
}

float getRandom() {
    return randomBuffer.next();
}


struct Random {
    float rand;             // random number between 0 and 1
    float sqrtRand;         // sqrt(rand)
    float sqrt_1_sub_rand;  // sqrt(1-rand)

    float _2_PI_rand;       // 2*PI*rand
    float sin2PIRand;       // sin(_2_PI_rand)
    float cos2PIRand;       // cos(_2_PI_rand)
}