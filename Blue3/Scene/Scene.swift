import MetalKit

class Scene {
    
    internal var cameraManager = CameraManager()
    
    internal var vertices: [SIMD3<Float>] = []
    internal var colors: [SIMD3<Float>] = []
    internal var normals: [SIMD3<Float>] = []
    internal var masks: [uint] = []
    internal var reflectivities: [Float] = []
    internal var skyBox: MTLTexture!

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
    
    private func addSolid(solid: Solid, reflectivity: Float = -1, transform: matrix_float4x4) {
        let n = solid.mesh.vertices.count
        
        for i in 0..<n {
            let vertex = solid.mesh.vertices[i]
            var transformedVertex = vector4(vertex.x, vertex.y, vertex.z, 1.0)
            transformedVertex = transform * transformedVertex;
            vertices.append(SIMD3<Float>(transformedVertex.x, transformedVertex.y, transformedVertex.z))

            let normal = solid.mesh.normals[i]
            var transformedNormal = vector4(normal.x, normal.y, normal.z, 1.0)
            transformedNormal = normalize(transform * transformedNormal)
            normals.append(normal)
        }
        
        if reflectivity != -1 {
            for _ in 0..<(n/3) {
                reflectivities.append(reflectivity)
            }
        } else {
            reflectivities.append(contentsOf: solid.mesh.reflectivities)
        }
        
        colors.append(contentsOf: solid.mesh.colors)
        masks.append(contentsOf: solid.mesh.masks)
    }
    
    func addObject(solid: Solid, reflectivity: Float = -1, transform: matrix_float4x4 = matrix_identity_float4x4) {
        addSolid(solid: solid, reflectivity: reflectivity, transform: transform)
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
