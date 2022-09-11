import MetalKit

class Sandbox: Scene {
    var camera = DebugCamera()
    var totalTime:Float = 0
    
    override func buildScene() {
        addCamera(camera)
        addObject(solid: Solid(.Cube))
//        addLight(solid: Solid(.Cube))
    }
    
    override func updateObjects(deltaTime: Float) {
    }

}
