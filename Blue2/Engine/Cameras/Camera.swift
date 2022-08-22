import simd

enum CameraTypes {
    case Debug
}

protocol Camera {
    var cameraType: CameraTypes { get }
    var position: SIMD3<Float> { get set }
    var rotation: SIMD3<Float> { get set }
    func update(deltaTime: Float)
}
