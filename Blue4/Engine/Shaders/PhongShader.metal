#include <metal_stdlib>
#import "Blue4-Bridging-Header.h"

using namespace metal;

struct VertexIn {
    float3 position        [[ attribute(0) ]];
    float2 uvCoordinate    [[ attribute(1) ]];
    float3 normal          [[ attribute(2) ]];
    float3 tangent         [[ attribute(3) ]];
    float3 bitangent       [[ attribute(4) ]];
};

struct RasterizerData {
    float4 position [[ position ]];
    float2 uvCoordinate;
    
    float3 worldPosition;
    float3 surfaceNormal;
    float3 toCameraVector;
};

struct ModelConstants {
    float4x4 modelMatrix [[ id(0) ]];
};

struct SceneConstants {
    float4x4 viewMatrix;
    float4x4 projectionMatrix;
    float3 cameraPosition;
};

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
    texture2d<float> texture        [[ id(0) ]];
    texture2d<float> normalMap      [[ id(1) ]];
    texture2d<float> metallicMap    [[ id(2) ]];
    texture2d<float> roughnessMap   [[ id(3) ]];
};

constant unsigned int primes2[] = {
    2,   3,  5,  7,
    11, 13, 17, 19,
    23, 29, 31, 37,
    41, 43, 47, 53,
};

float halton2(unsigned int i, unsigned int d) {
    unsigned int b = primes2[d];
    
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

inline float3 sampleAreaLight2(constant Light & light,
                            float2 u,
                            float3 position)
{
    u = u * 2.0f - 1.0f;

    float3 samplePosition = light.position +
                            light.right * u.x +
                            light.up * u.y;

    float3 lightDirection = samplePosition - position;

    float lightDistance = length(lightDirection);

    float inverseLightDistance = 1.0f / max(lightDistance, 1e-3f);

    lightDirection *= inverseLightDistance;
    
    float3 lightColor = light.color;
    lightColor *= (inverseLightDistance * inverseLightDistance);
    lightColor *= saturate(dot(-lightDirection, light.forward));
    
    return lightColor;
}

vertex RasterizerData basic_vertex_shader(const VertexIn vertexIn[[ stage_in ]], constant SceneConstants &sceneConstants [[ buffer(1) ]], constant ModelConstants &modelConstants [[ buffer(2) ]]) {
    
    RasterizerData rd;
    
    float4 worldPosition = modelConstants.modelMatrix * float4(vertexIn.position, 1);
    
    rd.position = sceneConstants.projectionMatrix * sceneConstants.viewMatrix * worldPosition;
    rd.uvCoordinate = vertexIn.uvCoordinate;
    
    rd.worldPosition = worldPosition.xyz;
    rd.surfaceNormal = (modelConstants.modelMatrix * float4(vertexIn.normal, 1)).xyz;

    rd.toCameraVector = sceneConstants.cameraPosition - worldPosition.xyz;
    
    return rd;
}

fragment half4 basic_fragment_shader(RasterizerData rd [[ stage_in ]], sampler sampler2d[[ sampler(0) ]], constant Material &material [[ buffer(0) ]], const device PrimitiveData *primitiveData [[ buffer(1) ]],
                                      constant unsigned int &textureId [[ buffer(2) ]], constant PSLight &psLight [[ buffer(3) ]], constant unsigned int &randomOffset [[ buffer(4) ]]){
    
    float4 color = material.color;

    if(material.isTextureEnabled){
        color = primitiveData[textureId].texture.sample(sampler2d, rd.uvCoordinate);
    }

    if(material.isLit) {
        color = material.color;
    } else {
//        float3 unitNormal = normalize(rd.surfaceNormal);
//        float3 unitToCameraVector = normalize(rd.toCameraVector);

        float3 totalAmbient = float3(0, 0, 0);
        float3 totalDiffuse = float3(0, 0, 0);
        float3 totalSpecular = float3(0, 0, 0);
        
        float2 r = float2(halton2(randomOffset, 0),
                          halton2(randomOffset, 1));

//        for(int i = 0 ; i < lightCount ; i++ ) {
        constant Light &lightData = psLight.light;
        
        // Ambinet
        totalAmbient += material.ambient + 0.1;
        
        // Diffuse
        totalDiffuse += sampleAreaLight2(lightData, r, rd.worldPosition);
            
//        }

        float3 phongIntensity = totalAmbient + totalDiffuse + totalSpecular;

        color *= float4(phongIntensity, 1.0);
    }
    
    if(color.a < 0.1) {
        discard_fragment(); // Find a better way, because this has performance hit.
    }
    
    return half4(color.r, color.g, color.b, color.a);
}
