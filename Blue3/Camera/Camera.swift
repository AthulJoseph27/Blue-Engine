import simd

enum CameraTypes {
    case Debug
}

protocol SceneCamera {
    var cameraType: CameraTypes     { get }
    var position: SIMD3<Float>      { get set }
    var deltaPosition: SIMD3<Float> { get set }
    var rotation: SIMD3<Float>      { get set }
    var deltaRotation: SIMD3<Float>      { get set }
    func update(deltaTime: Float)
}
