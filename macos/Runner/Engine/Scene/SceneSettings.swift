class SceneSettings {
    var currentScene: GameScenes
    var skybox: SkyboxTypes
    var ambientLighting: Float
    
    init(currentScene: GameScenes, skybox: SkyboxTypes, ambientLighting: Float) {
        self.currentScene = currentScene
        self.skybox = skybox
        self.ambientLighting = ambientLighting
    }
    
    func fromJson(_ json: [String: Any]) -> SceneSettings {
        let sceneSettings = SceneSettings(currentScene: currentScene, skybox: skybox, ambientLighting: ambientLighting)
        
        if let scene = json["scene"] as? String, let gameScene = GameScenes(rawValue: scene) {
            sceneSettings.currentScene = gameScene
        }
        
        if let skyboxName = json["skybox"] as? String, let skybox = SkyboxTypes(rawValue: skyboxName) {
            sceneSettings.skybox = skybox
        }
        
        if let ambient = json["ambient"] as? Float {
            sceneSettings.ambientLighting = ambient
        }
        
        return sceneSettings
    }
    
}
