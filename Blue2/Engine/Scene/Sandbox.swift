import MetalKit

class Sandbox: Scene {
    var camera = DebugCamera()
    
    override func buildScene() {
        addCamera(camera)
        addSolid(meshType: .Cube)
    }
    
    override func updateObjects(deltaTime: Float) {
        for solid in objects {
            solid.rotation.y+=deltaTime
            solid.rotation.x+=deltaTime
            solid.rotation.z+=deltaTime
            solid.update(deltaTime: deltaTime)
        }
    }
    
    func addSolid(meshType: MeshTypes) {
        let solid = Solid(meshType)
        super.addSolid(solid: solid)
    }
}
