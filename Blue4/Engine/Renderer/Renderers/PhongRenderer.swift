import MetalKit

class PhongRenderer: Renderer {
    var renderPipeline: MTLRenderPipelineState!
    var scene: PhongShadingScene?
    var size: CGSize!
    
    override func initialize() {
        updateViewPort()
        createPipeline()
    }
    
    override func updateViewPort() {
        scene = (SceneManager.currentRenderableScene as? PhongShadingScene)
    }
    
    private func createPipeline() {
        renderPipeline = RenderPipelineStateLibrary.pipelineState(.Basic)
    }
    
    override func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        self.size = size
    }
    
    override func draw(in view: MTKView) {
        if self.size.width <= 0 || self.size.height <= 0 {
            return
        }
        
        guard let drawable = view.currentDrawable, let renderPassDescriptor = view.currentRenderPassDescriptor else { return }
        
        let commandBuffer = Engine.commandQueue.makeCommandBuffer()
        let renderEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        renderEncoder?.setRenderPipelineState(renderPipeline)
        
        SceneManager.tickScene(deltaTime: 1/Float(view.preferredFramesPerSecond))
        
        if renderEncoder != nil {
            scene?.drawSolids(renderEncoder: renderEncoder!)
        }
        
        renderEncoder?.endEncoding()
        commandBuffer?.present(drawable)
        commandBuffer?.commit()
        
        if renderMode == .render {
            self.renderedTexture = drawable.texture
            self.renderMode = .display
            RendererManager.onRenderingComplete()
        }
    }
}
