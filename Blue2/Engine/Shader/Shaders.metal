#include <metal_stdlib>
using namespace metal;

struct VertexIn {
    float3 position [[ attribute(0) ]];
    float4 color [[ attribute(1) ]];
};

struct TriangleIn {
    float3 A [[ attribute(0) ]];
    float3 B [[ attribute(1) ]];
    float3 C [[ attribute(2) ]];
    float3 normal [[ attribute(3) ]];
    float4 color [[ attribute(4) ]];
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

struct Uniforms
{
    unsigned int width [[ attribute(0) ]];
    unsigned int height [[ attribute(1) ]];
    unsigned int triangleCount [[ attribute(2) ]];
    unsigned int frameIndex [[ attribute(3) ]];
    float3 cameraPositionDelta [[ attribute(4) ]];
    float3 cameraRotation [[ attribute(5) ]];
};

float get_dist(float3 a, float3 b) {
    return sqrt(pow((a.x-b.x),2) + pow((a.y-b.y),2) + pow((a.z - b.z),2));
}

Intersection get_intersection(Ray ray, device TriangleIn *triangles, int index){
    // Möller–Trumbore intersection algorithm
    
    Intersection intersection = Intersection();
    intersection.dist = -1;
    
    const float EPSILON = 0.0000001;
    
    float3 vertex0 = triangles[index].A;
    float3 vertex1 = triangles[index].B;
    float3 vertex2 = triangles[index].C;
    
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

float4 trace_ray(Ray ray, device TriangleIn *triangles, int trianglesCount) {
    float dist = FLT_MAX;
    int index = -1;
    
    for(int i=0;i<trianglesCount;i++){
        Intersection intersection = get_intersection(ray, triangles, i);
        if(intersection.dist == -1){
            continue;
        }
        
        if(intersection.dist < dist){
            dist = intersection.dist;
            index = i;
        }
    }
    
    if(index == -1){
        return float4(0,0,0,1);
    }
    
    return triangles[index].color;
}

kernel void ray_tracing_kernel(uint2 tid [[ thread_position_in_grid ]],
                               device TriangleIn *triangles,
                               constant Uniforms &uniforms [[ buffer(1) ]],
                               texture2d<float, access::write> destTexture){
    
    Camera camera = Camera();
    
    float2 screenCenter = float2(uniforms.width/2.0, uniforms.height/2.0);
    float3 delta = uniforms.cameraPositionDelta;
    
    camera.position = float3(screenCenter.x + delta.x , screenCenter.y + delta.y , -100 + delta.z);
//    camera.position = float3(0, 0, -1000);
    // assume screen is at z = 0
    
    float3 pixel_position = float3(tid.x, tid.y, 0);
    
    Ray ray = Ray();
    ray.orgin = camera.position;
    ray.direction =  normalize(pixel_position - camera.position);
    ray.color = float3(1.0, 1.0, 1.0);
    
    float4 color = trace_ray(ray, triangles, uniforms.triangleCount);
    
    uint2 pixelIndex = uint2(tid.x, uniforms.height - tid.y);
    
    destTexture.write(color, pixelIndex);
}
