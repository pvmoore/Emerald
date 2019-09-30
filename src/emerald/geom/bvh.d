module emerald.geom.bvh;

import emerald.all;

/**
 * Bounding Volume Hierarchy
 *
 *
 */
final class BVH : Shape {
private:
	__gshared static uint ids = 0;
    Shape left;
    Shape right;
	AABB aabb;
	uint id;
public:
    override AABB getAABB() 		{ return aabb; }
	override Material getMaterial() { assert(false); }

    this(Shape prim1, Shape prim2) {
		this.id    = ids++;
		this.left  = prim1;
		this.right = prim2;
		this.aabb  = prim1.getAABB().enclose(prim2.getAABB());
	}
    this(Shape prim1, Shape prim2, AABB bbox) {
		this.id    = ids++;
		this.left  = prim1;
		this.right = prim2;
        this.aabb  = bbox;
    }
    this(Shape[] shapes) {
		this.id = ids++;

        if(shapes.length==1) {
			this.left  = shapes[0];
			this.right = shapes[0];
			this.aabb  = left.getAABB();
		} else if(shapes.length==2) {
            this.left  = shapes[0];
			this.right = shapes[1];
			this.aabb  = left.getAABB().enclose(right.getAABB());
        } else {
            /* find the midpoint of the bounding box to use as a qsplit pivot */
			this.aabb = shapes[0].getAABB();

			for(auto i=1; i<shapes.length; i++) {
			    this.aabb.enclose(shapes[i].getAABB());
			}
			float3 pivot = (aabb.max() + aabb.min()) * 0.5f;
			int midPoint = qsplit(shapes, pivot.x, 0);

			/* create a new bounding volume */
			this.left  = buildBranch(shapes[0..midPoint], 1);
			this.right = buildBranch(shapes[midPoint..$], 1);
        }
    }
	override bool intersect(ref Ray r, IntersectInfo ii, float tmin = 0.01, float tmax = float.max) {
		float t;
	    if(!(aabb.intersect(r, t, tmin, tmax))) {
	        return false;
	    }

        tmin = min(t, tmin);

		/* Call hit on both branches to get the minimum intersection */
		bool isahit1 = right.intersect(r, ii, tmin, tmax);
		bool isahit2 =  left.intersect(r, ii, tmin, ii.t);
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
    static Shape buildBranch(Shape[] shapes, uint axis) {
		if(shapes.length==1) return shapes[0];
		if(shapes.length==2) return new BVH(shapes[0], shapes[1]);

		// find the midpoint of the bounding box to use as a qsplit pivot
		AABB box = shapes[0].getAABB();
		for(auto i=1; i<shapes.length; i++) {
		    box.enclose(shapes[i].getAABB());
		}
		auto pivot = (box.max() + box.min()) * 0.5f;

		/* now split according to correct axis */
		auto midPoint = qsplit(shapes, pivot[axis], axis);

		/* create a new bounding volume */
		auto lft  = buildBranch(shapes[0..midPoint], (axis+1)%3);
		auto rght = buildBranch(shapes[midPoint..$], (axis+1)%3);
		return new BVH(lft, rght, box);
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
