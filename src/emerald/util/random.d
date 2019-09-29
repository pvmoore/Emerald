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
