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
        
        let spaceShip2 = Solid(.SpaceShip)
        spaceShip2.position = SIMD3<Float>(150, 50, 0)
        spaceShip2.rotation = SIMD3<Float>(0, 1.57, 0)
        spaceShip2.scale = SIMD3<Float>(repeating: 20)
        
        addSolid(solid: spaceShip2)
    }
}
