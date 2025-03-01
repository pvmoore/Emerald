
layout(set = 0, binding = 0, std430) readonly buffer IN_random_data {
	float random[];
};
layout(set = 0, binding = 1, std430) readonly buffer IN_tentfilter_data {
	float tentFilter[];
};
layout(set = 0, binding = 2, std430) readonly buffer IN_shape_data {
	float shapes[];
};
layout(set = 0, binding = 3, std430) readonly buffer IN_material_data {
	float materials[];
};
layout(set = 0, binding = 4, std430) buffer INOUT_accumulated_colours {
	vec3 colours[];
};
layout(set = 0, binding = 5) uniform sampler2D textureSampler;

layout(set = 0, binding = 6, rgba8) uniform writeonly image2D imageOut;

layout(set = 0, binding = 7, std140) uniform readonly UBO {
	vec3 cameraPosition;
    float _pad1;
    vec3 cameraDirection; // normalised
    float _pad2;
} ubo;

// Push constants (128 bytes minimum - 32 floats)
layout(std140, push_constant) uniform readonly PC {
	float frameNumber;
	float imageIteration; 	// Current iteration for this image
	float imageState;     	// Set to 1 if we need to restart the accumulated colours from black
									// ie. the camera moved
	float random0;
	float random1;
	float random2;
	float random3;
} pc;
