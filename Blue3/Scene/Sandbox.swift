import MetalKit

class Sandbox: Scene {
    var camera = DebugCamera()
    var totalTime:Float = 0
    
    override func buildScene() {
        addCamera(camera)
        var transform = matrix_identity_float4x4
        transform.translate(direction: SIMD3<Float>(-800, 50, 0))
        transform.rotate(angle: 90, axis: SIMD3<Float>(0, 1, 0))
        transform.scale(axis: SIMD3<Float>(repeating: 50))
        
//        let fireplace = Solid(.FireplaceRoom)
//        addObject(solid: fireplace, transform: transform)
//
//        let quad = Solid(.Cube)
//        quad.setColor(SIMD4<Float>(0.5, 0.8, 0.9, 1))
//        quad.setRoughness(1.0)
//        quad.enableTexture(false)
//        quad.overrideMeshMaterial()
//
//        addObject(solid: quad, transform: transform)

        transform = matrix_identity_float4x4
        transform.translate(direction: SIMD3<Float>(0, 0, 0))
//        transform.rotate(angle: 90, axis: SIMD3<Float>(0, 1, 0))
        transform.scale(axis: SIMD3<Float>(repeating: 50))

        let triangle = Solid(.FireplaceRoom)
        addObject(solid: triangle, transform: transform)

        addLight(light: Light(meshType: .Sphere, lightData: LightData(position: SIMD3<Float>(100, 0, 0), color: SIMD3<Float>(1, 1, 1), brightness: 2, ambientIntensity: 0.4, diffuseIntensity: 1.0, specularIntensity: 1.0)), transform: transform)
        
    
//        addObject(solid: Solid(.None))
    }
    
    override func updateObjects(deltaTime: Float) {
//        var transform = modelConstants[0].modelMatrix
//        transform.rotate(angle: -1 *  deltaTime, axis: SIMD3<Float>(0, 1, 0))
//        modelConstants[0].modelMatrix = transform
//        modelConstants[1].modelMatrix = transform
    }

}
