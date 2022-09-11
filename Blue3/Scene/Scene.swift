import MetalKit

class Scene {
    
    internal var cameraManager = CameraManager()
    
    internal var vertices: [SIMD3<Float>] = []
    internal var colors: [SIMD3<Float>] = []
    internal var normals: [SIMD3<Float>] = []
    internal var triangleMasks: [uint32] = []
    internal var skyBox: MTLTexture!

    init(drawableSize: CGSize) {
        skyBox = nil
        buildScene()
    }
    
    func buildScene() {}
    
    func updateObjects(deltaTime: Float) {}
    
    private func addSolid(solid: Solid) {
        vertices.append(contentsOf: solid.mesh.vertices)
        colors.append(contentsOf: solid.mesh.colors)
        normals.append(contentsOf: solid.mesh.normals)
        triangleMasks.append(contentsOf: solid.mesh.masks)
    }
    
    func addObject(solid: Solid) {
        addSolid(solid: solid)
    }
    
    func addLight(solid: Solid, color: SIMD3<Float> = SIMD3<Float>(repeating: 1)) {
        
        solid.mesh.colors = []
        
        for _ in 0..<solid.mesh.vertices.count {
            solid.mesh.colors.append(color)
        }
        
        let triangleCount = solid.mesh.vertices.count / 3
        
        for _ in 0..<triangleCount {
            triangleMasks.append(Masks.TRIANGLE_MASK_LIGHT)
        }

        addSolid(solid: solid)
    }
    
    func addCamera(_ camera:Camera, _ setAsCurrentCamera: Bool = true) {
        cameraManager.registerCamera(camera: camera)
        if(setAsCurrentCamera) {
            cameraManager.setCamera(camera.cameraType)
        }
    }
    
    func updateCameras(deltaTime: Float) {
        cameraManager.update(deltaTime: deltaTime)
    }
}
