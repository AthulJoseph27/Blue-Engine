import MetalKit

class SceneManager {
    public static var initialized: Bool = false
    private static var _currentScene: GameScene!
    
    static var currentScene: GameScene {
        get {
            return SceneManager._currentScene
        }
    }
    
    public static func initialize(sceneType: SceneType, drawableSize: CGSize) {
        setScene(sceneType, drawableSize)
    }
    
    public static func setScene(_ sceneType: SceneType, _ drawableSize: CGSize){
        switch sceneType {
        case .StaticSandbox:
            _currentScene = Sandbox(drawableSize: drawableSize)
        case .DynamicSanbox:
            _currentScene = DynamicSandbox(drawableSize: drawableSize)
        }
    }
        
    public static func tickScene(deltaTime: Float) {
        _currentScene.updateScene(deltaTime: deltaTime)
        _currentScene.updateCameras(deltaTime: deltaTime)
        _currentScene.updateObjects(deltaTime: deltaTime)
    }
}
