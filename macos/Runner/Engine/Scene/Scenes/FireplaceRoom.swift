import MetalKit
import MetalPerformanceShaders

class FireplaceRoom: GameScene {
    
    override func buildScene() {
        let fireplaceRoom = Solid(.FireplaceRoom)
        fireplaceRoom.position = SIMD3<Float>(-2, -0.8, 1)
        solids.append(fireplaceRoom)
        
        var transform = matrix_identity_float4x4
        transform.translate(direction: SIMD3<Float>(0, 1, 0))
        transform.scale(axis: SIMD3<Float>(0.5, 1.98, 0.5))
        
        createCube(faceMask: Masks.FACE_MASK_POSITIVE_Y, color: SIMD3<Float>([1, 1, 1]), reflectivity: 0.0, transform: transform, inwardNormals: true, triangleMask: UInt32(TRIANGLE_MASK_LIGHT))
        addLight(light: Light(type: UInt32(LIGHT_TYPE_AREA), position: SIMD3<Float>(0, 1.98, 0), forward: SIMD3<Float>(0, -1, 0), right: SIMD3<Float>(0.25, 0, 0), up: SIMD3<Float>(0, 0, 0.25), color: SIMD3<Float>(4, 4, 6)))
    }
}
