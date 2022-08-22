import MetalKit

enum SceneTypes {
    case Sandbox
}

class SceneManager {
    public static var initialized: Bool = false
    private static var _currentScene: Scene!
    
    public static func initialize(sceneType: SceneTypes, drawableSize: CGSize) {
        setScene(sceneType, drawableSize)
    }
    
    public static func setScene(_ sceneType: SceneTypes, _ drawableSize: CGSize){
        switch sceneType {
        case .Sandbox:
            _currentScene = Sandbox(drawableSize: drawableSize)
        }
    }
    
    public static func tickScene(renderCommandEncoder: MTLComputeCommandEncoder, deltaTime: Float) {
        _currentScene.updateCameras(deltaTime: deltaTime)
        _currentScene.render(renderCommandEncoder: renderCommandEncoder)
    }
}
