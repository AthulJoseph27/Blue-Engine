import MetalKit
import MetalPerformanceShaders
import simd
import os

class RayTracingRenderer: Renderer {
    var intersector: MPSRayIntersector!
    
    var rayBuffer:          MTLBuffer!
    var shadowRayBuffer:    MTLBuffer!
    var intersectionBuffer: MTLBuffer!
    
    var textureSampler : MTLSamplerState!
    
    var rayPipeline: MTLComputePipelineState!
    var shadePipeline: MTLComputePipelineState!
    var shadowPipeline: MTLComputePipelineState!
    var accumulatePipeline: MTLComputePipelineState!
    var copyPipeline: MTLRenderPipelineState!

    var renderTarget: MTLTexture!
    var accumulationTarget: MTLTexture!
    var randomTexture: MTLTexture!
    
    var semaphore: DispatchSemaphore!
    var size: CGSize!
    
    var lastCheckPoint = Date()
    var timeIntervals: [CFTimeInterval] = []

    
    override func initialize() {
        self.createScene()
        self.createPipelines()
        self.createIntersector()
        
        semaphore = DispatchSemaphore(value: scene.renderOptions.maxFramesInFlight)
        
        let sampleDescriptor = MTLSamplerDescriptor()
        sampleDescriptor.minFilter = .linear
        sampleDescriptor.magFilter = .linear
        
        self.textureSampler = device.makeSamplerState(descriptor: sampleDescriptor)
    }
    
    private func createPipelines() {
        self.rayPipeline = ComputePipelineStateLibrary.pipelineState(.GenerateRay).computePipelineState
        self.shadePipeline = ComputePipelineStateLibrary.pipelineState(.Shade).computePipelineState
        self.shadowPipeline = ComputePipelineStateLibrary.pipelineState(.Shadow).computePipelineState
        self.accumulatePipeline = ComputePipelineStateLibrary.pipelineState(.Accumulate).computePipelineState
        
        self.copyPipeline = RenderPipelineStateLibrary.pipelineState(.RayTracing)
    }
    
    private func createScene() {
        SceneManager.setScene(.Sandbox, view.drawableSize)
        scene = SceneManager.currentScene
        scene.skyBox = Skyboxibrary.skybox(.Sky)
        scene.postBuildScene()
    }
    
    private func createIntersector() {
        intersector = MPSRayIntersector(device: device)
        intersector.rayDataType = .originMaskDirectionMaxDistance
        intersector.rayStride = scene.renderOptions.rayStride
        intersector.rayMaskOptions = scene.renderOptions.rayMaskOptions
    }

    override func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        self.size = size
        
        if size.width == 0 || size.height == 0 {
            return
        }

        lastCheckPoint = Date()
        timeIntervals.removeAll()


        let rayCount = Int(size.width * size.height)

        rayBuffer = device.makeBuffer(length: scene.renderOptions.rayStride * rayCount, options: .storageModePrivate)
        shadowRayBuffer = device.makeBuffer(length: scene.renderOptions.rayStride * rayCount, options: .storageModePrivate)
        intersectionBuffer = device.makeBuffer(length: scene.renderOptions.intersectionStride * rayCount,
                                               options: .storageModePrivate)

        let renderTargetDescriptor = MTLTextureDescriptor()
        renderTargetDescriptor.pixelFormat = .rgba32Float
        renderTargetDescriptor.textureType = .type2D
        renderTargetDescriptor.width = Int(size.width)
        renderTargetDescriptor.height = Int(size.height)
        renderTargetDescriptor.storageMode = .private
        renderTargetDescriptor.usage = [.shaderRead, .shaderWrite]
        
        
        renderTarget = device.makeTexture(descriptor: renderTargetDescriptor)!
        
        accumulationTarget = device.makeTexture(descriptor: renderTargetDescriptor)!
        
        let randomTextureDescriptor = MTLTextureDescriptor()
        randomTextureDescriptor.pixelFormat = .r32Uint
        randomTextureDescriptor.textureType = .type2D
        randomTextureDescriptor.width = Int(size.width)
        randomTextureDescriptor.height = Int(size.height)
        randomTextureDescriptor.usage = .shaderRead
        
        randomTexture = device.makeTexture(descriptor: randomTextureDescriptor)!
        
        var randomValues: [__uint32_t] = []
        
        for _ in 0..<(Int(size.width) * Int(size.height)) {
            randomValues.append(arc4random() % (1024 * 1024))
        }
        
        randomTexture.replace(region: MTLRegionMake2D(0, 0, Int(size.width), Int(size.height)), mipmapLevel: 0, withBytes: randomValues, bytesPerRow: MemoryLayout<__uint32_t>.size * Int(size.width))
        
        scene.frameIndex = 0
    }

    override func draw(in view: MTKView) {
        if size.width == 0 || size.height == 0 {
            return
        }
        
        semaphore.wait()
        
        // Rendering performance report
        let now = Date()
        let timePassed = now.timeIntervalSince(lastCheckPoint)
        if timePassed > 1 {
            let totalPixels = Int(size.width * size.height) * timeIntervals.count
            let totalTime = timeIntervals.reduce(0, +)
            DispatchQueue.main.async { [unowned self] in
                self.display(Double(totalPixels) / totalTime)
            }
            timeIntervals.removeAll()
            lastCheckPoint = now
        }
        
        let desc = MTLCommandBufferDescriptor()
        desc.errorOptions = .encoderExecutionStatus

        let commandBuffer = Engine.commandQueue.makeCommandBuffer(descriptor: desc)!
        commandBuffer.addCompletedHandler { [unowned self] cb in
            let executionDuration = cb.gpuEndTime - cb.gpuStartTime
            self.timeIntervals.append(executionDuration)
            self.semaphore.signal()
        }
        
        SceneManager.tickScene(deltaTime: 1.0/Float(view.preferredFramesPerSecond))
        scene.updateUniforms(size: view.drawableSize)

        let width = Int(size.width)
        let height = Int(size.height)
        let w = rayPipeline.threadExecutionWidth
        let h = rayPipeline.maxTotalThreadsPerThreadgroup / w
        let threadsPerThreadgroup = MTLSizeMake(w, h, 1)


        let computeEncoder = commandBuffer.makeComputeCommandEncoder()!

        computeEncoder.setBuffer(scene.uniformBuffer, offset: scene.uniformBufferOffset, index: 0)
        computeEncoder.setBuffer(rayBuffer, offset: 0, index: 1)

        computeEncoder.setTexture(randomTexture, index: 0)
        computeEncoder.setTexture(renderTarget, index: 1)

        computeEncoder.setComputePipelineState(rayPipeline)

        let threadsPerGrid = MTLSizeMake(width, height, 1)
        computeEncoder.dispatchThreads(threadsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)

        computeEncoder.endEncoding()
        for i in 0..<scene.renderOptions.maxBounce {
            intersector.intersectionDataType = scene.renderOptions.intersectionDataType
            intersector.encodeIntersection(commandBuffer: commandBuffer,
                                           intersectionType: .nearest,
                                           rayBuffer: rayBuffer,
                                           rayBufferOffset: 0,
                                           intersectionBuffer: intersectionBuffer,
                                           intersectionBufferOffset: 0,
                                           rayCount: width * height,
                                           accelerationStructure: scene.getAccelerationStructure())
            guard let shadeEncoder = commandBuffer.makeComputeCommandEncoder() else { return }

            let buffers = [scene.uniformBuffer, rayBuffer, shadowRayBuffer, intersectionBuffer, scene.vertexBuffer, scene.customIndexBuffer, scene.verticesCountBuffer, scene.indiciesCountBuffer, scene.maskBuffer, scene.materialBuffer, scene.textureBuffer]
            let offsets: [Int] = [scene.uniformBufferOffset, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
            
            shadeEncoder.useHeap(scene.heap.heap)
            shadeEncoder.setBuffers(buffers, offsets: offsets, range: 0..<buffers.count)
        
            var bounce = UInt32(i)
            
            shadeEncoder.setBytes(&bounce, length: uint.size, index: buffers.count)
            shadeEncoder.setTexture(randomTexture, index: 0)
            shadeEncoder.setTexture(renderTarget, index: 1)
            shadeEncoder.setTexture(scene.skyBox, index: 2)
            
            shadeEncoder.setSamplerState(textureSampler, index: 0)
            shadeEncoder.setComputePipelineState(shadePipeline)
            shadeEncoder.dispatchThreads(threadsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
            shadeEncoder.endEncoding()
            
            intersector.intersectionDataType = scene.renderOptions.intersectionDataType
            intersector.encodeIntersection(commandBuffer: commandBuffer, intersectionType: .any, rayBuffer: shadowRayBuffer, rayBufferOffset: 0, intersectionBuffer: intersectionBuffer, intersectionBufferOffset: 0, rayCount: width * height, accelerationStructure: scene.getAccelerationStructure())
            
            
            intersector.intersectionDataType = .distance
            intersector.encodeIntersection(commandBuffer: commandBuffer,
                                           intersectionType: .any,
                                           rayBuffer: shadowRayBuffer,
                                           rayBufferOffset: 0,
                                           intersectionBuffer: intersectionBuffer,
                                           intersectionBufferOffset: 0,
                                           rayCount: width * height,
                                           accelerationStructure: scene.getAccelerationStructure())

            guard let colorEncoder = commandBuffer.makeComputeCommandEncoder() else { return }
            colorEncoder.setBuffer(scene.uniformBuffer, offset: scene.uniformBufferOffset, index: 0)
            colorEncoder.setBuffer(shadowRayBuffer, offset: 0, index: 1)
            colorEncoder.setBuffer(intersectionBuffer, offset: 0, index: 2)

            colorEncoder.setTexture(renderTarget, index: 0)
            colorEncoder.setComputePipelineState(shadowPipeline)
            colorEncoder.dispatchThreads(threadsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
            colorEncoder.endEncoding()
            
        }
        
        guard let denoiseEncoder = commandBuffer.makeComputeCommandEncoder() else { return }
        denoiseEncoder.setBuffer(scene.uniformBuffer, offset: scene.uniformBufferOffset, index: 0)

        denoiseEncoder.setTexture(renderTarget, index: 0)
        denoiseEncoder.setTexture(accumulationTarget, index: 1)
        
        denoiseEncoder.setComputePipelineState(accumulatePipeline)
        denoiseEncoder.dispatchThreads(threadsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
        denoiseEncoder.endEncoding()


        if let renderPassDescriptor = view.currentRenderPassDescriptor {
            guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else { return }
            renderEncoder.setRenderPipelineState(copyPipeline)
            renderEncoder.setFragmentTexture(accumulationTarget, index: 0)
            renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
            renderEncoder.endEncoding()
            guard let drawable = view.currentDrawable else { return }
            commandBuffer.present(drawable)
        }
        commandBuffer.commit()
        
        if let error = commandBuffer.error as NSError? {
            
            if let encoderInfos = error.userInfo[MTLCommandBufferEncoderInfoErrorKey] as? [MTLCommandBufferEncoderInfo] {
                
                for info in encoderInfos {
                    print(info.label + info.debugSignposts.joined())
                    if info.errorState == .faulted {
                        print(info.label + "faulted!")
                    }
                }
            }
        }
    }
}
