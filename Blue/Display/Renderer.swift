import MetalKit

class Renderer: NSObject {
    public static var ScreenSize = SIMD2<Float>(repeating: 0)
    public static var AspectRatio: Float {
        return ScreenSize.x / ScreenSize.y
    }
    
    var scene = SandboxScene()
    
    init(_ mtkView: MTKView) {
        super.init()
        updateScreenSize(view: mtkView)
    }
}

extension Renderer: MTKViewDelegate {
    public func updateScreenSize(view: MTKView) {
        Renderer.ScreenSize = SIMD2<Float>(Float(view.bounds.width),Float(view.bounds.height))
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
    }
    
    func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable, let renderPassDescriptor = view.currentRenderPassDescriptor else { return }
        
        let commandBuffer = Engine.CommandQueue.makeCommandBuffer()
        let renderCommandEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        
        SceneManager.tickScene(renderCommandEncoder: renderCommandEncoder!, deltaTime: 1/Float(view.preferredFramesPerSecond))
        
        renderCommandEncoder?.endEncoding()
        commandBuffer?.present(drawable)
        commandBuffer?.commit()
    }
    
    
}
