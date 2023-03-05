import MetalKit

class SceneManager {
    public static var currentRendererType: RendererType = .StaticRT
    
    private static var _currentScene: GameScene!
    private static var _currentRenderableScene: RenderableScene!
    static var currentRenderableScene: RenderableScene {
        get {
            return SceneManager._currentRenderableScene
        }
    }
    static var currentScene: GameScene {
        get {
            return SceneManager._currentScene
        }
    }
    
    public static func initialize(scene: GameScenes, rendererType: RendererType) {
        currentRendererType = rendererType
        setScene(scene)
    }
    
    public static func setScene(_ scene: GameScenes){
        switch scene {
        case .Sandbox:
            _currentScene = Sandbox()
        case .Sponza:
            _currentScene = Sponza()
        case .FireplaceRoom:
            _currentScene = FireplaceRoom()
        case .SanMiguel:
            _currentScene = SanMiguel()
        }
        updateRenderableScene(currentRendererType)
    }
    
    public static func updateRenderableScene(_ rendererType: RendererType) {
        currentRendererType = rendererType
        switch rendererType {
        case .StaticRT:
            _currentRenderableScene = StaticRTScene(scene: _currentScene)
        case .DynamicRT:
            _currentRenderableScene = DynamicRTScene(scene: _currentScene)
        case .PhongShader:
            _currentRenderableScene = PhongShadingScene(scene: _currentScene)
        }
    }
    
    public static func tickScene(deltaTime: Float) {
        _currentRenderableScene.updateScene(deltaTime: deltaTime)
        _currentRenderableScene.updateCameras(deltaTime: deltaTime)
        _currentRenderableScene.updateObjects(deltaTime: deltaTime)
    }
}
