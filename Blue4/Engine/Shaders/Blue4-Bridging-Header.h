#ifndef ShaderTypes_h
#define ShaderTypes_h

#include <simd/simd.h>

#define TRIANGLE_MASK_GEOMETRY 1
#define TRIANGLE_MASK_LIGHT    2

#define RAY_MASK_PRIMARY   3
#define RAY_MASK_SHADOW    1
#define RAY_MASK_SECONDARY 1

#define LIGHT_TYPE_AREA   0
#define LIGHT_TYPE_SPOT   1
#define LIGHT_TYPE_SUN    2

struct Camera {
    vector_float3 position;
    vector_float3 right;
    vector_float3 up;
    vector_float3 forward;
};

struct Light {
    unsigned int type;
    vector_float3 position;
    vector_float3 forward;
    vector_float3 right;
    vector_float3 up;
    vector_float3 color;
};

struct PSLight {
    struct Light light;
    float ambient;
    float diffuse;
    float specular;
};

struct Uniforms
{
    unsigned int width;
    unsigned int height;
    unsigned int blocksWide;
    unsigned int frameIndex;
    unsigned int lightCount;
    struct Camera camera;
};

#endif /* ShaderTypes_h */

