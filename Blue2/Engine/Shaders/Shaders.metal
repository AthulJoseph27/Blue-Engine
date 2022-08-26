#include <metal_stdlib>

#define PI 3.14159265359

using namespace metal;

struct VertexIn {
    unsigned int solidId [[ attribute(0) ]];
    float3 position    [[ attribute(1) ]];
};

struct TriangleIn {
    unsigned int A     [[ attribute(0) ]];
    unsigned int B     [[ attribute(1) ]];
    unsigned int C     [[ attribute(2) ]];
    float3 normal      [[ attribute(3) ]];
    float4 color       [[ attribute(4) ]];
};

struct ModelConstants {
    float4x4 modelMatrix;
};

struct SceneConstants {
    float4x4 viewMatrix;
};

struct Camera {
    float3 position;
};

struct AreaLight {
    float3 position;
    float3 forward;
    float3 right;
    float3 up;
    float3 color;
};

struct Ray {
    float3 orgin;
    float3 direction;
    float3 color;
};

struct Intersection {
    float dist;
    float3 coordinates;
};

struct Skybox {
    int width;
    int height;
    bool isSet;
    texture2d<float, access::read> texture;
};

struct Uniforms
{
    unsigned int width         [[ attribute(0) ]];
    unsigned int height        [[ attribute(1) ]];
    unsigned int triangleCount [[ attribute(2) ]];
    unsigned int verticesCount [[ attribute(3) ]];
    int2 skyBoxSize            [[ attribute(4) ]];
    bool isSkyboxSet           [[ attribute(5) ]];
    float3 cameraPositionDelta [[ attribute(6) ]];
    float3 cameraRotation      [[ attribute(7) ]];
};

struct CameraRotation {
    float4x4 rotationMatrix;
};

float get_dist(float3 a, float3 b) {
    return sqrt(pow((a.x-b.x),2) + pow((a.y-b.y),2) + pow((a.z - b.z),2));
}

float4 getSkyBoxColor(float3 u, Skybox skyBox) {
    if (!skyBox.isSet) {
        return float4(0, 0, 0, 1);
    }

    normalize(u);

    float w = max(skyBox.width, skyBox.height);
    float h = min(skyBox.width, skyBox.height);

    float _u = 0.5 + atan2(u.z, u.x) / (2.0 * PI);
    float _v = 0.5 - asin(u.y) / PI;

    _u *= w - 1;
    _v *= h - 1;

    if (skyBox.width < skyBox.height) {
        return float4(skyBox.texture.read(uint2((int)_v, (int)_u)));
    }

        return float4(skyBox.texture.read(uint2((int)_u, (int)_v)));
    }

Intersection get_intersection(Ray ray, device VertexIn *vertices, device TriangleIn *triangles, int index){
    // Möller–Trumbore intersection algorithm
    
    Intersection intersection = Intersection();
    intersection.dist = -1;
    
    const float EPSILON = 0.0000001;
    
    float3 vertex0 = vertices[triangles[index].A].position;
    float3 vertex1 = vertices[triangles[index].B].position;
    float3 vertex2 = vertices[triangles[index].C].position;
    
    float3 edge1, edge2, h, s, q;
    float a,f,u,v;
    edge1 = vertex1 - vertex0;
    edge2 = vertex2 - vertex0;
    h = cross(ray.direction, edge2);
    a = dot(edge1, h);
    
    if (a > -EPSILON && a < EPSILON){
        return intersection;    // This ray is parallel to this triangle.
    }
    
    f = 1.0/a;
    s = ray.orgin - vertex0;
    u = f * dot(s, h);
    
    if (u < 0.0 || u > 1.0){
        return intersection;
    }
    
    q = cross(s, edge1);
    v = f * dot(ray.direction, q);
    
    if (v < 0.0 || (u + v) > 1.0){
        return intersection;
    }
    
    // At this stage we can compute t to find out where the intersection point is on the line.
    float t = f * dot(edge2, q);
    if (t > EPSILON) // ray intersection
    {
        intersection.coordinates = ray.orgin + ray.direction * t;
        intersection.dist = get_dist(intersection.coordinates, ray.orgin);
    }
    
    return intersection;
}

float4 trace_ray(Ray ray, device VertexIn *vertices, device TriangleIn *triangles, int trianglesCount, Skybox skybox) {
    float dist = FLT_MAX;
    int index = -1;
    
    for(int i=0;i<trianglesCount;i++){
        Intersection intersection = get_intersection(ray, vertices, triangles, i);
        if(intersection.dist == -1){
            continue;
        }
        
        if(intersection.dist < dist){
            dist = intersection.dist;
            index = i;
        }
    }
    
    if(index == -1){
        return getSkyBoxColor(ray.direction, skybox);
    }
    
    return triangles[index].color;
}

kernel void ray_tracing_kernel(uint2 tid [[ thread_position_in_grid ]],
                               device VertexIn *verticesOut [[ buffer(1) ]],
                               device TriangleIn *triangles [[ buffer(2) ]],
                               constant Uniforms &uniforms [[ buffer(3) ]],
                               constant CameraRotation &camRotation [[ buffer(5) ]],
                               texture2d<float, access::write> destTexture,
                               texture2d<float, access::read> skyBoxTexture){
    
    Camera camera = Camera();
    
    float2 screenCenter = float2(uniforms.width/2.0, uniforms.height/2.0);
    float3 delta = uniforms.cameraPositionDelta;
    
    camera.position = float3(screenCenter.x + delta.x , screenCenter.y + delta.y , -1200 + delta.z);
    
//    camera.position = float3(delta.x + 1000000, delta.y + 1000000 , -10000 + delta.z);
    
    // assume screen is at z = 0
    float3 pixel_position = float3(tid.x, tid.y, 0);
    
    Ray ray = Ray();
    ray.orgin = camera.position;
    
    ray.direction =  normalize(pixel_position - camera.position);
    float4 direction = camRotation.rotationMatrix * float4(ray.direction, 1);
    ray.direction = float3(direction.x, direction.y, direction.z);
    
    ray.color = float3(1.0, 1.0, 1.0);
    
    Skybox skybox = Skybox();
    skybox.width = uniforms.skyBoxSize.x;
    skybox.height = uniforms.skyBoxSize.y;
    skybox.isSet = uniforms.isSkyboxSet;
    skybox.texture = skyBoxTexture;
    
    float4 color = trace_ray(ray, verticesOut, triangles, uniforms.triangleCount, skybox);
    
//    float4 color = float4(verticesOut[triangles[0].C].position.x/(10 * 255), verticesOut[triangles[0].C].position.y/(10 * 255), verticesOut[triangles[0].C].position.z/(255), 1.0);
    
    uint2 pixelIndex = uint2(tid.x, uniforms.height - tid.y);
    
    destTexture.write(color, pixelIndex);
}

kernel void transform_tracing_kernel(uint index [[ thread_position_in_grid ]], device VertexIn *verticesIn [[ buffer(0) ]], device VertexIn *verticesOut [[ buffer(1) ]], device ModelConstants *modelConstants [[ buffer(4) ]], constant Uniforms &uniforms [[ buffer(3) ]]) {
    
    if(index >= uniforms.verticesCount) {
        return;
    }
    
    float4 result = modelConstants[verticesIn[index].solidId].modelMatrix *  float4(verticesIn[index].position, 1);
    
    verticesOut[index].position = float3(result.x, result.y, result.z);
}
