import MetalKit

class Node {
    var position: SIMD3<Float> = SIMD3<Float>(repeating: 0);
    var scale: SIMD3<Float> = SIMD3<Float>(repeating: 1);
    var rotation: SIMD3<Float> = SIMD3<Float>(repeating: 0);
    
    var modelMatrix: matrix_float4x4 {
        var modelMatrix = matrix_identity_float4x4
        modelMatrix.translate(direction: position)
        modelMatrix.scale(axis: scale)
        modelMatrix.rotate(angle: rotation.x, axis: X_AXIS)
        modelMatrix.rotate(angle: rotation.y, axis: Y_AXIS)
        modelMatrix.rotate(angle: rotation.z, axis: Z_AXIS)
        return modelMatrix;
    }
    
    func update(deltaTime: Float) {}
}
