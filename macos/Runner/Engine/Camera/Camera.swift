import simd

enum CameraTypes {
    case Debug
}

protocol SceneCamera {
    var cameraType: CameraTypes                 { get }
    var position: SIMD3<Float>                  { get set }
    var deltaPosition: SIMD3<Float>             { get set }
    var rotation: SIMD3<Float>                  { get set }
    var deltaRotation: SIMD3<Float>             { get set }
    var projectionMatrix: matrix_float4x4       { get }
    func update(deltaTime: Float)
}

extension SceneCamera {
    var viewMatrix: matrix_float4x4 {
        var viewMatrix = matrix_identity_float4x4
        viewMatrix.rotate(angle: (rotation.x + deltaRotation.x), axis: SIMD3<Float>(1, 0, 0))
        viewMatrix.rotate(angle: (rotation.y + deltaRotation.y), axis: SIMD3<Float>(0, 1, 0))
        viewMatrix.rotate(angle: (rotation.z + deltaRotation.z), axis: SIMD3<Float>(0, 0, 1))
        viewMatrix.translate(direction: -(position + deltaPosition))
        return viewMatrix
    }
}
