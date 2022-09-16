class CameraManager {
    private var _cameras: [CameraTypes : SceneCamera] = [:]
    public var currentCamera: SceneCamera!
    
    public func registerCamera(camera: SceneCamera) {
        self._cameras.updateValue(camera, forKey: camera.cameraType)
    }
    
    public func setCamera(_ cameraType: CameraTypes) {
        self.currentCamera = _cameras[cameraType]
    }
    
    internal func update(deltaTime: Float) {
        for camera in _cameras.values {
            camera.update(deltaTime: deltaTime)
        }
    }
}
