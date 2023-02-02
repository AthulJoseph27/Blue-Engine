import MetalKit
import os

class Renderer: NSObject, MTKViewDelegate {
    public static var screenSize = SIMD2<Float>(repeating: 0)
    public var renderedTexture: MTLTexture?
    public var renderMode: RenderMode
    public var renderQuality: RenderQuality
    internal var renderingSettings: RenderingSettings?
    internal let view: MTKView
    internal let device: MTLDevice
    internal let queue: MTLCommandQueue
    internal let library: MTLLibrary
    internal var scene: GameScene!
    internal var renderPassDescriptor: MTLRenderPassDescriptor!
    internal let display: (Double) -> Void
    
    init(withMetalKitView view: MTKView, displayCounter: @escaping (Double) -> Void) throws {
        display = displayCounter
        self.view = view
        self.device = Engine.device
        os_log("Metal device name is %s", device.name)
        
        self.library = Engine.defaultLibrary
        self.queue = Engine.commandQueue
        self.renderMode = .display
        self.renderQuality = .medium
        super.init()
        initialize()
    }
    
    func initialize() {
        updateScreenSize(view: view)
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
    
    func draw(in view: MTKView) {}
    
    func renderModeInitialize() {}
    
    func updateScene(sceneType: SceneType) {
        SceneManager.setScene(sceneType, view.drawableSize)
        scene = SceneManager.currentScene
        scene.skyBox = Skyboxibrary.skybox(.Sky)
        scene.postBuildScene()
    }
    
    func switchToRenderMode(settings: RenderingSettings) {
        view.isPaused = true
        renderingSettings = settings
        renderMode = .render
        scene.cameraManager.lockCamera()
        renderModeInitialize()
        view.isPaused = false
    }
    
    func switchToDisplayMode(settings: RenderingSettings) {
        view.isPaused = true
        renderingSettings = settings
        renderMode = .display
        scene.cameraManager.unlockCamera()
        view.isPaused = false
    }
    
    func updateRenderSettings(settings: RenderingSettings) {
        renderingSettings = settings
    }
    
    func updateScreenSize(view: MTKView) {
        Renderer.screenSize = SIMD2<Float>(Float(view.bounds.width),Float(view.bounds.height))
    }
}
