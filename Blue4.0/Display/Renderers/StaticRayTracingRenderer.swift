import MetalKit
import MetalPerformanceShaders
import simd
import os

class StaticRayTracingRenderer: Renderer {

    private static let maxBounce = 6

    private static let maxFramesInFlight = 3
    private static let alignedUniformsSize = 0//(MemoryLayout<Uniforms>.stride + 255) & ~255

    private static let rayStride = 48
    
    let intersectionStride = MemoryLayout<MPSIntersectionDistancePrimitiveIndexCoordinates>.size
    
    var accelerationStructure: MPSTriangleAccelerationStructure!
    var intersector: MPSRayIntersector!

    var vertexBuffer:         MTLBuffer!
    var indexBuffer:          MTLBuffer!
    var triangleMaskBuffer:   MTLBuffer!
    
    var heap: Heap!

    
    override func initialize() {
//        semaphore = DispatchSemaphore(value: maxFramesInFlight)
        
        self.createPipelines()
        self.createScene()
        self.createBuffers()
        self.createIntersector()
        self.createAcceleratedStructure()
        heap = Heap()
//        heap.initialize(scene: scene, sourceTextureBuffer: &sourceTextures)
        
        let sampleDescriptor = MTLSamplerDescriptor()
        sampleDescriptor.minFilter = .linear
        sampleDescriptor.magFilter = .linear
        
//        self.textureSampler = device.makeSamplerState(descriptor: sampleDescriptor)
    }
    
    private func createPipelines() {
    }
    
    private func createScene() {

    }
    
    private func createBuffers() {

    }
    
    private func createIntersector() {
        intersector = MPSRayIntersector(device: device)
        intersector.rayDataType = .originMaskDirectionMaxDistance
        intersector.rayStride = StaticRayTracingRenderer.rayStride
        intersector.rayMaskOptions = .primitive
    }
    
    private func createAcceleratedStructure() {
//        accelerationStructure = MPSTriangleAccelerationStructure(device: device)
//        accelerationStructure.vertexBuffer = vertexPositionBuffer
//        accelerationStructure.maskBuffer = triangleMaskBuffer
//        accelerationStructure.triangleCount = scene.vertices.count / 3
//        accelerationStructure.rebuild()
    }
    
    private func updateUniforms() {
    
    }

    override func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
    }

    override func draw(in view: MTKView) {
        
    }
}
