class CameraManager {
    private var _cameras: [CameraTypes : SceneCamera] = [:]
    private var locked = false
    public var currentCamera: SceneCamera!
    
    public func registerCamera(camera: SceneCamera) {
        self._cameras.updateValue(camera, forKey: camera.cameraType)
    }
    
    public func setCamera(_ cameraType: CameraTypes) {
        self.currentCamera = _cameras[cameraType]
    }
    
    public func lockCamera() {
        locked = true
    }
    
    public func unlockCamera() {
        locked = false
    }
    
    internal func update(deltaTime: Float) {
        if !locked {
            for camera in _cameras.values {
                camera.update(deltaTime: deltaTime)
            }
        }
    }
}
