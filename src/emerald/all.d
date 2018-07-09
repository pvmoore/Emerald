module emerald.all;

version(Win64) {} else { static assert(false); }

public:

version(LDC) {
    import ldc.attributes : fastmath;
} else {
    struct fastmath {

    }
}

import logging : log, flushLog;
import common : ObjectCache;
import maths :
    //AABB,
    FastRNG,
    max,
    min,
    RandomNoise3D,
    Ray,
    Sphere,
    TentFilter,
    Vector2,
    Vector3;
import gl :
    ApplicationListenerAdapter,
    OpenGL,
    PixelBuffer;
import resources : BMP;

alias Vec = Vector3;

import core.thread      : Thread;
import core.atomic      : atomicOp;
import std.conv 		: to;
import std.stdio		: writefln;
import std.format       : format;
import std.datetime.stopwatch : StopWatch;
import std.string       : toStringz;
import std.range        : iota;
import std.parallelism  : parallel;
import std.math			: pow, sqrt, PI, M_1_PI,
                          fabs, cos, sin;

import emerald.emerald;
import emerald.material;
import emerald.model;
import emerald.random;
import emerald.util;

import emerald.render.swrenderer;
