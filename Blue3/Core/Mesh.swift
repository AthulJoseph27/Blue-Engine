import MetalKit

protocol Mesh {
    var vertices:          [SIMD3<Float>] { get set }
    var normals:           [SIMD3<Float>] { get }
    var colors:            [SIMD3<Float>] { get }
    var uvCoordinates:     [SIMD2<Float>] { get }
    var masks:             [uint]         { get }
}

class CustomMesh: Mesh {
    internal var vertices:              [SIMD3<Float>]
    internal var normals:               [SIMD3<Float>]
    internal var tangents:              [SIMD3<Float>]
    internal var bitangents:            [SIMD3<Float>]
    internal var colors:                [SIMD3<Float>]
    internal var submeshIds:            [uint]
    internal var uvCoordinates:         [SIMD2<Float>]
    internal var masks:                 [uint]
    internal var materials:             [Material]
    internal var baseColorTextures:     [MTLTexture?]
    internal var normalMapTextures:     [MTLTexture?]
    internal var metallicMapTextures:   [MTLTexture?]
    internal var roughnessMapTextures:  [MTLTexture?]
    
    init() {
        self.vertices = []
        self.normals = []
        self.tangents = []
        self.bitangents = []
        self.colors = []
        self.submeshIds = []
        self.uvCoordinates = []
        self.masks = []
        self.materials = []
        self.baseColorTextures = []
        self.normalMapTextures = []
        self.metallicMapTextures = []
        self.roughnessMapTextures = []
        createMesh()
    }
    
    func createMesh(){}
    
    func computeNormal(vertices: [SIMD3<Float>])->SIMD3<Float> {
        let AB = vertices[1] - vertices[0]
        let AC = vertices[2] - vertices[0]
        
        return normalize(cross(AB, AC))
    }
    
    func addTriangle(vertices: [SIMD3<Float>], uvCoords: [SIMD2<Float>]? = nil, color: SIMD3<Float> = SIMD3<Float>(0.2, 0.2, 0.8), normal: SIMD3<Float>? = nil, normals: [SIMD3<Float>] = [], tangents: [SIMD3<Float>] = [], bitangents: [SIMD3<Float>] = [], mask: uint32 = Masks.TRIANGLE_MASK_GEOMETRY, submeshId:Int = 0) {
        
        self.vertices.append(contentsOf: vertices)
        
        var nr = normal
        
        var _uvCoords = uvCoords ?? []

        if uvCoords == nil {
            for _ in 0..<3{
                _uvCoords.append(SIMD2<Float>(0, 0))
            }
        }
        
        uvCoordinates.append(contentsOf: _uvCoords)
        
        if normals.count == 0 {
            
            if nr == nil {
                nr = computeNormal(vertices: vertices)
            }
            
            for _ in 0..<3{
                self.normals.append(nr!)
                self.tangents.append(SIMD3<Float>(repeating: 1))
                self.bitangents.append(SIMD3<Float>(repeating: 1))
            }
        }else{
            self.normals.append(contentsOf: normals)
            self.tangents.append(contentsOf: tangents)
            self.bitangents.append(contentsOf: bitangents)
        }
        
        for _ in 0..<3{
            colors.append(color)
            submeshIds.append(uint(submeshId))
        }
        
        masks.append(mask)
    }
}

class TriangleMesh : CustomMesh {
    override func createMesh() {
        let vertices = [
            SIMD3<Float>(0, 10, -20),
            SIMD3<Float>(-10 , -10, -20),
            SIMD3<Float>(10, -10, -20)
        ]
        addTriangle(vertices: vertices, uvCoords: [SIMD2<Float>(0.5, 0.5), SIMD2<Float>(0, 1), SIMD2<Float>(1, 1)], color: SIMD3<Float>(0, 1, 0))
    }
    
}

class QuadMesh : CustomMesh {
    override func createMesh() {
        let vertices = [
            SIMD3<Float>( 0, 0, -20),
            SIMD3<Float>( 0, 10, -20),
            SIMD3<Float>(10, 0, -20),
            SIMD3<Float>(10, 10, -20),
        ]
        addTriangle(vertices: [vertices[0], vertices[3], vertices[1]], uvCoords: [SIMD2<Float>(0, 1), SIMD2<Float>(1, 0), SIMD2<Float>(1, 1)])
        addTriangle(vertices: [vertices[0], vertices[2], vertices[3]], uvCoords: [SIMD2<Float>(0, 1), SIMD2<Float>(0, 0), SIMD2<Float>(1, 0)])
    }
}

class CubeMesh : CustomMesh {
    override func createMesh() {
        let vertices = [
            SIMD3<Float>(-540,-540,-540), // 0 0 0; 0
            SIMD3<Float>( 540,-540,-540), // 1 0 0; 1
            SIMD3<Float>( 540,-540, 540), // 1 0 1; 2
            SIMD3<Float>(-540,-540, 540), // 0 0 1; 3
            
            SIMD3<Float>(-540, 540,-540), // 0 1 0; 4
            SIMD3<Float>( 540, 540,-540), // 1 1 0; 5
            SIMD3<Float>( 540, 540, 540), // 1 1 1; 6
            SIMD3<Float>(-540, 540, 540), // 0 1 1; 7
        ]
        
        //Bottom Face
        addTriangle(vertices: [vertices[0], vertices[3], vertices[2]], color: SIMD3<Float>(1, 0, 0), normal: SIMD3<Float>(0, -1, 0))
        addTriangle(vertices: [vertices[0], vertices[2], vertices[1]], color: SIMD3<Float>(0, 1, 0), normal: SIMD3<Float>(0, -1, 0))
        
        //Top Face
        addTriangle(vertices: [vertices[4], vertices[7], vertices[6]], color: SIMD3<Float>(0, 0, 1), normal: SIMD3<Float>(0, 1, 0))
        addTriangle(vertices: [vertices[4], vertices[5], vertices[6]], color: SIMD3<Float>(1, 0, 0), normal: SIMD3<Float>(0, 1, 0))
        
        //Front Face
        addTriangle(vertices: [vertices[0], vertices[5], vertices[4]], color: SIMD3<Float>(0, 1, 0), normal: SIMD3<Float>(0, 0, 1))
        addTriangle(vertices: [vertices[0], vertices[1], vertices[5]], color: SIMD3<Float>(0, 0, 1), normal: SIMD3<Float>(0, 0, 1))
        
        //Back Face
        addTriangle(vertices: [vertices[3], vertices[7], vertices[6]], color: SIMD3<Float>(1, 0, 0), normal: SIMD3<Float>(0, 0, -1))
        addTriangle(vertices: [vertices[3], vertices[6], vertices[2]], color: SIMD3<Float>(0, 1, 0), normal: SIMD3<Float>(0, 0, -1))
        
        //Left Face
        addTriangle(vertices: [vertices[0], vertices[4], vertices[7]], color: SIMD3<Float>(0, 0, 1), normal: SIMD3<Float>(-1, 0, 0))
        addTriangle(vertices: [vertices[0], vertices[7], vertices[3]], color: SIMD3<Float>(1, 0, 0), normal: SIMD3<Float>(-1, 0, 0))
        
        //Right Face
        addTriangle(vertices: [vertices[1], vertices[6], vertices[5]], color: SIMD3<Float>(0, 1, 0), normal: SIMD3<Float>(1, 0, 0))
        addTriangle(vertices: [vertices[1], vertices[2], vertices[6]], color: SIMD3<Float>(0, 0, 1), normal: SIMD3<Float>(1, 0, 0))
        
    }
}

class ModelMesh: CustomMesh {
//    private var _meshes: [Any]!
    private var modelName: String!

    init(modelName: String) {
        self.modelName = modelName
        super.init()
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
        
        if let ambient = mdlMaterial!.property(with: .emission)?.float3Value { _material.ambient = ambient }
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
            
            if baseColorTextures.last == nil {
                material.isTextureEnabled = false
            }
            
            if normalMapTextures.last == nil {
                material.isNormalMapEnabled = false
            }
            
            if metallicMapTextures.last == nil {
                material.isMetallicMapEnabled = false
            }
            
            if roughnessMapTextures.last == nil {
                material.isRoughnessMapEnabled = false
            }
            
            materials.append(material)
        }
        
        let mtkMesh = mtkSubmesh.mesh!
        
        let vertexData = mtkMesh.vertexBuffers[0].buffer.contents()
        var pointer = vertexData.bindMemory(to: VertexIn.self, capacity: 1)
        var count = mtkMesh.vertexCount
        
        var vertices:   [SIMD3<Float>] = []
        var uvCoords:   [SIMD2<Float>] = []
        var normals:    [SIMD3<Float>] = []
        var tangents:   [SIMD3<Float>] = []
        var bitangents: [SIMD3<Float>] = []
        
        for _ in 0..<count {
            vertices.append(pointer.pointee.position)
            uvCoords.append(pointer.pointee.uvCoordinate)
            normals.append(pointer.pointee.normal)
            tangents.append(pointer.pointee.tangent)
            bitangents.append(pointer.pointee.bitangent)
            pointer = pointer.advanced(by: 1)
        }
        
        let indexBuffer = mtkSubmesh.indexBuffer.buffer.contents()
        var indexPointer = indexBuffer.bindMemory(to: UInt32.self, capacity: 1)
        indexPointer = indexPointer.advanced(by: mtkSubmesh.indexBuffer.offset)
        
        count = mtkSubmesh.indexCount/3
        
        for _ in 0..<count {
            var triangleVertices:   [SIMD3<Float>] = []
            var triangleUVCoords:   [SIMD2<Float>] = []
            var triangleNormals:    [SIMD3<Float>] = []
            var triangleTangents:   [SIMD3<Float>] = []
            var triangleBitangents: [SIMD3<Float>] = []
            
            for _ in 0..<3 {
                let index = Int(indexPointer.pointee)
                triangleVertices.append(vertices[index])
                triangleUVCoords.append(uvCoords[index])
                triangleNormals.append(normals[index])
                triangleTangents.append(tangents[index])
                triangleBitangents.append(bitangents[index])
                indexPointer = indexPointer.advanced(by: 1)
            }
            addTriangle(vertices: triangleVertices, uvCoords: triangleUVCoords, normals: triangleNormals, tangents: triangleTangents, bitangents: triangleBitangents, submeshId: submeshId)
        }
        
    }
    
    private func loadModel() {
        guard let assetURL = Bundle.main.url(forResource: modelName, withExtension: "obj") else {
            fatalError("Asset \(String(describing: modelName)) does not exist.")
                }
                
        let descriptor = MTKModelIOVertexDescriptorFromMetal(VertexDescriptorLibrary.getDescriptor(.Read))
               (descriptor.attributes[0] as! MDLVertexAttribute).name = MDLVertexAttributePosition
               (descriptor.attributes[1] as! MDLVertexAttribute).name = MDLVertexAttributeTextureCoordinate
               (descriptor.attributes[2] as! MDLVertexAttribute).name = MDLVertexAttributeNormal

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
                
        for i in 0..<mtkMeshes[0].submeshes.count {
            let mtkSubmesh = mtkMeshes[0].submeshes[i]
            let mdlSubmesh = mdlMeshes[0].submeshes![i] as! MDLSubmesh
            
            addMesh(mtkSubmesh: mtkSubmesh, mdlMesh: mdlSubmesh, submeshId: i)
        }
    }
    
    override func createMesh() {
        loadModel()
    }
}
