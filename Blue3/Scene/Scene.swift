import MetalKit

class Scene {
    
    internal var cameraManager = CameraManager()
    
    internal var vertices: [SIMD3<Float>] = []
    internal var uvCoordinates: [SIMD2<Float>] = []
    internal var colors: [SIMD3<Float>] = []
    internal var normals: [SIMD3<Float>] = []
    internal var masks: [uint] = []
    internal var reflectivities: [Float] = []
    internal var refractiveIndices: [Float] = []
    internal var skyBox: MTLTexture!
    internal var textures: [MTLTexture?] = []
    internal var textureIds: [uint] = []
    internal var materials: [Material] = []
    internal var materialIds: [uint] = []

    init(drawableSize: CGSize) {
        skyBox = Skyboxibrary.skybox(.Jungle)
        buildScene()
    }
    
    func buildScene() {}
    
    func updateObjects(deltaTime: Float) {}
    
    func getTriangleNormal(v0: SIMD3<Float>, v1: SIMD3<Float>, S v2: SIMD3<Float>) -> SIMD3<Float> {
        let e1: SIMD3<Float> = normalize(v1 - v0);
        let e2: SIMD3<Float> = normalize(v2 - v0);
        
        return cross(e1, e2);
    }
    
    func getTriangleNormal(v: [SIMD3<Float>]) -> SIMD3<Float> {
        let e1: SIMD3<Float> = normalize(v[1] - v[0]);
        let e2: SIMD3<Float> = normalize(v[2] - v[0]);
        
        return cross(e1, e2);
    }
    
    private func addSolid(solid: Solid, reflectivity: Float = -1, refractiveIndex: Float = -1, transform: matrix_float4x4) {
        
        let n = solid.mesh.vertices.count
        let start = vertices.count
        
        for i in 0..<n {
            let vertex = solid.mesh.vertices[i]
            var transformedVertex = vector4(vertex.x, vertex.y, vertex.z, 1.0)
            transformedVertex = transform * transformedVertex;
            vertices.append(SIMD3<Float>(transformedVertex.x, transformedVertex.y, transformedVertex.z))
            
            if(i<solid.mesh.uvCoordinates.count) {
                uvCoordinates.append(solid.mesh.uvCoordinates[i])
            }
        }
        
        for i in 0..<(n/3) {
            let j = i*3
            let normal = getTriangleNormal(v0: vertices[start+j], v1: vertices[start+j+1], S: vertices[start+j+2])
            for _ in 0..<3{
                normals.append(normal)
            }
        }
        
        if reflectivity != -1 {
            for _ in 0..<(n/3) {
                reflectivities.append(reflectivity)
            }
        } else {
            reflectivities.append(contentsOf: solid.mesh.reflectivities)
        }
        
        for _ in 0..<(n/3) {
            refractiveIndices.append(refractiveIndex)
        }
        
        colors.append(contentsOf: solid.mesh.colors)
        masks.append(contentsOf: solid.mesh.masks)
        
        let nextTextureId = uint(textures.count)
        
        for i in solid.mesh.submeshIds {
            textureIds.append(nextTextureId + i)
        }
        
//        for tex in solid.mesh.baseColorTextures {
//            if tex == nil {
//                textures.append(nil)
//                continue
//            }
//
//            let textureDescriptor = MTLTextureDescriptor()
//            textureDescriptor.pixelFormat = tex!.pixelFormat
//            textureDescriptor.textureType = .type2D
//            textureDescriptor.width = tex!.width
//            textureDescriptor.height = tex!.height
//            textureDescriptor.usage = .shaderRead
//            textureDescriptor.storageMode = .shared
//
//            let region = MTLRegionMake2D(0, 0, tex!.width, tex!.height)
//
//            if tex!.buffer?.contents() == nil {
//                textures.append(nil)
//                continue
//            }
//
//            let pixelData = tex!.buffer?.contents()
//            let pixelBytes = pixelData?.bindMemory(to: Float.self, capacity: tex!.bufferBytesPerRow * tex!.height)
////
//            let newTexture = Engine.device.makeTexture(descriptor: textureDescriptor)!
//            newTexture.replace(region: region, mipmapLevel: 0, withBytes: pixelBytes!, bytesPerRow: tex!.bufferBytesPerRow)
//
//            textures.append(tex)
//        }
        
        textures.append(contentsOf: solid.mesh.baseColorTextures)
        
        let nextMaterialId = uint(materials.count)
        
        for i in solid.mesh.submeshIds {
            materialIds.append(nextMaterialId + i)
        }
        
//        print(solid.mesh.submeshIds)
        materials.append(contentsOf: solid.mesh.materials)
    }
    
    func addObject(solid: Solid, reflectivity: Float = -1, refractiveIndex: Float = -1, transform: matrix_float4x4 = matrix_identity_float4x4) {
        addSolid(solid: solid, reflectivity: reflectivity, refractiveIndex: refractiveIndex, transform: transform)
    }
    
    func addLight(solid: Solid, color: SIMD3<Float> = SIMD3<Float>(repeating: 1), transform: matrix_float4x4 = matrix_identity_float4x4) {
        
        solid.mesh.colors = []
        
        for _ in 0..<solid.mesh.vertices.count {
            solid.mesh.colors.append(color)
        }
        
        let triangleCount = solid.mesh.vertices.count / 3
        solid.mesh.masks = []
        for _ in 0..<triangleCount {
            solid.mesh.masks.append(Masks.TRIANGLE_MASK_LIGHT)
        }
        
        addSolid(solid: solid, reflectivity: -1, transform: transform)
    }
    
    func addCamera(_ camera: SceneCamera, _ setAsCurrentCamera: Bool = true) {
        cameraManager.registerCamera(camera: camera)
        if(setAsCurrentCamera) {
            cameraManager.setCamera(camera.cameraType)
        }
    }
    
    func updateCameras(deltaTime: Float) {
        cameraManager.update(deltaTime: deltaTime)
    }
}
