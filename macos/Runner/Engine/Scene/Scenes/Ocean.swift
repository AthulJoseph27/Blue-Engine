import MetalKit
import MetalPerformanceShaders

class Ocean: GameScene {
    
    override func buildScene() {
        
        sceneTick = Float.pi / 8.0
        
        addLight(light: Light(type: UInt32(LIGHT_TYPE_SUN), position: SIMD3<Float>(0, 1.98, 0), forward: SIMD3<Float>(0, -1, 0), right: SIMD3<Float>(0.25, 0, 0), up: SIMD3<Float>(0, 0, 0.25), color: SIMD3<Float>(4, 4, 4)))
        
        let plane = Solid(.Plane)
        plane.setColor(SIMD3<Float>(0.2, 0.2, 0.8))
        plane.position = SIMD3<Float>(0, 0.5, 0)
        plane.updateBaseTexture(Skyboxibrary.skybox(.NightCity))
        plane.updateNormalTexture(Skyboxibrary.skybox(.Sky))
        plane.enableTexture(true)
        plane.enableNormalTexture(true)
        addSolid(solid: plane)
    
        updateSolids = animate
    }
    
    override internal func animate(solids: [Solid], time: Float) {
        
    }
}
    
