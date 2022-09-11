import simd

enum CameraTypes {
    case Debug
}

protocol Camera {
    var cameraType: CameraTypes { get }
    var position: SIMD3<Float> { get set }
    var deltaPosition: SIMD3<Float> { get set }
    var rotation: SIMD3<Float> { get set }
//    var projectionMatrix: matrix_float4x4 { get }
    func update(deltaTime: Float)
}

extension Camera {
    var rotationMatrix: matrix_float4x4 {
        var rotationMatrix = matrix_identity_float4x4
        rotationMatrix.rotate(angle: rotation.x, axis: X_AXIS)
        rotationMatrix.rotate(angle: rotation.y, axis: Y_AXIS)
        rotationMatrix.rotate(angle: rotation.z, axis: Z_AXIS)
        return rotationMatrix;
    }
    
//    var viewMatrix: matrix_float4x4 {
//        var viewMatrix = matrix_identity_float4x4
////        let newPosition = position + deltaPosition
//        viewMatrix.translate(direction: SIMD3<Float>(0, 0, 0))
//        return viewMatrix
//    }
}
