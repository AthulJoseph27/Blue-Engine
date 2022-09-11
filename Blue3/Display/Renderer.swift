//
//  Renderer.swift
//  Rays iOS
//
//  Created by Viktor Chernikov on 17/04/2019.
//  Copyright © 2019 Viktor Chernikov. All rights reserved.
//

import MetalKit
import MetalPerformanceShaders
import simd
import os

let maxFramesInFlight = 3
let alignedUniformsSize = (MemoryLayout<Uniforms>.stride + 255) & ~255

let rayStride = 48
let intersectionStride = MemoryLayout<MPSIntersectionDistancePrimitiveIndexCoordinates>.size

enum RendererInitError: Error {
    case noDevice
    case noLibrary
    case noQueue
    case errorCreatingBuffer
}

class Renderer: NSObject, MTKViewDelegate {
    
    let view: MTKView
    let device: MTLDevice
    let queue: MTLCommandQueue
    let library: MTLLibrary
    var scene: SceneTemp!

    var accelerationStructure: MPSTriangleAccelerationStructure!
    var intersector: MPSRayIntersector!

    var vertexPositionBuffer: MTLBuffer!
    var vertexNormalBuffer: MTLBuffer!
    var vertexColorBuffer: MTLBuffer!
    var rayBuffer: MTLBuffer!
    var shadowRayBuffer: MTLBuffer!
    var intersectionBuffer: MTLBuffer!
    var uniformBuffer: MTLBuffer!
    var randomBuffer: MTLBuffer!
    var triangleMaskBuffer: MTLBuffer!

    var rayPipeline: MTLComputePipelineState!
    var shadePipeline: MTLComputePipelineState!
    var shadowPipeline: MTLComputePipelineState!
    var accumulatePipeline: MTLComputePipelineState!
    var copyPipeline: MTLRenderPipelineState!

    var renderTarget: MTLTexture!
    var accumulationTarget: MTLTexture!

    var semaphore: DispatchSemaphore!
    var size: CGSize!
    var randomBufferOffset: Int!
    var uniformBufferOffset: Int!
    var uniformBufferIndex: Int = 0

    var frameIndex: uint = 0

    var lastCheckPoint = Date()
    var timeIntervals: [CFTimeInterval] = []

    let display: (Double) -> Void

    init(withMetalKitView view: MTKView, displayCounter: @escaping (Double) -> Void) throws {
        display = displayCounter
        self.view = view
        self.device = Engine.device
        os_log("Metal device name is %s", device.name)

        semaphore = DispatchSemaphore(value: maxFramesInFlight)

        // Load Metal
        self.library = Engine.defaultLibrary
        self.queue = Engine.commandQueue
        
        super.init()
        
        self.createPipelines()
        self.createScene()
        self.createBuffers()
        self.createIntersector()
    }
    
    private func createPipelines() {
        self.rayPipeline = ComputePipelineStateLibrary.pipelineState(.GenerateRay).computePipelineState
        self.shadePipeline = ComputePipelineStateLibrary.pipelineState(.Shade).computePipelineState
        self.shadowPipeline = ComputePipelineStateLibrary.pipelineState(.Shadow).computePipelineState
        self.accumulatePipeline = ComputePipelineStateLibrary.pipelineState(.Accumulate).computePipelineState
        
        self.copyPipeline = RenderPipelineStateLibrary.pipelineState(.RayTracing)
    }
    
    private func createScene() {
        scene = SceneTemp()
        
        var transform = matrix_identity_float4x4
        transform.translate(direction: SIMD3<Float>(0, 1, 0))
        transform.scale(axis: SIMD3<Float>(0.5, 1.98, 0.5))
        
        scene.createCube(faceMask: Masks.FACE_MASK_POSITIVE_Y, color: SIMD3<Float>([1, 1, 1]), transform: transform, inwardNormals: true, triangleMask: uint(TRIANGLE_MASK_LIGHT))

        // Top, bottom, back
        transform = matrix_identity_float4x4
        transform.translate(direction: SIMD3<Float>(0, 1, 0))
        transform.scale(axis: SIMD3<Float>(2, 2, 2))
        scene.createCube(faceMask: Masks.FACE_MASK_NEGATIVE_Y | Masks.FACE_MASK_POSITIVE_Y | Masks.FACE_MASK_NEGATIVE_Z, color: SIMD3<Float>([0.725, 0.71, 0.68]), transform: transform, inwardNormals: true, triangleMask: uint(TRIANGLE_MASK_GEOMETRY))

        // Left wall
        scene.createCube(faceMask: Masks.FACE_MASK_NEGATIVE_X, color: SIMD3<Float>([0.63, 0.065, 0.05]), transform: transform, inwardNormals: true, triangleMask: uint(TRIANGLE_MASK_GEOMETRY))

        // Right wall
        scene.createCube(faceMask: Masks.FACE_MASK_POSITIVE_X, color: SIMD3<Float>([0.14, 0.45, 0.091]), transform: transform, inwardNormals: true, triangleMask: uint(TRIANGLE_MASK_GEOMETRY))

        // Short box
        transform = matrix_identity_float4x4
        transform.translate(direction: SIMD3<Float>(0.3275, 0.3, 0.3725))
        transform.rotate(angle: -0.3, axis: SIMD3<Float>(0, 1, 0))
        transform.scale(axis: SIMD3<Float>(0.6, 0.6, 0.6))
        
        scene.createCube(faceMask: Masks.FACE_MASK_ALL, color: SIMD3<Float>([0.725, 0.71, 0.68]), transform: transform, inwardNormals: false, triangleMask: uint(TRIANGLE_MASK_GEOMETRY))

        // Tall box
        transform = matrix_identity_float4x4
        transform.translate(direction: SIMD3<Float>(-0.335, 0.6, -0.29))
        transform.rotate(angle: 0.3, axis: SIMD3<Float>(0, 1, 0))
        transform.scale(axis: SIMD3<Float>(0.6, 1.2, 0.6))
        
        scene.createCube(faceMask: Masks.FACE_MASK_ALL, color: SIMD3<Float>([0.725, 0.71, 0.68]), transform: transform, inwardNormals: false, triangleMask: uint(TRIANGLE_MASK_GEOMETRY))
    }
    
    private func createBuffers() {
        var vertices = scene.vertices
        var normals = scene.normals
        var colors = scene.colors
        var masks = scene.masks

        let uniformBufferSize = alignedUniformsSize * maxFramesInFlight

        let storageOptions: MTLResourceOptions

        #if arch(x86_64)
        storageOptions = .storageModeManaged
        #else // iOS, tvOS
        storageOptions = .storageModeShared
        #endif


        self.uniformBuffer = device.makeBuffer(length: uniformBufferSize, options: storageOptions)
        self.randomBuffer = device.makeBuffer(length: 256 * maxFramesInFlight * SIMD2<Float>.stride, options: storageOptions)

        let float3Size = SIMD3<Float>.stride
        self.vertexPositionBuffer = device.makeBuffer(bytes: &vertices, length: vertices.count * float3Size, options: storageOptions)
        self.vertexColorBuffer = device.makeBuffer(bytes: &colors, length: colors.count * float3Size, options: storageOptions)
        self.vertexNormalBuffer = device.makeBuffer(bytes: &normals, length: normals.count * float3Size, options: storageOptions)
        self.triangleMaskBuffer = device.makeBuffer(bytes: &masks, length: masks.count * uint.stride, options: storageOptions)

        // When using managed buffers, we need to indicate that we modified the buffer so that the GPU
        // copy can be updated
        #if arch(x86_64)
        if storageOptions.contains(.storageModeManaged) {
            vertexPositionBuffer.didModifyRange(0..<vertexPositionBuffer.length)
            vertexColorBuffer.didModifyRange(0..<vertexColorBuffer.length)
            vertexNormalBuffer.didModifyRange(0..<vertexNormalBuffer.length)
            triangleMaskBuffer.didModifyRange(0..<triangleMaskBuffer.length)
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
        uniforms.pointee.camera.position = SIMD3<Float>(0, 1, 3.38)

        uniforms.pointee.camera.forward = SIMD3<Float>(0, 0, -1)
        uniforms.pointee.camera.right = SIMD3<Float>(1, 0, 0)
        uniforms.pointee.camera.up = SIMD3<Float>(0, 1, 0)

        uniforms.pointee.light.position = SIMD3<Float>(0, 1.98, 0)
        uniforms.pointee.light.forward = SIMD3<Float>(0, -1, 0)
        uniforms.pointee.light.right = SIMD3<Float>(0.25, 0, 0)
        uniforms.pointee.light.up = SIMD3<Float>(0, 0, 0.25)
        uniforms.pointee.light.color = SIMD3<Float>(4, 4, 4);

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

        randomBufferOffset = 256 * MemoryLayout<SIMD2<Float>>.stride * uniformBufferIndex
        let float2Pointer = randomBuffer.contents().advanced(by: randomBufferOffset)
        var randoms = float2Pointer.bindMemory(to: SIMD2<Float>.self, capacity: 1)
        for _ in 0..<256 {
            randoms.pointee = SIMD2<Float>(Float.random(in: 0..<1), Float.random(in: 0..<1))
            randoms = randoms.advanced(by: 1)
        }

        // For managed storage mode
        #if arch(x86_64)
        randomBuffer.didModifyRange(randomBufferOffset..<randomBufferOffset + 256 * MemoryLayout<SIMD2<Float>>.stride)
        #endif

        uniformBufferIndex = (uniformBufferIndex + 1) % maxFramesInFlight
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
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

        renderTarget = device.makeTexture(descriptor: renderTargetDescriptor)
        accumulationTarget = device.makeTexture(descriptor: renderTargetDescriptor)
        frameIndex = 0
    }

    func draw(in view: MTKView) {
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

        updateUniforms()

        let width = Int(size.width)
        let height = Int(size.height)
        let w = rayPipeline.threadExecutionWidth
        let h = rayPipeline.maxTotalThreadsPerThreadgroup / w
        let threadsPerThreadgroup = MTLSizeMake(w, h, 1)


        let computeEncoder = commandBuffer.makeComputeCommandEncoder()!

        computeEncoder.setBuffer(uniformBuffer, offset: uniformBufferOffset, index: 0)
        computeEncoder.setBuffer(rayBuffer, offset: 0, index: 1)
        computeEncoder.setBuffer(randomBuffer, offset: randomBufferOffset, index: 2)

        computeEncoder.setTexture(renderTarget, index: 0)

        computeEncoder.setComputePipelineState(rayPipeline)

        let threadsPerGrid = MTLSizeMake(width, height, 1)
        computeEncoder.dispatchThreads(threadsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)

        computeEncoder.endEncoding()
        for _ in 0..<5 {
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
                           vertexColorBuffer, vertexNormalBuffer, randomBuffer, triangleMaskBuffer]
            let offsets: [Int] = [uniformBufferOffset, 0, 0, 0, 0, 0, randomBufferOffset, 0]
            shadeEncoder.setBuffers(buffers, offsets: offsets, range: 0..<8)

            shadeEncoder.setTexture(renderTarget, index: 0)
            shadeEncoder.setComputePipelineState(shadePipeline)
            shadeEncoder.dispatchThreads(threadsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
            shadeEncoder.endEncoding()

            intersector.intersectionDataType = .distance
            intersector.encodeIntersection(commandBuffer: commandBuffer,
                                           intersectionType: .any,
                                           rayBuffer: shadowRayBuffer,
                                           rayBufferOffset: 0,
                                           intersectionBuffer: intersectionBuffer,
                                           intersectionBufferOffset: 0,
                                           rayCount: width * height,
                                           accelerationStructure: accelerationStructure)
            guard let colourEncoder = commandBuffer.makeComputeCommandEncoder() else { return }
            colourEncoder.setBuffer(uniformBuffer, offset: uniformBufferOffset, index: 0)
            colourEncoder.setBuffer(shadowRayBuffer, offset: 0, index: 1)
            colourEncoder.setBuffer(intersectionBuffer, offset: 0, index: 2)

            colourEncoder.setTexture(renderTarget, index: 0)
            colourEncoder.setComputePipelineState(shadowPipeline)
            colourEncoder.dispatchThreads(threadsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
            colourEncoder.endEncoding()
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
