import MetalKit

class Sandbox: StaticScene {
    var camera = DebugCamera()
    var totalTime:Float = 0
    
    init(drawableSize: CGSize) {
        super.init()
    }
    
    override func buildScene() {
        addCamera(camera)
        
        let spaceShip = Solid(.Chest)
        spaceShip.position = SIMD3<Float>(0, 50, 0)
//        spaceShip.rotation = SIMD3<Float>(0, 1.57, 0)
//        spaceShip.scale = SIMD3<Float>(repeating: 50)
        
        addSolid(solid: spaceShip)
    }
}
