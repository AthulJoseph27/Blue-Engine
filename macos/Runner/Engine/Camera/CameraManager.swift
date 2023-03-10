class CameraManager {
    private static var _cameras: [CameraTypes : SceneCamera] = [:]
    private static var locked = false
    public static var currentCamera: SceneCamera!
    
    public static func registerCamera(camera: SceneCamera) {
        _cameras.updateValue(camera, forKey: camera.cameraType)
    }
    
    public static func setCamera(_ cameraType: CameraTypes) {
        currentCamera = _cameras[cameraType]
    }
    
    public static func setCameraControllSensitivity(_ settings: ControllSensitivity) {
        currentCamera.controllSensitivity = settings
    }
    
    public static func lockCamera() {
        locked = true
    }
    
    public static func unlockCamera() {
        locked = false
    }
    
    internal static func update(deltaTime: Float) {
        if !locked {
            for camera in _cameras.values {
                camera.update(deltaTime: deltaTime)
            }
        }
    }
}
