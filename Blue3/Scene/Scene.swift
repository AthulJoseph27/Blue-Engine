import MetalKit

class Scene {
    
    internal var cameraManager = CameraManager()
    
    internal var vertices: [SIMD3<Float>] = []
    internal var uvCoordinates: [SIMD2<Float>] = []
    internal var colors: [SIMD3<Float>] = []
    internal var normals: [SIMD3<Float>] = []
    internal var tangents: [SIMD3<Float>] = []
    internal var bitangents: [SIMD3<Float>] = []
    internal var masks: [uint] = []
    internal var skyBox: MTLTexture!
    internal var textures: [MTLTexture?] = []
    internal var normalMapTextures: [MTLTexture?] = []
    internal var metallicMapTextures: [MTLTexture?] = []
    internal var roughnessMapTextures: [MTLTexture?] = []
    internal var textureIds: [uint] = []
    internal var materials: [Material] = []
    internal var materialIds: [uint] = []
    internal var modelConstants: [ModelConstants] = []
    internal var modelConstantIds: [uint] = []
    internal var objects: [Solid] = []
    internal var lightSources: [Light] = []
    
    internal var deltaRotation = SIMD3<Float>(repeating: 0);

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
    
    private func addSolid(solid: Solid, transform: matrix_float4x4) {
        
        let n = solid.mesh.vertices.count
//        let start = vertices.count
        
        let nextModelConstantId = uint(modelConstants.count)
        modelConstants.append(solid.modelContants)
        
        for i in 0..<n {
            let vertex = solid.mesh.vertices[i]
            var transformedVertex = vector4(vertex.x, vertex.y, vertex.z, 1.0)
            transformedVertex = transform * transformedVertex;
            vertices.append(SIMD3<Float>(transformedVertex.x, transformedVertex.y, transformedVertex.z))
            modelConstantIds.append(nextModelConstantId)
            
            if(i<solid.mesh.uvCoordinates.count) {
                uvCoordinates.append(solid.mesh.uvCoordinates[i])
            }
        }
        
//        for i in 0..<(n/3) {
//            let j = i*3
//            let normal = getTriangleNormal(v0: vertices[start+j], v1: vertices[start+j+1], S: vertices[start+j+2])
//            for _ in 0..<3{
//                normals.append(normal)
//            }
//        }
        normals.append(contentsOf: solid.mesh.normals)
        tangents.append(contentsOf: solid.mesh.tangents)
        bitangents.append(contentsOf: solid.mesh.bitangents)
        
        colors.append(contentsOf: solid.mesh.colors)
        masks.append(contentsOf: solid.mesh.masks)
        
        let nextTextureId = uint(textures.count)
        for i in solid.mesh.submeshIds {
            textureIds.append(nextTextureId + i)
        }
        
        textures.append(contentsOf: solid.mesh.baseColorTextures)
        normalMapTextures.append(contentsOf: solid.mesh.normalMapTextures)
        metallicMapTextures.append(contentsOf: solid.mesh.metallicMapTextures)
        roughnessMapTextures.append(contentsOf: solid.mesh.normalMapTextures)
        
        assert(textures.count == normalMapTextures.count && textures.count == metallicMapTextures.count && roughnessMapTextures.count == textures.count)
        
        
        let nextMaterialId = uint(materials.count)
        
        for i in solid.mesh.submeshIds {
            materialIds.append(nextMaterialId + i)
        }
        
        materials.append(contentsOf: solid.mesh.materials)
        objects.append(solid)
    }
    
    func addObject(solid: Solid, transform: matrix_float4x4 = matrix_identity_float4x4) {
        addSolid(solid: solid, transform: transform)
    }
    
    func addLight(light: Light, color: SIMD3<Float> = SIMD3<Float>(repeating: 1), transform: matrix_float4x4 = matrix_identity_float4x4) {
        
        light.mesh.colors = []
        
        for _ in 0..<light.mesh.vertices.count {
            light.mesh.colors.append(color)
        }
        
        let triangleCount = light.mesh.vertices.count / 3
        light.mesh.masks = []
        for _ in 0..<triangleCount {
            light.mesh.masks.append(Masks.TRIANGLE_MASK_LIGHT)
        }
        
        addSolid(solid: light, transform: transform)
        lightSources.append(light)
        objects.append(light)

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
    
    func updateScene(deltaTime: Float) {
        deltaRotation.x += Mouse.getDWheelX()
        deltaRotation.y += Mouse.getDWheelY()
    }
}
