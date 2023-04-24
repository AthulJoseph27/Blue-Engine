import MetalKit
import SceneKit

class Mesh {
    private var modelName:  String!
    private var modelExtension: String!
    private var materialMap: [String : MDLMaterial] = [:]
    private var submeshIds: [uint]
    
    internal var submeshCount:          Int
    internal var vertexBuffer:          MTLBuffer!
    internal var indexBuffers:          [MTLBuffer]
    internal var materials:             [Material]
    internal var baseColorTextures:     [MTLTexture?]
    internal var normalMapTextures:     [MTLTexture?]
    internal var metallicMapTextures:   [MTLTexture?]
    internal var roughnessMapTextures:  [MTLTexture?]
    
    init(modelName: String, modelExtension: String = "obj") {
        self.modelName = modelName
        self.modelExtension = modelExtension
        indexBuffers = []
        submeshIds = []
        materials = []
        baseColorTextures = []
        normalMapTextures = []
        metallicMapTextures = []
        roughnessMapTextures = []
        submeshCount = 0
        if modelName != "None" {
            try? loadModel()
        }
    }
    
    init(modelPath: String) throws {
        var baseUrl = URL(fileURLWithPath: modelPath)
        self.modelName = baseUrl.lastPathComponent
        self.modelExtension = baseUrl.pathExtension
        baseUrl.deleteLastPathComponent()
        let url = URL(fileURLWithPath: self.modelName, relativeTo: baseUrl)
        
        indexBuffers = []
        submeshIds = []
        materials = []
        baseColorTextures = []
        normalMapTextures = []
        metallicMapTextures = []
        roughnessMapTextures = []
        submeshCount = 0
        do {
            try loadModel(url: url)
        } catch let error {
            throw error
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
        var _material = Material(isLit: false)
        
        if mdlMaterial == nil {
            return _material
        }
        
        if let ambient = mdlMaterial!.property(with: .emission)?.float3Value  { _material.ambient = ambient }
        if let diffuse = mdlMaterial!.property(with: .baseColor)?.float3Value { _material.diffuse = diffuse }
        if let specular = mdlMaterial!.property(with: .specular)?.float3Value { _material.specular = specular }
        if let shininess = mdlMaterial!.property(with: .specularExponent)?.floatValue { _material.shininess = shininess }
        if let opacity = mdlMaterial!.property(with: .opacity)?.floatValue { _material.opacity = opacity }
        if let opticalDensity = mdlMaterial!.property(with: .materialIndexOfRefraction)?.floatValue { _material.opticalDensity = opticalDensity }
        if let roughness = mdlMaterial!.property(with: .roughness)?.floatValue { _material.roughness = roughness }
        
        let _mdlMaterial = materialMap[mdlMaterial!.name]
        if _mdlMaterial != nil {
            _material.emissive = _mdlMaterial!.property(with: .emission)!.float3Value
        }
        
        if (_material.emissive.x + _material.emissive.y + _material.emissive.z) > 0 {
            _material.isLit = true
        }
        
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
//            print(mdlMesh.material?.name)
//            print(material)
//            print("")
        }
        
        indexBuffers.append(mtkSubmesh.indexBuffer.buffer)
        submeshCount+=1
    }
    
    private func loadMaterials(url: URL? = nil) {
        let fileURL = url ?? Bundle.main.url(forResource: modelName, withExtension: "mtl")!
        let mtlString = try! String(contentsOf: fileURL)

        let scanner = Scanner(string: mtlString)
        var currentMaterial: MDLMaterial?
        
        var materialName = ""

        while !scanner.isAtEnd {
            var line: String?
            line = scanner.scanUpToString("\n")
            
            if let line = line {
                let components = line.components(separatedBy: .whitespaces)
                
                switch components[0] {
                case "newmtl":
                    materialName = components[1]
                    currentMaterial = MDLMaterial(name: materialName, scatteringFunction: MDLScatteringFunction())
                case "Ke":
                    let emission = SIMD3<Float>(Float(components[1])!, Float(components[2])!, Float(components[3])!)
                    currentMaterial!.setProperty(MDLMaterialProperty(name: "Ke", semantic: .emission, float3: emission))
                default:
                    break
                }
            }
        }
        
        if !materialName.isEmpty {
            materialMap[materialName] = currentMaterial
        }
    }
    
    private func loadModel(url: URL? = nil) throws {
        var _url: URL?
        
        if url != nil {
            _url = url
        } else {
            _url = Bundle.main.url(forResource: modelName, withExtension: modelExtension)
        }
        
        guard let assetURL = _url else {
            throw MeshError.loadFailed("Asset \(String(describing: modelName)) does not exist.")
        }
        
        do {
            if modelExtension == "obj" {
                if url != nil {
                    let mtlFileName = String(modelName).replacingOccurrences(of: ".obj", with: ".mtl")
                    let mtlURL = URL(fileURLWithPath: mtlFileName, relativeTo: url?.baseURL)
                    loadMaterials(url: mtlURL)
                } else {
                    loadMaterials()
                }
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
                throw MeshError.loadFailed("ERROR::LOADING_MESH::__\(String(describing: modelName))__::\(error)")
            }
            
            var mtkMeshes: [MTKMesh] = []
            
            for mdlMesh in mdlMeshes {
                mdlMesh.addTangentBasis(forTextureCoordinateAttributeNamed: MDLVertexAttributeTextureCoordinate, tangentAttributeNamed: MDLVertexAttributeBitangent, bitangentAttributeNamed: MDLVertexAttributeTangent)
                mdlMesh.vertexDescriptor = descriptor
                
                do {
                    let mtkMesh = try MTKMesh(mesh: mdlMesh, device: Engine.device)
                    mtkMeshes.append(mtkMesh)
                } catch {
                    throw MeshError.loadFailed("ERROR::LOADING_MESH::__\(String(describing: modelName))__::\(error)")
                }
            }
            
            if mtkMeshes.count == 0 {
                throw MeshError.loadFailed("ERROR::LOADING_MESH::__NO DATA__")
            }
            
            vertexBuffer = mtkMeshes[0].vertexBuffers[0].buffer
            
            for i in 0..<mtkMeshes[0].submeshes.count {
                let mtkSubmesh = mtkMeshes[0].submeshes[i]
                let mdlSubmesh = mdlMeshes[0].submeshes![i] as! MDLSubmesh
                
                addMesh(mtkSubmesh: mtkSubmesh, mdlMesh: mdlSubmesh, submeshId: i)
            }
        } catch let error {
            throw error
        }
    }
}

enum MeshError: Error {
    case loadFailed(String)
}
