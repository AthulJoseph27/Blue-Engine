#include <metal_stdlib>
#include <simd/simd.h>

#import "Blue3-Bridging-Header.h"

using namespace metal;

#define PI 3.14159265359
//#define FRENEL_ANGLE 7*PI/8

struct Material {
    float4 color            [[ attribute(0) ]];
    bool isLit              [[ attribute(1) ]];
    float3 ambient          [[ attribute(2) ]];
    float3 diffuse          [[ attribute(3) ]];
    float3 specular         [[ attribute(4) ]];
    float3 emissive         [[ attribute(5) ]];
    float shininess         [[ attribute(5) ]];
    float opacity           [[ attribute(6) ]];
    float opticalDensity    [[ attribute(7) ]];
    float roughness         [[ attribute(8) ]];
    bool isTextureEnabled   [[ attribute(9) ]];
};

struct PrimitiveData {
    texture2d<float> texture [[ id(0) ]];
};

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
                      texture2d<unsigned int> randomTex [[texture(0)]],
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

inline void sampleSpotLight(float2 u,
                            float3 position,
                            thread float3 & lightDirection,
                            thread float3 & lightColor,
                            thread float & lightDistance)
{
    float radius = 10000;
    float3 center = float3(radius * 100, radius * 100, radius * 100);
    u = u * 2.0f - 1.0f;
    
    center.x += radius * u.x;
    center.y += radius * u.y;
    
    lightDirection = center - position;
    
    lightDistance = INFINITY;
    
//    float inverseLightDistance = 1.0f / max(lightDistance, 1e-3f);
    
//    lightDirection *= inverseLightDistance;
    lightColor = float3(1, 0.7, 0.7);
//    lightColor *= (inverseLightDistance * inverseLightDistance);
//    lightColor *= saturate(dot(-lightDirection, light.forward));
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

inline float3 sampleCosineWeightedHemisphere(float2 u) {
    float phi = 2.0f * M_PI_F * u.x;
    
    float cos_phi;
    float sin_phi = sincos(phi, cos_phi);
    
    float cos_theta = sqrt(u.y);
    float sin_theta = sqrt(1.0f - cos_theta * cos_theta);
    
    return float3(sin_theta * cos_phi, cos_theta, sin_theta * sin_phi);
}

inline float3 alignHemisphereWithNormal(float3 sample, float3 normal) {
    float3 up = normal;
    float3 right = normalize(cross(normal, float3(0.0072f, 1.0f, 0.0034f)));
    float3 forward = cross(right, up);
    
    return sample.x * right + sample.y * up + sample.z * forward;
}

inline float3 reflectRay(Ray ray, float3 intersectionPoint, float3 normal, float reflectivity, float rX, float rY) {
    /*
        base coneAngle/2.0 = alpha
        base = circle with radius r
        
        consider this to be arc, then
        
        h * alpha = r
        
        random -> 0..1
     
        random -> -1 .. 1
        
        choose a random point in the circle
     */
    
//    reflectivity += 1e-3; // to avoid getting infinity in tan
    
    float coneAngle = PI * (1.0 - reflectivity);
    float alpha = coneAngle / 2.0;
    
//    rX = 2.0f * rX - 1.0f;
//    rY = 2.0f * rY - 1.0f;
    
    rX = cos(PI * rX);
    rY = cos(PI * rY);
    
    float r;
    
    r = 15.0f * alpha;
    

    float3 center = intersectionPoint + reflect(ray.direction, normal);
    
    float3 point = float3(center.x + r * rX, center.y + r * rY, center.z);
    
    return point - intersectionPoint;
}

inline float3 refractRay(Ray ray, float3 normal, float eta) {
    bool inside = (dot(ray.direction, normal) >= 0);

    if(inside){
//         Invert normal
        normal *= -1;
    }
    
    return refract(normalize(ray.direction), normalize(normal), eta);
}

kernel void shadeKernel(uint2 tid [[thread_position_in_grid]],
                        constant Uniforms & uniforms,
                        device Ray *rays,
                        device Ray *shadowRays,
                        device Intersection *intersections,
                        device float3 *vertexColors,
                        device float3 *vertexNormals,
                        device uint *triangleMasks,
                        device Material *materials,
                        device uint *materialIds,
                        device PrimitiveData *primitiveData,
                        device uint *textureIds,
                        device float2 *uvCoordinates,
                        constant unsigned int & bounce,
                        texture2d<unsigned int> randomTex,
                        texture2d<float, access::write> dstTex,
                        texture2d<float, access::read> skyBox,
                        sampler sampler2d[[ sampler(0) ]])
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
                   
                   float3 objectColor;
                   
//                   sampleAreaLight(uniforms.light, r, intersectionPoint, lightDirection,
//                                   lightColor, lightDistance);
                   sampleSpotLight(r, intersectionPoint, lightDirection,
                                   lightColor, lightDistance);
                   lightColor *= saturate(dot(surfaceNormal, lightDirection));
                   
                   if(materials[materialIds[intersection.primitiveIndex]].isTextureEnabled){
                       objectColor = primitiveData[textureIds[intersection.primitiveIndex]].texture.sample(sampler2d, interpolateVertexAttribute(uvCoordinates, intersection)).xyz;
                   } else {
                       objectColor = interpolateVertexAttribute(vertexColors, intersection);
                   }
                   color *= objectColor;
                   
                   shadowRay.origin = intersectionPoint + surfaceNormal * 1e-3f;
                   shadowRay.direction = lightDirection;
                   shadowRay.mask = RAY_MASK_SHADOW;
                   shadowRay.maxDistance = lightDistance - 1e-3f;

                   shadowRay.color = lightColor * color;
                   
                   Material material = materials[materialIds[intersection.primitiveIndex]];
                   
                   float refractiveIndex = 0;

                   if(material.opacity < 0.99) {
                       refractiveIndex = material.opticalDensity;
                       if(refractiveIndex < 1.0) {
                           refractiveIndex = 1.0 / refractiveIndex;
                       }
                   }

                   float reflectivity = 1.0 - material.roughness;
                   
//                   float angleBIN = dot(surfaceNormal, -ray.direction);
                   
                   if(refractiveIndex >= 1.0f){
                        // Refract ray
                       ray.direction = refractRay(ray, surfaceNormal, 1.0 / refractiveIndex);
                       ray.origin = intersectionPoint + ray.direction * 1e-3f;
                       ray.color = color;
                       ray.mask = RAY_MASK_PRIMARY;
                       ray.maxDistance = INFINITY;
                   }else if(reflectivity > 0.0f){
                       // Reflect ray
                       ray.direction = reflect(ray.direction, surfaceNormal);
                       ray.origin = intersectionPoint + ray.direction * 1e-3f;
                       ray.color = color * reflectivity;
                       ray.mask = RAY_MASK_SECONDARY;
                       //                       ray.maxDistance = INFINITY;
                   }else{
                       r = float2(halton(offset + uniforms.frameIndex, bounce + 1),
                                  halton(offset + uniforms.frameIndex, bounce + 3));

                       ray.origin = intersectionPoint + surfaceNormal * 1e-3f;
                       ray.direction = reflectRay(ray, intersectionPoint, surfaceNormal, 0.0f, r.x, r.y);
                       ray.color = color;
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
//               if(ray.maxDistance >= 0.0f && ray.mask == RAY_MASK_PRIMARY){
//                   dstTex.write(, tid);
//               }
               ray.color = color * getSkyBoxColor(ray.direction, skyBox);
               shadowRay.color = ray.color;
               ray.maxDistance = -1.0f;
//               shadowRay.maxDistance = -1.0f;
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
        float3 color = dstTex.read(tid).xyz;
        
        if (shadowRay.maxDistance >= 0.0f && intersectionDistance < 0.0f) {
            color += shadowRay.color;
        }
        
        dstTex.write(float4(color, 1.0f), tid);
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
