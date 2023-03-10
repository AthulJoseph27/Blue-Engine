import MetalKit

class SceneManager {
    public static var currentRendererType: RendererType = .StaticRT
    
    private static var _sceneSettings = SceneSettings(currentScene: .Sandbox, skybox: .Sky, ambientLighting: 0.1)
    private static var _currentSceneName: GameScenes = .Sandbox
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
            _currentScene = Sandbox(skybox: _sceneSettings.skybox, ambient: _sceneSettings.ambientLighting)
            break
        case .Sponza:
            _currentScene = Sponza(skybox: _sceneSettings.skybox, ambient: _sceneSettings.ambientLighting)
            break
        case .FireplaceRoom:
            _currentScene = FireplaceRoom(skybox: _sceneSettings.skybox, ambient: _sceneSettings.ambientLighting)
            break
        case .SanMiguel:
            _currentScene = SanMiguel(skybox: _sceneSettings.skybox, ambient: _sceneSettings.ambientLighting)
            break
        case .Custom:
            _currentScene = Custom(skybox: _sceneSettings.skybox, ambient: _sceneSettings.ambientLighting, lights: _sceneSettings.sceneLights)
        }
        _currentSceneName = scene
        updateRenderableScene(currentRendererType)
    }
    
    public static func updateSceneSettings(arguments: [String: Any]) {
        let newSettings = _sceneSettings.fromJson(arguments)
        
        if newSettings.currentScene != _sceneSettings.currentScene {
            RendererManager.updateCurrentScene(scene: newSettings.currentScene)
        }
        
        if newSettings.skybox != _sceneSettings.skybox {
            _currentScene.updateSkybox(skybox: newSettings.skybox)
            
        }
        
        if newSettings.ambientLighting != _sceneSettings.ambientLighting {
            _currentScene.updateAmbient(ambient: newSettings.ambientLighting)
        }
        
        if arguments["sceneLights"] != nil {
            _currentScene.updateSceneLights(lights: newSettings.sceneLights)
            setScene(_currentSceneName)
        }
        
        _sceneSettings = newSettings
        _currentRenderableScene.updateSceneSettings(sceneSettings: newSettings)
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
