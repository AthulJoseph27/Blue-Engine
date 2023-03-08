import MetalKit

class SceneManager {
    public static var currentRendererType: RendererType = .StaticRT
    
    private static var _currentSkybox: SkyboxTypes = .Sky
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
            _currentScene = Sandbox(skybox: _currentSkybox)
            break
        case .Sponza:
            _currentScene = Sponza(skybox: _currentSkybox)
            break
        case .FireplaceRoom:
            _currentScene = FireplaceRoom(skybox: _currentSkybox)
            break
        case .SanMiguel:
            _currentScene = SanMiguel(skybox: _currentSkybox)
            break
        }
        updateRenderableScene(currentRendererType)
    }
    
    public static func updateSkybox(skybox: SkyboxTypes) {
        _currentSkybox = skybox
        _currentScene.updateSkybox(skybox: skybox)
        _currentRenderableScene.updateSkybox(skyboxType: skybox)
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
