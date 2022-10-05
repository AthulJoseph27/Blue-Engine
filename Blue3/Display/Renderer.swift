import MetalKit
import os

class Renderer: NSObject, MTKViewDelegate {
    let view: MTKView
    let device: MTLDevice
    let queue: MTLCommandQueue
    let library: MTLLibrary
    var scene: Scene!
    
    let display: (Double) -> Void
    
    init(withMetalKitView view: MTKView, displayCounter: @escaping (Double) -> Void) throws {
        display = displayCounter
        self.view = view
        self.device = Engine.device
        os_log("Metal device name is %s", device.name)
        
        self.library = Engine.defaultLibrary
        self.queue = Engine.commandQueue
        
        super.init()
        
        initialize()
    }
    
    func initialize() {}
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
    
    func draw(in view: MTKView) {}
    
}
