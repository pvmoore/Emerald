module emerald.all;

version(Win64) {} else { static assert(false); }

public:

@fastmath:

version(LDC) {
    import ldc.attributes : fastmath;
} else {
    struct fastmath {}
}

import logging   : log, flushLog;
import common    : as, expect, From, todo;
import resources : Image, BMP, PNG, Obj, ModelData;
import maths     : AABB,
                   Angle,
                   clamp,
                   FastRNG,
                   ImprovedPerlin,
                   RandomNoise3D,
                   Ray,
                   TentFilter,
                   degrees,
                   radians,
                   float2,
                   float3,
                   float4,
                   mat4,
                   uint4,
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

import emerald.gen.AbstractRayTracer;
import emerald.gen.LoopRayTracer;
import emerald.gen.RecursiveRayTracer;

import emerald.geom.box;
import emerald.geom.bvh;
import emerald.geom.intersect_info;
import emerald.geom.Rectangle;
import emerald.geom.shape;
import emerald.geom.sphere;
import emerald.geom.triangle;
import emerald.geom.TriangleMesh;

import emerald.model.camera;
import emerald.model.material;
import emerald.model.texture;

import emerald.scenes.CornellBox;
import emerald.scenes.OneSphere;
import emerald.scenes.RefractionScene;
import emerald.scenes.scene;
import emerald.scenes.Scene2;
import emerald.scenes.Scene3;
import emerald.scenes.Scene4;
import emerald.scenes.SuzanneScene;
import emerald.scenes.ManySpheres;

import emerald.util.random;
import emerald.util.util;

import emerald.render.swrenderer;
