#include <metal_stdlib>
using namespace metal;

struct VertexIn {
    float3 position        [[ attribute(0) ]];
    float3 color           [[ attribute(1) ]];
    float2 uvCoordinate    [[ attribute(2) ]];
    uint textureId         [[ attribute(3) ]];
    uint materialId        [[ attribute(4) ]];
    uint modelConstantId   [[ attribute(5) ]];
    float3 normal          [[ attribute(6) ]];
};

struct RasterizerData {
    float4 position [[ position ]];
    float4 color;
    float2 uvCoordinate;
    uint textureId  [[ id(0) ]];
    uint materialId [[ id(1) ]];
    
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

struct Light {
    float3 position             [[ attribute(0) ]];
    float3 color                [[ attribute(1) ]];
    
    float brightness            [[ attribute(2) ]];
    float ambientIntensity      [[ attribute(3) ]];
    float diffuseIntensity      [[ attribute(4) ]];
    float specularIntensity     [[ attribute(5) ]];
};

vertex RasterizerData basic_vertex_shader(const VertexIn vertexIn[[ stage_in ]], constant SceneConstants &sceneConstants [[ buffer(1) ]], const device ModelConstants* modelConstants [[ buffer(2) ]]) {
    
    RasterizerData rd;
    
    float4 worldPosition = modelConstants[vertexIn.modelConstantId].modelMatrix * float4(vertexIn.position, 1);
    
    rd.position = sceneConstants.projectionMatrix * sceneConstants.viewMatrix * worldPosition;
    rd.color = float4(vertexIn.color, 1);
    rd.uvCoordinate = vertexIn.uvCoordinate;
    rd.textureId = vertexIn.textureId;
    rd.materialId = vertexIn.materialId;
    
    rd.worldPosition = worldPosition.xyz;
    rd.surfaceNormal = (modelConstants[vertexIn.modelConstantId].modelMatrix * float4(vertexIn.normal, 1)).xyz;

    rd.toCameraVector = sceneConstants.cameraPosition - worldPosition.xyz;
    
    return rd;
}

fragment half4 basic_fragment_shader(RasterizerData rd [[ stage_in ]], sampler sampler2d[[ sampler(0) ]], const device Material* materials [[ buffer(0) ]], const device PrimitiveData* primitiveData [[ buffer(1) ]], constant Light* lightDatas [[ buffer(2) ]], constant int &lightCount [[ buffer(3) ]]){
    float4 color = materials[rd.materialId].color;
    
    if(materials[rd.materialId].isTextureEnabled){
        color = primitiveData[rd.textureId].texture.sample(sampler2d, rd.uvCoordinate);
    }
    
    if(materials[rd.materialId].isLit) {
        float3 unitNormal = normalize(rd.surfaceNormal);
        float3 unitToCameraVector = normalize(rd.toCameraVector);
        
        float3 totalAmbient = float3(0, 0, 0);
        float3 totalDiffuse = float3(0, 0, 0);
        float3 totalSpecular = float3(0, 0, 0);
        
        for(int i = 0 ; i < lightCount ; i++ ) {
            Light lightData = lightDatas[i];
            
            float3 unitToLightVector = normalize(lightData.position - rd.worldPosition);
            float3 unitReflectionVector = normalize(reflect(-unitToLightVector, unitNormal));
            //Ambient
            float3 ambientness = materials[rd.materialId].ambient * lightData.ambientIntensity;
            float3 ambientColor = ambientness * lightData.color;
            totalAmbient += ambientColor;
            
            // Diffuse
            float3 diffuseness = materials[rd.materialId].diffuse * lightData.diffuseIntensity;
            float nDotL = max(dot(unitNormal, unitToLightVector), 0.0);
            float3 diffuseColor = clamp(diffuseness * nDotL * lightData.color, 0.0, 1.0);
            totalDiffuse += diffuseColor;
            
            // Specular
            float3 specularness = materials[rd.materialId].specular * lightData.specularIntensity;
            float rDotV = max(dot(unitReflectionVector , unitToCameraVector), 0.0);
            float specularExp = pow(rDotV, materials[rd.materialId].shininess);
            float3 specularColor = clamp(specularness * specularExp * lightData.color * lightData.brightness, 0.0, 1.0);
            totalSpecular+=specularColor;
        }
        
        float3 phongIntensity = totalAmbient + totalDiffuse + totalSpecular;
        
        color *= float4(phongIntensity, 1.0);
    }
    
    
    return half4(color.r, color.g, color.b, color.a);
}
