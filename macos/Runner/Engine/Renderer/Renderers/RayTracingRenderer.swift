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
    
    var rayPipeline:        MTLComputePipelineState!
    var shadePipeline:      MTLComputePipelineState!
    var shadowPipeline:     MTLComputePipelineState!
    var accumulatePipeline: MTLComputePipelineState!
    var copyPipeline:       MTLRenderPipelineState!
    var renderPipeline:     MTLRenderPipelineState!
    
    var denoiserRasterizerPipeline: MTLRenderPipelineState!
    var shadowDenoiserPipeline:     MTLComputePipelineState!
    var compositePipeline:          MTLComputePipelineState!
    
    var shadowWithAlphaTestingPipeline:     MTLComputePipelineState!
    
    var renderTarget:               MTLTexture!
    var accumulationTarget:         MTLTexture!
    var previousTexture:            MTLTexture!
    var previousDepthNormalTexture: MTLTexture!
    var shadowRayTexture:           MTLTexture!
    var shadowTexture:              MTLTexture!
    var intersectionTexture:        MTLTexture!
    var randomTexture:              MTLTexture!
    
    var depthStencilState: MTLDepthStencilState!
    
    var svgf: MPSSVGF!
    var textureAllocator: MPSSVGFDefaultTextureAllocator!
    var TAA: MPSTemporalAA!
    var denoiser: MPSSVGFDenoiser!
    
    var semaphore: DispatchSemaphore!
    var size: CGSize!
    var threadsPerThreadgroup = MTLSizeMake(16, 16, 1)
    
    var lastCheckPoint = Date()
    var timeIntervals: [CFTimeInterval] = []
    
    var iterationCount = 0
    
    var scene: RTScene!
    
    private var _renderSettings: RayTracingSettings = RayTracingSettings(quality: .high, samples: 400, maxBounce: 6, alphaTesting: false)
    
    override func initialize() {
        
        self.updateViewPort()
        self.createPipelines()
        self.createIntersector()
        
        if scene is DynamicRTScene {
            self.loadMPSSVGF()

            let depthStencilDescriptor = MTLDepthStencilDescriptor()
            
            depthStencilDescriptor.isDepthWriteEnabled = true
            depthStencilDescriptor.depthCompareFunction = .less
            
            depthStencilState = Engine.device.makeDepthStencilState(descriptor: depthStencilDescriptor)
        }
        
        semaphore = DispatchSemaphore(value: scene.renderOptions.maxFramesInFlight)
        
        let sampleDescriptor = MTLSamplerDescriptor()
        sampleDescriptor.minFilter = .linear
        sampleDescriptor.magFilter = .linear
        
        self.textureSampler = device.makeSamplerState(descriptor: sampleDescriptor)
    }
    
    override func onResume() {
        scene.frameIndex = 0
    }
    
    override func updateRenderSettings(settings: RenderingSettings) {
        scene.frameIndex = 0
        _renderSettings = (settings as? RayTracingSettings) ?? _renderSettings
    }
    
    override func updateViewPort() {
        if !(SceneManager.currentRenderableScene is RTScene) {
            fatalError("Renderer and ViewPort mismatch!")
        }
        
        scene = (SceneManager.currentRenderableScene as! RTScene)
    }
    
    override func renderModeInitialize() {
        iterationCount = 0
    }
    
    private func createPipelines() {
        rayPipeline = ComputePipelineStateLibrary.pipelineState(.GenerateRay).computePipelineState
        shadePipeline = ComputePipelineStateLibrary.pipelineState(.Shade).computePipelineState
        shadowPipeline = ComputePipelineStateLibrary.pipelineState(.Shadow).computePipelineState
        shadowWithAlphaTestingPipeline = ComputePipelineStateLibrary.pipelineState(.ShadowWithAlphaTesting).computePipelineState
        accumulatePipeline = ComputePipelineStateLibrary.pipelineState(.Accumulate).computePipelineState
        
        copyPipeline = RenderPipelineStateLibrary.pipelineState(.RayTracing)
        renderPipeline = RenderPipelineStateLibrary.pipelineState(.Rendering)
        
        if scene is DynamicRTScene {
            denoiserRasterizerPipeline = RenderPipelineStateLibrary.pipelineState(.DenoiserRasterizer)
            compositePipeline = ComputePipelineStateLibrary.pipelineState(.Compositing).computePipelineState
        }
    }
    
    private func createIntersector() {
        intersector = MPSRayIntersector(device: device)
        intersector.rayDataType = .originMaskDirectionMaxDistance
        intersector.rayStride = scene.renderOptions.rayStride
        intersector.rayMaskOptions = scene.renderOptions.rayMaskOptions
    }
    
    private func loadMPSSVGF() {
        svgf = MPSSVGF(device: device)
        svgf.channelCount = 1
        svgf.temporalWeighting = .exponentialMovingAverage
        svgf.temporalReprojectionBlendFactor = 0.1
        
        textureAllocator = MPSSVGFDefaultTextureAllocator(device: device)
        denoiser = MPSSVGFDenoiser(SVGF: svgf, textureAllocator: textureAllocator)
        denoiser.bilateralFilterIterations = 5;
        
        TAA = MPSTemporalAA(device: Engine.device)
        
    }
    
    override func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        self.size = size
        
        if size.width == 0 || size.height == 0 {
            return
        }
        
        if scene is DynamicRTScene {
            dynamicRTMTKView(view, drawableSizeWillChange: size)
        } else {
            let textureDescriptor = MTLTextureDescriptor()
            textureDescriptor.pixelFormat = .r16Float
            textureDescriptor.textureType = .type2D
            textureDescriptor.width =  Int(size.width)
            textureDescriptor.height = Int(size.height)
            textureDescriptor.usage = .shaderWrite
            shadowTexture = Engine.device.makeTexture(descriptor: textureDescriptor)
        }

        lastCheckPoint = Date()
        timeIntervals.removeAll()


        let rayCount = Int(size.width * size.height)

        rayBuffer = device.makeBuffer(length: scene.renderOptions.rayStride * rayCount, options: .storageModePrivate)
        shadowRayBuffer = device.makeBuffer(length: scene.renderOptions.rayStride * rayCount, options: .storageModePrivate)
        intersectionBuffer = device.makeBuffer(length: scene.renderOptions.intersectionStride * rayCount, options: .storageModePrivate)

        let renderTargetDescriptor = MTLTextureDescriptor()
        renderTargetDescriptor.pixelFormat = .rgba32Float
        renderTargetDescriptor.textureType = .type2D
        renderTargetDescriptor.width =  Int(size.width)
        renderTargetDescriptor.height = Int(size.height)
        renderTargetDescriptor.storageMode = .shared
        renderTargetDescriptor.usage = [.shaderRead, .shaderWrite, .renderTarget]
        
        renderTarget = device.makeTexture(descriptor: renderTargetDescriptor)!
        accumulationTarget = device.makeTexture(descriptor: renderTargetDescriptor)!
        
        let randomTextureDescriptor = MTLTextureDescriptor()
        randomTextureDescriptor.pixelFormat = .r32Uint
        randomTextureDescriptor.textureType = .type2D
        randomTextureDescriptor.width =  Int(size.width)
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
        if renderMode == .display {
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
        } else {
            iterationCount += 1
            
            if iterationCount == 4 {
                // Textures initially are not loaded properly so skipping first few frames
                // else final image may have a tint of purple
                scene.frameIndex = 0
            }
            
            if iterationCount > (_renderSettings.samples + 6) {
                renderMode = .display
                RendererManager.onRenderingComplete()
            }
        }
        
        let desc = MTLCommandBufferDescriptor()
        desc.errorOptions = .encoderExecutionStatus

        let commandBuffer = Engine.commandQueue.makeCommandBuffer(descriptor: desc)!
        
        commandBuffer.addCompletedHandler { [unowned self] cb in
            let executionDuration = cb.gpuEndTime - cb.gpuStartTime
            self.timeIntervals.append(executionDuration)
            self.semaphore.signal()
        }
        
        
        if !(renderMode == .render && scene is DynamicRTScene) {
            SceneManager.tickScene(deltaTime: 1.0/Float(view.preferredFramesPerSecond))
        }
        
        scene.updateUniforms(size: view.drawableSize, renderQuality: _renderSettings.quality)
        
        let width = Int(size.width)
        let height = Int(size.height)
        let threadsPerGrid = MTLSizeMake(width, height, 1)

        generateRays(commandBuffer: commandBuffer, threadsPerGrid: threadsPerGrid)
        
        let maxBounce = _renderSettings.maxBounce
        
        for i in 0..<maxBounce {
            reflectRays(bounce: i, commandBuffer: commandBuffer, threadsPerGrid: threadsPerGrid)
            
            if _renderSettings.alphaTesting {
                traceShadowsWithAlphaTesting(commandBuffer: commandBuffer, threadsPerGrid: threadsPerGrid)
            } else {
                traceShadows(commandBuffer: commandBuffer, threadsPerGrid: threadsPerGrid)
            }
        }
        
        denoiseFrame(commandBuffer: commandBuffer, threadsPerGrid: threadsPerGrid)
        
        if let renderPassDescriptor = view.currentRenderPassDescriptor {
            guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else { return }
            renderEncoder.setRenderPipelineState(copyPipeline)
            renderEncoder.setFragmentTexture(accumulationTarget, index: 0)
            renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
            renderEncoder.endEncoding()
            guard let drawable = view.currentDrawable else { return }
            if renderMode == .render {
                self.renderedTexture = view.currentDrawable?.texture
            }
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
    
    private func generateRays(commandBuffer: MTLCommandBuffer, threadsPerGrid: MTLSize) {
        let computeEncoder = commandBuffer.makeComputeCommandEncoder()!

        computeEncoder.setBuffer(scene.uniformBuffer, offset: scene.uniformBufferOffset, index: 0)
        computeEncoder.setBuffer(rayBuffer, offset: 0, index: 1)

        computeEncoder.setTexture(randomTexture, index: 0)
        computeEncoder.setTexture(renderTarget, index: 1)

        computeEncoder.setComputePipelineState(rayPipeline)

        
        computeEncoder.dispatchThreads(threadsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)

        computeEncoder.endEncoding()
    }
    
    private func reflectRays(bounce: Int, commandBuffer: MTLCommandBuffer, threadsPerGrid: MTLSize) {
        intersector.intersectionDataType = scene.renderOptions.intersectionDataType

        intersector.encodeIntersection(commandBuffer: commandBuffer,
                                       intersectionType: .nearest,
                                       rayBuffer: rayBuffer,
                                       rayBufferOffset: 0,
                                       intersectionBuffer: intersectionBuffer,
                                       intersectionBufferOffset: 0,
                                       rayCount: Int(size.width * size.height),
                                       accelerationStructure: scene.getAccelerationStructure())
        guard let shadeEncoder = commandBuffer.makeComputeCommandEncoder() else { return }
        
        let buffers = [scene.uniformBuffer, scene.lightBuffer, rayBuffer, shadowRayBuffer, intersectionBuffer, scene.vertexBuffer, scene.customIndexBuffer, scene.verticesCountBuffer, scene.indiciesCountBuffer, scene.maskBuffer, scene.materialBuffer, scene.textureBuffer]
        let offsets: [Int] = [scene.uniformBufferOffset, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
        
        shadeEncoder.useHeap(scene.heap.heap)
        shadeEncoder.setBuffers(buffers, offsets: offsets, range: 0..<buffers.count)
    
        var _bounce = UInt32(bounce)
        shadeEncoder.setBytes(&_bounce, length: UInt32.size, index: buffers.count)
        
        shadeEncoder.setTexture(randomTexture, index: 0)
        shadeEncoder.setTexture(renderTarget, index: 1)
        shadeEncoder.setTexture(scene.skyBox, index: 2)
        
        shadeEncoder.setSamplerState(textureSampler, index: 0)
        shadeEncoder.setComputePipelineState(shadePipeline)
        shadeEncoder.dispatchThreads(threadsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
        shadeEncoder.endEncoding()
    }
    
    private func traceShadows(commandBuffer: MTLCommandBuffer, threadsPerGrid: MTLSize) {
        intersector.intersectionDataType = .distance
        intersector.encodeIntersection(commandBuffer: commandBuffer,
                                       intersectionType: .any,
                                       rayBuffer: shadowRayBuffer,
                                       rayBufferOffset: 0,
                                       intersectionBuffer: intersectionBuffer,
                                       intersectionBufferOffset: 0,
                                       rayCount: Int(size.width * size.height),
                                       accelerationStructure: scene.getAccelerationStructure())

        guard let colorEncoder = commandBuffer.makeComputeCommandEncoder() else { return }
        colorEncoder.setBuffer(scene.uniformBuffer, offset: scene.uniformBufferOffset, index: 0)
        colorEncoder.setBuffer(shadowRayBuffer, offset: 0, index: 1)
        colorEncoder.setBuffer(intersectionBuffer, offset: 0, index: 2)

        colorEncoder.setTexture(renderTarget, index: 0)
        colorEncoder.setTexture(shadowTexture, index: 1)
        colorEncoder.setComputePipelineState(shadowPipeline)
        
        colorEncoder.dispatchThreads(threadsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
        colorEncoder.endEncoding()
    }
    
    private func traceShadowsWithAlphaTesting(commandBuffer: MTLCommandBuffer, threadsPerGrid: MTLSize) {
        
        guard let colorEncoder = commandBuffer.makeComputeCommandEncoder() else { return }
        colorEncoder.setAccelerationStructure(scene.getMTLAccelerationStructure(), bufferIndex: 0)
        colorEncoder.setBuffer(scene.uniformBuffer, offset: scene.uniformBufferOffset, index: 1)
        colorEncoder.setBuffer(shadowRayBuffer, offset: 0, index: 2)
        colorEncoder.setBuffer(scene.vertexBuffer, offset: 0, index: 3);
        colorEncoder.setBuffer(scene.customIndexBuffer, offset: 0, index: 4);
        colorEncoder.setBuffer(scene.verticesCountBuffer, offset: 0, index: 5);
        colorEncoder.setBuffer(scene.indiciesCountBuffer, offset: 0, index: 6);
        colorEncoder.setBuffer(scene.materialBuffer, offset: 0, index: 7);
        colorEncoder.setBuffer(scene.textureBuffer, offset: 0, index: 8);

        colorEncoder.setTexture(renderTarget, index: 0)
        colorEncoder.setTexture(shadowTexture, index: 1)
        colorEncoder.setComputePipelineState(shadowWithAlphaTestingPipeline)
        
        colorEncoder.dispatchThreads(threadsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
        colorEncoder.endEncoding()
    }
    
    private func denoiseFrame(commandBuffer: MTLCommandBuffer, threadsPerGrid: MTLSize) {
        if (renderMode != .render) && (scene is DynamicRTScene) {
//            denoiseDynamicScene(commandBuffer: commandBuffer, threadsPerGrid: threadsPerGrid)
            accumulationTarget = renderTarget
            return
        }
        
        guard let denoiseEncoder = commandBuffer.makeComputeCommandEncoder() else { return }
        denoiseEncoder.setBuffer(scene.uniformBuffer, offset: scene.uniformBufferOffset, index: 0)

        denoiseEncoder.setTexture(renderTarget, index: 0)
        denoiseEncoder.setTexture(accumulationTarget, index: 1)
        
        denoiseEncoder.setComputePipelineState(accumulatePipeline)
        denoiseEncoder.dispatchThreads(threadsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
        denoiseEncoder.endEncoding()
    }
    
    private func denoiseDynamicScene(commandBuffer: MTLCommandBuffer, threadsPerGrid: MTLSize) {
        
        var colorTexture = textureAllocator.texture(with: .rgba16Float, width: Int(size.width), height: Int(size.height))!
        var depthNormalTexture = textureAllocator.texture(with: .rgba16Float, width: Int(size.width), height: Int(size.height))!
        var motionVectorTexture = textureAllocator.texture(with: .rg16Float, width: Int(size.width), height: Int(size.height))!
        
        encodeRasterizationToCommandBuffer(commandBuffer: commandBuffer, colorTexture: &colorTexture, depthNormalTexture: &depthNormalTexture, motionVectorTexture: &motionVectorTexture)
        
        let denoisedTexture = denoiser.encode(commandBuffer: commandBuffer, sourceTexture: renderTarget, motionVectorTexture: motionVectorTexture, depthNormalTexture: depthNormalTexture, previousDepthNormalTexture: previousDepthNormalTexture)
        
        textureAllocator.return(denoisedTexture)
        
        accumulationTarget = denoisedTexture
        
//        encodeCompositeToCommandBuffer(commandBuffer: commandBuffer, colorTexture: renderTarget, shadowTexture: shadowTexture, threadsPerGrid: threadsPerGrid)
//        accumulationTarget =
    }
    
    private func encodeCompositeToCommandBuffer(commandBuffer: MTLCommandBuffer, colorTexture: MTLTexture, shadowTexture: MTLTexture, threadsPerGrid: MTLSize) {
        
//        let compositeTexture = textureAllocator.texture(with: .rg16Float, width: Int(shadowRayTexture.width), height: Int(shadowRayTexture.height))
        
        let computeEncoder = commandBuffer.makeComputeCommandEncoder()!
        
        computeEncoder.setBytes(&scene.uniforms, length: MemoryLayout<Uniforms>.stride, index: 0)
        
        computeEncoder.setTexture(colorTexture, index: 0)
        computeEncoder.setTexture(shadowTexture, index: 1)
        computeEncoder.setTexture(accumulationTarget, index: 2)
        
        computeEncoder.setComputePipelineState(compositePipeline)
        
        computeEncoder.dispatchThreads(threadsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
        
        computeEncoder.endEncoding()
        
    }
    
    private func dynamicRTMTKView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        denoiser.releaseTemporaryTextures()
        textureAllocator.reset()
        
        shadowTexture = textureAllocator.texture(with: .r16Float, width: Int(size.width), height: Int(size.height))
        previousDepthNormalTexture = textureAllocator.texture(with: .rgba16Float, width: Int(size.width), height: Int(size.height))
        previousTexture = textureAllocator.texture(with: .rgba16Float, width: Int(size.width), height: Int(size.height))
        
        let renderTargetDescriptor = MTLTextureDescriptor()
        
        renderTargetDescriptor.width = Int(size.width)
        renderTargetDescriptor.height = Int(size.height)
        
        // Generate a 2xRGBA32Float 2D array texture to contain shadow ray origins,
        // min distances, directions, and max distances.
        renderTargetDescriptor.textureType = .type2DArray
        renderTargetDescriptor.pixelFormat = .rgba32Float
        renderTargetDescriptor.usage = [.renderTarget , .shaderRead]
        renderTargetDescriptor.storageMode = .private
        renderTargetDescriptor.arrayLength = 2
        
        shadowRayTexture = Engine.device.makeTexture(descriptor: renderTargetDescriptor)
        
        // Generate a 1xR32Float 2D array texture to contain the corresponding
        // intersection distance.
        renderTargetDescriptor.usage = [.shaderWrite , .shaderRead]
        renderTargetDescriptor.arrayLength = 1
        renderTargetDescriptor.pixelFormat = .r32Float
        
        intersectionTexture = Engine.device.makeTexture(descriptor: renderTargetDescriptor)
        
        // Finally, allocate a 2D R32UInt texture to contain random values for each
        // pixel. This value is used to decorrelate pixels while drawing pseudorandom
        // numbers from a Halton sequence while generating shadow rays.
        renderTargetDescriptor.textureType = .type2D
        renderTargetDescriptor.pixelFormat = .r8Uint
        renderTargetDescriptor.usage = .shaderRead
        renderTargetDescriptor.arrayLength = 1
        renderTargetDescriptor.storageMode = .shared
    }
    
    private func encodeRasterizationToCommandBuffer(commandBuffer: MTLCommandBuffer, colorTexture: inout MTLTexture, depthNormalTexture: inout MTLTexture, motionVectorTexture: inout MTLTexture) {
        
        let depthTexture = textureAllocator.texture(with: .depth32Float, width: Int(size.width), height: Int(size.height))!
        
        let renderPass = MTLRenderPassDescriptor()
        
        renderPass.colorAttachments[0].texture = colorTexture
        renderPass.colorAttachments[0].loadAction = .clear;
        renderPass.colorAttachments[0].clearColor = MTLClearColorMake(0.0, 0.0, 0.0, 1.0)
        renderPass.colorAttachments[0].storeAction = .store
        
        renderPass.colorAttachments[1].texture = depthNormalTexture;
        renderPass.colorAttachments[1].loadAction = .clear
        renderPass.colorAttachments[1].clearColor = MTLClearColorMake(1000.0, 0.0, 0.0, 0.0)
        renderPass.colorAttachments[1].storeAction = .store
        
        renderPass.colorAttachments[2].texture = motionVectorTexture
        renderPass.colorAttachments[2].loadAction = .clear
        renderPass.colorAttachments[2].clearColor = MTLClearColorMake(0.0, 0.0, 0.0, 0.0)
        renderPass.colorAttachments[2].storeAction = .store
        
        renderPass.colorAttachments[3].texture = shadowRayTexture;
        renderPass.colorAttachments[3].slice = 0;
        renderPass.colorAttachments[3].loadAction = .clear
        renderPass.colorAttachments[3].clearColor = MTLClearColorMake(0.0, 0.0, 0.0, 0.0)
        renderPass.colorAttachments[3].storeAction = .store
        
        renderPass.colorAttachments[4].texture = shadowRayTexture
        renderPass.colorAttachments[4].slice = 1
        renderPass.colorAttachments[4].loadAction = .clear
        // This clears the "max distance" field to -1 so the ray intersector
        // will exit immediately for pixels which are not covered by any geometry
        renderPass.colorAttachments[4].clearColor = MTLClearColorMake(0.0, 0.0, 0.0, -1.0)
        renderPass.colorAttachments[4].storeAction = .store
        
        renderPass.depthAttachment.texture = depthTexture
        renderPass.depthAttachment.loadAction = .clear
        renderPass.depthAttachment.clearDepth = 1.0
        renderPass.depthAttachment.storeAction = .dontCare
        
        let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPass)!
        
        let _scene = scene as! DynamicRTScene
        renderEncoder.setVertexBytes(&_scene.uniforms, length: MemoryLayout<Uniforms>.size, index: 0)
        renderEncoder.setVertexBytes(&_scene.prevUniforms, length: MemoryLayout<Uniforms>.size, index: 1)
        
        renderEncoder.setVertexBuffer(_scene.instanceTransformBuffer, offset:_scene.getInstanceTransformBufferOffset(), index: 3)
        renderEncoder.setVertexBuffer(_scene.instanceTransformBuffer, offset:_scene.getPreviousInstanceTransformBufferOffset(), index: 4)
        renderEncoder.setVertexBuffer(_scene.instanceNormalTransformBuffer, offset:_scene.getInstanceNormalTransformBufferOffset(), index: 5)
        
        renderEncoder.setFragmentBytes(&_scene.uniforms, length: MemoryLayout<Uniforms>.size, index: 0)
        renderEncoder.setFragmentBytes(&_scene.prevUniforms, length: MemoryLayout<Uniforms>.size, index: 1)
        
        renderEncoder.setFragmentTexture(randomTexture, index: 0)
        
        renderEncoder.setRenderPipelineState(denoiserRasterizerPipeline)
        renderEncoder.setDepthStencilState(depthStencilState)
                
        var instanceIndex: uint32 = 0
        
        // Draw each object instance in the scene in turn
        for  j in 0..<_scene.objects.count {
            let solid = _scene.objects[j]
            for i in 0..<solid.mesh.submeshCount {
                // All of the objects are packed into one set of vertex buffers,
                // so you need to bind them at this object's offset. Provide both
                // the current frame and previous frame's vertex data.
                let indexBuffer = solid.mesh.indexBuffers[i]
                let indexCount = indexBuffer.length / UInt32.stride
                
                renderEncoder.setVertexBuffer(_scene.denoiserDataBuffer, offset: _scene.accelerationStructures[j][i].vertexBufferOffset, index: 2)
                
                // Provide the instance index which will be used by the shader to look
                // up the transformation matrix.
                renderEncoder.setVertexBytes(&instanceIndex, length: uint32.size, index: 6)
                
                renderEncoder.drawIndexedPrimitives(type: .triangle, indexCount: indexCount, indexType: .uint32, indexBuffer: _scene.indexBuffer, indexBufferOffset: 0)
                
                instanceIndex += 1
            }
        }
        
        renderEncoder.endEncoding()
        
        
        textureAllocator.return(depthTexture)
    }
}
