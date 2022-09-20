#include <metal_stdlib>
#include <simd/simd.h>

#import "ShaderTypes.h"

using namespace metal;

#define PI 3.14159265359

struct Ray {
    packed_float3 origin;
    uint mask;
    packed_float3 direction;
    float maxDistance;
    float3 color;
};

struct Intersection {
    float distance;
    int primitiveIndex;
    float2 coordinates;
};

constant unsigned int primes[] = {
    2,   3,  5,  7,
    11, 13, 17, 19,
    23, 29, 31, 37,
    41, 43, 47, 53,
};

// Returns the i'th element of the Halton sequence using the d'th prime number as a
// base. The Halton sequence is a "low discrepency" sequence: the values appear
// random but are more evenly distributed then a purely random sequence. Each random
// value used to render the image should use a different independent dimension 'd',
// and each sample (frame) should use a different index 'i'. To decorrelate each
// pixel, a random offset can be applied to 'i'.
float halton(unsigned int i, unsigned int d) {
    unsigned int b = primes[d];
    
    float f = 1.0f;
    float invB = 1.0f / b;
    
    float r = 0;
    
    while (i > 0) {
        f = f * invB;
        r = r + f * (i % b);
        i = i / b;
    }
    
    return r;
}

kernel void rayKernel(uint2 tid                     [[thread_position_in_grid]],
                      constant Uniforms & uniforms  [[buffer(0)]],
                      device Ray *rays              [[buffer(1)]],
                      texture2d<unsigned int> randomTex      [[texture(0)]],
                      texture2d<float, access::write> dstTex [[texture(1)]])
{
    if (tid.x < uniforms.width && tid.y < uniforms.height) {
        unsigned int rayIdx = tid.y * uniforms.width + tid.x;

        device Ray & ray = rays[rayIdx];
        
        unsigned int offset = randomTex.read(tid).x;
        float2 r = float2(halton(offset + uniforms.frameIndex, 0),
                          halton(offset + uniforms.frameIndex, 1));
        
        float2 pixel = (float2)tid;
        pixel+=r; // Adding a small offset to pixel for anti-aliasing

        float2 uv = (float2)pixel / float2(uniforms.width, uniforms.height);
        uv = uv * 2.0f - 1.0f;
        
        constant Camera & camera = uniforms.camera;
        
        ray.origin = camera.position;
        
        ray.direction = normalize(uv.x * camera.right +
                                  uv.y * camera.up +
                                  camera.forward);
        ray.mask = RAY_MASK_PRIMARY;
        
        ray.maxDistance = INFINITY;
        
        ray.color = float3(1.0f, 1.0f, 1.0f);
        
        dstTex.write(float4(0.0f, 0.0f, 0.0f, 0.0f), tid);
    }
}

template<typename T>
inline T interpolateVertexAttribute(device T *attributes, Intersection intersection) {
    float3 uvw;
    uvw.xy = intersection.coordinates;
    uvw.z = 1.0f - uvw.x - uvw.y;
    
    unsigned int triangleIndex = intersection.primitiveIndex;
    
    T T0 = attributes[triangleIndex * 3 + 0];
    T T1 = attributes[triangleIndex * 3 + 1];
    T T2 = attributes[triangleIndex * 3 + 2];
    
    return uvw.x * T0 + uvw.y * T1 + uvw.z * T2;
}

inline void sampleAreaLight(constant AreaLight & light,
                            float2 u,
                            float3 position,
                            thread float3 & lightDirection,
                            thread float3 & lightColor,
                            thread float & lightDistance)
{
    u = u * 2.0f - 1.0f;
    
    float3 samplePosition = light.position +
                            light.right * u.x +
                            light.up * u.y;
    
    lightDirection = samplePosition - position;
    
    lightDistance = length(lightDirection);
    
    float inverseLightDistance = 1.0f / max(lightDistance, 1e-3f);
    
    lightDirection *= inverseLightDistance;
    lightColor = light.color;
    lightColor *= (inverseLightDistance * inverseLightDistance);
    lightColor *= saturate(dot(-lightDirection, light.forward));
}

inline float3 getSkyBoxColor(float3 u, texture2d<float, access::read> skyBox) {
    normalize(u);

    float w = max(skyBox.get_width(), skyBox.get_height());
    float h = min(skyBox.get_width(), skyBox.get_height());

    float _u = 0.5 + atan2(u.z, u.x) / (2.0 * PI);
    float _v = 0.5 - asin(u.y) / PI;

    _u *= w - 1;
    _v *= h - 1;

    if (skyBox.get_width() < skyBox.get_height()) {
        return float3(skyBox.read(uint2((int)_v, (int)_u)));
    }

        return float3(skyBox.read(uint2((int)_u, (int)_v)));
}

inline float3 getTrueReflectionDirection(Ray ray, float3 normal) {
    float3 n = normalize(normal);
    float3 d = normalize(ray.direction);

    // Reflected ray = d - 2*(d.n)n^
    
    n = (2.0 * (dot(d, n))) * n;
    
    d = d - n;
    
    return normalize(d);
}

inline float3 reflectRay(Ray ray, float3 intersectionPoint, float3 normal, float reflectivity, float rX, float rY) {
    /*
        base angle = alpha
        h = 1 unit
        base = circle with radius r
     
        tan (alpha/2) = r/h
        
        r = tan (alpha/2)
        
        random -> 0..1
     
        random -> -1 .. 1, values spread using cosine function; so rays are more likely to be deviated close to the center of the cone.
        
        choose a random point in the circle
     */
        
    float coneAngle = PI * (1.0 - reflectivity);
    float alpha = coneAngle / 2.0;

    rX = cos(rX * PI);
    rY = cos(rY * PI);
    
    float r;
    
    if(alpha == PI){
        r = MAXFLOAT / 2.0;
    } else {
        r = tan(alpha / 2.0);
    }

    // point where the true reflected ray would have hit base of the cone
    float3 center = intersectionPoint + getTrueReflectionDirection(ray, normal);
    
    float3 point = float3(center.x + r * rX, center.y + r * rY, center.z);
    
    return point - intersectionPoint;
}

inline float3 refractRay(Ray ray, float3 intersectionPoint, float3 normal, float refractiveIndex) {
    bool inside = (dot(normal , ray.direction) >= 0);
    
    if(inside){
        // Invert normal
        normal *= -1;
        refractiveIndex = 1.0 / (refractiveIndex + 1e-3f);
    }
    
    float3 x = normalize(normal);
    float3 z = normalize(cross(ray.direction, x));
    float3 y = cross(x, z);

    float angleI = acos(dot(-1 * x, ray.direction));
    float sinR = sin(angleI) / refractiveIndex;
    float cosR = sqrt(1.0 - sinR * sinR);

    float2 relativeRefractedRay = float2(-cosR, sinR);

    float3 refractedRay = relativeRefractedRay.x * x +  relativeRefractedRay.y * y;

    return refractedRay;
}

kernel void shadeKernel(uint2 tid [[thread_position_in_grid]],
                        constant Uniforms & uniforms,
                        device Ray *rays,
                        device Ray *shadowRays,
                        device Intersection *intersections,
                        device float3 *vertexColors,
                        device float3 *vertexNormals,
                        device uint *triangleMasks,
                        device float *reflectivities,
                        device float *refractiveIndices,
                        texture2d<unsigned int> randomTex,
                        texture2d<float, access::write> dstTex,
                        texture2d<float, access::read> skyBox)
{
    if (tid.x < uniforms.width && tid.y < uniforms.height) {
           unsigned int rayIdx = tid.y * uniforms.width + tid.x;
           device Ray & ray = rays[rayIdx];
           device Ray & shadowRay = shadowRays[rayIdx];
           device Intersection & intersection = intersections[rayIdx];
           
           float3 color = ray.color;
           
           if (ray.maxDistance >= 0.0f && intersection.distance >= 0.0f) {
               uint mask = triangleMasks[intersection.primitiveIndex];

               if (mask == TRIANGLE_MASK_GEOMETRY) {
                   float3 intersectionPoint = ray.origin + ray.direction * intersection.distance;

                   float3 surfaceNormal = interpolateVertexAttribute(vertexNormals, intersection);
                   surfaceNormal = normalize(surfaceNormal);

                   unsigned int offset = randomTex.read(tid).x;
                   float2 r = float2(halton(offset + uniforms.frameIndex, 0),
                                     halton(offset + uniforms.frameIndex, 1));

                   float3 lightDirection;
                   float3 lightColor;
                   float lightDistance;
                   
                   sampleAreaLight(uniforms.light, r, intersectionPoint, lightDirection,
                                   lightColor, lightDistance);
                   lightColor *= saturate(dot(surfaceNormal, lightDirection));
                   color *= interpolateVertexAttribute(vertexColors, intersection);
                   
                   shadowRay.origin = intersectionPoint + surfaceNormal * 1e-3f;
                   shadowRay.direction = lightDirection;
                   shadowRay.mask = RAY_MASK_SHADOW;
                   shadowRay.maxDistance = lightDistance - 1e-3f;
                   

                   shadowRay.color = lightColor * color;
                   
                   if(refractiveIndices[intersection.primitiveIndex] >= 1.0){
                        // Refract ray
                       float3 sampleDirection = refractRay(ray, intersectionPoint, surfaceNormal, refractiveIndices[intersection.primitiveIndex]);
                       ray.direction = sampleDirection;
                       ray.color = color;
                       ray.origin = intersectionPoint + surfaceNormal * 1e-3f;
                       ray.mask = RAY_MASK_SECONDARY;

                   }else{
                       // Reflect ray
                       float reflectivity = reflectivities[intersection.primitiveIndex];
                       
                       float3 sampleDirection = reflectRay(ray, intersectionPoint, surfaceNormal, reflectivity, r.x, r.y);
                       ray.direction = sampleDirection;
                       ray.color = color;
                       ray.origin = intersectionPoint + surfaceNormal * 1e-3f;
                       ray.mask = RAY_MASK_SECONDARY;
                   }
               }
               else {
                   dstTex.write(float4(uniforms.light.color, 1.0f), tid);
                   
                   ray.maxDistance = -1.0f;
                   shadowRay.maxDistance = -1.0f;
               }
           }
           else {
               if(ray.maxDistance >= 0.0f){
                   dstTex.write(float4(getSkyBoxColor(ray.direction, skyBox), 1.0f), tid);
               }
               ray.maxDistance = -1.0f;
               shadowRay.maxDistance = -1.0f;
           }
       }
}

kernel void shadowKernel(uint2 tid [[thread_position_in_grid]],
                         constant Uniforms & uniforms,
                         device Ray *shadowRays,
                         device float *intersections,
                         texture2d<float, access::read_write> dstTex)
{
    if (tid.x < uniforms.width && tid.y < uniforms.height) {
        unsigned int rayIdx = tid.y * uniforms.width + tid.x;
        device Ray & shadowRay = shadowRays[rayIdx];

        float intersectionDistance = intersections[rayIdx];

        if (shadowRay.maxDistance >= 0.0f && intersectionDistance < 0.0f) {
            float3 color = shadowRay.color;

            color += dstTex.read(tid).xyz;

            dstTex.write(float4(color, 1.0f), tid);
        }
    }
}

kernel void accumulateKernel(uint2 tid [[thread_position_in_grid]],
                             constant Uniforms & uniforms,
                             texture2d<float> renderTex,
                             texture2d<float, access::read_write> accumTex)
{
    if (tid.x < uniforms.width && tid.y < uniforms.height) {
        float3 color = renderTex.read(tid).xyz;

        if (uniforms.frameIndex > 0) {
            float3 prevColor = accumTex.read(tid).xyz;
            prevColor *= uniforms.frameIndex;
            
            color += prevColor;
            color /= (uniforms.frameIndex + 1);
        }
        
        accumTex.write(float4(color, 1.0f), tid);
    }
}

constant float2 quadVertices[] = {
    float2(-1, -1),
    float2(-1,  1),
    float2( 1,  1),
    float2(-1, -1),
    float2( 1,  1),
    float2( 1, -1)
};

struct CopyVertexOut {
    float4 position [[position]];
    float2 uv;
};

vertex CopyVertexOut copyVertex(unsigned short vid [[vertex_id]]) {
    float2 position = quadVertices[vid];
    
    CopyVertexOut out;
    
    out.position = float4(position, 0, 1);
    out.uv = position * 0.5f + 0.5f;
    
    return out;
}

fragment float4 copyFragment(CopyVertexOut in [[stage_in]],
                             texture2d<float> tex)
{
    constexpr sampler sam(min_filter::nearest, mag_filter::nearest, mip_filter::none);
    
    float3 color = tex.sample(sam, in.uv).xyz;
    
    color = color / (1.0f + color);
    
    return float4(color, 1.0f);
}
