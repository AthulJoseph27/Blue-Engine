import MetalKit

class Sandbox: Scene {
    var camera = DebugCamera()
    var totalTime:Float = 0
    
    override func buildScene() {
        addCamera(camera)
//        addObject(solid: Solid(.Cube))
        var transform = matrix_identity_float4x4
//        transform.translate(direction: SIMD3<Float>(1080, 720, -1210))
////        transform.rotate(angle: Float(90).toRadian, axis: SIMD3<Float>(0, 1, 0))
//        addObject(solid: Solid(.Monkey), reflectivity: 0, transform: transform)
        
        transform = matrix_identity_float4x4
        transform.translate(direction: SIMD3<Float>(1080, 720, -1210))
//        addLight(solid: Solid(.Cube), transform: transform)
        
        
        addObject(solid: Solid(.Monkey), refractiveIndex: 1.2, transform: transform)
    }
    
    override func updateObjects(deltaTime: Float) {
    }

}
