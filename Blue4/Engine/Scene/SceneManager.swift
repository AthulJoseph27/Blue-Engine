import MetalKit

class SceneManager {
    public static var initialized: Bool = false
    private static var _currentScene: GameScene!
    static var currentScene: GameScene {
        get {
            return SceneManager._currentScene
        }
    }
    
    public static func initialize(scene: GameScenes) {
        setScene(scene)
    }
    
    public static func setScene(_ scene: GameScenes){
        switch scene {
        case .Sandbox:
            _currentScene = Sandbox()
        case .TestScene:
            _currentScene = TestScene()
        }
    }
}
