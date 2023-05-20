import MetalKit
import MetalPerformanceShaders

class HarmonicCubes: GameScene {
    var totalTime = 0.0
    var cubes: [[Int]] = []
    
    override func buildScene() {
        
        addLight(light: Light(type: UInt32(LIGHT_TYPE_AREA), position: SIMD3<Float>(0, 1.98, 0), forward: SIMD3<Float>(0, -1, 0), right: SIMD3<Float>(0.25, 0, 0), up: SIMD3<Float>(0, 0, 0.25), color: SIMD3<Float>(4, 4, 4)))
        
        for x in -8..<10 {
            var temp: [Int] = []
            for y in -8..<10 {
                let cube = Solid(.Cube)
                cube.position = SIMD3<Float>(Float(x), 0, Float(y))
                cube.setColor(SIMD3<Float>(0.2, 0.2, 0.8))
                cube.setRoughness(1.0)
                cube.enableTexture(false)
                cube.animated = true
                temp.append(solids.count)
                solids.append(cube)
            }
            cubes.append(temp)
        }
        
        CameraManager.currentCamera.position = SIMD3<Float>(0, 17, 24)
        CameraManager.currentCamera.rotation = SIMD3<Float>(-0.66, 0, 0)
    
        updateSolids = animate
    }
    
    private func animate(solids: [Solid], deltaTime: Float) {
        totalTime += Double.pi / 8.0
        let offSet = totalTime
        
        for r in 0..<18 {
            for i in 0..<18 {
                let dist = ((Double(r - 8) * Double(r - 8) + Double(i - 8) * Double(i - 8)).squareRoot() / 64.squareRoot()) * Double.pi + offSet

                solids[cubes[r][i]].scale = SIMD3<Float>(1, 4 + 2 * sin(Float(dist)), 1)
            }
        }
    }
}
    
