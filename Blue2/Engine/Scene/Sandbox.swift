import MetalKit

class Sandbox: Scene {
    var camera = DebugCamera()
    var totalTime:Float = 0
    
    override func buildScene() {
        addCamera(camera)
        addSolid(meshType: .Cube)
    }
    
    override func updateObjects(deltaTime: Float) {
        totalTime+=deltaTime
        for solid in objects {
            solid.rotation.y+=deltaTime
            solid.rotation.x+=deltaTime
            solid.rotation.z+=deltaTime
            solid.scale = SIMD3<Float>(repeating: abs(sin(totalTime)))
            solid.position = SIMD3<Float>(1080, 680, 1080)
            solid.update(deltaTime: deltaTime)
        }
    }
    
    func addSolid(meshType: MeshTypes) {
        let solid = Solid(meshType)
        super.addSolid(solid: solid)
    }
}
