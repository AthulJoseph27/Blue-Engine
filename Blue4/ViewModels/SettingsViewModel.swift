import SwiftUI

class SettingsViewModel: ObservableObject {
    static let model = SettingsViewModel()
    static let scenes: [GameScenes] = [
        .Sandbox,
        .Sponza,
        .FireplaceRoom,
        .TestScene
    ]
    @Published var maxBounce = 4
    @Published var currentScene: GameScenes = .Sandbox
    
    func updateMaxBounce(bounce: Int) {
        RendererManager.updateViewPortSettings(viewPortType: .StaticRT, settings: RayTracingSettings(maxBounce: bounce))
    }
    
    func updateCurrentScene(scene: GameScenes) {
        RendererManager.updateCurrentScene(scene: scene)
    }
}
 
