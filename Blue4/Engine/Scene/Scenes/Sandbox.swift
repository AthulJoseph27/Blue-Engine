import MetalKit
import MetalPerformanceShaders

class Sandbox: GameScene {
    
    override func buildScene() {
        
        var transform = matrix_identity_float4x4
        transform.translate(direction: SIMD3<Float>(0, 1, 0))
        transform.scale(axis: SIMD3<Float>(0.5, 1.98, 0.5))
        
//        createCube(faceMask: Masks.FACE_MASK_POSITIVE_Y, color: SIMD3<Float>([1, 1, 1]), reflectivity: 0.0, transform: transform, inwardNormals: true, triangleMask: UInt32(TRIANGLE_MASK_LIGHT))
        
        //         Top, bottom, back
        transform = matrix_identity_float4x4
        transform.translate(direction: SIMD3<Float>(0, 1, 0))
        transform.scale(axis: SIMD3<Float>(2, 2, 2))
        createCube(faceMask: Masks.FACE_MASK_NEGATIVE_Y | Masks.FACE_MASK_POSITIVE_Y | Masks.FACE_MASK_NEGATIVE_Z, color: SIMD3<Float>([0.725, 0.71, 0.68]), reflectivity: 0.0, transform: transform, inwardNormals: true, triangleMask: uint(TRIANGLE_MASK_GEOMETRY))
        
        // Left wall
        createCube(faceMask: Masks.FACE_MASK_NEGATIVE_X, color: SIMD3<Float>([0.63, 0.065, 0.05]), reflectivity: 0.0, transform: transform, inwardNormals: true, triangleMask: uint(TRIANGLE_MASK_GEOMETRY))
        
        //        // Right wall
        createCube(faceMask: Masks.FACE_MASK_POSITIVE_X, color: SIMD3<Float>([0.14, 0.45, 0.091]), reflectivity: 0.0, transform: transform, inwardNormals: true, triangleMask: uint(TRIANGLE_MASK_GEOMETRY))
        
        //         Short box
        let monkey = Solid(.Cube)
        monkey.position = SIMD3<Float>(0.3275, 0.3, 0.3725)
        monkey.rotation = SIMD3<Float>(0, -0.3, 0)
        monkey.scale = SIMD3<Float>(0.3, 0.3, 0.3)
        monkey.setColor(SIMD4<Float>(0.2, 0.2, 0.8, 1.0))
        monkey.setOpticalDensity(1.01)
//        monkey.setRoughness(0.0)
        monkey.enableTexture(false)
        //        monkey.animated = true
        
        solids.append(monkey)
        
        //         Tall box
        let chest = Solid(.Chest)
        chest.position = SIMD3<Float>(-0.375, 0.5, -0.29)
        chest.rotation = SIMD3<Float>(0, 0.3, 0)
        chest.scale = SIMD3<Float>(0.008, 0.008, 0.008)
        solids.append(chest)
    }
}
    
