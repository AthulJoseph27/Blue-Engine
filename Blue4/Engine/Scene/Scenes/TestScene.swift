import MetalKit
import MetalPerformanceShaders

class TestScene: GameScene {
    
    override func buildScene() {
        
        let chest = Solid(.Chest)
        chest.position = SIMD3<Float>(-0.375, 0.5, -0.29)
        chest.rotation = SIMD3<Float>(0.0, -0.3, 0)
        chest.scale = SIMD3<Float>(0.008, 0.008, 0.008)
        solids.append(chest)
    }
}
    
