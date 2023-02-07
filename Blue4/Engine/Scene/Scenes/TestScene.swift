import MetalKit
import MetalPerformanceShaders

class TestScene: GameScene {
    
    override func buildScene() {
        
        let monkey = Solid(.Monkey)
        monkey.position = SIMD3<Float>(0.3275, 0.3, 0.3725)
        monkey.rotation = SIMD3<Float>(0, -0.3, 0)
        monkey.scale = SIMD3<Float>(0.3, 0.3, 0.3)
        monkey.setColor(SIMD4<Float>(0.2, 0.2, 0.8, 1.0))
        monkey.setOpticalDensity(1.1)
        monkey.enableTexture(false)
        
        solids.append(monkey)
    }
}
    
