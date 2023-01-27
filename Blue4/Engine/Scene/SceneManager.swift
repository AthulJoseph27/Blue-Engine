import MetalKit

enum SceneTypes {
    case BasicScene
    case Sandbox
    case RefractionScene
}

class SceneManager {
    public static var initialized: Bool = false
    private static var _currentScene: GameScene!
    
    static var currentScene: GameScene {
        get {
            return SceneManager._currentScene
        }
    }
    
    public static func initialize(sceneType: SceneTypes, drawableSize: CGSize) {
        setScene(sceneType, drawableSize)
    }
    
    public static func setScene(_ sceneType: SceneTypes, _ drawableSize: CGSize){
        switch sceneType {
        case .BasicScene:
            _currentScene = Sandbox(drawableSize: drawableSize)
        case .Sandbox:
            _currentScene = Sandbox(drawableSize: drawableSize)
        case .RefractionScene:
            _currentScene = Sandbox(drawableSize: drawableSize)
        }
    }
        
    public static func tickScene(deltaTime: Float) {
        _currentScene.updateScene(deltaTime: deltaTime)
        _currentScene.updateCameras(deltaTime: deltaTime)
        _currentScene.updateObjects(deltaTime: deltaTime)
    }
}
