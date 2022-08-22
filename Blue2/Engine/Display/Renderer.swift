import simd
import MetalKit
import MetalPerformanceShaders

class Renderer: NSObject {
    private var _rayPipeline: MTLComputePipelineState!
    
    init(_ mtkView: MTKView) {
        super.init()
        createPipelines(mtkView)
        createScene(mtkView)
    }
    
    func createPipelines(_ mtkView: MTKView) {
        let computePipelineState = ComputePipelineStateLibrary.pipelineState(.Basic)
        
        _rayPipeline = computePipelineState.rayPipelineState
    }
    
    func createScene(_ mtkView: MTKView) {
        let drawableSize = mtkView.drawableSize
        if(!SceneManager.initialized) {
            SceneManager.setScene(.Sandbox, drawableSize)
            SceneManager.initialized = true
        }
    }
}

extension Renderer: MTKViewDelegate {
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
    }
    
    func draw(in view: MTKView) {
        
        guard let drawable = view.currentDrawable else {
            return
        }
        
        let commandBuffer = Engine.commandQueue.makeCommandBuffer()!
        let computeEncoder = commandBuffer.makeComputeCommandEncoder()!
        
        let pipeline = ComputePipelineStateLibrary.pipelineState(.Basic).rayPipelineState
        
        computeEncoder.setComputePipelineState(pipeline!)
        
        SceneManager.tickScene(renderCommandEncoder: computeEncoder, deltaTime: 1/Float(view.preferredFramesPerSecond))
        
        computeEncoder.setTexture(drawable.texture, index: 0)
        
        let threadGroupWidth = pipeline!.threadExecutionWidth
        let threadGroupHeight = pipeline!.maxTotalThreadsPerThreadgroup / threadGroupWidth
        let threadGroupSize = MTLSize(width: threadGroupWidth, height: threadGroupHeight, depth: 1)
        
        let gridSize = MTLSizeMake(Int(view.drawableSize.width), Int(view.drawableSize.height), 1)
        
        computeEncoder.dispatchThreads(gridSize, threadsPerThreadgroup: threadGroupSize)
        computeEncoder.endEncoding()
        
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
    
    
}
