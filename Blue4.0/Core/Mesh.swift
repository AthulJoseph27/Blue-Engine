import MetalKit

class Mesh {
    private var modelName:  String!
    private var submeshIds: [uint]
    
    internal var submeshCount:          Int
    internal var vertexBuffer:          MTLBuffer!
    internal var indexBuffers:          [MTLBuffer]
    internal var materials:             [Material]
    internal var baseColorTextures:     [MTLTexture?]
    internal var normalMapTextures:     [MTLTexture?]
    internal var metallicMapTextures:   [MTLTexture?]
    internal var roughnessMapTextures:  [MTLTexture?]
    
    init(modelName: String) {
        self.modelName = modelName
        indexBuffers = []
        submeshIds = []
        materials = []
        baseColorTextures = []
        normalMapTextures = []
        metallicMapTextures = []
        roughnessMapTextures = []
        submeshCount = 0
        if modelName != "None" {
            loadModel()
        }
    }
    
    private func getTexture(for semantic: MDLMaterialSemantic,
                             in material: MDLMaterial?,
                             textureOrigin: MTKTextureLoader.Origin) -> MTLTexture? {
            let textureLoader = MTKTextureLoader(device: Engine.device)
            guard let materialProperty = material?.property(with: semantic) else { return nil }
            guard let sourceTexture = materialProperty.textureSamplerValue?.texture else { return nil }
        let options: [MTKTextureLoader.Option : Any] = [
                MTKTextureLoader.Option.origin : textureOrigin as Any,
                MTKTextureLoader.Option.generateMipmaps : true,
            ]
        
            let tex = try? textureLoader.newTexture(texture: sourceTexture, options: options)
            return tex
        }
    
    private func getMaterial(_ mdlMaterial: MDLMaterial?)->Material {
        var _material = Material(isLit: true)
        
        if mdlMaterial == nil {
            return _material
        }
        
        if let ambient = mdlMaterial!.property(with: .emission)?.float3Value  { _material.ambient = ambient }
        if let diffuse = mdlMaterial!.property(with: .baseColor)?.float3Value { _material.diffuse = diffuse }
        if let specular = mdlMaterial!.property(with: .specular)?.float3Value { _material.specular = specular }
        if let emission = mdlMaterial!.property(with: .emission)?.float3Value { _material.emissive = emission }
        if let shininess = mdlMaterial!.property(with: .specularExponent)?.floatValue { _material.shininess = shininess }
        if let opacity = mdlMaterial!.property(with: .opacity)?.floatValue { _material.opacity = opacity }
        if let opticalDensity = mdlMaterial!.property(with: .materialIndexOfRefraction)?.floatValue { _material.opticalDensity = opticalDensity }
        if let roughness = mdlMaterial!.property(with: .roughness)?.floatValue { _material.roughness = roughness }
        
        return _material
    }
    
    private func addMesh(mtkSubmesh: MTKSubmesh!, mdlMesh: MDLSubmesh, submeshId: Int) {
        if mtkSubmesh.mesh == nil {
            return
        }
        
        if submeshIds.isEmpty || submeshIds.last! != submeshId {
            // Add new Texture
            baseColorTextures.append(getTexture(for: .baseColor, in: mdlMesh.material, textureOrigin: .bottomLeft))
            normalMapTextures.append(getTexture(for: .objectSpaceNormal, in: mdlMesh.material, textureOrigin: .bottomLeft))
            metallicMapTextures.append(getTexture(for: .metallic , in: mdlMesh.material, textureOrigin: .bottomLeft))
            roughnessMapTextures.append(getTexture(for: .roughness, in: mdlMesh.material, textureOrigin: .bottomLeft))
            
            var material = getMaterial(mdlMesh.material)
            
            if baseColorTextures.last??.arrayLength == nil {
                material.isTextureEnabled = false
            }
            
            if normalMapTextures.last??.arrayLength == nil {
                material.isNormalMapEnabled = false
            }
            
            if metallicMapTextures.last??.arrayLength == nil {
                material.isMetallicMapEnabled = false
            }
            
            if roughnessMapTextures.last??.arrayLength == nil {
                material.isRoughnessMapEnabled = false
            }
            
            materials.append(material)
        }
        
        indexBuffers.append(mtkSubmesh.indexBuffer.buffer)
        submeshCount+=1
    }
    
    private func loadModel() {
        guard let assetURL = Bundle.main.url(forResource: modelName, withExtension: "obj") else {
            fatalError("Asset \(String(describing: modelName)) does not exist.")
                }
                
        let descriptor = MTKModelIOVertexDescriptorFromMetal(VertexDescriptorLibrary.getDescriptor(.Read))
               (descriptor.attributes[0] as! MDLVertexAttribute).name = MDLVertexAttributePosition
               (descriptor.attributes[1] as! MDLVertexAttribute).name = MDLVertexAttributeTextureCoordinate
               (descriptor.attributes[2] as! MDLVertexAttribute).name = MDLVertexAttributeNormal
               (descriptor.attributes[3] as! MDLVertexAttribute).name = MDLVertexAttributeTangent
               (descriptor.attributes[4] as! MDLVertexAttribute).name = MDLVertexAttributeBitangent

        let bufferAllocator = MTKMeshBufferAllocator(device: Engine.device)
        let asset: MDLAsset = MDLAsset(url: assetURL,
                                       vertexDescriptor: descriptor,
                                       bufferAllocator: bufferAllocator,
                                       preserveTopology: true,
                                       error: nil)
        asset.loadTextures()
        
        var mdlMeshes: [MDLMesh] = []
        do{
            mdlMeshes = try MTKMesh.newMeshes(asset: asset,
                                                   device: Engine.device).modelIOMeshes
            
        } catch {
            print("ERROR::LOADING_MESH::__\(String(describing: modelName))__::\(error)")
        }
        
        var mtkMeshes: [MTKMesh] = []
        
        for mdlMesh in mdlMeshes {
            mdlMesh.addTangentBasis(forTextureCoordinateAttributeNamed: MDLVertexAttributeTextureCoordinate, tangentAttributeNamed: MDLVertexAttributeBitangent, bitangentAttributeNamed: MDLVertexAttributeTangent)
            mdlMesh.vertexDescriptor = descriptor
            
            do {
                let mtkMesh = try MTKMesh(mesh: mdlMesh, device: Engine.device)
                mtkMeshes.append(mtkMesh)
            } catch {
                print("ERROR::LOADING_MESH::__\(String(describing: modelName))__::\(error)")
            }
        }
        
        vertexBuffer = mtkMeshes[0].vertexBuffers[0].buffer
        
        for i in 0..<mtkMeshes[0].submeshes.count {
            let mtkSubmesh = mtkMeshes[0].submeshes[i]
            let mdlSubmesh = mdlMeshes[0].submeshes![i] as! MDLSubmesh
            
            addMesh(mtkSubmesh: mtkSubmesh, mdlMesh: mdlSubmesh, submeshId: i)
        }
    }
}
