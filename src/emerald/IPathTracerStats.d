module emerald.IPathTracerStats;

import emerald.all;

interface IPathTracerStats {
    int getIterations();
    uint samplesPerPixel();
}