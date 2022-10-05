#include <metal_stdlib>
using namespace metal;

struct VertexIn {
    float3 position        [[ attribute(0) ]];
    float3 color           [[ attribute(1) ]];
    float2 uvCoordinate    [[ attribute(2) ]];
    uint textureId         [[ attribute(3) ]];
};

struct RasterizerData {
    float4 position [[ position ]];
    float4 color;
    float2 uvCoordinate;
//    uint textureId [[ id(0) ]];
};

struct ModelConstants {
    float4x4 modelMatrix;
};

struct SceneConstants {
    float4x4 viewMatrix;
    float4x4 projectionMatrix;
};

struct Material {
    bool useTexture;
    bool useMaterialColor;
    float4 color;
};

struct PrimitiveData {
    texture2d<float> texture;
};

vertex RasterizerData basic_vertex_shader(const VertexIn vertexIn[[ stage_in ]], constant SceneConstants &sceneConstants [[ buffer(1) ]]){
    RasterizerData rd;
    rd.position = sceneConstants.projectionMatrix * sceneConstants.viewMatrix *  float4(vertexIn.position, 1);
    rd.color = float4(vertexIn.color, 1);
    rd.uvCoordinate = vertexIn.uvCoordinate;
//    rd.textureId = vertexIn.textureId;
    
    return rd;
}

fragment half4 basic_fragment_shader(RasterizerData rd [[ stage_in ]], sampler sampler2d[[ sampler(0) ]]){
    float4 color = float4(0, 1, 0, 1);
    
//    if(!is_null_texture(primitiveData[rd.textureId].texture)){
//        color = primitiveData[rd.textureId].texture.sample(sampler2d, rd.uvCoordinate);
//    }
    
    return half4(color.r, color.g, color.b, color.a);
}
