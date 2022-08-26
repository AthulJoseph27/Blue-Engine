import simd
import MetalKit
import MetalPerformanceShaders

class Renderer: NSObject {
    
    init(_ mtkView: MTKView) {
        super.init()
//        createPipelines(mtkView)
        createScene(mtkView)
    }
    
//    func createPipelines(_ mtkView: MTKView) {
//        let computePipelineState = ComputePipelineStateLibrary.pipelineState(.TraceRay)
//
//        _rayPipeline = computePipelineState.computePipelineState
//    }
    
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
        
        let transformPipeline = ComputePipelineStateLibrary.pipelineState(.Transform).computePipelineState
        
        computeEncoder.setComputePipelineState(transformPipeline!)
        let verticesCount: Int = SceneManager.tickScene(renderCommandEncoder: computeEncoder, deltaTime: 1/Float(view.preferredFramesPerSecond))
        
        var threadGroupWidth = transformPipeline!.maxTotalThreadsPerThreadgroup
        var threadGroupHeight = 1
        
        var threadGroupSize = MTLSize(width: threadGroupWidth, height: threadGroupHeight, depth: 1)
        
        var gridSize = MTLSizeMake(verticesCount, 1, 1)
        
        computeEncoder.dispatchThreads(gridSize, threadsPerThreadgroup: threadGroupSize)
        
        let rayTracingPipeline = ComputePipelineStateLibrary.pipelineState(.TraceRay).computePipelineState
        
        computeEncoder.setComputePipelineState(rayTracingPipeline!)
        
        
        
        computeEncoder.setTexture(drawable.texture, index: 0)
        threadGroupWidth = rayTracingPipeline!.threadExecutionWidth
        threadGroupHeight = rayTracingPipeline!.maxTotalThreadsPerThreadgroup / threadGroupWidth
        threadGroupSize = MTLSize(width: threadGroupWidth, height: threadGroupHeight, depth: 1)
        gridSize = MTLSizeMake(Int(view.drawableSize.width), Int(view.drawableSize.height), 1)
        
        computeEncoder.dispatchThreads(gridSize, threadsPerThreadgroup: threadGroupSize)
        
        computeEncoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
    
    
}


//func draw(in view: MTKView) {
//
//    guard let drawable = view.currentDrawable else {
//        return
//    }
//
//    let commandBuffer = Engine.commandQueue.makeCommandBuffer()!
//    let computeEncoder = commandBuffer.makeComputeCommandEncoder()!
//
//    let rayTracingpipeline = ComputePipelineStateLibrary.pipelineState(.TraceRay).computePipelineState
//
//    computeEncoder.setComputePipelineState(rayTracingpipeline!)
//
//    SceneManager.tickScene(renderCommandEncoder: computeEncoder, deltaTime: 1/Float(view.preferredFramesPerSecond))
//
//    computeEncoder.setTexture(drawable.texture, index: 0)
//
//    let threadGroupWidth = rayTracingpipeline!.threadExecutionWidth
//    let threadGroupHeight = rayTracingpipeline!.maxTotalThreadsPerThreadgroup / threadGroupWidth
//    let threadGroupSize = MTLSize(width: threadGroupWidth, height: threadGroupHeight, depth: 1)
//
//    let gridSize = MTLSizeMake(Int(view.drawableSize.width), Int(view.drawableSize.height), 1)
//
//    computeEncoder.dispatchThreads(gridSize, threadsPerThreadgroup: threadGroupSize)
//    computeEncoder.endEncoding()
//
//    commandBuffer.present(drawable)
//    commandBuffer.commit()
//}
