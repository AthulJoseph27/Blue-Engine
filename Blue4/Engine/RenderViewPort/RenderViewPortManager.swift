import MetalKit

class RenderViewPortManager {
    private static var _currentViewPort: RenderViewPort!

    static var currentViewPort: RenderViewPort {
        get {
            return RenderViewPortManager._currentViewPort
        }
    }
    
    public static func setViewPort(_ viewPortType: RenderViewPortType) {
        switch viewPortType {
        case .StaticRT:
            _currentViewPort = StaticRTViewPort(scene: SceneManager.currentScene)
        case .DynamicRT:
            _currentViewPort = DynamicRTViewPort(scene: SceneManager.currentScene)
        case .VertexShader:
            _currentViewPort = PhongShadingViewPort(scene: SceneManager.currentScene)
        }
    }
    
    public static func tickScene(deltaTime: Float) {
        _currentViewPort.updateScene(deltaTime: deltaTime)
        _currentViewPort.updateCameras(deltaTime: deltaTime)
        _currentViewPort.updateObjects(deltaTime: deltaTime)
    }
}
