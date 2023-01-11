import MetalKit
import MetalPerformanceShaders
import simd
import os

let maxBounce = 6

let maxFramesInFlight = 3
let alignedUniformsSize = (MemoryLayout<Uniforms>.stride + 255) & ~255

let rayStride = 48
let intersectionStride = MemoryLayout<MPSIntersectionDistancePrimitiveIndexCoordinates>.size

class RayTracingRenderer: Renderer {

    var accelerationStructure: MPSTriangleAccelerationStructure!
    var intersector: MPSRayIntersector!

    var vertexPositionBuffer: MTLBuffer!
    var vertexNormalBuffer: MTLBuffer!
    var vertexTangentBuffer: MTLBuffer!
    var vertexBitangentBuffer: MTLBuffer!
    var vertexColorBuffer: MTLBuffer!
    var textureIdsBuffer: MTLBuffer!
    var materialIdsBuffer: MTLBuffer!
    var uvCoordsBuffer: MTLBuffer!
    
    var rayBuffer: MTLBuffer!
    var shadowRayBuffer: MTLBuffer!
    var intersectionBuffer: MTLBuffer!
    var uniformBuffer: MTLBuffer!
    var triangleMaskBuffer: MTLBuffer!
    
    var textureBuffer: MTLBuffer!
    var materialBuffer: MTLBuffer!
    var sourceTextures: MTLBuffer!
    var texture: MTLTexture!
    
    var heap: Heap!
    
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
    var uniformBufferOffset: Int!
    var uniformBufferIndex: Int = 0

    var frameIndex: uint = 0

    var lastCheckPoint = Date()
    var timeIntervals: [CFTimeInterval] = []
    
    override func initialize() {
        semaphore = DispatchSemaphore(value: maxFramesInFlight)
        
        self.createPipelines()
        self.createScene()
        self.createBuffers()
        self.createIntersector()
        heap = Heap()
        heap.initialize(scene: scene, sourceTextureBuffer: &sourceTextures)
        
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
    }
    
    private func createBuffers() {
        var vertices = scene.vertices
        var normals = scene.normals
        var tangents = scene.tangents
        var bitangents = scene.bitangents
        var colors = scene.colors
        var masks = scene.masks
        var textureIds: [uint] = []
        var materialIds: [uint] = []
        var uvCoords = scene.uvCoordinates
        
        for i in stride(from: 0, to: scene.materialIds.count, by: 3) {
            materialIds.append(scene.materialIds[i])
        }
        
        for i in stride(from: 0, to: scene.textureIds.count, by: 3) {
            textureIds.append(scene.textureIds[i])
        }
        
        let uniformBufferSize = alignedUniformsSize * maxFramesInFlight

        let storageOptions: MTLResourceOptions

        #if arch(x86_64)
        storageOptions = .storageModeManaged
        #else // iOS, tvOS
        storageOptions = .storageModeShared
        #endif


        self.uniformBuffer = device.makeBuffer(length: uniformBufferSize, options: storageOptions)

        let float3Size = SIMD3<Float>.stride
        self.vertexPositionBuffer = device.makeBuffer(bytes: &vertices, length: vertices.count * float3Size, options: storageOptions)
        self.vertexColorBuffer = device.makeBuffer(bytes: &colors, length: colors.count * float3Size, options: storageOptions)
        self.vertexNormalBuffer = device.makeBuffer(bytes: &normals, length: normals.count * float3Size, options: storageOptions)
        self.vertexTangentBuffer = device.makeBuffer(bytes: &tangents, length: tangents.count * float3Size, options: storageOptions)
        self.vertexBitangentBuffer = device.makeBuffer(bytes: &bitangents, length: bitangents.count * float3Size, options: storageOptions)
        self.triangleMaskBuffer = device.makeBuffer(bytes: &masks, length: masks.count * uint.stride, options: storageOptions)
        
        var materials: [Material] = scene.materials
        self.materialBuffer = device.makeBuffer(bytes: &materials, length: Material.stride(materials.count), options: storageOptions)
        self.materialIdsBuffer = device.makeBuffer(bytes: &materialIds, length: uint.stride(materialIds.count), options: storageOptions)
        
        self.textureIdsBuffer = device.makeBuffer(bytes: &textureIds, length: uint.stride(textureIds.count), options: storageOptions)
        
        self.uvCoordsBuffer = device.makeBuffer(bytes: &uvCoords, length: SIMD2<Float>.stride * uvCoords.count, options: storageOptions)
        
//        print(uvCoords.count);
//        print(textureIds.count);
        // When using managed buffers, we need to indicate that we modified the buffer so that the GPU
        // copy can be updated
        #if arch(x86_64)
        if storageOptions.contains(.storageModeManaged) {
            vertexPositionBuffer.didModifyRange(0..<vertexPositionBuffer.length)
            vertexColorBuffer.didModifyRange(0..<vertexColorBuffer.length)
            vertexNormalBuffer.didModifyRange(0..<vertexNormalBuffer.length)
            triangleMaskBuffer.didModifyRange(0..<triangleMaskBuffer.length)
            reflectivityBuffer.didModifyRange(0..<reflectivityBuffer.length)
            refractiveIndexBuffer.didModifyRange(0..<refractiveIndexBuffer.length)
        }
        #endif
    }
    
    private func createIntersector() {
        intersector = MPSRayIntersector(device: device)
        intersector.rayDataType = .originMaskDirectionMaxDistance
        intersector.rayStride = rayStride
        intersector.rayMaskOptions = .primitive

        // Create an acceleration structure from our vertex position data
        accelerationStructure = MPSTriangleAccelerationStructure(device: device)
        accelerationStructure.vertexBuffer = vertexPositionBuffer
        accelerationStructure.maskBuffer = triangleMaskBuffer
        accelerationStructure.triangleCount = scene.vertices.count / 3
        accelerationStructure.rebuild()
    }
    
    private func updateUniforms() {
        
        uniformBufferOffset = alignedUniformsSize * uniformBufferIndex
        
        let uniformsPointer = uniformBuffer.contents().advanced(by: uniformBufferOffset)
        let uniforms = uniformsPointer.bindMemory(to: Uniforms.self, capacity: 1)
        
        let currentCam = scene.cameraManager.currentCamera!
        uniforms.pointee.camera.position = currentCam.position + currentCam.deltaPosition
        
        if  abs(currentCam.deltaPosition.x) > 0 ||
            abs(currentCam.deltaPosition.y) > 0 ||
            abs(currentCam.deltaPosition.z) > 0 {
            scene.cameraManager.currentCamera!.position += currentCam.deltaPosition
            scene.cameraManager.currentCamera!.deltaPosition = SIMD3<Float>(repeating: 0)
            frameIndex = 0
        }
        
        // rotating camera x and z w.r.t y
        var transform = matrix_identity_float4x4
        transform.rotate(angle: currentCam.rotation.y + currentCam.deltaRotation.y, axis: SIMD3<Float>(0, 1, 0))
        transform.rotate(angle: currentCam.rotation.x + currentCam.deltaRotation.x, axis: SIMD3<Float>(1, 0, 0))
        
        if  abs(currentCam.deltaRotation.x) > 0 ||
            abs(currentCam.deltaRotation.y) > 0 ||
            abs(currentCam.deltaRotation.z) > 0 {
            scene.cameraManager.currentCamera!.rotation += currentCam.deltaRotation
            scene.cameraManager.currentCamera!.deltaRotation = SIMD3<Float>(repeating: 0)
            frameIndex = 0
        }
        
        
        let newForward = transform * SIMD4<Float>(0, 0, -1, 1)
        let newRigth = transform * SIMD4<Float>(1, 0, 0, 1)
        let newUp = transform * SIMD4<Float>(0, 1, 0, 1)
        
        uniforms.pointee.camera.forward = SIMD3<Float>(newForward.x, newForward.y, newForward.z)
        uniforms.pointee.camera.right = SIMD3<Float>(newRigth.x, newRigth.y, newRigth.z)
        uniforms.pointee.camera.up = SIMD3<Float>(newUp.x, newUp.y, newUp.z)

        uniforms.pointee.light.position = SIMD3<Float>(0, 1.98, 0)
        uniforms.pointee.light.forward = SIMD3<Float>(0, -1, 0)
        uniforms.pointee.light.right = SIMD3<Float>(0.25, 0, 0)
        uniforms.pointee.light.up = SIMD3<Float>(0, 0, 0.25)
        uniforms.pointee.light.color = SIMD3<Float>(4, 4, 4)

        let fieldOfView = 45.0 * (Float.pi / 180.0)
        let aspectRatio = Float(size.width) / Float(size.height)
        let imagePlaneHeight = tanf(fieldOfView / 2.0)
        let imagePlaneWidth = aspectRatio * imagePlaneHeight

        uniforms.pointee.camera.right *= imagePlaneWidth
        uniforms.pointee.camera.up *= imagePlaneHeight

        uniforms.pointee.width = UInt32(size.width)
        uniforms.pointee.height = UInt32(size.height)

        uniforms.pointee.blocksWide = (uniforms.pointee.width + 15) / 16
        uniforms.pointee.frameIndex = frameIndex
        frameIndex += 1
        // For managed storage mode
        #if arch(x86_64)
        uniformBuffer.didModifyRange(uniformBufferOffset..<uniformBufferOffset + alignedUniformsSize)
        #endif

        uniformBufferIndex = (uniformBufferIndex + 1) % maxFramesInFlight
    }

    override func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        self.size = size

        lastCheckPoint = Date()
        timeIntervals.removeAll()


        let rayCount = Int(size.width * size.height)

        rayBuffer = device.makeBuffer(length: rayStride * rayCount, options: .storageModePrivate)
        shadowRayBuffer = device.makeBuffer(length: rayStride * rayCount, options: .storageModePrivate)
        intersectionBuffer = device.makeBuffer(length: intersectionStride * rayCount,
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
        
        frameIndex = 0
    }

    override func draw(in view: MTKView) {
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

        let commandBuffer = Engine.commandQueue.makeCommandBuffer()!
        commandBuffer.addCompletedHandler { [unowned self] cb in
            let executionDuration = cb.gpuEndTime - cb.gpuStartTime
            self.timeIntervals.append(executionDuration)
            self.semaphore.signal()
        }
        
        SceneManager.tickScene(deltaTime: 1.0/Float(view.preferredFramesPerSecond))
        updateUniforms()

        let width = Int(size.width)
        let height = Int(size.height)
        let w = rayPipeline.threadExecutionWidth
        let h = rayPipeline.maxTotalThreadsPerThreadgroup / w
        let threadsPerThreadgroup = MTLSizeMake(w, h, 1)


        let computeEncoder = commandBuffer.makeComputeCommandEncoder()!

        computeEncoder.setBuffer(uniformBuffer, offset: uniformBufferOffset, index: 0)
        computeEncoder.setBuffer(rayBuffer, offset: 0, index: 1)

        computeEncoder.setTexture(randomTexture, index: 0)
        computeEncoder.setTexture(renderTarget, index: 1)

        computeEncoder.setComputePipelineState(rayPipeline)

        let threadsPerGrid = MTLSizeMake(width, height, 1)
        computeEncoder.dispatchThreads(threadsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)

        computeEncoder.endEncoding()
        for i in 0..<maxBounce {
            intersector.intersectionDataType = .distancePrimitiveIndexCoordinates
            intersector.encodeIntersection(commandBuffer: commandBuffer,
                                           intersectionType: .nearest,
                                           rayBuffer: rayBuffer,
                                           rayBufferOffset: 0,
                                           intersectionBuffer: intersectionBuffer,
                                           intersectionBufferOffset: 0,
                                           rayCount: width * height,
                                           accelerationStructure: accelerationStructure)
            guard let shadeEncoder = commandBuffer.makeComputeCommandEncoder() else { return }

            let buffers = [uniformBuffer, rayBuffer, shadowRayBuffer, intersectionBuffer,
                           vertexColorBuffer, vertexNormalBuffer, vertexTangentBuffer, vertexBitangentBuffer, triangleMaskBuffer, materialBuffer, materialIdsBuffer, sourceTextures, textureIdsBuffer, uvCoordsBuffer]
            let offsets: [Int] = [uniformBufferOffset, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
            
            shadeEncoder.useHeap(heap.heap)
            shadeEncoder.setBuffers(buffers, offsets: offsets, range: 0..<buffers.count)
        
            var bounce = uint(i)
            
            shadeEncoder.setBytes(&bounce, length: uint.size, index: buffers.count)
            shadeEncoder.setTexture(randomTexture, index: 0)
            shadeEncoder.setTexture(renderTarget, index: 1)
            shadeEncoder.setTexture(scene.skyBox, index: 2)
            
            shadeEncoder.setSamplerState(textureSampler, index: 0)
            shadeEncoder.setComputePipelineState(shadePipeline)
            shadeEncoder.dispatchThreads(threadsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
            shadeEncoder.endEncoding()
            
            intersector.intersectionDataType = .distancePrimitiveIndex
            intersector.encodeIntersection(commandBuffer: commandBuffer, intersectionType: .any, rayBuffer: shadowRayBuffer, rayBufferOffset: 0, intersectionBuffer: intersectionBuffer, intersectionBufferOffset: 0, rayCount: width * height, accelerationStructure: accelerationStructure)
            
            
            intersector.intersectionDataType = .distance
            intersector.encodeIntersection(commandBuffer: commandBuffer,
                                           intersectionType: .any,
                                           rayBuffer: shadowRayBuffer,
                                           rayBufferOffset: 0,
                                           intersectionBuffer: intersectionBuffer,
                                           intersectionBufferOffset: 0,
                                           rayCount: width * height,
                                           accelerationStructure: accelerationStructure)

            guard let colorEncoder = commandBuffer.makeComputeCommandEncoder() else { return }
            colorEncoder.setBuffer(uniformBuffer, offset: uniformBufferOffset, index: 0)
            colorEncoder.setBuffer(shadowRayBuffer, offset: 0, index: 1)
            colorEncoder.setBuffer(intersectionBuffer, offset: 0, index: 2)

            colorEncoder.setTexture(renderTarget, index: 0)
            colorEncoder.setComputePipelineState(shadowPipeline)
            colorEncoder.dispatchThreads(threadsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
            colorEncoder.endEncoding()
            
        }
        
        guard let denoiseEncoder = commandBuffer.makeComputeCommandEncoder() else { return }
        denoiseEncoder.setBuffer(uniformBuffer, offset: uniformBufferOffset, index: 0)

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
    }
}
