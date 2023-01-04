import MetalKit

class Sandbox: Scene {
    var camera = DebugCamera()
    var totalTime:Float = 0
    
    override func buildScene() {
        addCamera(camera)
//        addObject(solid: Solid(.Cube))
        var transform = matrix_identity_float4x4
//        transform.translate(direction: SIMD3<Float>(1080, 650, -1605))
        transform.translate(direction: SIMD3<Float>(1080, 650, -1605))
//        transform.rotate(angle: Float(180).toRadian, axis: SIMD3<Float>(0, 1, 0))
        let triangle = Solid(.SpaceShip)
//        triangle.setColor(SIMD4<Float>(1, 1, 0, 1))
        addObject(solid: triangle, reflectivity: 1.0, refractiveIndex: 0, transform: transform)
//        transform = matrix_identity_float4x4
//        transform.translate(direction: SIMD3<Float>(1080, 720, -1210))
//        transform.scale(axis: SIMD3<Float>(2,2,2))
//        addLight(solid: Solid(.Cube), transform: transform)
        
        
//        addObject(solid: Solid(.Triangle), reflectivity: 0.2, refractiveIndex: -1.2, transform: transform)
    }
    
    override func updateObjects(deltaTime: Float) {
    }

}
