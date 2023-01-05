import MetalKit

class Sandbox: Scene {
    var camera = DebugCamera()
    var totalTime:Float = 0
    
    override func buildScene() {
        addCamera(camera)
        var transform = matrix_identity_float4x4
        transform.translate(direction: SIMD3<Float>(0, 0, 0))
//        transform.scale(axis: SIMD3<Float>(repeating: 20))
        
        let triangle = Solid(.Chest)
        addObject(solid: triangle, reflectivity: 1.0, refractiveIndex: 0, transform: transform)
        
        transform = matrix_identity_float4x4
        transform.translate(direction: SIMD3<Float>(0, 200, 100))
//        transform.scale(axis: SIMD3<Float>(repeating: 20))

        addLight(light: Light(meshType: .None, lightData: LightData(position: SIMD3<Float>(0, 200, 100), color: SIMD3<Float>(1, 1, 1), brightness: 10, ambientIntensity: 0.8, diffuseIntensity: 0.8, specularIntensity: 0.1)), transform: transform)
        
    
        addObject(solid: Solid(.None))
    }
    
    override func updateObjects(deltaTime: Float) {
        var transform = modelConstants[0].modelMatrix
        transform.rotate(angle: -1 *  deltaTime, axis: SIMD3<Float>(0, 1, 0))
        modelConstants[0].modelMatrix = transform
        modelConstants[1].modelMatrix = transform
    }

}
