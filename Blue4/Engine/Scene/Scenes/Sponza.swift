import MetalKit
import MetalPerformanceShaders

class Sponza: GameScene {
    
    override func buildScene() {
        let sponza = Solid(.Sponza)
        sponza.position = SIMD3<Float>(-5.375, 0.5, -0.29)
        sponza.scale = SIMD3<Float>(0.008, 0.008, 0.008)
        solids.append(sponza)
    }
}
    
