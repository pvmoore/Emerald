module emerald.all;

version(Win64) {} else { static assert(false); }

public:

version(LDC) {
    import ldc.attributes : fastmath;
} else {
    struct fastmath {}
}

import logging   : log, flushLog;
import common    : From;
import resources : BMP;
import maths :
    AABB,
    FastRNG,
    max,
    min,
    RandomNoise3D,
    Ray,
    Sphere,
    TentFilter,
    RandomBuffer,
    ImprovedPerlin,
    float2,
    float3,
    degrees;
import gl :
    ApplicationListenerAdapter,
    OpenGL,
    PixelBuffer;


import core.sync.mutex          : Mutex;
import core.thread              : Thread;
import core.atomic              : atomicOp;

import std.conv 		        : to;
import std.stdio		        : writefln;
import std.format               : format;
import std.datetime.stopwatch   : StopWatch;
import std.string               : toStringz;
import std.range                : iota;
import std.parallelism          : parallel, defaultPoolThreads, totalCPUs;
import std.math			        : pow, sqrt, PI, M_1_PI, fabs, cos, sin;

import emerald.emerald;
import emerald.photos;

import emerald.gen.material;
import emerald.gen.model;
import emerald.gen.raytracer;

import emerald.util.random;
import emerald.util.util;

import emerald.render.swrenderer;
