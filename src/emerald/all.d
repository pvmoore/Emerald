module emerald.all;

version(Win64) {} else { static assert(false); }

public:

version(LDC) {
    import ldc.attributes : fastmath;
} else {
    struct fastmath {}
}

import logging   : log, flushLog;
import common    : as, From;
import resources : BMP;
import maths     : AABB,
                   FastRNG,
                   ImprovedPerlin,
                   RandomBuffer,
                   RandomNoise3D,
                   Ray,
                   TentFilter,
                   degrees,
                   float2,
                   float3,
                   max,
                   min;
import gl        : ApplicationListenerAdapter,
                   OpenGL,
                   PixelBuffer;


import core.sync.mutex          : Mutex;
import core.thread              : Thread;
import core.atomic              : atomicOp;

import std.array                : appender;
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
import emerald.version_;

import emerald.gen.raytracer;

import emerald.geom.bvh;
import emerald.geom.intersect_info;
import emerald.geom.shape;
import emerald.geom.sphere;

import emerald.model.camera;
import emerald.model.material;
import emerald.model.scene;

import emerald.util.random;
import emerald.util.util;

import emerald.render.swrenderer;
