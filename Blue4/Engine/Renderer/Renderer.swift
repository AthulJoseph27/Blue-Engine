import MetalKit
import os

class Renderer: NSObject, MTKViewDelegate {
    public static var screenSize = SIMD2<Float>(repeating: 0)
    public var renderedTexture: MTLTexture?
    public var renderMode: RenderMode
    public var renderQuality: RenderQuality
    let view: MTKView
    let device: MTLDevice
    let queue: MTLCommandQueue
    let library: MTLLibrary
    var scene: GameScene!
    var renderPassDescriptor: MTLRenderPassDescriptor!
    let display: (Double) -> Void
    
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
    
//    func onRenderingDone() {
//        RendererManager.setRenderMode(mode: .display)
//    }
    
    public func updateScreenSize(view: MTKView) {
        Renderer.screenSize = SIMD2<Float>(Float(view.bounds.width),Float(view.bounds.height))
    }
}
