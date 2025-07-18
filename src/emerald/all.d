module emerald.all;

version(Win64) {} else { static assert(false); }

public:

@fastmath:

enum EPSILON = 0.00001f;
enum TMIN    = 0.05f;       // Setting this lower causes artifacts

version(LDC) {
    import ldc.attributes : fastmath;
} else {
    struct fastmath {}
}

import logging   : log, flushLog, setEagerFlushing;
import common    : Borrowed;
import common.utils: as, expect, isA, From, todo;
import resources : Image, BMP, PNG, Obj, ModelData;
import maths     : AABB,
                   Angle,
                   Camera2D,
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
                   uint2,
                   uint4,
                   max,
                   maxOf,
                   min;

import core.sync.mutex          : Mutex;
import core.thread              : Thread;
import core.atomic              : atomicOp;

import std.array                : appender;
import std.conv 		        : to;
import std.stdio		        : writefln;
import std.format               : format;
import std.datetime.stopwatch   : StopWatch;
import std.string               : toStringz;
import std.range                : iota, array;
import std.parallelism          : parallel, defaultPoolThreads, totalCPUs;
import std.math			        : pow, sqrt, PI, M_1_PI, fabs, cos, sin;
import std.random				: uniform, Mt19937, unpredictableSeed;
import std.algorithm.iteration  : map;

import emerald.emerald;
import emerald.EmeraldGPU;
import emerald.EmeraldVK;
import emerald.IPathTracerStats;
import emerald.photos;
import emerald.version_;

import emerald.gen.AbstractPathTracer;
import emerald.gen.GPUPathTracer;
import emerald.gen.LoopPathTracer;
import emerald.gen.RecursivePathTracer;

import emerald.geom.BoxBuilder;
import emerald.geom.bvh;
import emerald.geom.intersect_info;
import emerald.geom.RectangleBuilder;
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

import emerald.render.renderer;
import emerald.render.gpuRenderer;

import emerald.util.random;
import emerald.util.util;
