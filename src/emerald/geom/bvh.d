module emerald.geom.bvh;

import emerald.all;

/**
 * Bounding Volume Hierarchy
 *
 *
 */
final class BVH : Shape {
private:
    Shape left;
    Shape right;
	AABB aabb;
	uint id;

	this() {
		this.id = ids++;
	}
public:
	enum AxisStrategy { ROTATE, PICK_LONGEST }

    override AABB getAABB() {
		return aabb;
	}
	override Material getMaterial() {
		expect(false); assert(false);
	}
	override float2 getUV(IntersectInfo intersect) {
		expect(false); assert(false);
	}
	override void recalculate() {
		left.recalculate();
		right.recalculate();
		recalculateAABB();
    }

	static Shape build(Shape[] shapes,
					   AxisStrategy axisStrategy = AxisStrategy.PICK_LONGEST,
					   uint axis = 0)
	{
		if(shapes.length==0) {
			assert(false);
		} else if(shapes.length==1) {
			return shapes[0];
		} else if(shapes.length==2) {
			auto bvh  = new BVH();
			bvh.left  = shapes[0];
			bvh.right = shapes[1];
			bvh.aabb  = bvh.left.getAABB().enclose(bvh.right.getAABB());
			return bvh;
		} else {
			// find the midpoint of the bounding box to use as a qsplit pivot
			AABB box = shapes[0].getAABB();
			for(auto i=1; i<shapes.length; i++) {
				box.enclose(shapes[i].getAABB());
			}

			if(axisStrategy==AxisStrategy.PICK_LONGEST) {
				/* Pick the longest axis */
				axis = box.longestAxis();
			}

			auto pivot = (box.max()[axis] + box.min()[axis]) * 0.5f;

			/* now split according to correct axis */
			auto midPoint = qsplit(shapes, pivot, axis);

			/* create a new bounding volume */
			auto bvh  = new BVH;
			bvh.left  = build(shapes[0..midPoint], axisStrategy, (axis+1)%3);
			bvh.right = build(shapes[midPoint..$], axisStrategy, (axis+1)%3);
			bvh.aabb  = box;
			return bvh;
		}
	}

	override bool intersect(ref Ray r, IntersectInfo ii, float tmin) {
		float t;
	    if(!(aabb.intersect(r, t, tmin, ii.t))) {
	        return false;
	    }
        tmin = min(t, tmin);

		/* Call hit on both branches to get the minimum intersection */
		bool isahit1 = right.intersect(r, ii, tmin);
		bool isahit2 =  left.intersect(r, ii, tmin);
		return isahit1 || isahit2;
	}
	override string dump(string padding) {
		auto buf = appender!(string);

		buf ~= "%sBVH{%s %s\n".format(padding, id, aabb);
		buf ~= (left ? left.dump(padding ~ "   ") : "   null") ~ "\n";
		buf ~= (right ? right.dump(padding ~ "   ") : "   null") ~ "\n";
		buf ~= padding~"}";
		return buf.data;
	}
private:
	void recalculateAABB() {
        this.aabb = left.getAABB();
        aabb.enclose(right.getAABB());
    }
    static uint qsplit(Shape[] list, float pivotVal, uint axis) {
        int retVal = 0;
        auto size  = list.length.as!uint;

        for(auto i=0; i<size; i++) {
            auto bbox     = list[i].getAABB();
            auto centroid = (bbox.min()[axis] + bbox.max()[axis]) * 0.5f;

            if(centroid < pivotVal) {
                auto temp    = list[i];
                list[i]      = list[retVal];
                list[retVal] = temp;
                retVal++;
            }
        }
        if(retVal==0 || retVal==size) retVal = size>>>1;
        return retVal;
    }
}
