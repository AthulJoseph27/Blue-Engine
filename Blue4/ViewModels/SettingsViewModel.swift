import SwiftUI

class SettingsViewModel: ObservableObject {
    static let model = SettingsViewModel()
    static let rayTracingScenes: [SceneType] = [
        .StaticSandbox,
        .DynamicSanbox
    ]
    static let vertexShaderScenes: [SceneType] = []
    @Published var maxBounce = 1
    @Published var currentScene: SceneType = .StaticSandbox
    
    func updateMaxBounce(bounce: Int) {
        RendererManager.updateViewPortSettings(rendererType: .RayTracing, settings: RayTracingSettings(maxBounce: bounce))
    }
    
    func updateCurrentScene(scene: SceneType) {
        RendererManager.updateCurrentScene(scene: scene)
    }
}
 
